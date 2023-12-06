use starknet::{ContractAddress, get_caller_address, ClassHash, get_contract_address, get_tx_info};

use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
use pixelaw::core::actions::{
    IActionsDispatcher as ICoreActionsDispatcher,
    IActionsDispatcherTrait as ICoreActionsDispatcherTrait
};

#[derive(Model, Copy, Drop, Serde)]
struct App {
    #[key]
    system: ContractAddress,
    name: felt252,
    // ipfs link to the contract's manifest.json
    manifest: felt252,
    icon: felt252,
    // Default action for the UI (a function in the system)
    action: felt252
}

#[derive(Model, Copy, Drop, Serde)]
struct AppUser {
    #[key]
    system: ContractAddress,
    #[key]
    player: ContractAddress,
    // Default action for the UI (a function in the system)
    action: felt252
    // TODO maybe other generic App/User specific settings can go here.
}

#[derive(Model, Copy, Drop, Serde)]
struct AppName {
    #[key]
    name: felt252,
    system: ContractAddress
}

#[derive(Model, Copy, Drop, Serde)]
struct CoreActionsAddress {
    #[key]
    key: felt252,
    value: ContractAddress
}

#[derive(Model, Copy, Drop, Serde)]
struct Instruction {
  #[key]
  system: ContractAddress,
  #[key]
  selector: felt252,
  instruction: felt252
}




