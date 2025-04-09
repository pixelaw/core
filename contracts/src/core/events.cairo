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
pub struct Notification {
    #[key]
    pub position: Position,
    pub app: ContractAddress,
    pub color: u32,
    pub from: Option<ContractAddress>,
    pub to: Option<ContractAddress>,
    pub text: felt252,
}

