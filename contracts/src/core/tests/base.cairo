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
    actions::{
        actions, IActionsDispatcher, IActionsDispatcherTrait,
        CORE_ACTIONS_KEY, //    has_write_access, set_instruction, alert_player, new_app, get_system_address,
        //    get_player_address, update_pixel, update_permission, process_queue, schedule_queue
    },
    utils::{get_core_actions, Direction, Position, DefaultParameters},
    tests::helpers::{setup, setup_apps, ZERO_ADDRESS, set_caller}
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

const TEST_POSITION: Position = Position { x: 1, y: 1 };
const WHITE_COLOR: u32 = 0xFFFFFFFF;
const RED_COLOR: u32 = 0xFF0000FF;


const PERMISSION_ALL: Permission =
    Permission { app: true, color: true, owner: true, text: true, timestamp: true, action: true };

const PERMISSION_NONE: Permission =
    Permission {
        app: false, color: false, owner: false, text: false, timestamp: false, action: false
    };

fn init_core_actions(world: IWorldDispatcher, core_actions: IActionsDispatcher) {
    let core_address = get!(world, CORE_ACTIONS_KEY, (CoreActionsAddress));
    assert(core_address.value == ZERO_ADDRESS(), 'should be 0');

    core_actions.init();

    let core_address = get!(world, CORE_ACTIONS_KEY, (CoreActionsAddress));
    assert(core_address.value != ZERO_ADDRESS(), 'should not be 0');
}

fn test_register_new_app(world: IWorldDispatcher, core_actions: IActionsDispatcher) {
    let app_name = 'myname';
    let mock_app1_system = contract_address_const::<0xBEAD>();
    let _new_app1: App = core_actions.new_app(mock_app1_system, app_name, '', '');
    // TODO check return values

    let loaded_app1_name = get!(world, app_name, (AppName));
    let loaded_app1 = get!(world, loaded_app1_name.system, (App));
    assert(loaded_app1.name == app_name, 'App name incorrect');
    assert(loaded_app1.system == mock_app1_system, 'App system incorrect');
}

fn setup_paint_app(
    world: IWorldDispatcher,
    core_actions: IActionsDispatcher,
    paint_actions: IPaintActionsDispatcher
) {
    let paint_appname = get!(world, PAINT_APP_KEY, (AppName));
    assert(paint_appname.system == ZERO_ADDRESS(), 'still empty');

    core_actions.new_app(paint_actions.contract_address, PAINT_APP_KEY, '', '');
    let paint_appname = get!(world, PAINT_APP_KEY, (AppName));
    let paint_app = get!(world, paint_appname.system, (App));
    assert(paint_appname.system == paint_actions.contract_address, 'set to system');
    assert(paint_app.name == PAINT_APP_KEY, 'appname set');
}

fn test_paint_interaction(paint_actions: IPaintActionsDispatcher) {
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
fn test_update_permission(
    world: IWorldDispatcher, core_actions: IActionsDispatcher, player1: ContractAddress
) {
    let permissioning_system = contract_address_const::<0xBEEF01>();
    let permissioned_system = contract_address_const::<0xDEAD01>();

    set_caller(player1);

    // Setup PermissioningApp
    let permissioning: App = core_actions.new_app(permissioning_system, 'permissioning', '', '');

    // Setup PermissionedApp
    let permissioned: App = core_actions.new_app(permissioned_system, 'permissioned', '', '');

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


fn test_has_write_access(
    world: IWorldDispatcher,
    core_actions: IActionsDispatcher,
    paint_actions: IPaintActionsDispatcher,
    player_1: ContractAddress,
    player_2: ContractAddress
) {
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

fn test_update_pixel(
    world: IWorldDispatcher, core_actions: IActionsDispatcher, player_1: ContractAddress
) {
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

fn get_system_address(world: IWorldDispatcher, app_name: felt252) -> ContractAddress {
    let app = get!(world, app_name, (App));
    app.system
}

fn test_get_player_address(
    core_actions: IActionsDispatcher, player1: ContractAddress, player2: ContractAddress
) {
    // Test with 0 address, we expect the caller
    set_account_contract_address(player1);

    let addr = core_actions.get_player_address(ZERO_ADDRESS());
    assert(addr == player1, 'should return player1');

    let addr = core_actions.get_player_address(player2);
    assert(addr == player2, 'should return player2');
}

fn test_get_system_address(
    core_actions: IActionsDispatcher,
    paint_contract: ContractAddress,
    snake_contract: ContractAddress
) {
    set_caller(paint_contract);

    let addr = core_actions.get_system_address(ZERO_ADDRESS());
    assert(addr == paint_contract, 'should return paint_contract');

    let addr = core_actions.get_system_address(snake_contract);
    assert(addr == snake_contract, 'should return snake_contract');
}

fn alert_player(player: ContractAddress, message: felt252) {
    // Implementation for alerting the player
    println!("Alerting player {:?}: {}", player, message);
}

fn set_instruction(world: IWorldDispatcher, player: ContractAddress, instruction: felt252) {
    // Implementation for setting an instruction for the player
    println!("Setting instruction for player {:?}: {}", player, instruction);
}

fn process_queue(world: IWorldDispatcher) {
    // Implementation for processing the action queue
    println!("Processing action queue");
}

fn schedule_queue(world: IWorldDispatcher, action: felt252) {
    // Implementation for scheduling actions in the queue
    println!("Scheduling action: {}", action);
}
#[test]
#[available_gas(999_999_999)]
fn test_core() {
    let (world, core_actions, player_1, player_2) = setup();
    let (paint_actions, snake_actions) = setup_apps(world);

    init_core_actions(world, core_actions);

    test_register_new_app(world, core_actions);

    test_paint_interaction(paint_actions);

    test_get_player_address(core_actions, player_1, player_2);

    test_get_system_address(
        core_actions, paint_actions.contract_address, snake_actions.contract_address
    );

    test_update_permission(world, core_actions, player_1);

    test_has_write_access(world, core_actions, paint_actions, player_1, player_2);

    test_update_pixel(world, core_actions, player_1);
    // // Alert player
// alert_player(player_address, 'This is a test alert');

    // // Set instruction
// set_instruction(world, player_address, 'Move to position (2, 2)');

    // // Process queue
// process_queue(world);

    // // Schedule queue
// schedule_queue(world, 'Paint action');
}
