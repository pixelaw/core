#[cfg(test)]
mod tests {
    use starknet::class_hash::{ClassHash};

    use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

    use pixelaw::core::models::registry::{app, app_name, core_actions_address};

    use pixelaw::core::models::pixel::{Pixel, PixelUpdate};
    use pixelaw::core::models::pixel::{pixel};
    use pixelaw::core::models::permissions::{permissions};
    use pixelaw::core::utils::{get_core_actions, Direction, Position, DefaultParameters};
    use pixelaw::core::actions::{actions, IActionsDispatcher, IActionsDispatcherTrait};
    use dojo::utils::test::{spawn_test_world, deploy_contract};
    use core::poseidon::poseidon_hash_span;

    use core::traits::TryInto;


    const SPAWN_PIXEL_ENTRYPOINT: felt252 =
        0x01c199924ae2ed5de296007a1ac8aa672140ef2a973769e4ad1089829f77875a;

    #[test]
    #[available_gas(30000000)]
    fn test_process_queue() {
        let mut models = array![
            pixel::TEST_CLASS_HASH,
            app::TEST_CLASS_HASH,
            app_name::TEST_CLASS_HASH,
            core_actions_address::TEST_CLASS_HASH,
            permissions::TEST_CLASS_HASH,
        ];
        let world = spawn_test_world("pixelaw", models);

        let core_actions_address = world
            .deploy_contract('salt1', actions::TEST_CLASS_HASH.try_into().unwrap());

        let core_actions = IActionsDispatcher { contract_address: core_actions_address };

        let position = Position { x: 0, y: 0 };

        let mut calldata: Array<felt252> = ArrayTrait::new();
        calldata.append('snake');
        position.serialize(ref calldata);
        calldata.append('snake');
        calldata.append(0);
        let id = poseidon_hash_span(
            array![
                0.into(),
                core_actions_address.into(),
                SPAWN_PIXEL_ENTRYPOINT.into(),
                poseidon_hash_span(calldata.span())
            ]
                .span()
        );

        core_actions
            .process_queue(id, 0, core_actions_address, SPAWN_PIXEL_ENTRYPOINT, calldata.span());

        let pixel = get!(world, (position).into(), (Pixel));

        // check timestamp
        assert(
            pixel.created_at == starknet::get_block_timestamp(), 'incorrect timestamp.created_at'
        );
        assert(
            pixel.updated_at == starknet::get_block_timestamp(), 'incorrect timestamp.updated_at'
        );
        assert(pixel.x == position.x, 'incorrect timestamp.x');
        assert(pixel.y == position.y, 'incorrect timestamp.y');
    }
}
