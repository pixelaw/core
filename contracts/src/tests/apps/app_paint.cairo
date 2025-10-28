use dojo::model::ModelStorage;
use pixelaw_test_utils::{setup_apps, setup_core};
use starknet::testing::set_account_contract_address;
use crate::apps::paint::IPaintActionsDispatcherTrait;
use crate::core::models::pixel::Pixel;
use crate::core::utils::{DefaultParameters, Position, encode_rgba};

#[test]
#[available_gas(3000000000)]
fn test_paint_actions() {
    // Deploy everything
    let (mut world, _core_actions, _player_1, _player_2) = setup_core();
    let (paint_actions, _snake_actions, _player_actions, _house_actions) = setup_apps(ref world);

    let player1 = 0x1337.try_into().unwrap();
    set_account_contract_address(player1);

    let color = encode_rgba(1, 0, 0, 1);

    paint_actions
        .interact(
            DefaultParameters {
                player_override: Option::None,
                system_override: Option::None,
                area_hint: Option::None,
                position: Position { x: 1, y: 1 },
                color: color,
            },
        );

    let pixel_1_1: Pixel = world.read_model(Position { x: 1, y: 1 });
    assert(pixel_1_1.color == color, 'should be the color');
}
