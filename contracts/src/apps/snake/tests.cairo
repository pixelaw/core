#[cfg(test)]
mod tests {
    use starknet::class_hash::Felt252TryIntoClassHash;

    use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
    use pixelaw::core::models::registry::{app, app_name, core_actions_address};

    use pixelaw::core::models::pixel::{Pixel, PixelUpdate};
    use pixelaw::core::models::pixel::{pixel};
    use pixelaw::core::models::permissions::{permissions};
    use pixelaw::core::utils::{get_core_actions, Direction, Position, DefaultParameters};
    use pixelaw::core::actions::{actions, IActionsDispatcher, IActionsDispatcherTrait};

    use dojo::test_utils::{spawn_test_world, deploy_contract};

    use pixelaw::apps::snake::app::{
        snake_actions, snake, snake_segment, ISnakeActionsDispatcher, ISnakeActionsDispatcherTrait
    };
    use pixelaw::apps::paint::app::{
        paint_actions, IPaintActionsDispatcher, IPaintActionsDispatcherTrait
    };
    use pixelaw::apps::snake::app::{Snake};

    use debug::PrintTrait;

    use zeroable::Zeroable;


    // Helper function: deploys world and actions
    fn deploy_world() -> (
        IWorldDispatcher, IActionsDispatcher, ISnakeActionsDispatcher, IPaintActionsDispatcher
    ) {
        let player1 = starknet::contract_address_const::<0x1337>();

        // Deploy World and models
        let world = spawn_test_world(
            array![
                pixel::TEST_CLASS_HASH,
                app::TEST_CLASS_HASH,
                app_name::TEST_CLASS_HASH,
                core_actions_address::TEST_CLASS_HASH,
                permissions::TEST_CLASS_HASH,
                snake::TEST_CLASS_HASH,
                snake_segment::TEST_CLASS_HASH,
            ]
        );

        // Deploy Core actions
        let core_actions_address = world
            .deploy_contract('salt1', actions::TEST_CLASS_HASH.try_into().unwrap());
        let core_actions = IActionsDispatcher { contract_address: core_actions_address };

        // Deploy Snake actions
        let snake_actions_address = world
            .deploy_contract('salt2', snake_actions::TEST_CLASS_HASH.try_into().unwrap());
        let snake_actions = ISnakeActionsDispatcher { contract_address: snake_actions_address };

        // Deploy Paint actions
        let paint_actions = IPaintActionsDispatcher {
            contract_address: world
                .deploy_contract('salt3', paint_actions::TEST_CLASS_HASH.try_into().unwrap())
        };

        // Setup dojo auth
        world.grant_writer('Pixel', core_actions_address);
        world.grant_writer('App', core_actions_address);
        world.grant_writer('AppName', core_actions_address);
        world.grant_writer('CoreActionsAddress', core_actions_address);
        world.grant_writer('Permissions', core_actions_address);

        world.grant_writer('Snake', snake_actions_address);
        world.grant_writer('SnakeSegment', snake_actions_address);

        (world, core_actions, snake_actions, paint_actions)
    }


    #[test]
    #[available_gas(3000000000)]
    fn test_playthrough() {
        // Deploy everything
        let (world, core_actions, snake_actions, paint_actions) = deploy_world();
        let SNAKE_COLOR = 0xFF00FF;

        core_actions.init();
        snake_actions.init();

        // Setup players
        let player1 = starknet::contract_address_const::<0x1337>();
        let player2 = starknet::contract_address_const::<0x42>();

        // Impersonate player1
        starknet::testing::set_account_contract_address(player1);

        assert(get!(world, (1, 1), Pixel).color != SNAKE_COLOR, 'wrong pixel color for 1,1');

        // Spawn the snake
        snake_actions
            .interact(
                DefaultParameters {
                    for_player: Zeroable::zero(),
                    for_system: Zeroable::zero(),
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
        assert(pixel1_1.color == 0, 'wrong pixel color 3');

        // Check that the pixel is snake at 2,1
        let pixel2_1 = get!(world, (2, 1), Pixel);
        assert(pixel2_1.color == SNAKE_COLOR, 'wrong pixel color 4');

        // Move right (head at 3,1 now)
        snake_actions.move(player1);

        // Check if the pixel is blank again at 2,1
        assert(get!(world, (2, 1), Pixel).color == 0, 'wrong pixel color 5');

        // Paint 4,1 so player1 owns it
        paint_actions
            .interact(
                DefaultParameters {
                    for_player: Zeroable::zero(),
                    for_system: Zeroable::zero(),
                    position: Position { x: 4, y: 1 },
                    color: 0xF0F0F0
                }
            );

        // Grow right (head at 4,1 now) -> on top of the painted. Snake should grow
        snake_actions.move(player1);

        // Check that 3,1 is still snake color
        assert(get!(world, (3, 1), Pixel).color == SNAKE_COLOR, 'wrong pixel color 6');

        // Move right (head at 5,1 now)
        snake_actions.move(player1);

        // Let player2 paint 6,1 so the snake will die
        //
        // The Snake is now 2 long, on 4,1 and 5,1
        // It will die in 3 moves: 
        //  1: hit the other pixel
        //  2: shrink
        //  3: shrink / delete
        starknet::testing::set_account_contract_address(player2);
        paint_actions
            .interact(
                DefaultParameters {
                    for_player: Zeroable::zero(),
                    for_system: Zeroable::zero(),
                    position: Position { x: 6, y: 1 },
                    color: 0xF0F0F0
                }
            );

        starknet::testing::set_account_contract_address(player1);

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

        // This command should revert
        // snake_actions.move(player1);

        // Spawn the snake again at 3,1 so it grows from the paint at 4,1
        snake_actions
            .interact(
                DefaultParameters {
                    for_player: Zeroable::zero(),
                    for_system: Zeroable::zero(),
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
                    for_player: Zeroable::zero(),
                    for_system: Zeroable::zero(),
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
