use core::{traits::TryInto};

use pixelaw::{
    core::{
        models::{
            pixel::m_Pixel, registry::{m_App, m_AppName, m_CoreActionsAddress, CoreActionsAddress},
            area::{m_Area, m_RTree}
        },
        actions::{actions, IActionsDispatcher, IActionsDispatcherTrait, CORE_ACTIONS_KEY},
        utils::{Position}
    },
    apps::{paint::app::{IPaintActionsDispatcher}, snake::app::{ISnakeActionsDispatcher}}
};

use dojo::world::{WorldStorage};
use dojo::model::ModelStorage;
use dojo_cairo_test::{
    spawn_test_world, deploy_contract, NamespaceDef, TestResource, ContractDefTrait
};

use starknet::{contract_address_const, ContractAddress};


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

fn namespace_def() -> NamespaceDef {
    let ndef = NamespaceDef {
        namespace: "pixelaw", resources: [
            TestResource::Model(m_Pixel::TEST_CLASS_HASH.try_into().unwrap()),
            TestResource::Model(m_App::TEST_CLASS_HASH.try_into().unwrap()),
            TestResource::Model(m_AppName::TEST_CLASS_HASH.try_into().unwrap()),
            TestResource::Model(m_CoreActionsAddress::TEST_CLASS_HASH.try_into().unwrap()),
            TestResource::Model(m_RTree::TEST_CLASS_HASH.try_into().unwrap()),
            TestResource::Model(m_Area::TEST_CLASS_HASH.try_into().unwrap()),
            TestResource::Contract(
                ContractDefTrait::new(actions::TEST_CLASS_HASH, "actions")
                    .with_writer_of([dojo::utils::bytearray_hash(@"pixelaw")].span())
            )
        ].span()
    };

    ndef
}

pub fn setup_core_initialized() -> (
    WorldStorage, IActionsDispatcher, ContractAddress, ContractAddress
) {
    let (world, core_actions, player_1, player_2) = setup_core();

    core_actions.init();

    (world, core_actions, player_1, player_2)
}

pub fn setup_core() -> (WorldStorage, IActionsDispatcher, ContractAddress, ContractAddress) {
    let ndef = namespace_def();
    let mut world = spawn_test_world([ndef].span());

    let core_actions_address = deploy_contract(
        actions::TEST_CLASS_HASH.try_into().unwrap(), [].span()
    );
    let core_actions = IActionsDispatcher { contract_address: core_actions_address };

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
