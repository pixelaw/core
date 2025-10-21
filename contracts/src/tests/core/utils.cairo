use crate::apps::paint::IPaintActionsDispatcherTrait;
use crate::core::utils::{DefaultParameters, Position, is_area_free};
use crate::tests::helpers::{RED_COLOR, WHITE_COLOR, set_caller, setup_apps, setup_core};

#[test]
fn test_is_area_free_empty_area() {
    let (mut world, _core_actions, _player_1, _player_2) = setup_core();

    let position = Position { x: 10, y: 10 };
    let width = 3_u16;
    let height = 3_u16;

    // Test completely empty area
    let result = is_area_free(ref world, position, width, height);
    assert(result == true, 'area should be free');
}

#[test]
fn test_is_area_free_single_occupied_pixel() {
    let (mut world, _core_actions, player_1, _player_2) = setup_core();
    let (paint_actions, _snake_actions, _player_actions, _house_actions) = setup_apps(ref world);

    let base_position = Position { x: 10, y: 10 };
    let occupied_position = Position { x: 11, y: 11 }; // Inside the 3x3 area
    let width = 3_u16;
    let height = 3_u16;

    // Place a pixel in the area
    set_caller(player_1);
    paint_actions
        .put_color(
            DefaultParameters {
                player_override: Option::None,
                system_override: Option::None,
                area_hint: Option::None,
                position: occupied_position,
                color: RED_COLOR,
            },
        );

    // Test area with one occupied pixel
    let result = is_area_free(ref world, base_position, width, height);
    assert(result == false, 'area should not be free');
}

#[test]
fn test_is_area_free_pixel_outside_area() {
    let (mut world, _core_actions, player_1, _player_2) = setup_core();
    let (paint_actions, _snake_actions, _player_actions, _house_actions) = setup_apps(ref world);

    let base_position = Position { x: 10, y: 10 };
    let outside_position = Position { x: 15, y: 15 }; // Outside the 3x3 area
    let width = 3_u16;
    let height = 3_u16;

    // Place a pixel outside the area
    set_caller(player_1);
    paint_actions
        .put_color(
            DefaultParameters {
                player_override: Option::None,
                system_override: Option::None,
                area_hint: Option::None,
                position: outside_position,
                color: RED_COLOR,
            },
        );

    // Test area should still be free since pixel is outside
    let result = is_area_free(ref world, base_position, width, height);
    assert(result == true, 'area should be free');
}

#[test]
fn test_is_area_free_corner_pixel() {
    let (mut world, _core_actions, player_1, _player_2) = setup_core();
    let (paint_actions, _snake_actions, _player_actions, _house_actions) = setup_apps(ref world);

    let base_position = Position { x: 10, y: 10 };
    let corner_position = Position { x: 12, y: 12 }; // Bottom-right corner of 3x3 area
    let width = 3_u16;
    let height = 3_u16;

    // Place a pixel at the corner
    set_caller(player_1);
    paint_actions
        .put_color(
            DefaultParameters {
                player_override: Option::None,
                system_override: Option::None,
                area_hint: Option::None,
                position: corner_position,
                color: WHITE_COLOR,
            },
        );

    // Test area should not be free since corner pixel is occupied
    let result = is_area_free(ref world, base_position, width, height);
    assert(result == false, 'area should not be free');
}

#[test]
fn test_is_area_free_1x1_area() {
    let (mut world, _core_actions, player_1, _player_2) = setup_core();
    let (paint_actions, _snake_actions, _player_actions, _house_actions) = setup_apps(ref world);

    let position = Position { x: 5, y: 5 };
    let width = 1_u16;
    let height = 1_u16;

    // Test single empty pixel
    let result = is_area_free(ref world, position, width, height);
    assert(result == true, 'area should be free');

    // Occupy the single pixel
    set_caller(player_1);
    paint_actions
        .put_color(
            DefaultParameters {
                player_override: Option::None,
                system_override: Option::None,
                area_hint: Option::None,
                position,
                color: RED_COLOR,
            },
        );

    // Test single occupied pixel
    let result = is_area_free(ref world, position, width, height);
    assert(result == false, 'area should not be free');
}
