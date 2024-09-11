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
    utils::{get_core_actions, Direction, Position, DefaultParameters},
};

pub fn setup() -> (
    IWorldDispatcher,
    IActionsDispatcher,
    ContractAddress,
    ContractAddress
) {
    let mut models = array![
        pixel::TEST_CLASS_HASH,
        app::TEST_CLASS_HASH,
        app_name::TEST_CLASS_HASH,
        core_actions_address::TEST_CLASS_HASH,
        permissions::TEST_CLASS_HASH,
    ];
    let world = spawn_test_world(["pixelaw"].span(), models.span());

    let core_actions_address = world
        .deploy_contract('salt1', actions::TEST_CLASS_HASH.try_into().unwrap());

    let core_actions = IActionsDispatcher { contract_address: core_actions_address };

    // Setup players
    let player_1 = contract_address_const::<0x1337>();
    let player_2 = contract_address_const::<0x42>();


    (world, core_actions, player_1, player_2)
}
