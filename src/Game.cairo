/// Interface representing `HelloContract`.
/// This interface allows modification and retrieval of the contract balance.
#[starknet::interface]
pub trait IGame<TContractState> {
    fn create_bet(
        ref self: TContractState, 
        players: Array::<starknet::ContractAddress>, 
        token_address:starknet::ContractAddress, // the currency used for the bet (exp: STRK, ETH, ...)
        amount_per_player:u256, // the amount each player has to pay
    ) -> starknet::ContractAddress;
    fn get_bets(self: @TContractState) -> Array::<starknet::ContractAddress>;
    fn get_bets_by_player(self: @TContractState, player:starknet::ContractAddress) -> Array::<starknet::ContractAddress>;
}

/// Simple contract for managing balance.
#[starknet::contract]
pub mod Game {
    use starknet::{ContractAddress, get_caller_address, contract_address_const, syscalls, SyscallResultTrait};
    use starknet::class_hash::ClassHash;
    use starknet::storage::{
        StoragePointerReadAccess, StoragePointerWriteAccess,
        StoragePathEntry, Map,
        Vec, VecTrait, MutableVecTrait,
    };

    #[storage]
    struct Storage {
        bet_class_hash: ClassHash,
        name: felt252, // name of the game
        owner: ContractAddress, // the one who deployed the contract
        bets: Vec<ContractAddress>, // bets
        bets_by_player: Map<ContractAddress, Vec<ContractAddress>>, // player -> bets
        salt_counter:u256,
    }

    #[constructor]
    fn constructor(ref self: ContractState, bet_class_hash:ClassHash, name:felt252) {
        self.bet_class_hash.write(bet_class_hash);
        self.name.write(name);
        self.owner.write(get_caller_address());
    }

    #[abi(embed_v0)]
    impl GameImpl of super::IGame<ContractState> {
        fn create_bet(ref self: ContractState, players: Array::<starknet::ContractAddress>, token_address:starknet::ContractAddress, amount_per_player:u256) -> ContractAddress {
            let game_class_hash = self.bet_class_hash.read();
            let salt = self.salt_counter.read();
            
            let mut call_data = ArrayTrait::<felt252>::new();
            players.serialize(ref call_data);
            token_address.serialize(ref call_data);
            amount_per_player.serialize(ref call_data);

            let (bet_contract_address, _) = syscalls::deploy_syscall(game_class_hash, salt.try_into().unwrap(), call_data.span(), false).unwrap_syscall();
            
            self.salt_counter.write(salt+1);
            self.bets.append().write(bet_contract_address);

            for i in 0..players.len() {
                self.bets_by_player.entry(*players.at(i)).append().write(bet_contract_address);
            };

            bet_contract_address
        }

        fn get_bets(self: @ContractState) -> Array::<starknet::ContractAddress> {
            let mut bets:Array::<starknet::ContractAddress> = array![];

            for index in 0..self.bets.len() {
                let bet_address = self.bets.at(index).read();
                bets.append(bet_address);
            };

            bets
        }

        fn get_bets_by_player(self: @ContractState, player:starknet::ContractAddress) -> Array::<starknet::ContractAddress> {
            let mut bets:Array::<starknet::ContractAddress> = array![];
            let bets_vec = self.bets_by_player.entry(player);

            for index in 0..bets_vec.len() {
                let bet_address = bets_vec.at(index).read();
                bets.append(bet_address);
            };

            bets
        }

    }
}
