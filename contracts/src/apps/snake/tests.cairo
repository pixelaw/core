#[cfg(test)]
mod tests {
    use dojo::utils::test::{spawn_test_world};
    use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
    use pixelaw::apps::paint::app::{
        paint_actions, IPaintActionsDispatcher, IPaintActionsDispatcherTrait
    };

    use pixelaw::apps::snake::app::{
        snake_actions, snake, snake_segment, ISnakeActionsDispatcher, ISnakeActionsDispatcherTrait
    };
    use pixelaw::apps::snake::app::{Snake};
    use pixelaw::core::actions::{
        actions as core_actions, IActionsDispatcher, IActionsDispatcherTrait
    };

    use pixelaw::core::models::pixel::{Pixel, PixelUpdate};
    use pixelaw::core::models::pixel::{pixel};
    use pixelaw::core::models::registry::{app, app_name, core_actions_address};
    use pixelaw::core::tests::helpers::{set_caller, setup_core_initialized, setup_apps_initialized};
    use pixelaw::core::utils::{get_core_actions, Direction, Position, DefaultParameters};
    use starknet::{contract_address_const, testing::set_account_contract_address};


    #[test]
    #[available_gas(3000000000)]
    fn test_playthrough() {
        let (world, _core_actions, _player_1, _player_2) = setup_core_initialized();
        let (paint_actions, snake_actions) = setup_apps_initialized(world);

        let SNAKE_COLOR = 0xFF00FF;

        // Setup players
        let player1 = contract_address_const::<0x1337>();
        let player2 = contract_address_const::<0x42>();

        // Impersonate player1
        set_account_contract_address(player1);

        assert(get!(world, (1, 1), Pixel).color != SNAKE_COLOR, 'wrong pixel color for 1,1');

        // Spawn the snake
        snake_actions
            .interact(
                DefaultParameters {
                    player_override: Option::None,
                    system_override: Option::None,
                    area_hint: Option::None,
                    position: Position { x: 1, y: 1 },
                    color: SNAKE_COLOR
                },
                Direction::Right
            );

        assert(get!(world, (1, 1), Pixel).color == SNAKE_COLOR, 'wrong pixel color for 1,1');

        // Move the snake
        snake_actions.move(player1);

        // TODO check if there is a QueueScheduled event and if its correct

        // Check if the pixel is blank again at 1,1
        let pixel1_1 = get!(world, (1, 1), Pixel);
        assert(pixel1_1.color == 0, 'wrong pixel color 1,1');

        // Check that the pixel is snake at 2,1
        let pixel2_1 = get!(world, (2, 1), Pixel);
        assert(pixel2_1.color == SNAKE_COLOR, 'wrong pixel color 2,1');

        // Move right (head at 3,1 now)
        snake_actions.move(player1);

        // Check if the pixel is blank again at 2,1
        assert(get!(world, (2, 1), Pixel).color == 0, 'wrong pixel color 2,1');

        // Paint 4,1 so player1 owns it
        paint_actions
            .interact(
                DefaultParameters {
                    player_override: Option::None,
                    system_override: Option::None,
                    area_hint: Option::None,
                    position: Position { x: 4, y: 1 },
                    color: 0xF0F0F0
                }
            );

        // Grow right (head at 4,1 now) -> on top of the painted. Snake should grow
        snake_actions.move(player1);

        // Check that 3,1 is still snake color
        assert(get!(world, (3, 1), Pixel).color == SNAKE_COLOR, 'wrong pixel color 3,1');

        // Move right (head at 5,1 now)
        snake_actions.move(player1);

        // Let player2 paint 6,1 so the snake will die
        //
        // The Snake is now 2 long, on 4,1 and 5,1
        // It will die in 3 moves:
        //  1: hit the other pixel
        //  2: shrink
        //  3: shrink / delete
        set_caller(player2);
        paint_actions
            .interact(
                DefaultParameters {
                    player_override: Option::None,
                    system_override: Option::None,
                    area_hint: Option::None,
                    position: Position { x: 6, y: 1 },
                    color: 0xF0F0F0
                }
            );

        set_caller(player1);

        // Hit the pixel
        snake_actions.move(player1);

        // Shrink the tail
        snake_actions.move(player1);

        // Check that 4,1 is not snake color
        assert(get!(world, (4, 1), Pixel).color != SNAKE_COLOR, 'wrong pixel color for 4,1');

        // Shrink the head / die
        snake_actions.move(player1);
        // Check that 5,1 is not snake color
        assert(get!(world, (5, 1), Pixel).color != SNAKE_COLOR, 'wrong pixel color for 5,1');

        // Spawn the snake again at 3,1 so it grows from the paint at 4,1
        snake_actions
            .interact(
                DefaultParameters {
                    player_override: Option::None,
                    system_override: Option::None,
                    area_hint: Option::None,
                    position: Position { x: 3, y: 1 },
                    color: SNAKE_COLOR
                },
                Direction::Right
            );

        assert(get!(world, (3, 1), Pixel).color == SNAKE_COLOR, 'wrong pixel color for 3,1');

        // Moved to 4,1, it should now grow
        snake_actions.move(player1);

        // Now turn it Up so it runs into the border
        snake_actions
            .interact(
                DefaultParameters {
                    player_override: Option::None,
                    system_override: Option::None,
                    area_hint: Option::None,
                    position: Position { x: 3, y: 1 },
                    color: SNAKE_COLOR
                },
                Direction::Up
            );

        // Move up to 4,0
        snake_actions.move(player1);

        // Ran into 4,! - it should die
        snake_actions.move(player1);

        assert(get!(world, (4, 0), Pixel).color == SNAKE_COLOR, 'wrong pixel color for 4,0');
        assert(get!(world, (4, 1), Pixel).color == SNAKE_COLOR, 'wrong pixel color for 4,1');

        snake_actions.move(player1);

        assert(get!(world, (4, 0), Pixel).color == SNAKE_COLOR, 'wrong pixel color for 4,0');
        assert(get!(world, (4, 1), Pixel).color != SNAKE_COLOR, 'wrong pixel color for 4,1');

        snake_actions.move(player1);

        assert(get!(world, (4, 0), Pixel).color != SNAKE_COLOR, 'wrong pixel color for 4,0');
        assert(get!(world, (4, 1), Pixel).color != SNAKE_COLOR, 'wrong pixel color for 4,1');
    }
}
