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

use pixelaw::{
    core::{
        models::{
            registry::{App, AppName, app, app_name, core_actions_address, CoreActionsAddress},
            pixel::{Pixel, PixelUpdate, pixel}, permissions::{permissions, Permission, Permissions},
            area::{ROOT_RTREENODE,RTreeNode, RTreeNodePackableImpl, ChildrenPackableImpl}
        },
        actions::{actions, IActionsDispatcher, IActionsDispatcherTrait, CORE_ACTIONS_KEY},
        utils::{get_core_actions, Direction, Position, DefaultParameters, MAX_DIMENSION},
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
fn test_root_area() {
    let rect_in = ROOT_RTREENODE;

    let root_id: u64 = rect_in.pack();

    let rect_out: RTreeNode = root_id.unpack();

    println!("{:?}", rect_out);
    println!("root_id: {:?}", root_id);
    assert(rect_in == rect_out, 'root_id not same');
}

#[test]
fn test_area_packing() {
    let rect_in = RTreeNode {
        x_min: 123, y_min: 321, x_max: 456, y_max: 654, is_leaf: false, is_area: true
    };

    let id = rect_in.pack();

    let rect_out = id.unpack();

    // println!("{:?}", rect_out);
    assert(rect_in == rect_out, 'rect not same');
}

#[test]
fn test_child_packing() {
    let input = array![123].span();
    let out = input.pack();

    assert(out.unpack() == input, '1 span not same');


    let input = array![123, 321].span();
    let out = input.pack();

    assert(out.unpack() == input, '2 span not same');


    let input = array![123, 321, 456].span();
    let out = input.pack();

    assert(out.unpack() == input, '3 span not same');



    let input = array![123, 321, 456, 654].span();
    let out = input.pack();

    assert(out.unpack() == input, '4 span not same');



}
