use core::fmt::Display;
use starknet::{
    get_block_timestamp, contract_address_const, ClassHash, ContractAddress,
    testing::{set_block_timestamp, set_account_contract_address, set_caller_address},
};

use core::{traits::TryInto, poseidon::poseidon_hash_span};

use dojo::{
    utils::test::{spawn_test_world, deploy_contract},
    world::{IWorldDispatcher, IWorldDispatcherTrait}
};

use pixelaw::core::{
    models::{
        registry::{App, AppName, app, app_name, core_actions_address, CoreActionsAddress},
        pixel::{Pixel, PixelUpdate, pixel}, permissions::{permissions, Permission, Permissions}
    },
    actions::{actions, IActionsDispatcher, IActionsDispatcherTrait, CORE_ACTIONS_KEY},
    utils::{get_core_actions, Direction, Position, DefaultParameters},
    tests::helpers::{
        setup_core, setup_core_initialized, setup_apps, setup_apps_initialized, ZERO_ADDRESS,
        set_caller, drop_all_events, TEST_POSITION, WHITE_COLOR, RED_COLOR, PERMISSION_ALL,
        PERMISSION_NONE
    }
};

use pixelaw::{
    apps::{
        paint::app::{
            paint_actions, IPaintActionsDispatcher, IPaintActionsDispatcherTrait,
            APP_KEY as PAINT_APP_KEY
        },
        snake::app::{
            snake, Snake, snake_segment, SnakeSegment, snake_actions, ISnakeActionsDispatcher,
            ISnakeActionsDispatcherTrait, APP_KEY as SNAKE_APP_KEY
        }
    }
};


#[test]
fn test_init_core_actions() {
    let (world, core_actions, _player_1, _player_2) = setup_core();
    let core_address = get!(world, CORE_ACTIONS_KEY, (CoreActionsAddress));
    assert(core_address.value == ZERO_ADDRESS(), 'should be 0');

    core_actions.init();

    let core_address = get!(world, CORE_ACTIONS_KEY, (CoreActionsAddress));
    assert(core_address.value != ZERO_ADDRESS(), 'should not be 0');
}

#[test]
fn test_register_new_app() {
    let (world, core_actions, _player_1, _player_2) = setup_core();
    let app_name = 'myname';
    let mock_app1_system = contract_address_const::<0xBEAD>();
    let _new_app1: App = core_actions.new_app(mock_app1_system, app_name, '');
    // TODO check return values

    let loaded_app1_name = get!(world, app_name, (AppName));
    let loaded_app1 = get!(world, loaded_app1_name.system, (App));
    assert(loaded_app1.name == app_name, 'App name incorrect');
    assert(loaded_app1.system == mock_app1_system, 'App system incorrect');
}


#[test]
fn test_paint_interaction() {
    let (world, _core_actions, _player_1, _player_2) = setup_core_initialized();
    let (paint_actions, _snake_actions) = setup_apps_initialized(world);

    paint_actions
        .interact(
            DefaultParameters {
                for_player: ZERO_ADDRESS(), // Leave this 0 if not processing the Queue
                for_system: ZERO_ADDRESS(), // Leave this 0 if not processing the Queue
                position: TEST_POSITION,
                color: RED_COLOR
            }
        );
}

#[test]
fn test_update_permission() {
    let (world, core_actions, player_1, _player_2) = setup_core_initialized();

    let permissioning_system = contract_address_const::<0xBEEF01>();
    let permissioned_system = contract_address_const::<0xDEAD01>();

    set_caller(player_1);

    // Setup PermissioningApp
    let permissioning: App = core_actions.new_app(permissioning_system, 'permissioning', '');

    // Setup PermissionedApp
    let permissioned: App = core_actions.new_app(permissioned_system, 'permissioned', '');

    // Check that existing permissions are NONE
    let current_permissions = get!(world, (permissioning.system, permissioned.system), Permissions);
    assert(current_permissions.permission == PERMISSION_NONE, 'permissions not none');

    // Update the permissions, as caller
    set_caller(permissioning.system);
    core_actions.update_permission(permissioned.name, PERMISSION_ALL);

    // Check that existing permissions are ALL
    let new_permissions = get!(world, (permissioning.system, permissioned.system), Permissions);

    assert(new_permissions.permission == PERMISSION_ALL, 'permissions not all');
}


#[test]
fn test_has_write_access() {
    let (world, core_actions, player_1, player_2) = setup_core_initialized();
    let (paint_actions, _snake_actions) = setup_apps_initialized(world);

    // Scenario:
    // Check if Player2 can change Player1's pixel

    let position = Position { x: 12, y: 12 };
    let color = 0xFF0000FF;
    // Setup Pixel
    set_caller(player_1);
    paint_actions
        .put_color(
            DefaultParameters {
                for_player: ZERO_ADDRESS(), for_system: ZERO_ADDRESS(), position, color
            }
        );

    // Setup PixelUpdate
    let pixel_update = PixelUpdate {
        x: 12,
        y: 12,
        color: Option::Some(0xFF00FFFF),
        owner: Option::Some(player_1),
        app: Option::Some(paint_actions.contract_address),
        text: Option::None,
        timestamp: Option::None,
        action: Option::None
    };

    set_caller(player_2);
    let pixel = get!(world, (position.x, position.y), Pixel);

    let has_access = core_actions
        .has_write_access(ZERO_ADDRESS(), ZERO_ADDRESS(), pixel, pixel_update);

    assert(has_access == false, 'should not have access');

    set_caller(player_1);

    let has_access = core_actions
        .has_write_access(ZERO_ADDRESS(), ZERO_ADDRESS(), pixel, pixel_update);

    assert(has_access == true, 'should have access');
}


#[test]
fn test_update_pixel() {
    let (world, core_actions, player_1, _player_2) = setup_core_initialized();

    set_caller(player_1);

    let x = 22;
    let y = 23;
    let color: u32 = 0xFF00FFFF;
    let app = contract_address_const::<0xBEEFDEAD>();
    let owner = player_1;
    let text = 'mytext';
    let timestamp: u64 = 123123;
    let action = 'myaction';

    let empty_pixel = Pixel {
        x,
        y,
        color: 0,
        app: ZERO_ADDRESS(),
        owner: ZERO_ADDRESS(),
        text: 0,
        timestamp: 0,
        action: 0,
        created_at: 0,
        updated_at: 0
    };

    let mut changed_pixel = Pixel {
        x, y, color, app, owner, text, timestamp, action, created_at: 0, updated_at: 0
    };

    let pixel_update = PixelUpdate {
        x,
        y,
        color: Option::Some(color),
        owner: Option::Some(owner),
        app: Option::Some(app),
        text: Option::Some(text),
        timestamp: Option::Some(timestamp),
        action: Option::Some(action)
    };

    let pixel = get!(world, (x, y), Pixel);

    assert(pixel == empty_pixel, 'pixel not empty');

    core_actions.update_pixel(ZERO_ADDRESS(), ZERO_ADDRESS(), pixel_update);

    let pixel = get!(world, (x, y), Pixel);

    // TODO properly test created_at and updated_at (if we even keep them like this)
    changed_pixel.created_at = pixel.created_at;
    changed_pixel.updated_at = pixel.updated_at;

    assert(pixel == changed_pixel, 'pixel was not changed');
}


#[test]
fn test_get_player_address() {
    let (_world, core_actions, player_1, player_2) = setup_core_initialized();

    // Test with 0 address, we expect the caller
    set_account_contract_address(player_1);

    let addr = core_actions.get_player_address(ZERO_ADDRESS());
    assert(addr == player_1, 'should return player1');

    let addr = core_actions.get_player_address(player_2);
    assert(addr == player_2, 'should return player2');
}


#[test]
fn test_get_system_address() {
    let (world, core_actions, _player_1, _player_2) = setup_core_initialized();
    let (paint_actions, snake_actions) = setup_apps_initialized(world);

    set_caller(paint_actions.contract_address);

    let addr = core_actions.get_system_address(ZERO_ADDRESS());
    assert(addr == paint_actions.contract_address, 'should return paint_contract');

    let addr = core_actions.get_system_address(snake_actions.contract_address);
    assert(addr == snake_actions.contract_address, 'should return snake_contract');
}

// TODO Try alerting with a nonexisting appkey (should panic)

#[test]
fn test_alert_player() {
    let (world, core_actions, player_1, _player_2) = setup_core_initialized();
    let (paint_actions, _snake_actions) = setup_apps_initialized(world);

    // Prep params
    let position = Position { x: 12, y: 12 };
    let message = 'testme';
    let caller = paint_actions.contract_address;
    let player = player_1;

    set_caller(caller);

    // Pop all the previous events from the log so only the following one will be there
    drop_all_events(world.contract_address);

    // Call the action
    core_actions.alert_player(position, player, message);

    // Assert that the correct event was emitted
    assert_eq!(
        starknet::testing::pop_log(world.contract_address),
        Option::Some(
            pixelaw::core::actions::actions::Alert {
                position, caller, player, message, timestamp: get_block_timestamp()
            }
        )
    );
}

fn test_set_instruction(world: IWorldDispatcher, player: ContractAddress, instruction: felt252) {
    // Implementation for setting an instruction for the player
    println!("Setting instruction for player {:?}: {}", player, instruction);
}

