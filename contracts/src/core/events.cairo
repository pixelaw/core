use pixelaw::core::models::registry::{App};
use pixelaw::core::utils::{Position};
use starknet::{ContractAddress};


#[derive(Drop, starknet::Event, Debug, PartialEq)]
pub struct QueueScheduled {
    pub id: felt252,
    pub timestamp: u64,
    pub called_system: ContractAddress,
    pub selector: felt252,
    pub calldata: Span<felt252>,
}

#[derive(Drop, starknet::Event, Debug, PartialEq)]
pub struct QueueProcessed {
    pub id: felt252,
}

#[derive(Drop, starknet::Event)]
pub struct AppNameUpdated {
    pub app: App,
    pub caller: felt252,
}

#[derive(Debug, Drop, Serde, starknet::Event, PartialEq)]
pub struct Alert {
    pub position: Position,
    pub caller: ContractAddress,
    pub player: ContractAddress,
    pub message: felt252,
    pub timestamp: u64,
}

