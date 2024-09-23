use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
use pixelaw::core::actions::{
    IActionsDispatcher as ICoreActionsDispatcher,
    IActionsDispatcherTrait as ICoreActionsDispatcherTrait
};
use starknet::{ContractAddress, get_caller_address, ClassHash, get_contract_address, get_tx_info};

#[derive(Copy, Drop, Serde)]
#[dojo::model(namespace: "pixelaw", nomapping: true)]
pub struct App {
    #[key]
    pub system: ContractAddress,
    pub name: felt252,
    pub icon: felt252,
    // Default action for the UI (a function in the system)
    pub action: felt252
}

#[derive(Copy, Drop, Serde)]
#[dojo::model(namespace: "pixelaw", nomapping: true)]
pub struct AppUser {
    #[key]
    pub system: ContractAddress,
    #[key]
    pub player: ContractAddress,
    // Default action for the UI (a function in the system)
    pub action: felt252
    // TODO maybe other generic App/User specific settings can go here.
}

#[derive(Copy, Drop, Serde)]
#[dojo::model(namespace: "pixelaw", nomapping: true)]
pub struct AppName {
    #[key]
    pub name: felt252,
    pub system: ContractAddress
}

#[derive(Copy, Drop, Serde)]
#[dojo::model(namespace: "pixelaw", nomapping: true)]
pub struct CoreActionsAddress {
    #[key]
    pub key: felt252,
    pub value: ContractAddress
}

#[derive(Copy, Drop, Serde)]
#[dojo::model(namespace: "pixelaw", nomapping: true)]
pub struct Instruction {
    #[key]
    pub system: ContractAddress,
    #[key]
    pub selector: felt252,
    pub instruction: felt252
}
