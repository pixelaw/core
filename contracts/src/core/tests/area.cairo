use core::fmt::Display;

use core::{traits::TryInto, poseidon::poseidon_hash_span};

use dojo::{
    utils::test::{spawn_test_world, deploy_contract},
    world::{IWorldDispatcher, IWorldDispatcherTrait}
};
use pixelaw::core::utils;

use pixelaw::{
    core::{
        models::{
            registry::{App, AppName, app, app_name, core_actions_address, CoreActionsAddress},
            pixel::{Pixel, PixelUpdate, pixel}, permissions::{permissions, Permission, Permissions},
            area::{
                ROOT_ID, FIRST_RTREENODE, ROOT_RTREENODE_EMPTY, ROOT_RTREENODE, RTreeNode,
                RTreeNodePackableImpl, ChildrenPackableImpl
            }
        },
        actions::{actions, IActionsDispatcher, IActionsDispatcherTrait, CORE_ACTIONS_KEY},
        utils::{Bounds, get_core_actions, Direction, Position, DefaultParameters, MAX_DIMENSION},
        utils::area::{print_tree, find_node_for_position, get_ancestors},
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
use starknet::{
    get_block_timestamp, contract_address_const, ClassHash, ContractAddress,
    testing::{set_block_timestamp, set_account_contract_address, set_caller_address},
};

#[test]
fn test_root_area() {
    let root_id_empty: u64 = ROOT_RTREENODE_EMPTY.pack();
    let root_id: u64 = ROOT_RTREENODE.pack();
    let first_id: u64 = FIRST_RTREENODE.pack();

    let rootnode_empty: RTreeNode = root_id_empty.unpack();
    let rootnode: RTreeNode = root_id.unpack();

    println!("root_id_empty: {:?}", root_id_empty);
    println!("root_id: {:?}", root_id);
    println!("first_id: {:?}", first_id);

    println!("rootnode_empty: {:?}", rootnode_empty);
    println!("rootnode: {:?}", rootnode);

    assert(ROOT_RTREENODE_EMPTY == rootnode_empty, 'rootnode_empty not same');
    assert(ROOT_RTREENODE == rootnode, 'rootnode not same');
}

#[test]
fn test_area_packing() {
    let rect_in = RTreeNode {
        bounds: utils::Bounds { x_min: 123, y_min: 321, x_max: 456, y_max: 654 },
        is_leaf: false,
        is_area: true
    };

    let id = rect_in.pack();

    let rect_out = id.unpack();

    // println!("{:?}", rect_out);
    assert(rect_in == rect_out, 'rect not same');
}


#[test]
fn test_adding() {
    let (world, core_actions, _player_1, _player_2) = setup_core_initialized();

    let bounds_1 = Bounds { x_min: 10, y_min: 10, x_max: 19, y_max: 19 };
    let bounds_2 = Bounds { x_min: 20, y_min: 20, x_max: 29, y_max: 29 };
    let bounds_3 = Bounds { x_min: 30, y_min: 30, x_max: 39, y_max: 39 };
    let bounds_4 = Bounds { x_min: 40, y_min: 40, x_max: 49, y_max: 49 };
    let bounds_5 = Bounds { x_min: 50, y_min: 50, x_max: 59, y_max: 59 };
    let bounds_6 = Bounds { x_min: 60, y_min: 60, x_max: 69, y_max: 69 };
    let bounds_7 = Bounds { x_min: 70, y_min: 70, x_max: 79, y_max: 79 };
    let bounds_8 = Bounds { x_min: 80, y_min: 80, x_max: 89, y_max: 89 };
    let bounds_9 = Bounds { x_min: 1050, y_min: 1050, x_max: 1059, y_max: 1059 };

    let position_1 = Position { x: 1, y: 1 };
    let position_2 = Position { x: 11, y: 11 };

    let _result = core_actions.add_area(bounds_1, Option::None);
    println!("------------------ PRINTING TREE -----------------");
    print_tree(world, ROOT_ID, "");

    let not_found = find_node_for_position(world, position_1, ROOT_ID, true); // has_area=true

    assert(not_found == 0, 'should not find');

    let found = find_node_for_position(world, position_2, ROOT_ID, true); // has_area=true

    assert(found != 0, 'should find');

    // Add more than 4 so node splitting is necessary
    let _area_id = core_actions.add_area(bounds_2, Option::None);

    println!("------------------ PRINTING TREE -----------------");
    print_tree(world, ROOT_ID, "");

    let _area_id = core_actions.add_area(bounds_3, Option::None);

    let area_id = core_actions.add_area(bounds_4, Option::None);

    let mut ancestors: Array<u64> = array![];
    get_ancestors(world, ref ancestors, area_id);
    assert(ancestors == array![ROOT_ID, 6422726, area_id], 'wrong ancestors');

    // Trigger a split
    let _result = core_actions.add_area(bounds_5, Option::None);
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

    let out_unpacked: Span<u64> = out.unpack();
    assert(out_unpacked == input, '3 span not same');

    let input = array![123, 321, 456, 654].span();
    let out = input.pack();

    assert(out.unpack() == input, '4 span not same');
}
