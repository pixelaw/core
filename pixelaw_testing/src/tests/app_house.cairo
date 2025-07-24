use dojo::model::{ModelStorage};

use pixelaw::core::models::pixel::{Pixel};
use pixelaw::core::utils::{DefaultParameters, Position};
use pixelaw::apps::house::{IHouseActionsDispatcherTrait, House, PlayerHouse};
use pixelaw::apps::player::{IPlayerActionsDispatcherTrait};
use pixelaw::apps::player::{Player};
use crate::helpers::{setup_core, setup_apps, set_caller};
use starknet::{contract_address_const, testing::{set_block_timestamp}};

// House app test constants
const HOUSE_COLOR: u32 = 0x8B4513FF; // Brown color
const LIFE_REGENERATION_TIME: u64 = 120; // 2 minutes in seconds (matches house.cairo)

#[test]
#[available_gas(3000000000)]
fn test_build_house() {
    // Initialize the world
    let (mut world, _core_actions, _player_1, _player_2) = setup_core();
    let (_paint_actions, _snake_actions, _player_actions, house_actions) = setup_apps(ref world);

    let player1 = contract_address_const::<0x1337>();
    set_caller(player1);

    // Define the position for our house (top-left corner)
    let house_position = Position { x: 10, y: 10 };

    // Build a house at the specified position using interact
    house_actions
        .interact(
            DefaultParameters {
                player_override: Option::None,
                system_override: Option::None,
                area_hint: Option::None,
                position: house_position,
                color: HOUSE_COLOR,
            },
        );

    // Verify that the center of the house has the correct color and emoji
    let center_pixel: Pixel = world.read_model(Position { x: 11, y: 11 });
    assert(center_pixel.color == HOUSE_COLOR, 'House center should be brown');

    // Check if player has a house in the registry
    let player_house: PlayerHouse = world.read_model(player1);
    assert(player_house.player == player1, 'Owner mismatch');
    assert(player_house.has_house == true, 'Player should have a house');
    assert(player_house.house_position == house_position, 'House position mismatch');

    // Check that the house model was created correctly
    let house: House = world.read_model(house_position);
    assert(house.owner == player1, 'House owner mismatch');
}

#[test]
#[available_gas(3000000000)]
#[should_panic(expected: ("Player already has a house", 'ENTRYPOINT_FAILED'))]
fn test_build_second_house() {
    // Initialize the world
    let (mut world, _core_actions, _player_1, _player_2) = setup_core();
    let (_paint_actions, _snake_actions, _player_actions, house_actions) = setup_apps(ref world);

    let player1 = contract_address_const::<0x1337>();
    set_caller(player1);

    // Build first house using interact
    house_actions
        .interact(
            DefaultParameters {
                player_override: Option::None,
                system_override: Option::None,
                area_hint: Option::None,
                position: Position { x: 10, y: 10 },
                color: HOUSE_COLOR,
            },
        );

    // Try to build a second house - should fail
    house_actions
        .interact(
            DefaultParameters {
                player_override: Option::None,
                system_override: Option::None,
                area_hint: Option::None,
                position: Position { x: 20, y: 20 },
                color: HOUSE_COLOR,
            },
        );
}

#[test]
#[available_gas(3000000000)]
fn test_collect_life() {
    // Initialize the world
    let (mut world, _core_actions, _player_1, _player_2) = setup_core();
    let (_paint_actions, _snake_actions, player_actions, house_actions) = setup_apps(ref world);

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
    // Set the initial timestamp
    let initial_timestamp: u64 = 1000;
    set_block_timestamp(initial_timestamp);

    // Build a house using interact
    let house_position = Position { x: 10, y: 10 };
    house_actions
        .interact(
            DefaultParameters {
                player_override: Option::None,
                system_override: Option::None,
                area_hint: Option::None,
                position: house_position,
                color: HOUSE_COLOR,
            },
        );

    // Get the initial player data
    let player_data: Player = world.read_model(player1);
    let initial_lives: u32 = player_data.lives;

    // Fast forward time to enable life collection
    set_block_timestamp(initial_timestamp + LIFE_REGENERATION_TIME + 1);

    // Collect life using interact (click on house)
    house_actions
        .interact(
            DefaultParameters {
                player_override: Option::None,
                system_override: Option::None,
                area_hint: Option::None,
                position: house_position,
                color: HOUSE_COLOR,
            },
        );

    // Check if player gained a life
    let player_data_after: Player = world.read_model(player1);
    assert(player_data_after.lives == initial_lives + 1, 'Player should gain a life');

    // Check if the house's last_life_generated was updated
    let house: House = world.read_model(house_position);
    assert(
        house.last_life_generated == initial_timestamp + LIFE_REGENERATION_TIME + 1,
        'Last life time not updated',
    );
}

#[test]
#[available_gas(3000000000)]
#[should_panic(expected: ("Life not ready yet", 'ENTRYPOINT_FAILED'))]
fn test_collect_life_too_soon() {
    // Initialize the world
    let (mut world, _core_actions, _player_1, _player_2) = setup_core();
    let (_paint_actions, _snake_actions, _player_actions, house_actions) = setup_apps(ref world);

    let player1 = contract_address_const::<0x1337>();
    set_caller(player1);

    // Set the initial timestamp
    let initial_timestamp: u64 = 1000;
    set_block_timestamp(initial_timestamp);

    // Build a house using interact
    let house_position = Position { x: 10, y: 10 };
    house_actions
        .interact(
            DefaultParameters {
                player_override: Option::None,
                system_override: Option::None,
                area_hint: Option::None,
                position: house_position,
                color: HOUSE_COLOR,
            },
        );

    // Fast forward time but not enough (only half the required time)
    set_block_timestamp(initial_timestamp + LIFE_REGENERATION_TIME / 2);

    // Try to collect life too soon - should fail
    house_actions
        .interact(
            DefaultParameters {
                player_override: Option::None,
                system_override: Option::None,
                area_hint: Option::None,
                position: house_position,
                color: HOUSE_COLOR,
            },
        );
}
