use starknet::{ContractAddress};

use snforge_std::{declare, ContractClassTrait, DeclareResultTrait, start_cheat_caller_address, stop_cheat_caller_address, start_cheat_caller_address_global, stop_cheat_caller_address_global};

use zkwager::GameRegister::IGameRegisterDispatcher;
use zkwager::GameRegister::IGameRegisterDispatcherTrait;
use zkwager::Game::IGameDispatcher;
use zkwager::Game::IGameDispatcherTrait;
use zkwager::Bet::IBetDispatcher;
use zkwager::Bet::IBetDispatcherTrait;

use zkwager::constants::{CALLER_1, CALLER_2, CALLER_3, OWNER, STRK_TOKEN_CONTRACT};
use zkwager::types::{BetData};

use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};

fn DEFAULT_BET_PARAMS () -> BetData {
    BetData {
        players: array![CALLER_1(), CALLER_2(), CALLER_3()],
        token_contract: STRK_TOKEN_CONTRACT(),
        amount: 100,
    }
}

fn fund_contract_for_gas(contract_address:ContractAddress) {
    let token_dispatcher = IERC20Dispatcher { contract_address: STRK_TOKEN_CONTRACT() };
    start_cheat_caller_address(token_dispatcher.contract_address, CALLER_2());
    // adding a bit of tokens to the contract to pay for the gas
    token_dispatcher.transfer(contract_address, 100000);
    stop_cheat_caller_address(token_dispatcher.contract_address);
}

fn approve_amount(dispatcher:IERC20Dispatcher, owner:ContractAddress, spender:ContractAddress, amount:u256) {
    start_cheat_caller_address(dispatcher.contract_address, owner);
    dispatcher.approve(spender, amount);
    stop_cheat_caller_address(dispatcher.contract_address);
}

fn deploy_game_register() -> IGameRegisterDispatcher {
    start_cheat_caller_address_global(OWNER());
    let game_clash_hash = declare("Game").unwrap().contract_class().class_hash;
    let bet_clash_hash = declare("Bet").unwrap().contract_class().class_hash;
    let mut call_data = ArrayTrait::<felt252>::new();
    game_clash_hash.serialize(ref call_data);
    bet_clash_hash.serialize(ref call_data);
    
    let contract = declare("GameRegister").unwrap().contract_class();
    let (contract_address, _) = contract.deploy(@call_data).unwrap();
    let dispatcher = IGameRegisterDispatcher { contract_address };
    stop_cheat_caller_address_global();
    dispatcher
}

#[test]
#[fork(url: "https://starknet-sepolia.public.blastapi.io/rpc/v0_7", block_number:428086)]
fn test_full_flow() {
    // deploy register game contract and get dispatcher
    let game_register_dispatcher = deploy_game_register();
    
    // create a game and its dispatcher
    start_cheat_caller_address(game_register_dispatcher.contract_address, OWNER());
    let game_address = game_register_dispatcher.register_game('test_game');
    let game_dispatcher = IGameDispatcher { contract_address: game_address };
    stop_cheat_caller_address(game_register_dispatcher.contract_address);
    
    // create a bet and get its dispatcher
    let bet_params = DEFAULT_BET_PARAMS();
    start_cheat_caller_address(game_dispatcher.contract_address, CALLER_1());
    let bet_address = game_dispatcher.create_bet(bet_params.players, bet_params.token_contract, bet_params.amount);
    let bet_dispatcher = IBetDispatcher { contract_address: bet_address };
    stop_cheat_caller_address(game_dispatcher.contract_address);

    // testing bet flow 
    let token_dispatcher = IERC20Dispatcher { contract_address: STRK_TOKEN_CONTRACT() };

    fund_contract_for_gas(bet_dispatcher.contract_address);

    approve_amount(token_dispatcher, CALLER_1(), bet_dispatcher.contract_address, 100);
    approve_amount(token_dispatcher, CALLER_2(), bet_dispatcher.contract_address, 100);
    approve_amount(token_dispatcher, CALLER_3(), bet_dispatcher.contract_address, 100);
    
    bet_dispatcher.collect_bet_amount();

    start_cheat_caller_address(bet_dispatcher.contract_address, CALLER_1());
    // in this case we are calling it from the winner account (like win the game and trigger the call, but, maybe should be call from a kind of game address?) maybe ERC-6551
    bet_dispatcher.set_winner(CALLER_1());
    stop_cheat_caller_address(bet_dispatcher.contract_address);

    start_cheat_caller_address(bet_dispatcher.contract_address, CALLER_1());
    bet_dispatcher.withdraw_prize();
    stop_cheat_caller_address(bet_dispatcher.contract_address);
    
}
