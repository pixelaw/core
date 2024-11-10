use core::fmt::Display;

use core::{traits::TryInto, poseidon::poseidon_hash_span};
use dojo::model::{ModelStorage};
use dojo::world::storage::WorldStorage;

use dojo::{
    utils::test::{spawn_test_world, deploy_contract},
    world::{IWorldDispatcher, IWorldDispatcherTrait}
};

use pixelaw::core::{
    models::{
        registry::{App, AppName, app, app_name, core_actions_address, CoreActionsAddress},
        pixel::{Pixel, PixelUpdate, PixelUpdateResult, PixelUpdateResultTrait, pixel},
    },
    actions::{actions, IActionsDispatcher, IActionsDispatcherTrait, CORE_ACTIONS_KEY},
    utils::{get_callers, get_core_actions, Direction, Position, DefaultParameters},
    tests::helpers::{
        setup_core, setup_core_initialized, setup_apps, setup_apps_initialized, ZERO_ADDRESS,
        set_caller, drop_all_events, TEST_POSITION, WHITE_COLOR, RED_COLOR,
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
use starknet::{
    get_block_timestamp, contract_address_const, ClassHash, ContractAddress,
    testing::{
        set_block_timestamp, set_account_contract_address, set_caller_address, set_contract_address
    },
};


#[test]
fn test_init_core_actions() {
    let (world, core_actions, _player_1, _player_2) = setup_core();
    let core_address: CoreActionsAddress = world.read_model(CORE_ACTIONS_KEY);
    assert(core_address.value == ZERO_ADDRESS(), 'should be 0');

    core_actions.init();

    let core_address: CoreActionsAddress = world.read_model(CORE_ACTIONS_KEY);
    assert(core_address.value != ZERO_ADDRESS(), 'should not be 0');
}

#[test]
fn test_register_new_app() {
    let (world, core_actions, _player_1, _player_2) = setup_core();
    let app_name = 'myname';
    let mock_app1_system = contract_address_const::<0xBEAD>();
    let _new_app1: App = core_actions.new_app(mock_app1_system, app_name, '');
    // TODO check return values

    let loaded_app1_name: AppName = world.read_model(app_name);
    let loaded_app1: App = world.read_model(loaded_app1_name.system);
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
                player_override: Option::None,
                system_override: Option::None,
                area_hint: Option::None,
                position: TEST_POSITION,
                color: RED_COLOR
            }
        );
}


#[test]
fn test_can_update_pixel() {
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
                player_override: Option::None,
                system_override: Option::None,
                area_hint: Option::None,
                position,
                color
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
    let pixel: Pixel = world.read_model((position.x, position.y));

    let has_access = core_actions
        .can_update_pixel(player_2, ZERO_ADDRESS(), pixel, pixel_update, Option::None, false)
        .is_ok();

    assert(has_access == false, 'should not have access');

    set_caller(player_1);

    let has_access = core_actions
        .can_update_pixel(player_1, ZERO_ADDRESS(), pixel, pixel_update, Option::None, false)
        .is_ok();

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

    let pixel: Pixel = world.read_model((x, y));

    assert(pixel == empty_pixel, 'pixel not empty');

    let _ = core_actions
        .update_pixel(ZERO_ADDRESS(), ZERO_ADDRESS(), pixel_update, Option::None, false);

    let pixel: Pixel = world.read_model((x, y));

    // TODO properly test created_at and updated_at (if we even keep them like this)
    changed_pixel.created_at = pixel.created_at;
    changed_pixel.updated_at = pixel.updated_at;

    assert(pixel == changed_pixel, 'pixel was not changed');
}

#[test]
#[should_panic(expected: 'only core can override')]
fn test_get_callers_non_core() {
    let (mut world, _core_actions, _player_1, player_2) = setup_core_initialized();
    let system_override = starknet::contract_address_const::<0x69>();

    // Don't fake the calling contract, so this call fails

    let has_override = DefaultParameters {
        player_override: Option::Some(player_2),
        system_override: Option::Some(system_override),
        area_hint: Option::None,
        position: Position { x: 1, y: 1 },
        color: 0
    };
    let (_player, _system) = get_callers(ref world, has_override);
}

#[test]
fn test_get_callers() {
    let (mut world, core_actions, player_1, player_2) = setup_core_initialized();

    let system_override = starknet::contract_address_const::<0x69>();

    let no_override = DefaultParameters {
        player_override: Option::None,
        system_override: Option::None,
        area_hint: Option::None,
        position: Position { x: 1, y: 1 },
        color: 0
    };

    let has_override = DefaultParameters {
        player_override: Option::Some(player_2),
        system_override: Option::Some(system_override),
        area_hint: Option::None,
        position: Position { x: 1, y: 1 },
        color: 0
    };

    // Test with 0 address, we expect the caller
    set_account_contract_address(player_1);

    let (player, system) = get_callers(ref world, no_override);
    assert(player == player_1, 'should return player1');
    assert(system == ZERO_ADDRESS(), 'should return zero');

    // impersonate core_actions so the override is allowed
    set_contract_address(core_actions.contract_address);

    let (player, system) = get_callers(ref world, has_override);
    assert(player == player_2, 'should return player_2');
    assert(system == system_override, 'should return system_override');
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
    drop_all_events(world.dispatcher.contract_address);

    // Call the action
    core_actions.alert_player(position, player, message);

    // Assert that the correct event was emitted
    assert_eq!(
        starknet::testing::pop_log(world.dispatcher.contract_address),
        Option::Some(
            pixelaw::core::events::Alert {
                position, caller, player, message, timestamp: get_block_timestamp()
            }
        )
    );
}

