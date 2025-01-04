#[starknet::interface]
pub trait IGameRegister<TContractState> {
    fn register_game(ref self: TContractState, name:felt252) -> starknet::ContractAddress;
    fn get_games(self: @TContractState) -> Array<starknet::ContractAddress>;
    fn get_games_by_owner(self: @TContractState, owner:starknet::ContractAddress) -> Array<starknet::ContractAddress>;
    //
    fn get_owner(self: @TContractState) -> starknet::ContractAddress;
}


#[starknet::contract]
pub mod GameRegister {

    use starknet::storage::{
        StoragePointerReadAccess, StoragePointerWriteAccess,
        StoragePathEntry, Map,
        Vec, VecTrait, MutableVecTrait,
    };
    use starknet::{get_caller_address, ContractAddress, syscalls, SyscallResultTrait };
    use starknet::class_hash::ClassHash;

    use openzeppelin::access::ownable::OwnableComponent;

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    // Ownable Mixin
    #[abi(embed_v0)]
    impl OwnableMixinImpl = OwnableComponent::OwnableMixinImpl<ContractState>;
    impl InternalImpl = OwnableComponent::InternalImpl<ContractState>;

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        OwnableEvent: OwnableComponent::Event
    }

    #[storage]
    struct Storage {
        games: Vec<ContractAddress>, // games
        games_by_owner: Map<ContractAddress, Vec<ContractAddress>>, // owner -> games
        game_class_hash: ClassHash,
        bet_clash_hash: ClassHash,
        salt_counter: u256,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage
    }

    #[constructor]
    fn constructor(ref self: ContractState, game_class_hash:ClassHash, bet_clash_hash:ClassHash) {
        self.game_class_hash.write(game_class_hash);
        self.bet_clash_hash.write(bet_clash_hash);
        self.salt_counter.write(0);
        self.ownable.initializer(get_caller_address());
    }

    #[abi(embed_v0)]
    impl GameRegisterImpl of super::IGameRegister<ContractState> {
        fn register_game(ref self: ContractState, name:felt252) -> ContractAddress {
            let game_class_hash = self.game_class_hash.read();
            let salt = self.salt_counter.read();
            let game_owner = get_caller_address();
            
            let mut call_data = ArrayTrait::<felt252>::new();
            self.bet_clash_hash.read().serialize(ref call_data);
            call_data.append(name);
            call_data.append(game_owner.into());

            let (game_contract_address, _) = syscalls::deploy_syscall(game_class_hash, salt.try_into().unwrap(), call_data.span(), false).unwrap_syscall();
            
            self.salt_counter.write(salt+1);
            self.games_by_owner.entry(game_owner).append().write(game_contract_address);
            self.games.append().write(game_contract_address);
            
            game_contract_address
        }

        fn get_games(self: @ContractState) -> Array<ContractAddress> {
            let mut games:Array<ContractAddress> = array![];

            for index in 0..self.games.len() {
                let mut game_address = self.games.at(index).read();
                games.append(game_address);
            };

            games
        }

        fn get_games_by_owner(self: @ContractState, owner:ContractAddress) -> Array<ContractAddress> {
            let mut games:Array<ContractAddress> = array![];
            let games_vec = self.games_by_owner.entry(owner);

            for index in 0..games_vec.len() {
                games.append(games_vec.at(index).read());
            };

            games
        }

        /////
        fn get_owner(self: @ContractState) -> starknet::ContractAddress {
            self.ownable.owner()
        }
    }
}
