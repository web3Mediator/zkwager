use starknet::{ContractAddress, contract_address_const};

// mock wallet addresses
pub fn CALLER_1() -> ContractAddress {
    contract_address_const::<0x123>()
}

pub fn CALLER_2() -> ContractAddress {
    contract_address_const::<0x456>()
}

pub fn CALLER_3() -> ContractAddress {
    contract_address_const::<0x789>()
}

// FT tokens 
pub fn STRK_TOKEN_CONTRACT() -> ContractAddress {
    contract_address_const::<0xabc>()
}