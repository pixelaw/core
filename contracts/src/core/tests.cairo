#[cfg(test)]
mod tests {
    use starknet::class_hash::{ClassHash, Felt252TryIntoClassHash};

    use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

    use dojo::test_utils::{spawn_test_world, deploy_contract};

    use pixelaw::core::models::app::{app, app_name};
    use pixelaw::core::models::color::color;
    use pixelaw::core::models::actions_model::actions_model;
    use pixelaw::core::models::alert::alert;
    use pixelaw::core::models::owner::owner;
    use pixelaw::core::models::owner::Owner;
    use pixelaw::core::models::permission::permission;
    use pixelaw::core::models::app::app;
    use pixelaw::core::models::app::PixelType;
    use pixelaw::core::models::position::Position;
    use pixelaw::core::models::text::text;
    use pixelaw::core::models::timestamp::timestamp;
    use pixelaw::core::models::timestamp::Timestamp;

    use super::{actions, IActionsDispatcher, IActionsDispatcherTrait};

    const SPAWN_PIXEL_ENTRYPOINT: felt252 =
        0x01c199924ae2ed5de296007a1ac8aa672140ef2a973769e4ad1089829f77875a;

    #[test]
    #[available_gas(30000000)]
    fn test_process_queue() {
        let caller = starknet::contract_address_const::<0x0>();

        // models
        let mut models = array![
            app::TEST_CLASS_HASH,
            app_name::TEST_CLASS_HASH,
            actions_model::TEST_CLASS_HASH,
            owner::TEST_CLASS_HASH,
            permission::TEST_CLASS_HASH,
            app::TEST_CLASS_HASH,
            timestamp::TEST_CLASS_HASH,
            text::TEST_CLASS_HASH,
            color::TEST_CLASS_HASH,
        ];
        // deploy world with models
        let world = spawn_test_world(models);

        let class_hash: ClassHash = actions::TEST_CLASS_HASH.try_into().unwrap();

        // deploy systems contract
        let contract_address = world.deploy_contract(0, class_hash);

        let actions_system = IActionsDispatcher { contract_address };
        let id = 0;

        let position = Position { x: 0, y: 0 };

        let mut calldata: Array<felt252> = ArrayTrait::new();
        calldata.append('snake');
        position.serialize(ref calldata);
        calldata.append('snake');
        calldata.append(0);

        actions_system.process_queue(id, contract_address, SPAWN_PIXEL_ENTRYPOINT, calldata.span());

        let (owner, app, timestamp) = get!(world, (position).into(), (Owner, PixelType, Timestamp));

        // check timestamp
        assert(
            timestamp.created_at == starknet::get_block_timestamp(),
            'incorrect timestamp.created_at'
        );
        assert(
            timestamp.updated_at == starknet::get_block_timestamp(),
            'incorrect timestamp.updated_at'
        );
        assert(timestamp.x == position.x, 'incorrect timestamp.x');
        assert(timestamp.y == position.y, 'incorrect timestamp.y');
    }
}
