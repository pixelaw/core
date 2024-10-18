use core::fmt::Display;

use core::{traits::TryInto, poseidon::poseidon_hash_span};

use dojo::{
    utils::test::{spawn_test_world, deploy_contract},
    world::{IWorldDispatcher, IWorldDispatcherTrait}
};
use pixelaw::core::utils::{MAX_DIMENSION};

use pixelaw::core::{
    models::{
        registry::{App, AppName, app, app_name, core_actions_address, CoreActionsAddress},
        pixel::{Pixel, PixelUpdate, PixelUpdateResult, PixelUpdateResultTrait, pixel},
        area::{
            Area, ROOT_ID, FIRST_RTREENODE, ROOT_RTREENODE_EMPTY, ROOT_RTREENODE, RTreeNode,
            RTreeNodePackableImpl, ChildrenPackableImpl
        }
    },
    actions::{actions, IActionsDispatcher, IActionsDispatcherTrait, CORE_ACTIONS_KEY},
    utils::{Bounds, get_core_actions, Direction, Position, DefaultParameters},
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
    testing::{set_block_timestamp, set_account_contract_address, set_caller_address},
};
const BOUNDS_1: Bounds = Bounds { x_min: 0, y_min: 0, x_max: 1000, y_max: 1000 };
const POSITION_1: Position = Position { x: 1, y: 1 };

#[test]
#[should_panic(expected: ('position overflow', 'ENTRYPOINT_FAILED'))]
fn test_pixel_with_invalid_position() {
    let (_world, core_actions, player_1, _player_2) = setup_core_initialized();

    // Setup PixelUpdate with x/y that are u16, but not u15
    let pixel_update = PixelUpdate {
        x: MAX_DIMENSION + 2,
        y: MAX_DIMENSION + 3,
        color: Option::Some(0xFF00FFFF),
        owner: Option::Some(player_1),
        app: Option::None,
        text: Option::None,
        timestamp: Option::None,
        action: Option::None
    };
    let _ = core_actions
        .update_pixel(ZERO_ADDRESS(), ZERO_ADDRESS(), pixel_update, Option::None, false);
}

#[test]
fn test_add_new_pixel_in_owned_area() {
    let (world, core_actions, player_1, player_2) = setup_core_initialized();

    set_caller(player_1);

    let _a1: Area = core_actions
        .add_area(
            Bounds { x_min: 0, y_min: 0, x_max: 1000, y_max: 1000 },
            player_1,
            WHITE_COLOR,
            ZERO_ADDRESS()
        );

    set_caller(player_2);

    let pixel = get!(world, (POSITION_1.x, POSITION_1.y), Pixel);

    // Setup PixelUpdate
    let pixel_update = PixelUpdate {
        x: pixel.x,
        y: pixel.y,
        color: Option::Some(0xFF00FFFF),
        owner: Option::Some(player_2),
        app: Option::None,
        text: Option::None,
        timestamp: Option::None,
        action: Option::None
    };

    let has_access = core_actions
        .can_update_pixel(player_2, ZERO_ADDRESS(), pixel, pixel_update, Option::None, false)
        .is_ok();

    assert(has_access == false, 'should not have access');
}
