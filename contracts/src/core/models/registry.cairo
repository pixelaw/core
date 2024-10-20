use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
use pixelaw::core::actions::{
    IActionsDispatcher as ICoreActionsDispatcher,
    IActionsDispatcherTrait as ICoreActionsDispatcherTrait
};
use starknet::{ContractAddress, get_caller_address, ClassHash, get_contract_address, get_tx_info};

#[derive(Debug, Copy, Drop, Serde)]
#[dojo::model(namespace: "pixelaw", nomapping: true)]
pub struct App {
    #[key]
    pub system: ContractAddress,
    pub name: felt252,
    pub icon: felt252,
    // Default action for the UI (a function in the system)
    pub action: felt252
}

pub trait AppCalldataTrait<App> {
    fn add_to_calldata(self: App, ref calldata: Array<felt252>);
}

pub impl AppCalldataTraitImpl of AppCalldataTrait<App> {
    fn add_to_calldata(self: App, ref calldata: Array<felt252>) {
        calldata.append(self.system.into());
        calldata.append(self.name.into());
        calldata.append(self.icon.into());
        calldata.append(self.action.into());
    }
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

