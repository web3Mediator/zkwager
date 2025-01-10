use starknet::{ContractAddress};
// use starknet::class_hash::{ClassHash, };

use snforge_std::{declare, ContractClassTrait, DeclareResultTrait, start_cheat_caller_address, stop_cheat_caller_address};

use zkwager::Bet::IBetDispatcher;
use zkwager::Bet::IBetDispatcherTrait;

use zkwager::constants::{CALLER_1, CALLER_2, CALLER_3, STRK_TOKEN_CONTRACT};
use zkwager::types::{BetData};

use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};

fn DEFAULT_BET_PARAMS () -> BetData {
    BetData {
        players: array![CALLER_1(), CALLER_2(), CALLER_3()],
        token_contract: STRK_TOKEN_CONTRACT(),
        amount: 100,
    }
}

fn deploy_bet(bet_params:BetData) -> IBetDispatcher {
    let bet_contract = declare("Bet").unwrap().contract_class();
    
    let mut call_data = ArrayTrait::<felt252>::new();

    bet_params.players.serialize(ref call_data);
    bet_params.token_contract.serialize(ref call_data);
    bet_params.amount.serialize(ref call_data);

    let (contract_address, _) = bet_contract.deploy(@call_data).unwrap();

    let bet_dispatcher = IBetDispatcher { contract_address: contract_address };

    bet_dispatcher
}

#[test]
fn test_deploy() {
    let bet_params = DEFAULT_BET_PARAMS();
    let dispatcher = deploy_bet(bet_params);
    let bet_data = dispatcher.get_bet_data();

    assert_eq!(bet_data.players.len(), DEFAULT_BET_PARAMS().players.len(), "Players should be the same");
    assert_eq!(bet_data.token_contract, DEFAULT_BET_PARAMS().token_contract, "Token contract should be the same");
    assert_eq!(bet_data.amount, DEFAULT_BET_PARAMS().amount, "Amount should be the same");
}



#[test]
#[fork(url: "https://starknet-sepolia.public.blastapi.io/rpc/v0_7", block_number:428086)]
fn test_collect_bet_amount() {
    let dispatcher = deploy_bet(DEFAULT_BET_PARAMS());
    let token_dispatcher = IERC20Dispatcher { contract_address: STRK_TOKEN_CONTRACT() };
    fund_contract_for_gas(dispatcher.contract_address);

    // accept the bet
    approve_amount(token_dispatcher, CALLER_1(), dispatcher.contract_address, 100);
    approve_amount(token_dispatcher, CALLER_2(), dispatcher.contract_address, 100);
    approve_amount(token_dispatcher, CALLER_3(), dispatcher.contract_address, 100);

    // collect bet amount and close bet
    start_cheat_caller_address(dispatcher.contract_address, CALLER_1()); // should be called from game contract or something like that, not for a player OR for simplicity, that the one who creates the bet starts it, this make sense to me
    let previous_contract_balance = token_dispatcher.balance_of(dispatcher.contract_address);
    let previous_caller_1_balance = token_dispatcher.balance_of(CALLER_1());
    let previous_caller_2_balance = token_dispatcher.balance_of(CALLER_2());
    let previous_caller_3_balance = token_dispatcher.balance_of(CALLER_3());
    dispatcher.collect_bet_amount();
    let new_contract_balance = token_dispatcher.balance_of(dispatcher.contract_address);
    let new_caller_1_balance = token_dispatcher.balance_of(CALLER_1());
    let new_caller_2_balance = token_dispatcher.balance_of(CALLER_2());
    let new_caller_3_balance = token_dispatcher.balance_of(CALLER_3());
    stop_cheat_caller_address(dispatcher.contract_address);

    assert_eq!(new_contract_balance - previous_contract_balance, 300, "Contract balance should be 300"); // 3 players * 100 each one = 300
    assert_eq!(previous_caller_1_balance - new_caller_1_balance, 100, "Caller 1 balance should be 100 less");
    assert_eq!(previous_caller_2_balance - new_caller_2_balance, 100, "Caller 2 balance should be 100 less");
    assert_eq!(previous_caller_3_balance - new_caller_3_balance, 100, "Caller 3 balance should be 100 less");
}


#[test]
#[fork(url: "https://starknet-sepolia.public.blastapi.io/rpc/v0_7", block_number:428086)]
fn test_withdraw_prize() {
    let dispatcher = deploy_bet(DEFAULT_BET_PARAMS());
    
    let token_dispatcher = IERC20Dispatcher { contract_address: STRK_TOKEN_CONTRACT() };

    fund_contract_for_gas(dispatcher.contract_address);

    approve_amount(token_dispatcher, CALLER_1(), dispatcher.contract_address, 100);
    approve_amount(token_dispatcher, CALLER_2(), dispatcher.contract_address, 100);
    approve_amount(token_dispatcher, CALLER_3(), dispatcher.contract_address, 100);
    
    dispatcher.collect_bet_amount();

    start_cheat_caller_address(dispatcher.contract_address, CALLER_1());
    // in this case we are calling it from the winner account (like win the game and trigger the call, but, maybe should be call from a kind of game address?) maybe ERC-6551
    dispatcher.set_winner(CALLER_1());
    stop_cheat_caller_address(dispatcher.contract_address);

    start_cheat_caller_address(dispatcher.contract_address, CALLER_1());
    let previous_contract_balance = token_dispatcher.balance_of(dispatcher.contract_address);
    let previous_caller_balance = token_dispatcher.balance_of(CALLER_1());
    dispatcher.withdraw_prize();
    let new_contract_balance = token_dispatcher.balance_of(dispatcher.contract_address);
    let new_caller_balance = token_dispatcher.balance_of(CALLER_1());
    stop_cheat_caller_address(dispatcher.contract_address);
    
    assert_eq!(previous_contract_balance - new_contract_balance, 300, "Contract balance should be 300 less");
    assert_eq!(new_caller_balance - previous_caller_balance, 300, "Caller balance should be 300 more");
}

fn fund_contract_for_gas(contract_address:ContractAddress) {
    let token_dispatcher = IERC20Dispatcher { contract_address: STRK_TOKEN_CONTRACT() };
    start_cheat_caller_address(token_dispatcher.contract_address, CALLER_2());
    // adding a bit of tokens to the contract to pay for the gas
    token_dispatcher.transfer(contract_address, 100000);
    stop_cheat_caller_address(token_dispatcher.contract_address);
}

// dispatcher, owner, spender, amount
fn approve_amount(dispatcher:IERC20Dispatcher, owner:ContractAddress, spender:ContractAddress, amount:u256) {
    start_cheat_caller_address(dispatcher.contract_address, owner);
    dispatcher.approve(spender, amount);
    stop_cheat_caller_address(dispatcher.contract_address);
}

// Pending tests 
// - Test that some players not allow, they should be excluded from the bet 
