use starknet::{
    get_block_timestamp, contract_address_const, ClassHash, ContractAddress,
    testing::{set_block_timestamp, set_account_contract_address},
};

use core::{traits::TryInto, poseidon::poseidon_hash_span};

use dojo::{
    utils::test::{spawn_test_world, deploy_contract},
    world::{IWorldDispatcher, IWorldDispatcherTrait}
};

use pixelaw::core::{
    models::{
        registry::{App, AppName, app, app_name, core_actions_address, CoreActionsAddress},
        pixel::{Pixel, PixelUpdate, pixel}, permissions::{permissions}
    },
    actions::{actions, IActionsDispatcher, IActionsDispatcherTrait, CORE_ACTIONS_KEY},
    utils::{get_core_actions, Direction, Position, DefaultParameters},
    tests::helpers::{setup, setup_apps}
};


#[test]
#[available_gas(30000000)]
fn test_core() {
    let ZERO_ADDRESS: ContractAddress = contract_address_const::<0>();

    let (world, core_actions, player_1, player_2) = setup();
    let position = Position { x: 0, y: 0 };

    // core_actions.init
    let core_address = get!(world, CORE_ACTIONS_KEY, (CoreActionsAddress));
    assert(core_address.value == ZERO_ADDRESS, 'should be 0');

    core_actions.init();

    let core_address = get!(world, CORE_ACTIONS_KEY, (CoreActionsAddress));
    assert(core_address.value != ZERO_ADDRESS, 'should not be 0');


    // new_app
    let mock_app1_system = contract_address_const::<0xBEEF>();
    let mock_app1_name = 'app1';
    let _new_app1: App = core_actions.new_app(mock_app1_system, mock_app1_name, '', '');
    // TODO check return values

    let loaded_app1_name = get!(world, mock_app1_name, (AppName));
    let loaded_app1 = get!(world, loaded_app1_name.system, (App));
    assert(loaded_app1.name == mock_app1_name, 'App name incorrect');
    assert(loaded_app1.system == mock_app1_system, 'App system incorrect');

    let (paint_actions, snake_actions) = setup_apps(world);


    // update_permission



    // has_write_access
    // update_pixel 
    // get_system_address 
    // get_player_address

    // alert_player
    // set_instruction

    // process_queue 
    // schedule_queue
}
