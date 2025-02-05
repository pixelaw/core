use pixelaw::{
    core::{
        actions::area::{find_node_for_position}, actions::{IActionsDispatcherTrait},
        models::{
            area::{
                Area, ChildrenPackableImpl, FIRST_RTREENODE, ROOT_ID, ROOT_RTREENODE,
                ROOT_RTREENODE_EMPTY, RTreeNode, RTreeNodePackableImpl,
            },
        },
        utils, utils::{Bounds, Position},
    },
};
use pixelaw_test_helpers::{WHITE_COLOR, ZERO_ADDRESS, setup_core_initialized};

// Declare constants for bounds and positions
const BOUNDS_1: Bounds = Bounds { x_min: 10, y_min: 10, x_max: 19, y_max: 19 };
const BOUNDS_2: Bounds = Bounds { x_min: 20, y_min: 20, x_max: 29, y_max: 29 };
const BOUNDS_3: Bounds = Bounds { x_min: 30, y_min: 30, x_max: 39, y_max: 39 };
const BOUNDS_4: Bounds = Bounds { x_min: 40, y_min: 40, x_max: 49, y_max: 49 };
const BOUNDS_5: Bounds = Bounds { x_min: 50, y_min: 50, x_max: 59, y_max: 59 };
const BOUNDS_6: Bounds = Bounds { x_min: 60, y_min: 60, x_max: 69, y_max: 69 };
const BOUNDS_7: Bounds = Bounds { x_min: 70, y_min: 70, x_max: 79, y_max: 79 };
const BOUNDS_8: Bounds = Bounds { x_min: 80, y_min: 80, x_max: 84, y_max: 84 };
const BOUNDS_9: Bounds = Bounds { x_min: 85, y_min: 85, x_max: 89, y_max: 89 };
const BOUNDS_10: Bounds = Bounds { x_min: 90, y_min: 90, x_max: 99, y_max: 99 };
const BOUNDS_11: Bounds = Bounds { x_min: 100, y_min: 100, x_max: 109, y_max: 109 };
const BOUNDS_12: Bounds = Bounds { x_min: 110, y_min: 110, x_max: 119, y_max: 119 };
const BOUNDS_13: Bounds = Bounds { x_min: 120, y_min: 120, x_max: 129, y_max: 129 };
const BOUNDS_14: Bounds = Bounds { x_min: 130, y_min: 130, x_max: 139, y_max: 139 };
const BOUNDS_15: Bounds = Bounds { x_min: 1050, y_min: 1050, x_max: 1059, y_max: 1059 };

const POSITION_1: Position = Position { x: 1, y: 1 };
const POSITION_2: Position = Position { x: 11, y: 11 };
const POSITION_3: Position = Position { x: 131, y: 131 };
const POSITION_15: Position = Position { x: 1051, y: 1052 };


#[test]
fn test_root_area() {
    let root_id_empty: u64 = ROOT_RTREENODE_EMPTY.pack();
    let root_id: u64 = ROOT_RTREENODE.pack();
    let _first_id: u64 = FIRST_RTREENODE.pack();

    let rootnode_empty: RTreeNode = root_id_empty.unpack();
    let rootnode: RTreeNode = root_id.unpack();

    assert(ROOT_RTREENODE_EMPTY == rootnode_empty, 'rootnode_empty not same');
    assert(ROOT_RTREENODE == rootnode, 'rootnode not same');
}

#[test]
fn test_area_packing() {
    let rect_in = RTreeNode {
        bounds: utils::Bounds { x_min: 123, y_min: 321, x_max: 456, y_max: 654 },
        is_leaf: false,
        is_area: true,
    };

    let id = rect_in.pack();

    let rect_out = id.unpack();

    // println!("{:?}", rect_out);
    assert(rect_in == rect_out, 'rect not same');
}

#[test]
#[should_panic(expected: ('overlap topleft', 'ENTRYPOINT_FAILED'))]
fn test_adding_overlapping() {
    let (_world, core_actions, player_1, _player_2) = setup_core_initialized();

    let _a1: Area = core_actions.add_area(BOUNDS_1, player_1, WHITE_COLOR, ZERO_ADDRESS());
    let _a2: Area = core_actions
        .add_area(
            Bounds {
                x_min: 15, y_min: 15, x_max: 25, y_max: 25,
            }, // These bounds are overlapping the prior
            player_1,
            WHITE_COLOR,
            ZERO_ADDRESS(),
        );
}


#[test]
#[should_panic(expected: ('overlap containing', 'ENTRYPOINT_FAILED'))]
fn test_adding_containing() {
    let (_world, core_actions, player_1, _player_2) = setup_core_initialized();

    let _a1: Area = core_actions.add_area(BOUNDS_1, player_1, WHITE_COLOR, ZERO_ADDRESS());

    // println!("------------------ PRINTING TREE -----------------");
    // print_tree(world, ROOT_ID, "");

    let _a2: Area = core_actions
        .add_area(
            Bounds {
                x_min: 5, y_min: 5, x_max: 25, y_max: 25,
            }, // These bounds are containing the prior (so all corners are not inside another area)
            player_1,
            WHITE_COLOR,
            ZERO_ADDRESS(),
        );
}

#[test]
fn test_remove() {
    let (mut world, core_actions, player_1, _player_2) = setup_core_initialized();

    let a1: Area = core_actions.add_area(BOUNDS_1, player_1, WHITE_COLOR, ZERO_ADDRESS());
    core_actions.remove_area(a1.id);

    assert(find_node_for_position(ref world, POSITION_2, ROOT_ID, true) == 0, 'should not find 1');
}


#[test]
#[should_panic(expected: ('not area', 'ENTRYPOINT_FAILED'))]
fn test_remove_nonarea() {
    let (_world, core_actions, player_1, _player_2) = setup_core_initialized();

    let _a1: Area = core_actions.add_area(BOUNDS_1, player_1, WHITE_COLOR, ZERO_ADDRESS());
    core_actions.remove_area(120);
}

#[test]
fn test_adding() {
    let (mut world, core_actions, player_1, _player_2) = setup_core_initialized();

    let _a1: Area = core_actions.add_area(BOUNDS_1, player_1, WHITE_COLOR, ZERO_ADDRESS());

    let not_found = find_node_for_position(ref world, POSITION_1, ROOT_ID, true); // has_area=true

    assert(not_found == 0, 'should not find');

    let found = find_node_for_position(ref world, POSITION_2, ROOT_ID, true); // has_area=true

    assert(found != 0, 'should find');

    // Add more than 4 so node splitting is necessary
    let _a2 = core_actions.add_area(BOUNDS_2, player_1, WHITE_COLOR, ZERO_ADDRESS());

    let _a3 = core_actions.add_area(BOUNDS_3, player_1, WHITE_COLOR, ZERO_ADDRESS());

    let _a4 = core_actions.add_area(BOUNDS_4, player_1, WHITE_COLOR, ZERO_ADDRESS());

    // // Trigger a split
    let _a5 = core_actions.add_area(BOUNDS_5, player_1, WHITE_COLOR, ZERO_ADDRESS());

    // Keep adding
    let _a6 = core_actions.add_area(BOUNDS_6, player_1, WHITE_COLOR, ZERO_ADDRESS());

    let _a7 = core_actions.add_area(BOUNDS_7, player_1, WHITE_COLOR, ZERO_ADDRESS());

    let _a8 = core_actions.add_area(BOUNDS_8, player_1, WHITE_COLOR, ZERO_ADDRESS());
    let _a9 = core_actions.add_area(BOUNDS_9, player_1, WHITE_COLOR, ZERO_ADDRESS());

    let _a10 = core_actions.add_area(BOUNDS_10, player_1, WHITE_COLOR, ZERO_ADDRESS());

    let _a11 = core_actions.add_area(BOUNDS_11, player_1, WHITE_COLOR, ZERO_ADDRESS());

    let _a12 = core_actions.add_area(BOUNDS_12, player_1, WHITE_COLOR, ZERO_ADDRESS());
    let _a13 = core_actions.add_area(BOUNDS_13, player_1, WHITE_COLOR, ZERO_ADDRESS());
    let _a14 = core_actions.add_area(BOUNDS_14, player_1, WHITE_COLOR, ZERO_ADDRESS());

    // FIXME this addition messes up the tree (doesnt move children correctly)
    let _a15 = core_actions.add_area(BOUNDS_15, player_1, WHITE_COLOR, ZERO_ADDRESS());

    // println!("------------------ AFTER LAST SPLIT -----------------");
    // print_tree(world, ROOT_ID, "");
    // println!("------------------ ------------- -----------------");

    assert(find_node_for_position(ref world, POSITION_2, ROOT_ID, true) != 0, 'should find 2');
    assert(find_node_for_position(ref world, POSITION_3, ROOT_ID, true) != 0, 'should find 3');
    assert(find_node_for_position(ref world, POSITION_15, ROOT_ID, true) != 0, 'should find 3');

    let areas = core_actions
        .find_areas_inside_bounds(Bounds { x_min: 30, y_min: 30, x_max: 45, y_max: 45 });

    assert(*areas.at(0).id == 4222253504790685, 'not area 1');
    assert(*areas.at(1).id == 5629671339327685, 'not area 2');
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
