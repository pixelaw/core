#[cfg(test)]
mod tests {
    use core::traits::TryInto;

    use dojo::model::{ModelStorage};
    use dojo::utils::test::{spawn_test_world};
    use dojo::world::storage::WorldStorage;

    use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
    use pixelaw::apps::paint::app::{
        paint_actions, IPaintActionsDispatcher, IPaintActionsDispatcherTrait
    };
    use pixelaw::core::actions::{actions, IActionsDispatcher, IActionsDispatcherTrait};
    use pixelaw::core::models::pixel::{Pixel, PixelUpdate};
    use pixelaw::core::models::pixel::{pixel};

    use pixelaw::core::models::registry::{app, app_name, core_actions_address};
    use pixelaw::core::tests::helpers::{setup_core_initialized, setup_apps_initialized};
    use pixelaw::core::utils::{
        get_core_actions, encode_rgba, decode_rgba, Direction, Position, DefaultParameters
    };

    use starknet::{contract_address_const, testing::set_account_contract_address};

    #[test]
    #[available_gas(3000000000)]
    fn test_paint_actions() {
        // Deploy everything
        let (world, _core_actions, _player_1, _player_2) = setup_core_initialized();
        let (paint_actions, _snake_actions) = setup_apps_initialized(world);

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
                    color: color
                },
            );

        let pixel_1_1: Pixel = world.read_model((1, 1));
        assert(pixel_1_1.color == color, 'should be the color');
    }
}
