use dojo::model::{ModelStorage};

use pixelaw::apps::paint::{IPaintActionsDispatcherTrait};
use pixelaw::core::models::pixel::{Pixel};
use pixelaw::core::utils::{DefaultParameters, Position, encode_rgba};

use crate::helpers::{setup_apps, setup_core};
use starknet::{contract_address_const, testing::set_account_contract_address};

#[test]
#[available_gas(3000000000)]
fn test_paint_actions() {
    // Deploy everything
    let (mut world, _core_actions, _player_1, _player_2) = setup_core();
    let (paint_actions, _snake_actions, _player_actions) = setup_apps(ref world);

    let player1 = contract_address_const::<0x1337>();
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
