#[cfg(test)]
mod tests {
    use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
    use pixelaw::core::models::pixel::{Pixel, PixelUpdate};
    use pixelaw::core::utils::{get_core_actions, Direction, Position, DefaultParameters};
    use pixelaw::core::models::registry::{app, app_name, core_actions_address};
    use starknet::{get_caller_address, get_contract_address, get_execution_info, ContractAddress};
    use pixelaw::core::actions::{actions, IActionsDispatcher, IActionsDispatcherTrait};
    use dojo::test_utils::{spawn_test_world, deploy_contract};
    use pixelaw::apps::minesweeper::app::{
        minesweeper_actions, MinesweeperGame, State, IMinesweeperActionsDispatcher, IMinesweeperActionsDispatcherTrait, minesweeper_game};

    use pixelaw::core::models::pixel::{pixel};
    use pixelaw::core::models::permissions::{permissions};

    // Helper function: deploys world and actions
    fn deploy_world() -> (IWorldDispatcher, IActionsDispatcher, IMinesweeperActionsDispatcher) {
        // Deploy World and models
        let world = spawn_test_world(
            array![
                pixel::TEST_CLASS_HASH,
                minesweeper_game::TEST_CLASS_HASH,
                app::TEST_CLASS_HASH,
                app_name::TEST_CLASS_HASH,
                core_actions_address::TEST_CLASS_HASH,
                permissions::TEST_CLASS_HASH,
            ]
        );

        // Deploy Core actions
        let core_actions_address = world
            .deploy_contract('salt1', actions::TEST_CLASS_HASH.try_into().unwrap());
        let core_actions = IActionsDispatcher { contract_address: core_actions_address };

        // Deploy Minesweeper actions
        let minesweeper_actions_address = world
            .deploy_contract('salt', minesweeper_actions::TEST_CLASS_HASH.try_into().unwrap());
        let minesweeper_actions = IMinesweeperActionsDispatcher { contract_address: minesweeper_actions_address };

        // Setup dojo auth
        world.grant_writer('Pixel',core_actions_address);
        world.grant_writer('App',core_actions_address);
        world.grant_writer('AppName',core_actions_address);
        world.grant_writer('CoreActionsAddress',core_actions_address);
        world.grant_writer('Permissions',core_actions_address);

        world.grant_writer('MinesweeperGame',minesweeper_actions_address);
        world.grant_writer('Player',minesweeper_actions_address);


        (world, core_actions, minesweeper_actions)
    }

    #[test]
    #[available_gas(3000000000)]
    fn test_create_minefield() {
        // Deploy everything
        let (world, core_actions, minesweeper_actions) = deploy_world();

        core_actions.init();
        minesweeper_actions.init();

        // Impersonate player
        let player = starknet::contract_address_const::<0x1337>();
        starknet::testing::set_account_contract_address(player);

        //computer variables
        let size: u64 = 5;
        let mines_amount: u64 = 10;

        // Player creates minefield
        minesweeper_actions
            .interact(
                DefaultParameters {
                    for_player: Zeroable::zero(),
                    for_system: Zeroable::zero(),
                    position: Position { x: 1, y: 1 },
                    color: 0
                },
                size,
                mines_amount
            );
    }

    // #[test]
    // #[available_gas(3000000000)]
    // fn test_create_conditions() {
    //     // Deploy everything
    //     let (world, core_actions, minesweeper_actions) = deploy_world();

    //     core_actions.init();
    //     minesweeper_actions.init();

    //     // Impersonate player
    //     let player = starknet::contract_address_const::<0x1337>();
    //     starknet::testing::set_account_contract_address(player);



    //     //computer variables
    //     let size: u64 = 5;
    //     let mines_amount: u64 = 10;

    //     //add owned pixel
    //     core_actions
    //         .update_pixel(
    //         player,
    //         system,
    //         PixelUpdate {
    //             x: 1,
    //             y: 1,
    //             color: Option::Some(default_params.color), //should I pass in a color to define the minesweepers field color?
    //             alert: Option::None,
    //             timestamp: Option::None,
    //             text: Option::None,
    //             app: Option::Some(system),
    //             owner: Option::Some(player),
    //             action: Option::Some('reveal'),
    //             }
    //         );



    //     // Player creates minefield
    //     minesweeper_actions
    //         .interact(
    //             DefaultParameters {
    //                 for_player: Zeroable::zero(),
    //                 for_system: Zeroable::zero(),
    //                 position: Position { x: 1, y: 1 },
    //                 color: 0
    //             },
    //             size,
    //             mines_amount
    //         );
    // }
}
