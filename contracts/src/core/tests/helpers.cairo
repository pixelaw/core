use core::{traits::TryInto, poseidon::poseidon_hash_span};

use dojo::{
    utils::test::{spawn_test_world, deploy_contract},
    world::{IWorldDispatcher, IWorldDispatcherTrait}
};

use pixelaw::core::{
    models::{
        registry::{
            App, app, app_name, core_actions_address, CoreActionsAddress, Instruction, instruction
        },
        pixel::{Pixel, PixelUpdate, pixel}, permissions::{permissions, Permission, Permissions}
    },
    actions::{actions, IActionsDispatcher, IActionsDispatcherTrait, CORE_ACTIONS_KEY},
    utils::{get_core_actions, Direction, Position, DefaultParameters}
};

use pixelaw::{
    apps::{
        paint::app::{paint_actions, IPaintActionsDispatcher, IPaintActionsDispatcherTrait},
        snake::app::{
            snake, Snake, snake_segment, SnakeSegment, snake_actions, ISnakeActionsDispatcher,
            ISnakeActionsDispatcherTrait
        }
    }
};
use starknet::{
    get_block_timestamp, contract_address_const, ClassHash, ContractAddress,
    testing::{set_block_timestamp, set_account_contract_address},
};


pub const TEST_POSITION: Position = Position { x: 1, y: 1 };
pub const WHITE_COLOR: u32 = 0xFFFFFFFF;
pub const RED_COLOR: u32 = 0xFF0000FF;


pub const PERMISSION_ALL: Permission =
    Permission { app: true, color: true, owner: true, text: true, timestamp: true, action: true };

pub const PERMISSION_NONE: Permission =
    Permission {
        app: false, color: false, owner: false, text: false, timestamp: false, action: false
    };


pub fn set_caller(caller: ContractAddress) {
    starknet::testing::set_account_contract_address(caller);
    starknet::testing::set_contract_address(caller);
}

pub fn ZERO_ADDRESS() -> ContractAddress {
    contract_address_const::<0x0>()
}

pub fn setup_core_initialized() -> (
    IWorldDispatcher, IActionsDispatcher, ContractAddress, ContractAddress
) {
    let (world, core_actions, player_1, player_2) = setup_core();

    core_actions.init();

    (world, core_actions, player_1, player_2)
}

pub fn setup_core() -> (IWorldDispatcher, IActionsDispatcher, ContractAddress, ContractAddress) {
    let mut models = array![
        pixel::TEST_CLASS_HASH,
        app::TEST_CLASS_HASH,
        app_name::TEST_CLASS_HASH,
        core_actions_address::TEST_CLASS_HASH,
        permissions::TEST_CLASS_HASH,
        instruction::TEST_CLASS_HASH,
    ];
    let world = spawn_test_world(["pixelaw"].span(), models.span());

    let core_actions_address = world
        .deploy_contract('salt1', actions::TEST_CLASS_HASH.try_into().unwrap());
    let core_actions = IActionsDispatcher { contract_address: core_actions_address };

    // Setup permissions
    world.grant_writer(selector_from_tag!("pixelaw-App"), core_actions_address);
    world.grant_writer(selector_from_tag!("pixelaw-AppName"), core_actions_address);
    world.grant_writer(selector_from_tag!("pixelaw-CoreActionsAddress"), core_actions_address);
    world.grant_writer(selector_from_tag!("pixelaw-Pixel"), core_actions_address);
    world.grant_writer(selector_from_tag!("pixelaw-Permissions"), core_actions_address);
    world.grant_writer(selector_from_tag!("pixelaw-Instruction"), core_actions_address);

    // Setup players
    let player_1 = contract_address_const::<0x1337>();
    let player_2 = contract_address_const::<0x42>();

    (world, core_actions, player_1, player_2)
}


pub fn setup_apps_initialized(
    world: IWorldDispatcher
) -> (IPaintActionsDispatcher, ISnakeActionsDispatcher) {
    let (paint_actions, snake_actions) = setup_apps(world);

    paint_actions.init();
    snake_actions.init();

    (paint_actions, snake_actions)
}

pub fn setup_apps(world: IWorldDispatcher) -> (IPaintActionsDispatcher, ISnakeActionsDispatcher) {
    let core_address = get!(world, CORE_ACTIONS_KEY, (CoreActionsAddress));

    world.register_model((snake::TEST_CLASS_HASH).try_into().unwrap());
    world.register_model((snake_segment::TEST_CLASS_HASH).try_into().unwrap());

    let paint_actions_address = world
        .deploy_contract('salt3', paint_actions::TEST_CLASS_HASH.try_into().unwrap());
    let paint_actions = IPaintActionsDispatcher { contract_address: paint_actions_address };

    let snake_actions_address = world
        .deploy_contract('salt4', snake_actions::TEST_CLASS_HASH.try_into().unwrap());
    let snake_actions = ISnakeActionsDispatcher { contract_address: snake_actions_address };

    // Setup permissions
    world.grant_writer(selector_from_tag!("pixelaw-Snake"), core_address.value);
    world.grant_writer(selector_from_tag!("pixelaw-SnakeSegment"), core_address.value);

    (paint_actions, snake_actions)
}

pub fn drop_all_events(address: ContractAddress) {
    loop {
        match starknet::testing::pop_log_raw(address) {
            core::option::Option::Some(_) => {},
            core::option::Option::None => { break; },
        };
    }
}
