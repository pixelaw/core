use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
use pixelaw::core::models::pixel::{Pixel, PixelUpdate};
use pixelaw::core::utils::{Position, DefaultParameters};
use starknet::{get_caller_address, get_contract_address, get_execution_info, ContractAddress};


#[starknet::interface]
trait IHunterActions<TContractState> {
    fn init(self: @TContractState);
    fn interact(self: @TContractState, default_params: DefaultParameters);
}


#[derive(Model, Copy, Drop, Serde, SerdeLen)]
struct LastAttempt {
    #[key]
    player: ContractAddress,
    timestamp: u64
}

const APP_KEY: felt252 = 'hunter';

#[dojo::contract]
mod hunter_actions {
    use poseidon::poseidon_hash_span;
    use starknet::{
        get_tx_info, get_caller_address, get_contract_address, get_execution_info, ContractAddress
    };

    use super::{IHunterActions, LastAttempt};
    use pixelaw::core::models::pixel::{Pixel, PixelUpdate};

    use pixelaw::core::models::permissions::{Permission};
    use pixelaw::core::actions::{
        IActionsDispatcher as ICoreActionsDispatcher,
        IActionsDispatcherTrait as ICoreActionsDispatcherTrait
    };
    use super::APP_KEY;
    use pixelaw::core::utils::{get_core_actions, Direction, Position, DefaultParameters};

    use debug::PrintTrait;


    // impl: implement functions specified in trait
    #[external(v0)]
    impl HunterActionsImpl of IHunterActions<ContractState> {
        /// Initialize the Hunter App
        fn init(self: @ContractState) {
            let core_actions = get_core_actions(self.world_dispatcher.read());

            core_actions.update_app_name(APP_KEY);
        }


        /// Put color on a certain position
        ///
        /// # Arguments
        ///
        /// * `position` - Position of the pixel.
        /// * `new_color` - Color to set the pixel to.
        fn interact(self: @ContractState, default_params: DefaultParameters) {
            'interact'.print();

            let COOLDOWN_SEC = 3;

            // Load important variables
            let world = self.world_dispatcher.read();
            let core_actions = get_core_actions(world);
            let position = default_params.position;
            let player = core_actions.get_player_address(default_params.for_player);
            let system = core_actions.get_system_address(default_params.for_system);
            let mut pixel = get!(world, (position.x, position.y), (Pixel));

            // Check if we have a winner
            let timestamp = starknet::get_block_timestamp();


            let mut last_attempt = get!(world, (player), LastAttempt);

            // assert(timestamp - last_attempt.timestamp > COOLDOWN_SEC, 'Not so fast');
            assert(pixel.owner.is_zero(), 'Hunt only empty pixels');

            let timestamp_felt252 = timestamp.into();
            let x_felt252 = position.x.into();
            let y_felt252 = position.y.into();

            // Generate hash (timestamp, x, y)
            let hash: u256 = poseidon_hash_span(array![timestamp_felt252, x_felt252, y_felt252].span()).into();

            // Check if the last 3 bytes of the hash are 000
            // let MASK = 0xFFFFFFFFFFFFFFFF0000;  // TODO, this is a placeholder
            // let MASK: u256 = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff; // use this for debug.
            let MASK: u256 = 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc00;  // this represents: 1/1024
            let result = ((hash | MASK) == MASK);

            assert(result, 'Oops, no luck');

            // We can now update color of the pixel
            core_actions
                .update_pixel(
                    player,
                    system,
                    PixelUpdate {
                        x: position.x,
                        y: position.y,
                        color: Option::Some(default_params.color),
                        alert: Option::Some(''),    // TODO a notification?
                        timestamp: Option::None,
                        text: Option::Some('U+2B50'),   // Star emoji
                        app: Option::Some(system),
                        owner: Option::Some(player),
                        action: Option::None
                    }
                );

        // Update the timestamp for the cooldown
            last_attempt.timestamp = timestamp;
            set!(world, (last_attempt));

            'hunt DONE'.print();
        }


    }
}
