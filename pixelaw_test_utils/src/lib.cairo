use dojo::world::{IWorldDispatcherTrait, WorldStorage, WorldStorageTrait, world};
use dojo_cairo_test::{
    ContractDef, ContractDefTrait, NamespaceDef, TestResource, WorldStorageTestTrait,
    spawn_test_world,
};
use starknet::ContractAddress;
use pixelaw::apps::house::{IHouseActionsDispatcher, house_actions, m_House, m_PlayerHouse};
use pixelaw::apps::paint::{IPaintActionsDispatcher, paint_actions};
use pixelaw::apps::player::{IPlayerActionsDispatcher, m_Player, m_PositionPlayer, player_actions};
use pixelaw::apps::snake::{ISnakeActionsDispatcher, m_Snake, m_SnakeSegment, snake_actions};
use pixelaw::core::actions::{IActionsDispatcher, actions};
use pixelaw::core::events::{e_Notification, e_QueueScheduled};
use pixelaw::core::models::area::{m_Area, m_RTree};
use pixelaw::core::models::pixel::m_Pixel;
use pixelaw::core::models::queue::m_QueueItem;
use pixelaw::core::models::registry::{m_App, m_AppName, m_CoreActionsAddress};
use pixelaw::core::utils::Position;


pub const TEST_POSITION: Position = Position { x: 1, y: 1 };
pub const WHITE_COLOR: u32 = 0xFFFFFFFF;
pub const RED_COLOR: u32 = 0xFF0000FF;


pub fn set_caller(caller: ContractAddress) {
    starknet::testing::set_account_contract_address(caller);
    starknet::testing::set_contract_address(caller);
}

pub fn ZERO_ADDRESS() -> ContractAddress {
    0x0.try_into().unwrap()
}

fn app_namespace_defs() -> NamespaceDef {
    let ndef = NamespaceDef {
        namespace: "pixelaw",
        resources: [
            TestResource::Model(m_Snake::TEST_CLASS_HASH),
            TestResource::Model(m_SnakeSegment::TEST_CLASS_HASH),
            TestResource::Model(m_Player::TEST_CLASS_HASH),
            TestResource::Model(m_PositionPlayer::TEST_CLASS_HASH),
            TestResource::Model(m_House::TEST_CLASS_HASH),
            TestResource::Model(m_PlayerHouse::TEST_CLASS_HASH),
            TestResource::Contract(snake_actions::TEST_CLASS_HASH),
            TestResource::Contract(paint_actions::TEST_CLASS_HASH),
            TestResource::Contract(player_actions::TEST_CLASS_HASH),
            TestResource::Contract(house_actions::TEST_CLASS_HASH),
        ]
            .span(),
    };

    ndef
}

fn core_namespace_defs() -> NamespaceDef {
    let ndef = NamespaceDef {
        namespace: "pixelaw",
        resources: [
            TestResource::Model(m_Pixel::TEST_CLASS_HASH),
            TestResource::Model(m_App::TEST_CLASS_HASH),
            TestResource::Model(m_AppName::TEST_CLASS_HASH),
            TestResource::Model(m_CoreActionsAddress::TEST_CLASS_HASH),
            TestResource::Model(m_RTree::TEST_CLASS_HASH),
            TestResource::Model(m_Area::TEST_CLASS_HASH),
            TestResource::Model(m_QueueItem::TEST_CLASS_HASH),
            TestResource::Event(e_QueueScheduled::TEST_CLASS_HASH),
            TestResource::Event(e_Notification::TEST_CLASS_HASH),
            TestResource::Contract(actions::TEST_CLASS_HASH),
        ]
            .span(),
    };

    ndef
}

fn core_contract_defs() -> Span<ContractDef> {
    [
        ContractDefTrait::new(@"pixelaw", @"actions")
            .with_writer_of([dojo::utils::bytearray_hash(@"pixelaw")].span())
    ]
        .span()
}

fn app_contract_defs() -> Span<ContractDef> {
    [
        ContractDefTrait::new(@"pixelaw", @"paint_actions")
            .with_writer_of([dojo::utils::bytearray_hash(@"pixelaw")].span()),
        ContractDefTrait::new(@"pixelaw", @"snake_actions")
            .with_writer_of([dojo::utils::bytearray_hash(@"pixelaw")].span()),
        ContractDefTrait::new(@"pixelaw", @"player_actions")
            .with_writer_of([dojo::utils::bytearray_hash(@"pixelaw")].span()),
        ContractDefTrait::new(@"pixelaw", @"house_actions")
            .with_writer_of([dojo::utils::bytearray_hash(@"pixelaw")].span()),
    ]
        .span()
}


pub fn setup_core() -> (WorldStorage, IActionsDispatcher, ContractAddress, ContractAddress) {
    let mut world = spawn_test_world(world::TEST_CLASS_HASH, [core_namespace_defs()].span());

    world.sync_perms_and_inits(core_contract_defs());

    let (core_actions_address, _) = world.dns(@"actions").unwrap();
    let core_actions = IActionsDispatcher { contract_address: core_actions_address };

    // Setup players
    let player_1 = 0x1337.try_into().unwrap();
    let player_2 = 0x42.try_into().unwrap();

    (world, core_actions, player_1, player_2)
}


pub fn setup_apps(
    ref world: WorldStorage,
) -> (
    IPaintActionsDispatcher,
    ISnakeActionsDispatcher,
    IPlayerActionsDispatcher,
    IHouseActionsDispatcher,
) {
    update_test_world(ref world, [app_namespace_defs()].span());

    world.sync_perms_and_inits(app_contract_defs());

    let (paint_actions_address, _) = world.dns(@"paint_actions").unwrap();
    let paint_actions = IPaintActionsDispatcher { contract_address: paint_actions_address };

    let (snake_actions_address, _) = world.dns(@"snake_actions").unwrap();
    let snake_actions = ISnakeActionsDispatcher { contract_address: snake_actions_address };

    let (player_actions_address, _) = world.dns(@"player_actions").unwrap();
    let player_actions = IPlayerActionsDispatcher { contract_address: player_actions_address };

    let (house_actions_address, _) = world.dns(@"house_actions").unwrap();
    let house_actions = IHouseActionsDispatcher { contract_address: house_actions_address };

    (paint_actions, snake_actions, player_actions, house_actions)
}


pub fn update_test_world(ref world: WorldStorage, namespaces_defs: Span<NamespaceDef>) {
    for ns in namespaces_defs {
        let namespace = ns.namespace.clone();

        // TODO make this failsafe
        // world.dispatcher.register_namespace(namespace.clone());

        for r in ns.resources.clone() {
            match r {
                TestResource::Event(ch) => {
                    world.dispatcher.register_event(namespace.clone(), (*ch).try_into().unwrap());
                },
                TestResource::Model(ch) => {
                    world.dispatcher.register_model(namespace.clone(), (*ch).try_into().unwrap());
                },
                TestResource::Contract(ch) => {
                    world
                        .dispatcher
                        .register_contract(
                            (*ch).try_into().unwrap(), namespace.clone(), (*ch).try_into().unwrap(),
                        );
                },
                TestResource::Library((
                    _ch, _name, _version,
                )) => { // FIXME somehow cannot call "register_library", for later fix when we're using
                // libraries world
                //     .register_library(
                //         namespace.clone(),
                //         (*ch).try_into().unwrap(),
                //         (*name).clone(),
                //         (*version).clone(),
                //     );
                },
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
