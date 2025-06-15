use pixelaw_testing::helpers::{set_caller, setup_apps, setup_core};
use pixelaw::{
    apps::paint::{IPaintActionsDispatcherTrait}, apps::snake::{ISnakeActionsDispatcherTrait},
    core::{
        models::{area::{ChildrenPackableImpl, RTreeNodePackableImpl}},
        utils::{DefaultParameters, Direction, Position},
    },
};

#[test]
fn test_app_permissions() {
    let (mut world, _core_actions, player_1, _player_2) = setup_core();
    let (_paint_actions, _snake_actions, _player_actions, _house_actions) = setup_apps(ref world);
    set_caller(player_1);
}

#[test]
fn test_hooks() {
    let (mut world, _core_actions, player_1, _player_2) = setup_core();
    let (paint_actions, snake_actions, _player_actions, _house_actions) = setup_apps(ref world);

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
