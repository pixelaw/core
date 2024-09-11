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
        registry::{app, app_name, core_actions_address},
        pixel::{Pixel, PixelUpdate, pixel},
        permissions::{permissions}
    },
    actions::{actions, IActionsDispatcher, IActionsDispatcherTrait},
    utils::{get_core_actions, Direction, Position, DefaultParameters}, tests::helpers::setup
};



#[test]
#[available_gas(30000000)]
fn base_test() {

    let (world, core_actions, player_1, player_2) = pixelaw::core::tests::helpers::setup();
    let position = Position { x: 0, y: 0 };

    // TODO tests for the following:
// init
// update_permission update_app has_write_access
// process_queue schedule_queue
// update_pixel new_app
// get_system_address get_player_address
// alert_player
// set_instruction

}
