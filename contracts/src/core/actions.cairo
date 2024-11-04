pub mod app;
pub mod area;
pub mod pixel;
pub mod queue;

use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
use pixelaw::core::models::area::{Area, RTreeNode};
use pixelaw::core::models::pixel::{PixelUpdateResult, Pixel, PixelUpdate};
use pixelaw::core::models::registry::{App, AppName, CoreActionsAddress};
use pixelaw::core::utils::{Position, MAX_DIMENSION, Bounds};
use pixelaw::core::utils;
use starknet::{ContractAddress, ClassHash, contract_address_const};

pub const CORE_ACTIONS_KEY: felt252 = 'core_actions';


#[starknet::interface]
pub trait IActions<T> {
    /// Initializes the Pixelaw actions model.
    ///
    /// # Arguments
    ///
    /// * `world` - A reference to the world dispatcher.
    fn init(ref self: T);


    // Check if and how a Pixel can be updated, based on given params
    // It checks all ownership (pixel and Area) and hooks
    fn can_update_pixel(
        ref self: T,
        for_player: ContractAddress,
        for_system: ContractAddress,
        pixel: Pixel,
        pixel_update: PixelUpdate,
        area_id_hint: Option<u64>,
        allow_modify: bool
    ) -> PixelUpdateResult;


    /// Updates a pixel with the provided updates.
    ///
    /// # Arguments
    ///
    /// * `world` - A reference to the world dispatcher.
    /// * `for_player` - The player making the update.
    /// * `for_system` - The system making the update.
    /// * `pixel_update` - The updates to apply to the pixel.
    fn update_pixel(
        ref self: T,
        for_player: ContractAddress,
        for_system: ContractAddress,
        pixel_update: PixelUpdate,
        area_id: Option<u64>,
        allow_modify: bool
    ) -> PixelUpdateResult;


    /// Processes a scheduled queue item.
    ///
    /// # Arguments
    ///
    /// * `world` - A reference to the world dispatcher.
    /// * `id` - The unique identifier of the queue item.
    /// * `timestamp` - The timestamp when the queue item was scheduled.
    /// * `called_system` - The system contract address to call.
    /// * `selector` - The function selector to call in the system.
    /// * `calldata` - The calldata to pass to the function.
    fn process_queue(
        ref self: T,
        id: felt252,
        timestamp: u64,
        called_system: ContractAddress,
        selector: felt252,
        calldata: Span<felt252>,
    );

    /// Schedules a queue item to be processed at a specified timestamp.
    ///
    /// # Arguments
    ///
    /// * `world` - A reference to the world dispatcher.
    /// * `timestamp` - The timestamp when the queue item should be processed.
    /// * `called_system` - The system contract address to call.
    /// * `selector` - The function selector to call in the system.
    /// * `calldata` - The calldata to pass to the function.
    fn schedule_queue(
        ref self: T,
        timestamp: u64,
        called_system: ContractAddress,
        selector: felt252,
        calldata: Span<felt252>,
    );

    /// Registers a new app.
    ///
    /// # Arguments
    ///
    /// * `world` - A reference to the world dispatcher.
    /// * `system` - Contract address of the app's systems or zero to use the caller.
    /// * `name` - Name of the app.
    /// * `icon` - Unicode hex of the icon of the app.
    ///
    /// # Returns
    ///
    /// * `App` - Struct containing the contract address and name fields.
    fn new_app(ref self: T, system: ContractAddress, name: felt252, icon: felt252,) -> App;


    /// Sends an alert to a player.
    ///
    /// # Arguments
    ///
    /// * `world` - A reference to the world dispatcher.
    /// * `position` - The position associated with the alert.
    /// * `player` - The player to alert.
    /// * `message` - The message to send.
    fn alert_player(ref self: T, position: Position, player: ContractAddress, message: felt252,);


    fn add_area(
        ref self: T, bounds: Bounds, owner: ContractAddress, color: u32, app: ContractAddress
    ) -> Area;
    fn remove_area(ref self: T, area_id: u64);
    fn find_area_by_position(ref self: T, position: Position) -> Option<Area>;
    fn find_areas_inside_bounds(ref self: T, bounds: Bounds) -> Span<Area>;
}


#[dojo::contract(namespace: "pixelaw", nomapping: true)]
pub mod actions {
    use core::poseidon::poseidon_hash_span;
    use pixelaw::core::events::{QueueScheduled, QueueProcessed, AppNameUpdated, Alert};
    use pixelaw::core::models::area::{
        BoundsTraitImpl, RTreeTraitImpl, ROOT_ID, RTreeNode, RTree, Area, RTreeNodePackableImpl
    };
    use pixelaw::core::models::pixel::{Pixel, PixelUpdate, PixelUpdateResult};
    use pixelaw::core::models::queue::QueueItem;

    use pixelaw::core::models::registry::{App, AppName, CoreActionsAddress};

    use pixelaw::core::utils::{get_core_actions_address, Position, MAX_DIMENSION, Bounds};
    use starknet::{
        ContractAddress, get_caller_address, get_contract_address, get_tx_info,
        contract_address_const, syscalls::{call_contract_syscall},
    };

    use super::{IActions};


    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        QueueScheduled: QueueScheduled,
        QueueProcessed: QueueProcessed,
        AppNameUpdated: AppNameUpdated,
        Alert: Alert,
    }


    #[abi(embed_v0)]
    impl ActionsImpl of IActions<ContractState> {
        fn init(ref self: ContractState) {
            set!(
                world,
                (CoreActionsAddress { key: super::CORE_ACTIONS_KEY, value: get_contract_address() })
            );

            // Initialize root RTree
            set!(world, RTree { id: ROOT_ID, children: 1310762 });
        }

        fn can_update_pixel(
            ref self: ContractState,
            for_player: ContractAddress,
            for_system: ContractAddress,
            pixel: Pixel,
            pixel_update: PixelUpdate,
            area_id_hint: Option<u64>,
            allow_modify: bool
        ) -> PixelUpdateResult {
            super::pixel::can_update_pixel(
                world, for_player, for_system, pixel, pixel_update, area_id_hint, allow_modify
            )
        }

        fn update_pixel(
            ref self: ContractState,
            for_player: ContractAddress,
            for_system: ContractAddress,
            pixel_update: PixelUpdate,
            area_id: Option<u64>,
            allow_modify: bool
        ) -> PixelUpdateResult {
            super::pixel::update_pixel(
                world, for_player, for_system, pixel_update, area_id, allow_modify
            )
        }

        fn schedule_queue(
            ref self: ContractState,
            timestamp: u64,
            called_system: ContractAddress,
            selector: felt252,
            calldata: Span<felt252>,
        ) {
            let event = super::queue::schedule_queue(
                world, timestamp, called_system, selector, calldata
            );
            emit!(world, (Event::QueueScheduled(event)));
        }


        fn process_queue(
            ref self: ContractState,
            id: felt252,
            timestamp: u64,
            called_system: ContractAddress,
            selector: felt252,
            calldata: Span<felt252>,
        ) {
            let event = super::queue::process_queue(
                world, id, timestamp, called_system, selector, calldata
            );

            emit!(world, (Event::QueueProcessed(event)));
        }


        fn new_app(
            ref self: ContractState, system: ContractAddress, name: felt252, icon: felt252,
        ) -> App {
            super::app::new_app(world, system, name, icon)
        }


        fn alert_player(
            ref self: ContractState, position: Position, player: ContractAddress, message: felt252,
        ) {
            let caller = get_caller_address();
            let app = get!(world, caller, (App));
            assert!(app.name != '', "cannot be called by a non-app");
            emit!(
                world,
                (Event::Alert(
                    Alert {
                        position,
                        caller,
                        player,
                        message,
                        timestamp: starknet::get_block_timestamp()
                    }
                ))
            );
        }


        fn add_area(
            ref self: ContractState,
            bounds: Bounds,
            owner: ContractAddress,
            color: u32,
            app: ContractAddress
        ) -> Area {
            super::area::add_area(world, bounds, owner, color, app)
        }

        fn remove_area(ref self: ContractState, area_id: u64) {
            super::area::remove_area(world, area_id);
        }

        fn find_area_by_position(ref self: ContractState, position: Position,) -> Option<Area> {
            let result = super::area::find_node_for_position(world, position, ROOT_ID, true);
            match result {
                0 => Option::None,
                _ => Option::Some(get!(world, (result), (Area)))
            }
        }

        fn find_areas_inside_bounds(ref self: ContractState, bounds: Bounds) -> Span<Area> {
            let mut result: Array<Area> = array![];
            let mut area_ids: Array<u64> = array![];
            let smallest_node = super::area::find_smallest_node_spanning_bounds(
                world, bounds, ROOT_ID, false
            );
            super::area::find_nodes_inside_bounds(world, ref area_ids, bounds, smallest_node, true);
            if area_ids.len() == 0 {
                return result.span();
            }
            for area_id in area_ids {
                result.append(get!(world, area_id, (Area)));
            };
            result.span()
        }
    }
}
