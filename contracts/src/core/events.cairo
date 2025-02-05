use pixelaw::core::utils::{Position};
use starknet::{ContractAddress};


#[derive(Drop, Debug, PartialEq, Serde)]
#[dojo::event]
pub struct QueueScheduled {
    #[key]
    pub id: felt252,
    pub timestamp: u64,
    pub called_system: ContractAddress,
    pub selector: felt252,
    pub calldata: Span<felt252>,
}

#[derive(Drop, Debug, PartialEq, Serde)]
#[dojo::event]
pub struct QueueProcessed {
    #[key]
    pub id: felt252,
    pub result: felt252,
}


#[derive(Drop, Debug, PartialEq, Serde)]
#[dojo::event]
pub struct Alert {
    #[key]
    pub position: Position,
    pub caller: ContractAddress,
    pub player: ContractAddress,
    pub message: felt252,
    pub timestamp: u64,
}

