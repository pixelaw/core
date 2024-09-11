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

use pixelaw::{
    apps::{
        paint::app::{paint_actions, IPaintActionsDispatcher, APP_KEY as PAINT_APP_KEY},
        snake::app::{snake, Snake, snake_segment, SnakeSegment, snake_actions, ISnakeActionsDispatcher, APP_KEY as SNAKE_APP_KEY}
    }
};

#[test]
#[available_gas(30000000)]
fn test_core() {
    let ZERO_ADDRESS: ContractAddress = contract_address_const::<0>();

    let (world, core_actions, _player_1, _player_2) = setup();
    let _position = Position { x: 0, y: 0 };

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

    // Test registering a random app
    let loaded_app1_name = get!(world, mock_app1_name, (AppName));
    let loaded_app1 = get!(world, loaded_app1_name.system, (App));
    assert(loaded_app1.name == mock_app1_name, 'App name incorrect');
    assert(loaded_app1.system == mock_app1_system, 'App system incorrect');

    // test registering paint / snake
    let (paint_actions, _snake_actions) = setup_apps(world);

    let paint_appname = get!(world, PAINT_APP_KEY, (AppName));
    assert(paint_appname.system == ZERO_ADDRESS, 'still empty');

    core_actions.new_app(paint_actions.contract_address, PAINT_APP_KEY, '', '');
    let paint_appname = get!(world, PAINT_APP_KEY, (AppName));
    let paint_app = get!(world, paint_appname.system, (App));
    assert(paint_appname.system == paint_actions.contract_address, 'set to system');
    assert(paint_app.name == PAINT_APP_KEY, 'appname set');


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
