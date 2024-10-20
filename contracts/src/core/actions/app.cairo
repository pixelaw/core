use core::poseidon::poseidon_hash_span;
use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
use pixelaw::core::models::area::{
    BoundsTraitImpl, RTreeTraitImpl, ROOT_ID, RTreeNode, RTree, Area, RTreeNodePackableImpl
};
use pixelaw::core::models::pixel::{Pixel, PixelUpdate};
use pixelaw::core::models::queue::QueueItem;

use pixelaw::core::models::registry::{App, AppName, CoreActionsAddress};
use pixelaw::core::utils::{get_core_actions_address, Position, MAX_DIMENSION, Bounds};
use pixelaw::core::utils;
use starknet::{
    ContractAddress, get_caller_address, get_contract_address, get_tx_info, contract_address_const,
    syscalls::{call_contract_syscall},
};


pub fn new_app(
    world: IWorldDispatcher, system: ContractAddress, name: felt252, icon: felt252,
) -> App {
    let mut app_system = system;
    // If the system is not given, use the caller for this.
    // This is expected to be called from the `app.init()` function
    if system == contract_address_const::<0>() {
        app_system = get_caller_address();
    }

    // Load app
    let mut app = get!(world, app_system, (App));

    // Load app_name
    let mut app_name = get!(world, name, (AppName));

    // Ensure neither contract nor name have been registered
    assert!(app.name == 0 && app_name.system == contract_address_const::<0>(), "app already set");

    // Associate system with name
    app.name = name;
    app.icon = icon;

    // Associate name with system
    app_name.system = system;

    // Store both associations
    set!(world, (app, app_name));

    // Return the system association
    app
}
