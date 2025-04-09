use dojo::model::{ModelStorage};

use pixelaw::core::models::pixel::{Pixel};
use pixelaw::core::utils::{DefaultParameters, Position, Emoji};
use pixelaw::core::actions::{IActionsDispatcherTrait as ICoreActionsDispatcherTrait};
use pixelaw::apps::{
    player::{
        IPlayerActionsDispatcher, IPlayerActionsDispatcherTrait, m_Player, m_PositionPlayer,
        player_actions,
    },
};
use crate::helpers::{set_caller, setup_apps_initialized, setup_core_initialized};
use starknet::{contract_address_const, testing::set_account_contract_address};

#[test]
#[available_gas(3000000000)]
fn test_player_interaction() {
    // Initialize the world and apps
    let (world, _core_actions, _player_1, _player_2) = setup_core_initialized();
    let (_paint_actions, _snake_actions, player_actions) = setup_apps_initialized(world);

    let player1 = contract_address_const::<0x1337>();
    set_account_contract_address(player1);

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
}
