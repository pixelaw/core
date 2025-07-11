use dojo::model::{ModelStorage};

use pixelaw::core::models::pixel::{Pixel};
use pixelaw::core::utils::{DefaultParameters, Position};
use pixelaw::apps::{player::{IPlayerActionsDispatcherTrait, Player, PLAYER_LIVES}};
use crate::helpers::{setup_apps, setup_core, set_caller};
use starknet::{contract_address_const};

#[test]
#[available_gas(3000000000)]
fn test_player_interaction() {
    // Initialize the world and apps
    let (mut world, _core_actions, _player_1, _player_2) = setup_core();
    let (_paint_actions, _snake_actions, player_actions, _house_actions) = setup_apps(ref world);

    let player1 = contract_address_const::<0x1337>();
    set_caller(player1);

    // Define initial position and color
    let initial_position = Position { x: 1, y: 1 };
    let player_color = 0xFF00FF;

    // Interact with a pixel to create a new player
    player_actions
        .interact(
            DefaultParameters {
                player_override: Option::None,
                system_override: Option::None,
                area_hint: Option::None,
                position: initial_position,
                color: player_color,
            },
        );

    // Verify the player was created at the correct position
    let pixel: Pixel = world.read_model(Position { x: 1, y: 1 });
    assert(pixel.color == player_color, 'Player not at 1,1 w color');

    // Verify the player model was created with correct lives
    let player_data: Player = world.read_model(player1);
    assert(player_data.lives == PLAYER_LIVES, 'Player should have 5 lives');
    assert(player_data.position == initial_position, 'Player position mismatch');

    // Move the player to a new position
    let new_position = Position { x: 2, y: 1 };
    player_actions
        .interact(
            DefaultParameters {
                player_override: Option::None,
                system_override: Option::None,
                area_hint: Option::None,
                position: new_position,
                color: player_color,
            },
        );

    // Verify the player moved correctly
    let pixel_new: Pixel = world.read_model(Position { x: 2, y: 1 });
    assert(pixel_new.color == player_color, 'Player should have moved to 2,1');

    // Verify the old position is cleared
    let pixel_old: Pixel = world.read_model(Position { x: 1, y: 1 });
    assert(pixel_old.color != player_color, 'Old position should be cleared');

    // Verify the player model was updated with the new position
    let player_data_after: Player = world.read_model(player1);
    assert(player_data_after.position == new_position, 'Player position not updated');
    assert(player_data_after.lives == PLAYER_LIVES, 'Player lives should remain same');
}
