use dojo::world::{IWorldDispatcherTrait, WorldStorageTrait, WorldStorage};

use dojo_cairo_test::{
    spawn_test_world, NamespaceDef, TestResource, ContractDefTrait, ContractDef,
    WorldStorageTestTrait
};

use pixelaw::{
    apps::{
        paint::app::{paint_actions, IPaintActionsDispatcher, IPaintActionsDispatcherTrait},
        snake::app::{
            m_Snake, m_SnakeSegment, ISnakeActionsDispatcher, ISnakeActionsDispatcherTrait,
            snake_actions
        }
    },
    core::{
        models::{
            registry::{m_App, m_AppName, m_CoreActionsAddress}, pixel::{m_Pixel},
            area::{m_RTree, m_Area}
        },
        actions::{actions, IActionsDispatcher, IActionsDispatcherTrait}, utils::{Position},
    }
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

pub fn setup_core_initialized() -> (
    WorldStorage, IActionsDispatcher, ContractAddress, ContractAddress
) {
    let (world, core_actions, player_1, player_2) = setup_core();

    core_actions.init();

    (world, core_actions, player_1, player_2)
}

fn namespace_def() -> NamespaceDef {
    let ndef = NamespaceDef {
        namespace: "pixelaw", resources: [
            TestResource::Model(m_Pixel::TEST_CLASS_HASH),
            TestResource::Model(m_App::TEST_CLASS_HASH),
            TestResource::Model(m_AppName::TEST_CLASS_HASH),
            TestResource::Model(m_CoreActionsAddress::TEST_CLASS_HASH),
            TestResource::Model(m_RTree::TEST_CLASS_HASH),
            TestResource::Model(m_Area::TEST_CLASS_HASH),
            TestResource::Model(m_Snake::TEST_CLASS_HASH),
            TestResource::Model(m_SnakeSegment::TEST_CLASS_HASH),
            TestResource::Event(pixelaw::core::events::e_QueueScheduled::TEST_CLASS_HASH),
            TestResource::Event(pixelaw::core::events::e_QueueProcessed::TEST_CLASS_HASH),
            TestResource::Event(pixelaw::core::events::e_Alert::TEST_CLASS_HASH),
            TestResource::Event(snake_actions::e_Moved::TEST_CLASS_HASH),
            TestResource::Event(snake_actions::e_Died::TEST_CLASS_HASH),
            TestResource::Contract(actions::TEST_CLASS_HASH),
            TestResource::Contract(snake_actions::TEST_CLASS_HASH),
            TestResource::Contract(paint_actions::TEST_CLASS_HASH),
        ].span()
    };

    ndef
}

fn core_contract_defs() -> Span<ContractDef> {
    [
        ContractDefTrait::new(@"pixelaw", @"actions")
            .with_writer_of([dojo::utils::bytearray_hash(@"pixelaw")].span())
    ].span()
}

fn app_contract_defs() -> Span<ContractDef> {
    [
        ContractDefTrait::new(@"pixelaw", @"paint_actions")
            .with_writer_of([dojo::utils::bytearray_hash(@"pixelaw")].span()),
        ContractDefTrait::new(@"pixelaw", @"snake_actions")
            .with_writer_of([dojo::utils::bytearray_hash(@"pixelaw")].span())
    ].span()
}


pub fn setup_core() -> (WorldStorage, IActionsDispatcher, ContractAddress, ContractAddress) {
    let mut world = spawn_test_world([namespace_def()].span());

    world.sync_perms_and_inits(core_contract_defs());

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


pub fn setup_apps(world: WorldStorage) -> (IPaintActionsDispatcher, ISnakeActionsDispatcher) {
    world.sync_perms_and_inits(app_contract_defs());

    let (paint_actions_address, _) = world.dns(@"paint_actions").unwrap();
    let paint_actions = IPaintActionsDispatcher { contract_address: paint_actions_address };

    let (snake_actions_address, _) = world.dns(@"snake_actions").unwrap();
    let snake_actions = ISnakeActionsDispatcher { contract_address: snake_actions_address };

    (paint_actions, snake_actions)
}

pub fn setup_apps_initialized(
    world: WorldStorage
) -> (IPaintActionsDispatcher, ISnakeActionsDispatcher) {
    let (paint_actions, snake_actions): (IPaintActionsDispatcher, ISnakeActionsDispatcher) =
        setup_apps(
        world
    );
    paint_actions.init();
    snake_actions.init();

    (paint_actions, snake_actions)
}


pub fn update_test_world(ref world: WorldStorage, namespaces_defs: Span<NamespaceDef>) {
    for ns in namespaces_defs {
        let namespace = ns.namespace.clone();

        // TODO make this failsafe
        // world.dispatcher.register_namespace(namespace.clone());

        for r in ns
            .resources
            .clone() {
                match r {
                    TestResource::Event(ch) => {
                        world
                            .dispatcher
                            .register_event(namespace.clone(), (*ch).try_into().unwrap());
                    },
                    TestResource::Model(ch) => {
                        world
                            .dispatcher
                            .register_model(namespace.clone(), (*ch).try_into().unwrap());
                    },
                    TestResource::Contract(ch) => {
                        world
                            .dispatcher
                            .register_contract(*ch, namespace.clone(), (*ch).try_into().unwrap());
                    }
                }
            }
    };
}

pub fn drop_all_events(address: ContractAddress) {
    loop {
        match starknet::testing::pop_log_raw(address) {
            core::option::Option::Some(_) => {},
            core::option::Option::None => { break; },
        };
    }
}
