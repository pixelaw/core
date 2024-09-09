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


    // Helper function: deploys world and actions
    fn deploy_world() -> (IWorldDispatcher, IActionsDispatcher, IPaintActionsDispatcher) {
        // Deploy World and models
        let mut models = array![
            pixel::TEST_CLASS_HASH,
            app::TEST_CLASS_HASH,
            app_name::TEST_CLASS_HASH,
            core_actions_address::TEST_CLASS_HASH,
            permissions::TEST_CLASS_HASH,
        ];
        let world = spawn_test_world(["pixelaw"].span(), models.span());

        // Deploy Core actions
        let core_actions_address = world
            .deploy_contract('salt1', actions::TEST_CLASS_HASH.try_into().unwrap());
        let core_actions = IActionsDispatcher { contract_address: core_actions_address };

        // Deploy Paint actions
        let paint_actions_address = world
            .deploy_contract('salt2', paint_actions::TEST_CLASS_HASH.try_into().unwrap());
        let paint_actions = IPaintActionsDispatcher { contract_address: paint_actions_address };

        world.grant_writer(selector_from_tag!("pixelaw-Pixel"), core_actions_address);
        world.grant_writer(selector_from_tag!("pixelaw-App"), core_actions_address);
        world.grant_writer(selector_from_tag!("pixelaw-AppName"), core_actions_address);
        world.grant_writer(selector_from_tag!("pixelaw-Permissions"), core_actions_address);
        world.grant_writer(selector_from_tag!("pixelaw-CoreActionsAddress"), core_actions_address);

        (world, core_actions, paint_actions)
    }

    #[test]
    #[available_gas(3000000000)]
    fn test_paint_actions() {
        // Deploy everything
        let (world, core_actions, paint_actions) = deploy_world();

        core_actions.init();
        paint_actions.init();

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
