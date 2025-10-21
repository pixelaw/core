use dojo::model::ModelStorage;
use dojo::world::storage::WorldStorage;
use pixelaw::core::models::area::{BoundsTraitImpl, RTreeNodePackableImpl, RTreeTraitImpl};
use pixelaw::core::models::registry::{App, AppName};
use starknet::{ContractAddress, get_caller_address};

pub fn new_app(
    ref world: WorldStorage, system: ContractAddress, name: felt252, icon: felt252,
) -> App {
    let mut app_system = system;
    // If the system is not given, use the caller for this.
    // This is expected to be called from the `app.init()` function
    if system == 0.try_into().unwrap() {
        app_system = get_caller_address();
    }

    // Load app
    let mut app: App = world.read_model(app_system);

    // Load app_name
    let mut app_name: AppName = world.read_model(name);

    // Ensure neither contract nor name have been registered
    assert!(app.name == 0 && app_name.system == 0.try_into().unwrap(), "app already set");

    // Associate system with name
    app.name = name;
    app.icon = icon;

    // TODO add plugin

    // Associate name with system
    app_name.system = system;

    // Store both associations
    world.write_model(@app_name);
    world.write_model(@app);

    // Return the system association
    app
}
