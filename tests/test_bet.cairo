use starknet::{ContractAddress, get_caller_address, contract_address_const};
// use starknet::class_hash::{ClassHash, };

use snforge_std::{declare, ContractClassTrait, DeclareResultTrait, start_cheat_caller_address, stop_cheat_caller_address};

use zkwager::GameRegister::IGameRegisterDispatcher;
use zkwager::GameRegister::IGameRegisterDispatcherTrait;
use zkwager::Game::IGameDispatcher;
use zkwager::Game::IGameDispatcherTrait;
use zkwager::Bet::IBetDispatcher;
use zkwager::Bet::IBetDispatcherTrait;

use zkwager::constants::{CALLER_1, CALLER_2, CALLER_3, STRK_TOKEN_CONTRACT};
use zkwager::types::{BetData};

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

// #[test]
// fn test_create_bet() {
//     let dispatcher = deploy_game();

//     start_cheat_caller_address(dispatcher.contract_address, CALLER_1());
//     let bet_address = dispatcher.create_bet(array![CALLER_1(), CALLER_2()], STRK_TOKEN_CONTRACT(), 100);
//     let bets = dispatcher.get_bets();
//     let bets_by_player_1 = dispatcher.get_bets_by_player(CALLER_1());
//     let bets_by_player_2 = dispatcher.get_bets_by_player(CALLER_2());
//     stop_cheat_caller_address(dispatcher.contract_address);

//     assert_eq!(bets.len(), 1, "Bets should contain one bet after creation");
//     assert_eq!(*bets.at(0), bet_address, "The created bet should be in the bets list");

//     assert_eq!(bets_by_player_1.len(), 1, "Bets by player 1 should contain one bet after creation");
//     assert_eq!(*bets_by_player_1.at(0), bet_address, "The created bet should be in the bets by player 1 list");

//     assert_eq!(bets_by_player_2.len(), 1, "Bets by player 2 should contain one bet after creation");
//     assert_eq!(*bets_by_player_2.at(0), bet_address, "The created bet should be in the bets by player 2 list");
// }

