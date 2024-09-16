use starknet::{
    get_block_timestamp, contract_address_const, ClassHash, ContractAddress,
    testing::{set_block_timestamp, set_account_contract_address},
};

use core::{traits::TryInto, poseidon::poseidon_hash_span};

use dojo::{
    utils::test::{spawn_test_world, deploy_contract},
    world::{IWorldDispatcher, IWorldDispatcherTrait}
};

use pixelaw::core::{
    models::{
        registry::{app, app_name, core_actions_address}, pixel::{Pixel, PixelUpdate, pixel},
        permissions::{permissions}
    },
    actions::{actions, IActionsDispatcher, IActionsDispatcherTrait},
    utils::{get_core_actions, Direction, Position, DefaultParameters}, tests::helpers::setup_core_initialized
};


const SPAWN_PIXEL_ENTRYPOINT: felt252 =
    0x01c199924ae2ed5de296007a1ac8aa672140ef2a973769e4ad1089829f77875a;

#[test]
#[available_gas(30000000)]
fn test_process_queue() {
    let (world, core_actions, _player_1, _player_2) = pixelaw::core::tests::helpers::setup_core_initialized();
    let position = Position { x: 0, y: 0 };

    let mut calldata: Array<felt252> = ArrayTrait::new();
    calldata.append('snake');
    position.serialize(ref calldata);
    calldata.append('snake');
    calldata.append(0);
    let id = poseidon_hash_span(
        array![
            0.into(),
            core_actions.contract_address.into(),
            SPAWN_PIXEL_ENTRYPOINT.into(),
            poseidon_hash_span(calldata.span())
        ]
            .span()
    );

    core_actions
        .process_queue(
            id, 0, core_actions.contract_address.into(), SPAWN_PIXEL_ENTRYPOINT, calldata.span()
        );

    let pixel = get!(world, (position).into(), (Pixel));

    // check timestamp
    assert(pixel.created_at == starknet::get_block_timestamp(), 'incorrect timestamp.created_at');
    assert(pixel.updated_at == starknet::get_block_timestamp(), 'incorrect timestamp.updated_at');
    assert(pixel.x == position.x, 'incorrect timestamp.x');
    assert(pixel.y == position.y, 'incorrect timestamp.y');
}
