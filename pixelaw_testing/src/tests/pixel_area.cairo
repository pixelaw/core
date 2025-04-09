use dojo::model::{ModelStorage};
use pixelaw_testing::helpers::{WHITE_COLOR, ZERO_ADDRESS, set_caller, setup_core_initialized};
use pixelaw::{
    core::{
        actions::{IActionsDispatcherTrait},
        models::{
            area::{Area, ChildrenPackableImpl, RTreeNodePackableImpl},
            pixel::{Pixel, PixelUpdate, PixelUpdateResultTrait},
        },
        utils::{Bounds, MAX_DIMENSION, Position},
    },
};
const BOUNDS_1: Bounds = Bounds { x_min: 0, y_min: 0, x_max: 1000, y_max: 1000 };
const POSITION_1: Position = Position { x: 1, y: 1 };

#[test]
#[should_panic(expected: ('position overflow', 'ENTRYPOINT_FAILED'))]
fn test_pixel_with_invalid_position() {
    let (_world, core_actions, player_1, _player_2) = setup_core_initialized();

    // Setup PixelUpdate with x/y that are u16, but not u15
    let pixel_update = PixelUpdate {
        position: Position { x: MAX_DIMENSION + 2, y: MAX_DIMENSION + 3 },
        color: Option::Some(0xFF00FFFF),
        owner: Option::Some(player_1),
        app: Option::None,
        text: Option::None,
        timestamp: Option::None,
        action: Option::None,
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
            ZERO_ADDRESS(),
        );

    set_caller(player_2);

    let pixel: Pixel = world.read_model(POSITION_1);

    // Setup PixelUpdate
    let pixel_update = PixelUpdate {
        position: pixel.position,
        color: Option::Some(0xFF00FFFF),
        owner: Option::Some(player_2),
        app: Option::None,
        text: Option::None,
        timestamp: Option::None,
        action: Option::None,
    };

    let has_access = core_actions
        .can_update_pixel(player_2, ZERO_ADDRESS(), pixel, pixel_update, Option::None, false)
        .is_ok();

    assert(has_access == false, 'should not have access');
}
