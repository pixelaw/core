use pixelaw::{
    apps::paint::app::{IPaintActionsDispatcherTrait},
    apps::snake::app::{ISnakeActionsDispatcherTrait},
    core::{
        models::{area::{ChildrenPackableImpl, RTreeNodePackableImpl}},
        utils::{DefaultParameters, Direction, Position},
    },
};
use pixelaw_test_helpers::{set_caller, setup_apps_initialized, setup_core_initialized};

#[test]
fn test_app_permissions() {
    let (world, _core_actions, player_1, _player_2) = setup_core_initialized();
    let (_paint_actions, _snake_actions) = setup_apps_initialized(world);
    set_caller(player_1);
}

#[test]
fn test_hooks() {
    let (world, _core_actions, player_1, _player_2) = setup_core_initialized();
    let (paint_actions, snake_actions) = setup_apps_initialized(world);

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
                color: 0xFF00FFFF,
            },
        );

    paint_actions
        .interact(
            DefaultParameters {
                player_override: Option::None,
                system_override: Option::None,
                area_hint: Option::None,
                position: Position { x: 123, y: 321 },
                color: 0xAF00FFFF,
            },
        );

    snake_actions
        .interact(
            DefaultParameters {
                player_override: Option::None,
                system_override: Option::None,
                area_hint: Option::None,
                position: Position { x: 223, y: 321 },
                color: 0xAF00FFFF,
            },
            Direction::Right,
        );
}
