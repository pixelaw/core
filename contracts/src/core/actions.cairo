use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
use pixelaw::core::models::pixel::{Pixel, PixelUpdate};
use pixelaw::core::models::permissions::{Permission};
    use pixelaw::core::models::registry::{App, AppName, CoreActionsAddress};
use pixelaw::core::utils::Position;

use starknet::{ContractAddress, ClassHash};

const CORE_ACTIONS_KEY: felt252 = 'core_actions';

#[starknet::interface]
trait IActions<TContractState> {
    fn init(self: @TContractState);
    fn update_permission(self: @TContractState, for_system: felt252, permission: Permission);
    fn update_app(self: @TContractState, name: felt252, icon: felt252, manifest: felt252);
    fn has_write_access(
        self: @TContractState,
        for_player: ContractAddress,
        for_system: ContractAddress,
        pixel: Pixel,
        pixel_update: PixelUpdate,
    ) -> bool;
    fn process_queue(
        self: @TContractState,
        id: felt252,
        timestamp: u64,
        called_system: ContractAddress,
        selector: felt252,
        calldata: Span<felt252>
    );
    fn schedule_queue(
        self: @TContractState,
        timestamp: u64,
        called_system: ContractAddress,
        selector: felt252,
        calldata: Span<felt252>
    );
    fn update_pixel(
        self: @TContractState,
        for_player: ContractAddress,
        for_system: ContractAddress,
        pixel_update: PixelUpdate
    );
    fn new_app(self: @TContractState, system: ContractAddress, name: felt252, icon: felt252, manifest: felt252) -> App;
    fn get_system_address(self: @TContractState, for_system: ContractAddress) -> ContractAddress;
    fn get_player_address(self: @TContractState, for_player: ContractAddress) -> ContractAddress;
    fn alert_player(self: @TContractState, position: Position, player: ContractAddress, message: felt252);
    fn set_instruction(self: @TContractState, selector: felt252, instruction: felt252);
}


#[dojo::contract]
mod actions {
    use starknet::{
        ContractAddress, get_caller_address, ClassHash, get_contract_address, get_tx_info
    };
    use starknet::info::TxInfo;
    use super::IActions;
    use pixelaw::core::models::registry::{App, AppName, CoreActionsAddress, Instruction};
    use pixelaw::core::models::permissions::{Permission, Permissions};
    use pixelaw::core::models::pixel::{Pixel, PixelUpdate};
    use debug::PrintTrait;
    use poseidon::poseidon_hash_span;
    use pixelaw::core::models::queue::{QueueItem};
    use pixelaw::core::utils::{get_core_actions_address, Position};
    use zeroable::Zeroable;
    use pixelaw::core::traits::{IInteroperabilityDispatcher, IInteroperabilityDispatcherTrait};


    #[derive(Drop, starknet::Event)]
    struct QueueScheduled {
        id: felt252,
        timestamp: u64,
        called_system: ContractAddress,
        selector: felt252,
        calldata: Span<felt252>
    }

    #[derive(Drop, starknet::Event)]
    struct QueueProcessed {
        id: felt252
    }

    #[derive(Drop, starknet::Event)]
    struct AppNameUpdated {
        app: App,
        caller: felt252
    }

    #[derive(Drop, starknet::Event)]
    struct Alert {
      position: Position,
      caller: ContractAddress,
      player: ContractAddress,
      message: felt252,
      timestamp: u64
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        QueueScheduled: QueueScheduled,
        QueueProcessed: QueueProcessed,
        AppNameUpdated: AppNameUpdated,
        Alert: Alert
    }


    // impl: implement functions specified in trait
    #[abi(embed_v0)]
    impl ActionsImpl of IActions<ContractState> {
        /// Initializes the Pixelaw actions model
        fn init(self: @ContractState) {
            let world = self.world_dispatcher.read();

            set!(
                world,
                (CoreActionsAddress { key: super::CORE_ACTIONS_KEY, value: get_contract_address() })
            );
        }

        /// not performing checks because it's only granting permissions to a system by the caller
        /// it is in the app's responsibility to handle update_permission responsibly
        fn update_permission(self: @ContractState, for_system: felt252, permission: Permission) {
            let world = self.world_dispatcher.read();
            let caller_address = get_caller_address();

            // Retrieve the App of the for_system
            let allowed_app = get!(world, for_system, (AppName));
            let allowed_app = allowed_app.system;

            set!(world, Permissions { allowing_app: caller_address, allowed_app, permission });
        }


        /// Updates the name of an app in the registry
        ///
        /// # Arguments
        ///
        /// * `name` - The new name of the app
        /// * `icon` - unicode hex of the icon of the app
        /// * `manifest` - url to the system's manifest.json
        fn update_app(self: @ContractState, name: felt252, icon: felt252, manifest: felt252) {
            let world = self.world_dispatcher.read();
            let system = get_caller_address();
            let app = self.new_app(system, name, icon, manifest);
            emit!(world, AppNameUpdated { app, caller: system.into() });
        }


        fn schedule_queue(
            self: @ContractState,
            timestamp: u64,
            called_system: ContractAddress,
            selector: felt252,
            calldata: Span<felt252>
        ) {
            'schedule_queue'.print();
            let world = self.world_dispatcher.read();

            // TODO Review security

            // Retrieve the caller system from the address.
            // This prevents non-system addresses to schedule queue
            // let caller_system = get!(world, caller_address, (App)).system;

            // let calldata_span = calldata.span();

            // hash the call and store the hash for verification
            let id = poseidon_hash_span(
                array![
                    timestamp.into(), called_system.into(), selector, poseidon_hash_span(calldata)
                ]
                    .span()
            );

            // Emit the event, so an external scheduler can pick it up
            emit!(
                world, QueueScheduled { id, timestamp, called_system, selector, calldata: calldata }
            );
            'schedule_queue DONE'.print();
        }


        fn process_queue(
            self: @ContractState,
            id: felt252,
            timestamp: u64,
            called_system: ContractAddress,
            selector: felt252,
            calldata: Span<felt252>
        ) {
            'process_queue'.print();
            let world = self.world_dispatcher.read();
            // A quick check on the timestamp so we know its not too early for this one
            assert(timestamp <= starknet::get_block_timestamp(), 'timestamp still in the future');

            // TODO Do we need a mechanism to ensure that Queued items are really coming from a schedule?
            // In theory someone can just call this action directly with whatever, as long as the ID is correct it will be executed.
            // It is only possible to call Apps though, so as long as the security of the Apps is okay, it should be fine?
            // And we could add some rate limiting to prevent griefing?
            //
            // The only way i can think of doing "authentication" of a QueueItem would be to store the ID (hash) onchain, but that gets expensive soon?

            // Recreate the id to check the integrity
            let calculated_id = poseidon_hash_span(
                array![
                    timestamp.into(), called_system.into(), selector, poseidon_hash_span(calldata)
                ]
                    .span()
            );

            // TODO check if id exists onchain

            // Only valid when the queue item was found by the hash
            assert(calculated_id == id, 'Invalid Id');

            // Make the call itself
            let _result = starknet::call_contract_syscall(called_system, selector, calldata);

            // Tell the offchain schedulers that this one is done
            emit!(world, QueueProcessed { id });
            'process_queue DONE'.print();
        }

        fn has_write_access(
            self: @ContractState,
            for_player: ContractAddress,
            for_system: ContractAddress,
            pixel: Pixel,
            pixel_update: PixelUpdate
        ) -> bool {
            let world = self.world_dispatcher.read();

            // The originator of the transaction
            let caller_account = get_tx_info().unbox().account_contract_address;

            // The address making this call. Could be a System of an App
            let caller_address = get_caller_address();

            // First check: Can we grant based on ownership?
            // If caller is owner or not owned by anyone, allow
            if pixel.owner == caller_account || pixel.owner.is_zero() {
                return true;
            } else if caller_account == caller_address {
                // The caller is not a System, and not owner, so no reason to keep looking.
                return false;
            }

            // Deal with Scheduler calling

            // The caller_address is a System, let's see if it has access

            // Retrieve the App of the calling System
            let caller_app = get!(world, caller_address, (App));

            // TODO decide whether an App by default has write on a pixel with same App?

            // If its the same app, always allow.
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


        fn update_pixel(
            self: @ContractState,
            for_player: ContractAddress,
            for_system: ContractAddress,
            pixel_update: PixelUpdate
        ) {
            'update_pixel'.print();
            let world = self.world_dispatcher.read();
            let mut pixel = get!(world, (pixel_update.x, pixel_update.y), (Pixel));

            assert(
                self.has_write_access(for_player, for_system, pixel, pixel_update), 'No access!'
            );

            let old_pixel_app = pixel.app;
            old_pixel_app.print();

            if !old_pixel_app.is_zero() {
              let interoperable_app = IInteroperabilityDispatcher { contract_address: old_pixel_app };
              let app_caller = get!(world, for_system, (App));
              interoperable_app.on_pre_update(pixel_update, app_caller, for_player)
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

            if !old_pixel_app.is_zero() {
              let interoperable_app = IInteroperabilityDispatcher { contract_address: old_pixel_app };
              let app_caller = get!(world, for_system, (App));
              interoperable_app.on_post_update(pixel_update, app_caller, for_player)
            }

            'update_pixel DONE'.print();
        }


        fn get_player_address(
            self: @ContractState, for_player: ContractAddress
        ) -> ContractAddress {
            let _world = self.world_dispatcher.read();
            if for_player.is_zero() {
                'get_player_address.zero'.print();
                let result = get_tx_info().unbox().account_contract_address;
                result.print();
                // Return the caller account from the transaction (the end user)
                return result;
            } else {
                'get_player_address.nonzero'.print();
                // TODO: check if getter is a system or the core actions contract

                // Return the for_player
                return for_player;
            }
        }


        fn get_system_address(
            self: @ContractState, for_system: ContractAddress
        ) -> ContractAddress {

            if !for_system.is_zero() {
                // TODO
                // Check that the caller is the CoreActions contract
                // Otherwise, it should be 0 (if caller not core_actions)

                // Return the for_player
                return for_system;
            } else {
                // Return the caller account from the transaction (the end user)
                return get_caller_address();
            }
        }

        /// Registers an App
        ///
        /// # Arguments
        ///
        /// * `system` - Contract address of the app's systems
        /// * `name` - Name of the app
        /// * `icon` - unicode hex of the icon of the app
        /// * `manifest` - url to the system's manifest.json
        ///
        /// # Returns
        ///
        /// * `App` - Struct with contractaddress and name fields
        fn new_app(self: @ContractState, system: ContractAddress, name: felt252, icon: felt252, manifest: felt252) -> App {
            let world = self.world_dispatcher.read();
            // Load app
            let mut app = get!(world, system, (App));

            // Load app_name
            let mut app_name = get!(world, name, (AppName));

            // Ensure neither contract nor name have been registered
            assert(
                app.name == 0
                    && app_name.system == starknet::contract_address_const::<0x0>(),
                'app already set'
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

        fn alert_player(self: @ContractState, position: Position, player: ContractAddress, message: felt252) {
          let world = self.world_dispatcher.read();
          let caller = get_caller_address();
          let app = get!(world, caller, (App));
          assert(app.name != '', 'cannot be called by a non-app');
          emit!(world, Alert { position, caller, player, message, timestamp: starknet::get_block_timestamp() });
        }

        fn set_instruction(self: @ContractState, selector: felt252, instruction: felt252) {
          let world = self.world_dispatcher.read();
          let system = get_caller_address();
          let app = get!(world, system, (App));
          assert(app.name != '', 'cannot be called by a non-app');
          set!(
            world, (
              Instruction {
                system,
                selector,
                instruction
              }
          ))
        }
    }
}
