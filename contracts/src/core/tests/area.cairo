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
use core::starknet::storage_access::StorePacking;

use pixelaw::{
    core::{
        models::{
            registry::{App, AppName, app, app_name, core_actions_address, CoreActionsAddress},
            pixel::{Pixel, PixelUpdate, pixel}, permissions::{permissions, Permission, Permissions},
            area::{Rect, Rectangle, RectPackableImpl}
        },
        actions::{actions, IActionsDispatcher, IActionsDispatcherTrait, CORE_ACTIONS_KEY},
        utils::{get_core_actions, Direction, Position, DefaultParameters},
        tests::helpers::{
            setup_core, setup_core_initialized, setup_apps, setup_apps_initialized, ZERO_ADDRESS,
            set_caller, drop_all_events, TEST_POSITION, WHITE_COLOR, RED_COLOR, PERMISSION_ALL,
            PERMISSION_NONE
        },
    },
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
fn test_area_types() {
    let rect_in = Rectangle{
        x_min: 123,
        y_min: 321,
        x_max: 456,
        y_max: 654,
        is_leaf: false,
        is_area: true
    };

    let id = rect_in.pack();
    
    let rect_out = id.unpack();

    println!("{:?}", rect_out);
    assert(rect_in == rect_out, 'rect not same');
}
