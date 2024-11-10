use core::{traits::TryInto, poseidon::poseidon_hash_span};

use dojo::{
    utils::test::{spawn_test_world, deploy_contract},
    world::{WorldStorage, WorldStorageTrait, IWorld, World, IWorldDispatcher},
    model::{ModelStorage, ModelValueStorage, ModelStorageTest}, event::EventStorage,
    tests::helpers::{WorldStorageTrait, IUpgradeableWorldDispatcherTrait}
};
use dojo_cairo_test::{
    WorldStorageTestTrait, spawn_test_world, NamespaceDef, TestResource, ContractDefTrait
};
use pixelaw::{
    apps::{
        paint::app::{paint_actions, IPaintActionsDispatcher, IPaintActionsDispatcherTrait},
        snake::app::{
            m_Snake, Snake, m_SnakeSegment, SnakeSegment, m_SnakeActions, ISnakeActionsDispatcher,
            ISnakeActionsDispatcherTrait
        }
    },
    core::{
        models::{
            registry::{App, m_App, m_App_name, m_CoreActionsAddress, CoreActionsAddress},
            pixel::{Pixel, PixelUpdate, m_Pixel}, area::{m_RTree, RTree, m_Area, Area}
        },
        actions::{actions, IActionsDispatcher, IActionsDispatcherTrait, CORE_ACTIONS_KEY},
        utils::{get_core_actions, Direction, Position, DefaultParameters},
    }
};


use starknet::{
    get_block_timestamp, contract_address_const, ClassHash, ContractAddress,
    testing::{set_block_timestamp, set_account_contract_address},
};


pub const TEST_POSITION: Position = Position { x: 1, y: 1 };
pub const WHITE_COLOR: u32 = 0xFFFFFFFF;
pub const RED_COLOR: u32 = 0xFF0000FF;


pub fn set_caller(caller: ContractAddress) {
    starknet::testing::set_account_contract_address(caller);
    starknet::testing::set_contract_address(caller);
}

pub fn ZERO_ADDRESS() -> ContractAddress {
    contract_address_const::<0x0>()
}

pub fn setup_core_initialized() -> (
    WorldStorage, IActionsDispatcher, ContractAddress, ContractAddress
) {
    let (world, core_actions, player_1, player_2) = setup_core();

    core_actions.init();

    (world, core_actions, player_1, player_2)
}

fn namespace_def() -> NamespaceDef {
    let ndef = NamespaceDef {
        namespace: "ns", resources: [
            TestResource::Model(m_Pixel::TEST_CLASS_HASH.try_into().unwrap()),
            TestResource::Model(m_App::TEST_CLASS_HASH.try_into().unwrap()),
            TestResource::Model(m_AppName::TEST_CLASS_HASH.try_into().unwrap()),
            TestResource::Model(m_CoreActionsAddress::TEST_CLASS_HASH.try_into().unwrap()),
            TestResource::Model(m_RTree::TEST_CLASS_HASH.try_into().unwrap()),
            TestResource::Model(m_Area::TEST_CLASS_HASH.try_into().unwrap()),
            TestResource::Model(m_Snake::TEST_CLASS_HASH.try_into().unwrap()),
            TestResource::Model(m_SnakeSegment::TEST_CLASS_HASH.try_into().unwrap()),
            TestResource::Event(actions::e_Moved::TEST_CLASS_HASH.try_into().unwrap()),
            TestResource::Contract(
                ContractDefTrait::new(actions::TEST_CLASS_HASH, "actions")
                    .with_writer_of([dojo::utils::bytearray_hash(@"ns")].span())
            )
        ].span()
    };

    ndef
}

pub fn setup_core() -> (WorldStorage, IActionsDispatcher, ContractAddress, ContractAddress) {
    let mut world: WorldStorage = spawn_test_world([namespace_def()].span());

    let (core_actions_address, _) = world.dns(@"actions").unwrap();
    let core_actions = IActionsDispatcher { contract_address: core_actions_address };

    // FIXME: Setup permissions
    // world.dispatcher.grant_writer(selector_from_tag!("pixelaw-App"), core_actions_address);
    // world.grant_writer(selector_from_tag!("pixelaw-AppName"), core_actions_address);
    // world.grant_writer(selector_from_tag!("pixelaw-CoreActionsAddress"), core_actions_address);
    // world.grant_writer(selector_from_tag!("pixelaw-Pixel"), core_actions_address);
    // world.grant_writer(selector_from_tag!("pixelaw-RTree"), core_actions_address);
    // world.grant_writer(selector_from_tag!("pixelaw-Area"), core_actions_address);

    // Setup players
    let player_1 = contract_address_const::<0x1337>();
    let player_2 = contract_address_const::<0x42>();

    (world, core_actions, player_1, player_2)
}


pub fn setup_apps_initialized(
    world: WorldStorage
) -> (IPaintActionsDispatcher, ISnakeActionsDispatcher) {
    let (paint_actions, snake_actions) = setup_apps(world);

    paint_actions.init();
    snake_actions.init();

    (paint_actions, snake_actions)
}

pub fn setup_apps(world: WorldStorage) -> (IPaintActionsDispatcher, ISnakeActionsDispatcher) {
    let core_address: CoreActionsAddress = world.read_model(CORE_ACTIONS_KEY);

    let paint_actions_address = world
        .deploy_contract('salt3', paint_actions::TEST_CLASS_HASH.try_into().unwrap());
    let paint_actions = IPaintActionsDispatcher { contract_address: paint_actions_address };

    let snake_actions_address = world
        .deploy_contract('salt4', snake_actions::TEST_CLASS_HASH.try_into().unwrap());
    let snake_actions = ISnakeActionsDispatcher { contract_address: snake_actions_address };

    // Setup permissions
    world.grant_writer(selector_from_tag!("pixelaw-Snake"), core_address.value);
    world.grant_writer(selector_from_tag!("pixelaw-SnakeSegment"), core_address.value);

    world.grant_writer(selector_from_tag!("pixelaw-Snake"), snake_actions_address);
    world.grant_writer(selector_from_tag!("pixelaw-SnakeSegment"), snake_actions_address);

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
