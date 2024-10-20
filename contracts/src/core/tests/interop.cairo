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
        pixel::{Pixel, PixelUpdate, pixel},
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

#[test]
fn test_app_permissions() {
    let (world, _core_actions, player_1, _player_2) = setup_core_initialized();
    let (_paint_actions, _snake_actions) = setup_apps_initialized(world);
    set_caller(player_1);
}

#[test]
fn test_hooks() {
    let (world, _core_actions, player_1, _player_2) = setup_core_initialized();
    let (paint_actions, _snake_actions) = setup_apps_initialized(world);

    set_caller(player_1);

    // Paint has hooks, Snake does not??
    // TODO more testing
    paint_actions
        .interact(
            DefaultParameters {
                player_override: Option::None,
                system_override: Option::None,
                area_hint: Option::None,
                position: Position { x: 123, y: 321 },
                color: 0xFF00FFFF
            },
        );

    paint_actions
        .interact(
            DefaultParameters {
                player_override: Option::None,
                system_override: Option::None,
                area_hint: Option::None,
                position: Position { x: 123, y: 321 },
                color: 0xAF00FFFF
            },
        );
}
