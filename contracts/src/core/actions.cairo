use starknet::{ContractAddress, ClassHash, contract_address_const};
use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
use pixelaw::core::models::pixel::{Pixel, PixelUpdate};
use pixelaw::core::models::permissions::{Permission};
use pixelaw::core::models::registry::{App, AppName, CoreActionsAddress};
use pixelaw::core::utils::Position;

pub const CORE_ACTIONS_KEY: felt252 = 'core_actions';

#[dojo::interface]
pub trait IActions<TContractState> {
    /// Initializes the Pixelaw actions model.
    ///
    /// # Arguments
    ///
    /// * `world` - A reference to the world dispatcher.
    fn init(ref world: IWorldDispatcher);

    /// Updates the permissions for a specified system.
    ///
    /// # Arguments
    ///
    /// * `world` - A reference to the world dispatcher.
    /// * `app_key` - The key of the app (example: 'paint') to update permissions for.
    /// * `permission` - The permission to set for the system.
    fn update_permission(ref world: IWorldDispatcher, app_key: felt252, permission: Permission);

    // fn update_app(ref world: IWorldDispatcher, name: felt252, icon: felt252, manifest: felt252);

    /// Checks if a player or system has write access to a pixel.
    ///
    /// # Arguments
    ///
    /// * `world` - A reference to the world dispatcher.
    /// * `for_player` - The player contract address.
    /// * `for_system` - The system contract address.
    /// * `pixel` - The pixel to check access for.
    /// * `pixel_update` - The proposed update to the pixel.
    ///
    /// # Returns
    ///
    /// * `bool` - True if access is granted, false otherwise.
    fn has_write_access(
        ref world: IWorldDispatcher,
        for_player: ContractAddress,
        for_system: ContractAddress,
        pixel: Pixel,
        pixel_update: PixelUpdate,
    ) -> bool;

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
        ref world: IWorldDispatcher,
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
        ref world: IWorldDispatcher,
        timestamp: u64,
        called_system: ContractAddress,
        selector: felt252,
        calldata: Span<felt252>,
    );

    /// Updates a pixel with the provided updates.
    ///
    /// # Arguments
    ///
    /// * `world` - A reference to the world dispatcher.
    /// * `for_player` - The player making the update.
    /// * `for_system` - The system making the update.
    /// * `pixel_update` - The updates to apply to the pixel.
    fn update_pixel(
        ref world: IWorldDispatcher,
        for_player: ContractAddress,
        for_system: ContractAddress,
        pixel_update: PixelUpdate,
    );

    /// Registers a new app.
    ///
    /// # Arguments
    ///
    /// * `world` - A reference to the world dispatcher.
    /// * `system` - Contract address of the app's systems or zero to use the caller.
    /// * `name` - Name of the app.
    /// * `icon` - Unicode hex of the icon of the app.
    /// * `manifest` - URL to the system's `manifest.json`.
    ///
    /// # Returns
    ///
    /// * `App` - Struct containing the contract address and name fields.
    fn new_app(
        ref world: IWorldDispatcher,
        system: ContractAddress,
        name: felt252,
        icon: felt252,
        manifest: felt252,
    ) -> App;

    /// Retrieves the system address.
    ///
    /// # Arguments
    ///
    /// * `for_system` - The system contract address. If zero, returns the caller's address.
    ///
    /// # Returns
    ///
    /// * `ContractAddress` - The system address.
    fn get_system_address(for_system: ContractAddress) -> ContractAddress;

    /// Retrieves the player address.
    ///
    /// # Arguments
    ///
    /// * `for_player` - The player contract address. If zero, returns the caller's account address.
    ///
    /// # Returns
    ///
    /// * `ContractAddress` - The player address.
    fn get_player_address(for_player: ContractAddress) -> ContractAddress;

    /// Sends an alert to a player.
    ///
    /// # Arguments
    ///
    /// * `world` - A reference to the world dispatcher.
    /// * `position` - The position associated with the alert.
    /// * `player` - The player to alert.
    /// * `message` - The message to send.
    fn alert_player(
        ref world: IWorldDispatcher,
        position: Position,
        player: ContractAddress,
        message: felt252,
    );

    /// Sets an instruction for a given selector in a system.
    ///
    /// # Arguments
    ///
    /// * `world` - A reference to the world dispatcher.
    /// * `selector` - The function selector.
    /// * `instruction` - The instruction to set.
    fn set_instruction(ref world: IWorldDispatcher, selector: felt252, instruction: felt252);
}

#[dojo::contract(namespace: "pixelaw", nomapping: true)]
pub mod actions {
    use core::poseidon::poseidon_hash_span;
    use starknet::{
        ContractAddress, get_caller_address, get_contract_address, get_tx_info,
        contract_address_const, syscalls::{call_contract_syscall},
    };

    use super::IActions;

    use pixelaw::core::models::registry::{App, AppName, CoreActionsAddress, Instruction};
    use pixelaw::core::models::permissions::{Permission, Permissions};
    use pixelaw::core::models::pixel::{Pixel, PixelUpdate};
    use pixelaw::core::models::queue::QueueItem;
    use pixelaw::core::utils::{get_core_actions_address, Position};
    use pixelaw::core::traits::{IInteroperabilityDispatcher, IInteroperabilityDispatcherTrait};

    #[derive(Drop, starknet::Event)]
    struct QueueScheduled {
        id: felt252,
        timestamp: u64,
        called_system: ContractAddress,
        selector: felt252,
        calldata: Span<felt252>,
    }

    #[derive(Drop, starknet::Event)]
    struct QueueProcessed {
        id: felt252,
    }

    #[derive(Drop, starknet::Event)]
    struct AppNameUpdated {
        app: App,
        caller: felt252,
    }

    #[derive(Debug, Drop, Serde, starknet::Event, PartialEq)]
    pub struct Alert {
        pub position: Position,
        pub caller: ContractAddress,
        pub player: ContractAddress,
        pub message: felt252,
        pub timestamp: u64,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        QueueScheduled: QueueScheduled,
        QueueProcessed: QueueProcessed,
        AppNameUpdated: AppNameUpdated,
        Alert: Alert,
    }

    // impl: implement functions specified in trait
    #[abi(embed_v0)]
    impl ActionsImpl of IActions<ContractState> {
        /// Initializes the Pixelaw actions model.
        ///
        /// One World has one CoreActions model that can be discovered by anyone.
        fn init(ref world: IWorldDispatcher) {
            set!(
                world,
                (CoreActionsAddress { key: super::CORE_ACTIONS_KEY, value: get_contract_address() })
            );
        }

        /// Updates the permissions for a specified system.
        ///
        /// # Arguments
        ///
        /// * `world` - A reference to the world dispatcher.
        /// * `app_key` - The key of the app (example: 'paint') to update permissions for.
        /// * `permission` - The permission to set for the system.
        ///
        /// # Remarks
        ///
        /// This function grants permissions to a system by the caller.
        /// It is the app's responsibility to handle `update_permission` responsibly.
        fn update_permission(
            ref world: IWorldDispatcher,
            app_key: felt252,
            permission: Permission,
        ) {
            let caller_address = get_caller_address();

            // TODO maybe check that the caller is indeed an app?
            
            // Retrieve the App of the `for_system`
            let allowed_app = get!(world, app_key, (AppName));
            let allowed_app = allowed_app.system;

            println!("appkey: {:?}", app_key);
            println!("caller_address: {:?}", caller_address);
            println!("allowed_app: {:?}", allowed_app);

            set!(
                world,
                Permissions {
                    allowing_app: caller_address,
                    allowed_app,
                    permission
                }
            );
        }

        // FIXME Disabled update_app, it's not implemented as it should, and seems unused
        // /// Updates the name of an app in the registry.
        // ///
        // /// # Arguments
        // ///
        // /// * `world` - A reference to the world dispatcher.
        // /// * `name` - The new name of the app.
        // /// * `icon` - Unicode hex of the icon of the app.
        // /// * `manifest` - URL to the system's `manifest.json`.
        // fn update_app(
        //     ref world: IWorldDispatcher,
        //     name: felt252,
        //     icon: felt252,
        //     manifest: felt252,
        // ) {
        //     let system = get_caller_address();
        //     let app = self.new_app(system, name, icon, manifest);
        //     emit!(
        //         world,
        //         (Event::AppNameUpdated(AppNameUpdated {
        //             app,
        //             caller: system.into()
        //         }))
        //     );
        // }

        /// Schedules a queue item to be processed at a specified timestamp.
        ///
        /// # Arguments
        ///
        /// * `world` - A reference to the world dispatcher.
        /// * `timestamp` - The timestamp when the queue item should be processed.
        /// * `called_system` - The system contract address to call.
        /// * `selector` - The function selector to call in the system.
        /// * `calldata` - The calldata to pass to the function.
        ///
        /// # Remarks
        ///
        /// This function emits an event that external schedulers can pick up.
        fn schedule_queue(
            ref world: IWorldDispatcher,
            timestamp: u64,
            called_system: ContractAddress,
            selector: felt252,
            calldata: Span<felt252>,
        ) {
            println!("schedule_queue");

            // TODO: Review security

            // hash the call and store the hash for verification
            let id = poseidon_hash_span(
                array![
                    timestamp.into(),
                    called_system.into(),
                    selector,
                    poseidon_hash_span(calldata)
                ]
                .span(),
            );

            // Emit the event, so an external scheduler can pick it up
            emit!(
                world,
                (Event::QueueScheduled(QueueScheduled {
                    id,
                    timestamp,
                    called_system,
                    selector,
                    calldata: calldata
                }))
            );
            println!("schedule_queue DONE");
        }

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
        ///
        /// # Remarks
        ///
        /// This function verifies the integrity of the queue item before processing it.
        fn process_queue(
            ref world: IWorldDispatcher,
            id: felt252,
            timestamp: u64,
            called_system: ContractAddress,
            selector: felt252,
            calldata: Span<felt252>,
        ) {
            println!("process_queue");

            // A quick check on the timestamp so we know it's not too early for this one
            assert!(
                timestamp <= starknet::get_block_timestamp(),
                "timestamp still in the future"
            );

            // Recreate the id to check the integrity
            let calculated_id = poseidon_hash_span(
                array![
                    timestamp.into(),
                    called_system.into(),
                    selector,
                    poseidon_hash_span(calldata)
                ]
                .span(),
            );

            // Only valid when the queue item was found by the hash
            assert!(calculated_id == id, "Invalid Id");

            // Make the call itself
            let _result = call_contract_syscall(called_system, selector, calldata);

            // Tell the offchain schedulers that this one is done
            emit!(world, (Event::QueueProcessed(QueueProcessed { id })));
            println!("process_queue DONE");
        }

        /// Checks if a player or system has write access to a pixel.
        ///
        /// # Arguments
        ///
        /// * `world` - A reference to the world dispatcher.
        /// * `for_player` - The player contract address.
        /// * `for_system` - The system contract address.
        /// * `pixel` - The pixel to check access for.
        /// * `pixel_update` - The proposed update to the pixel.
        ///
        /// # Returns
        ///
        /// * `bool` - True if access is granted, false otherwise.
        ///
        /// # Remarks
        ///
        /// This function verifies whether the caller has the necessary permissions to update the pixel.
        fn has_write_access(
            ref world: IWorldDispatcher,
            for_player: ContractAddress,
            for_system: ContractAddress,
            pixel: Pixel,
            pixel_update: PixelUpdate,
        ) -> bool {
            // The originator of the transaction
            let caller_account = get_tx_info().unbox().account_contract_address;

            // The address making this call. Could be a System of an App
            let caller_address = get_caller_address();

                        // First check: Can we grant based on ownership?
            // If caller is owner or not owned by anyone, allow
            if pixel.owner == caller_account || pixel.owner == contract_address_const::<0>() {
                return true;
            } else if caller_account == caller_address {
                // The caller is not a System, and not owner, so no reason to keep looking.
                return false;
            }
            // Deal with Scheduler calling

            // The `caller_address` is a System, let's see if it has access

            // Retrieve the App of the calling System
            let caller_app = get!(world, caller_address, (App));

            // TODO: Decide whether an App by default has write on a pixel with same App

            // If it's the same app, always allow.
            // It's the responsibility of the App developer to ensure separation of ownership
            if pixel.app == caller_app.system {
                return true;
            }

            let permissions = get!(world, (pixel.app, caller_app.system).into(), (Permissions));

            if pixel_update.app.is_some() && !permissions.permission.app {
                return false;
            };
            if pixel_update.color.is_some() && !permissions.permission.color {
                return false;
            };
            if pixel_update.owner.is_some() && !permissions.permission.owner {
                return false;
            };
            if pixel_update.text.is_some() && !permissions.permission.text {
                return false;
            };
            if pixel_update.timestamp.is_some() && !permissions.permission.timestamp {
                return false;
            };
            if pixel_update.action.is_some() && !permissions.permission.action {
                return false;
            };

            // Since we checked all the permissions and no assert fired, we can return true
            true
        }

        /// Updates a pixel with the provided updates.
        ///
        /// # Arguments
        ///
        /// * `world` - A reference to the world dispatcher.
        /// * `for_player` - The player making the update.
        /// * `for_system` - The system making the update.
        /// * `pixel_update` - The updates to apply to the pixel.
        ///
        /// # Remarks
        ///
        /// This function applies the updates to the pixel if the caller has write access.
        fn update_pixel(
            ref world: IWorldDispatcher,
            for_player: ContractAddress,
            for_system: ContractAddress,
            pixel_update: PixelUpdate,
        ) {
            println!("update_pixel");

            let mut pixel = get!(world, (pixel_update.x, pixel_update.y), (Pixel));

            assert!(
                self.has_write_access(for_player, for_system, pixel, pixel_update),
                "No access!"
            );

            let old_pixel_app = pixel.app;
            println!("{:?}", old_pixel_app);

            if old_pixel_app != contract_address_const::<0>() {
                let interoperable_app =
                    IInteroperabilityDispatcher { contract_address: old_pixel_app };
                let app_caller = get!(world, for_system, (App));
                interoperable_app.on_pre_update(pixel_update, app_caller, for_player);
            }

            // If the pixel has no owner set yet, do that now.
            if pixel.created_at == 0 {
                let now = starknet::get_block_timestamp();

                pixel.created_at = now;
                pixel.updated_at = now;
            }

            if pixel_update.app.is_some() {
                pixel.app = pixel_update.app.unwrap();
            }

            if pixel_update.color.is_some() {
                pixel.color = pixel_update.color.unwrap();
            }

            if pixel_update.owner.is_some() {
                pixel.owner = pixel_update.owner.unwrap();
            }

            if pixel_update.text.is_some() {
                pixel.text = pixel_update.text.unwrap();
            }

            if pixel_update.timestamp.is_some() {
                pixel.timestamp = pixel_update.timestamp.unwrap();
            }

            if pixel_update.action.is_some() {
                pixel.action = pixel_update.action.unwrap()
            }

            // Set Pixel
            set!(world, (pixel));

            if old_pixel_app != contract_address_const::<0>() {
                let interoperable_app =
                    IInteroperabilityDispatcher { contract_address: old_pixel_app };
                let app_caller = get!(world, for_system, (App));
                interoperable_app.on_post_update(pixel_update, app_caller, for_player);
            }

            println!("update_pixel DONE");
        }

        /// Retrieves the player address.
        ///
        /// # Arguments
        ///
        /// * `for_player` - The player contract address. If zero, returns the caller's account address.
        ///
        /// # Returns
        ///
        /// * `ContractAddress` - The player address.
        fn get_player_address(for_player: ContractAddress) -> ContractAddress {
            if for_player == contract_address_const::<0>() {
                println!("get_player_address.zero");
                let result = get_tx_info().unbox().account_contract_address;
                println!("{:?}", result);
                // Return the caller account from the transaction (the end user)
                return result;
            } else {
                println!("get_player_address.nonzero");
                // TODO: Check if getter is a system or the core actions contract

                // Return the `for_player`
                return for_player;
            }
        }

        /// Retrieves the system address.
        ///
        /// # Arguments
        ///
        /// * `for_system` - The system contract address. If zero, returns the caller's address.
        ///
        /// # Returns
        ///
        /// * `ContractAddress` - The system address.
        fn get_system_address(for_system: ContractAddress) -> ContractAddress {
            if for_system != contract_address_const::<0>() {
                // TODO: Check that the caller is the CoreActions contract
                // Otherwise, it should be zero (if caller not core_actions)

                // Return the `for_system`
                return for_system;
            } else {
                // Return the caller account from the transaction (the end user)
                return get_caller_address();
            }
        }

        /// Registers a new app.
        ///
        /// # Arguments
        ///
        /// * `world` - A reference to the world dispatcher.
        /// * `system` - Contract address of the app's systems or zero to use the caller.
        /// * `name` - Name of the app.
        /// * `icon` - Unicode hex of the icon of the app.
        /// * `manifest` - URL to the system's `manifest.json`.
        ///
        /// # Returns
        ///
        /// * `App` - Struct containing the contract address and name fields.
        fn new_app(
            ref world: IWorldDispatcher,
            system: ContractAddress,
            name: felt252,
            icon: felt252,
            manifest: felt252,
        ) -> App {
            let mut app_system = system;
            // If the system is not given, use the caller for this.
            // This is expected to be called from the `app.init()` function
            if system == contract_address_const::<0>() {
                app_system = get_caller_address();
            }

            // Load app
            let mut app = get!(world, app_system, (App));

            // Load app_name
            let mut app_name = get!(world, name, (AppName));

            // Ensure neither contract nor name have been registered
            assert!(
                app.name == 0 && app_name.system == contract_address_const::<0>(),
                "app already set"
            );

            // Associate system with name
            app.name = name;
            app.icon = icon;
            app.manifest = manifest;

            // Associate name with system
            app_name.system = system;

            // Store both associations
            set!(world, (app, app_name));

            // Return the system association
            app
        }

        /// Sends an alert to a player.
        ///
        /// # Arguments
        ///
        /// * `world` - A reference to the world dispatcher.
        /// * `position` - The position associated with the alert.
        /// * `player` - The player to alert.
        /// * `message` - The message to send.
        ///
        /// # Remarks
        ///
        /// Only callable by registered apps.
        fn alert_player(
            ref world: IWorldDispatcher,
            position: Position,
            player: ContractAddress,
            message: felt252,
        ) {
            let caller = get_caller_address();
            let app = get!(world, caller, (App));
            assert!(app.name != '', "cannot be called by a non-app");
            emit!(
                world,
                (Event::Alert(Alert {
                    position,
                    caller,
                    player,
                    message,
                    timestamp: starknet::get_block_timestamp()
                }))
            );
        }

        /// Sets an instruction for a given selector in a system.
        ///
        /// # Arguments
        ///
        /// * `world` - A reference to the world dispatcher.
        /// * `selector` - The function selector.
        /// * `instruction` - The instruction to set.
        ///
        /// # Remarks
        ///
        /// Only callable by registered apps.
        fn set_instruction(ref world: IWorldDispatcher, selector: felt252, instruction: felt252) {
            let system = get_caller_address();
            let app = get!(world, system, (App));
            assert!(app.name != '', "cannot be called by a non-app");
            set!(world, (Instruction { system, selector, instruction }))
        }
    }
}
