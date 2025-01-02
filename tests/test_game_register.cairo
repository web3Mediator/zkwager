use starknet::{ContractAddress, get_caller_address, contract_address_const};
// use starknet::class_hash::{ClassHash, };

use snforge_std::{declare, ContractClassTrait, DeclareResultTrait, start_cheat_caller_address, stop_cheat_caller_address};

use zkwager::GameRegister::IGameRegisterDispatcher;
use zkwager::GameRegister::IGameRegisterDispatcherTrait;

use zkwager::constants::{CALLER_1, CALLER_2};

fn deploy_game_register() -> IGameRegisterDispatcher {

    let game_clash_hash = declare("Game").unwrap().contract_class().class_hash;
    let bet_clash_hash = declare("Bet").unwrap().contract_class().class_hash;
    let mut call_data = ArrayTrait::<felt252>::new();
    game_clash_hash.serialize(ref call_data);
    bet_clash_hash.serialize(ref call_data);

    let contract = declare("GameRegister").unwrap().contract_class();
    let (contract_address, _) = contract.deploy(@call_data).unwrap();
    let dispatcher = IGameRegisterDispatcher { contract_address };
    dispatcher
}

#[test]
fn test_deploy() {
    let dispatcher = deploy_game_register();
    let games = dispatcher.get_games();

    assert_eq!(games.len(), 0, "Games should be empty right after deployment");
}

#[test]
fn test_register_game() {
    let dispatcher = deploy_game_register();

    start_cheat_caller_address(dispatcher.contract_address, CALLER_1());
    let game_address = dispatcher.register_game('test_game');
    let games = dispatcher.get_games();
    let games_by_owner = dispatcher.get_games_by_owner(CALLER_1());
    stop_cheat_caller_address(dispatcher.contract_address);

    assert_eq!(games.len(), 1, "Games should contain one game after registration");
    assert_eq!(*games.at(0), game_address, "The registered game should be in the games list");
    assert_eq!(games_by_owner.len(), 1, "Games by owner should contain one game after registration");
    assert_eq!(*games_by_owner.at(0), game_address, "The registered game should be in the games by owner list");
}

#[test]
fn test_register_multiple_games() {
    let dispatcher = deploy_game_register();

    start_cheat_caller_address(dispatcher.contract_address, CALLER_1());
    let game_address_1 = dispatcher.register_game('test_game_1');
    let game_address_2 = dispatcher.register_game('test_game_2');
    let games = dispatcher.get_games();
    let games_by_owner = dispatcher.get_games_by_owner(CALLER_1());
    stop_cheat_caller_address(dispatcher.contract_address);

    assert_eq!(games.len(), 2, "Games should contain two games after registration");
    assert_eq!(*games.at(0), game_address_1, "The first registered game should be in the games list");
    assert_eq!(*games.at(1), game_address_2, "The second registered game should be in the games list");
    assert_eq!(games_by_owner.len(), 2, "Games by owner should contain two games after registration");
    assert_eq!(*games_by_owner.at(0), game_address_1, "The first registered game should be in the games by owner list");
    assert_eq!(*games_by_owner.at(1), game_address_2, "The second registered game should be in the games by owner list");
}

#[test]
fn test_register_multiple_games_from_different_owners () {
    let dispatcher = deploy_game_register();

    start_cheat_caller_address(dispatcher.contract_address, CALLER_1());
    let game_address_1 = dispatcher.register_game('test_game_1');
    stop_cheat_caller_address(dispatcher.contract_address);

    start_cheat_caller_address(dispatcher.contract_address, CALLER_2());
    let game_address_2 = dispatcher.register_game('test_game_2');
    stop_cheat_caller_address(dispatcher.contract_address);

    let games = dispatcher.get_games();
    let games_by_owner_1 = dispatcher.get_games_by_owner(CALLER_1());
    let games_by_owner_2 = dispatcher.get_games_by_owner(CALLER_2());

    assert_eq!(games.len(), 2, "Games should contain two games after registration");
    assert_eq!(*games.at(0), game_address_1, "The first registered game should be in the games list");
    assert_eq!(*games.at(1), game_address_2, "The second registered game should be in the games list");

    assert_eq!(games_by_owner_1.len(), 1, "Games by owner 1 should contain one game after registration");
    assert_eq!(*games_by_owner_1.at(0), game_address_1, "The first registered game should be in the games by owner 1 list");

    assert_eq!(games_by_owner_2.len(), 1, "Games by owner 2 should contain one game after registration");
    assert_eq!(*games_by_owner_2.at(0), game_address_2, "The second registered game should be in the games by owner 2 list");
}

