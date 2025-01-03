use starknet::{ContractAddress, contract_address_const};

pub fn OWNER() -> ContractAddress {
    contract_address_const::<0x123>()
}
// mock wallet addresses with tokens
pub fn CALLER_1() -> ContractAddress {
    contract_address_const::<0x0416575467BBE3E3D1ABC92d175c71e06C7EA1FaB37120983A08b6a2B2D12794>()
}

pub fn CALLER_2() -> ContractAddress {
    contract_address_const::<0x0092fB909857ba418627B9e40A7863F75768A0ea80D306Fb5757eEA7DdbBd4Fc>()
}

pub fn CALLER_3() -> ContractAddress {
    contract_address_const::<0x05f76B9ADf5D18Ca000ef6e7e9B7cBef63c72749426E91C1b206b42CEDAd7E1E>()
}

// FT tokens 
pub fn STRK_TOKEN_CONTRACT() -> ContractAddress {
    contract_address_const::<0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d>()
}