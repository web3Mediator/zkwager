/// Interface representing `HelloContract`.
/// This interface allows modification and retrieval of the contract balance.
#[starknet::interface]
pub trait IBet<TContractState> {
    fn receive_amount(ref self: TContractState); // transfer from the caller address to the contract
    fn close_bet(ref self: TContractState);
    fn get_bet_data(self: @TContractState) -> zkwager::types::BetData; 
    fn set_winner(ref self: TContractState, winner: starknet::ContractAddress);
    fn withdraw_prize(ref self: TContractState);
}

/// Simple contract for managing balance.
#[starknet::contract]
pub mod Bet {
    use starknet::{ContractAddress, get_caller_address, get_contract_address, contract_address_const, syscalls, SyscallResultTrait};
    use starknet::class_hash::ClassHash;
    use starknet::storage::{
        StoragePointerReadAccess, StoragePointerWriteAccess,
        StoragePathEntry, Map,
        Vec, VecTrait, MutableVecTrait,
    };
    use zkwager::types::{BetData};

    use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};

    

    #[storage]
    struct Storage {
        players: Vec<ContractAddress>, 
        paid_players: Vec<ContractAddress>,
        amount_per_player: u256,
        winner: ContractAddress,
        token_address: ContractAddress,
        closed: bool,
        finished: bool,
    }
    
    #[constructor]
    fn constructor(
        ref self: ContractState,
        players: Array::<ContractAddress>,
        token_address: ContractAddress,
        amount_per_player: u256,
    ) {
        self.amount_per_player.write(amount_per_player);
        self.token_address.write(token_address);
        for i in 0..players.len() {
            self.players.append().write(*players.at(i));
        };
        self.closed.write(false);
        self.finished.write(false);
    }

    #[abi(embed_v0)]
    impl BetImpl of super::IBet<ContractState> {
        fn receive_amount(ref self: ContractState) {
            assert!(!self.closed.read(), "The bet should be open to receive amounts");
            // transfer from the caller address to the contract
            let token_address = self.token_address.read();
            let amount_per_player = self.amount_per_player.read();
            let caller_address = get_caller_address();
            let contract_address = get_contract_address();
            let dispatcher = IERC20Dispatcher { contract_address:token_address };

            let allowance = dispatcher.allowance(caller_address, contract_address);
            dispatcher.transfer_from(caller_address, contract_address, amount_per_player);

            self.paid_players.append().write(caller_address);
        }


        fn close_bet(ref self: ContractState) {
            // this should be called just for game contract
            self.closed.write(true);
        }

        fn get_bet_data(self: @ContractState) -> BetData {
            let mut players = ArrayTrait::<ContractAddress>::new();            
            for i in 0..self.players.len() {
                let player_address = self.players.at(i).read();
                players.append(player_address);
            };
            let amount_per_player = self.amount_per_player.read();
            let token_address = self.token_address.read();
            let closed = self.closed.read();
            let finished = self.finished.read();
            BetData {
                players: players,
                token_contract: token_address,
                amount: amount_per_player,
            }
        }

        fn set_winner(ref self: ContractState, winner: ContractAddress) {
            self.winner.write(winner);
            self.finished.write(true);
        }

        fn withdraw_prize(ref self: ContractState) {
            assert!(self.finished.read(), "The bet should be finished before withdrawing the prize");
            assert!(self.winner.read() == get_caller_address(), "Only the winner can withdraw the prize");
            // ??? transfer to 0??
            let token_address = self.token_address.read();
            let amount_per_player = self.amount_per_player.read();
            let winner = self.winner.read();
            let dispatcher = IERC20Dispatcher { contract_address:token_address };
            let amount = self.paid_players.len().into() * amount_per_player;
            dispatcher.transfer(winner, amount);
        }
        
    }
}
