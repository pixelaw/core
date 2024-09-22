#[cfg(test)]
mod tests {
    use core::traits::TryInto;

    use starknet::{contract_address_const, testing::set_account_contract_address};

    use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
    use dojo::utils::test::{spawn_test_world};

    use pixelaw::core::models::registry::{app, app_name, core_actions_address};
    use pixelaw::core::models::pixel::{Pixel, PixelUpdate};
    use pixelaw::core::models::pixel::{pixel};
    use pixelaw::core::models::permissions::{permissions};
    use pixelaw::core::utils::{
        get_core_actions, encode_color, decode_color, Direction, Position, DefaultParameters
    };
    use pixelaw::core::actions::{actions, IActionsDispatcher, IActionsDispatcherTrait};
    use pixelaw::apps::paint::app::{
        paint_actions, IPaintActionsDispatcher, IPaintActionsDispatcherTrait
    };
    use pixelaw::core::tests::helpers::{setup_core_initialized, setup_apps_initialized};


    #[test]
    #[available_gas(3000000000)]
    fn test_paint_actions() {
        // Deploy everything
        let (world, _core_actions, _player_1, _player_2) = setup_core_initialized();
        let (paint_actions, _snake_actions) = setup_apps_initialized(world);
    

        let player1 = contract_address_const::<0x1337>();
        set_account_contract_address(player1);

        let color = encode_color(1, 0, 0, 1);

        paint_actions
            .interact(
                DefaultParameters {
                    for_player: contract_address_const::<0>(),
                    for_system: contract_address_const::<0>(),
                    position: Position { x: 1, y: 1 },
                    color: color
                },
            );

        let pixel_1_1 = get!(world, (1, 1), (Pixel));
        assert(pixel_1_1.color == color, 'should be the color');

        println!("Passed test");
    }
}
