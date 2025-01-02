use starknet::ContractAddress;

#[derive(Drop, Serde)]
pub struct BetData {
    pub players: Array<ContractAddress>,
    pub token_contract: ContractAddress,
    pub amount: u256,
}