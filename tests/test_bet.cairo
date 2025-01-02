use starknet::{ContractAddress, get_caller_address, contract_address_const};
// use starknet::class_hash::{ClassHash, };

use snforge_std::{declare, ContractClassTrait, DeclareResultTrait, start_cheat_caller_address, stop_cheat_caller_address, start_cheat_caller_address_global, stop_cheat_caller_address_global};

use zkwager::GameRegister::IGameRegisterDispatcher;
use zkwager::GameRegister::IGameRegisterDispatcherTrait;
use zkwager::Game::IGameDispatcher;
use zkwager::Game::IGameDispatcherTrait;
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

    let game_clash_hash = declare("Game").unwrap().contract_class().class_hash;
    let bet_clash_hash = declare("Bet").unwrap().contract_class().class_hash;
    let mut call_data = ArrayTrait::<felt252>::new();
    game_clash_hash.serialize(ref call_data);
    bet_clash_hash.serialize(ref call_data);

    let contract = declare("GameRegister").unwrap().contract_class();
    let (contract_address, _) = contract.deploy(@call_data).unwrap();
    let game_register_dispatcher = IGameRegisterDispatcher { contract_address };

    let game_address = game_register_dispatcher.register_game('test_game');
    let game_dispatcher = IGameDispatcher { contract_address: game_address };

    let bet_address = game_dispatcher.create_bet(bet_params.players, bet_params.token_contract, bet_params.amount);
       
    let bet_dispatcher = IBetDispatcher { contract_address: bet_address };

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
fn test_receive_amount() {
    let dispatcher = deploy_bet(DEFAULT_BET_PARAMS());
    let token_dispatcher = IERC20Dispatcher { contract_address: STRK_TOKEN_CONTRACT() };

    fund_contract_for_gas(dispatcher.contract_address);

    start_cheat_caller_address_global(CALLER_1());
    token_dispatcher.approve(dispatcher.contract_address, 100);
    // dispatcher.receive_amount();
    stop_cheat_caller_address_global();
}

fn fund_contract_for_gas(contract_address:ContractAddress) {
    let token_dispatcher = IERC20Dispatcher { contract_address: STRK_TOKEN_CONTRACT() };
    start_cheat_caller_address(token_dispatcher.contract_address, CALLER_2());
    // adding a bit of tokens to the contract to pay for the gas
    token_dispatcher.transfer(contract_address, 10000);
    stop_cheat_caller_address(token_dispatcher.contract_address);
}
