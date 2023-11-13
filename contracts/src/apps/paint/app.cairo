use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
use pixelaw::core::models::pixel::{Pixel, PixelUpdate};
use pixelaw::core::utils::{get_core_actions, Direction, Position, DefaultParameters};
use starknet::{get_caller_address, get_contract_address, get_execution_info, ContractAddress};


#[starknet::interface]
trait IPaintActions<TContractState> {
    fn init(self: @TContractState);
    fn interact(self: @TContractState, default_params: DefaultParameters);
    fn fade(self: @TContractState, default_params: DefaultParameters);
}

const APP_KEY: felt252 = 'paint';
const APP_ICON: felt252 = 'U+1F58C';

#[dojo::contract]
mod paint_actions {
    use starknet::{
        get_tx_info, get_caller_address, get_contract_address, get_execution_info, ContractAddress
    };

    use super::IPaintActions;
    use pixelaw::core::models::pixel::{Pixel, PixelUpdate};

    use pixelaw::core::models::permissions::{Permission};
    use pixelaw::core::actions::{
        IActionsDispatcher as ICoreActionsDispatcher,
        IActionsDispatcherTrait as ICoreActionsDispatcherTrait
    };
    use super::{APP_KEY, APP_ICON};
    use pixelaw::core::utils::{get_core_actions, Direction, Position, DefaultParameters};

    use debug::PrintTrait;

    fn subu8(nr: u8, sub: u8) -> u8 {
        if nr >= sub {
            return nr - sub;
        } else {
            return 0;
        }
    }


    // ARGB
    // 0xFF FF FF FF
    // empty: 0x 00 00 00 00
    // normal color: 0x 00 FF FF FF

    fn encode_color(r: u8, g: u8, b: u8) -> u32 {
        (r.into() * 0x10000) + (g.into() * 0x100) + b.into()
    }

    fn decode_color(color: u32) -> (u8, u8, u8) {
        let r = (color / 0x10000);
        let g = (color / 0x100) & 0xff;
        let b = color & 0xff;

        (r.try_into().unwrap(), g.try_into().unwrap(), b.try_into().unwrap())
    }

    // impl: implement functions specified in trait
    #[external(v0)]
    impl ActionsImpl of IPaintActions<ContractState> {
        /// Initialize the Paint App (TODO I think, do we need this??)
        fn init(self: @ContractState) {
            let world = self.world_dispatcher.read();
            let core_actions = pixelaw::core::utils::get_core_actions(world);

            core_actions.update_app_name(APP_KEY, APP_ICON);


            // TODO: replace this with proper granting of permission

            core_actions.update_permission('snake',
              Permission {
                alert: false,
                app: false,
                color: true,
                owner: false,
                text: true,
                timestamp: false,
                action: false
              }
            );
        }


        /// Put color on a certain position
        ///
        /// # Arguments
        ///
        /// * `position` - Position of the pixel.
        /// * `new_color` - Color to set the pixel to.
        fn interact(
            self: @ContractState,
            default_params: DefaultParameters
        ) {
            'put_color'.print();

            // Load important variables
            let world = self.world_dispatcher.read();
            let core_actions = get_core_actions(world);
            let position = default_params.position;
            let player = core_actions.get_player_address( default_params.for_player);
            let system = core_actions.get_system_address( default_params.for_system);


            // Load the Pixel
            let mut pixel = get!(world, (position.x, position.y), (Pixel));

            // TODO: Load Paint App Settings like the fade steptime
            // For example for the Cooldown feature
            let COOLDOWN_SECS = 5;

            // Check if 5 seconds have passed or if the sender is the owner
            // TODO error message confusing, have to split this
            assert(
                pixel.owner.is_zero() || (pixel.owner) == player || starknet::get_block_timestamp()
                    - pixel.timestamp < COOLDOWN_SECS,
                'Cooldown not over'
            );

            // We can now update color of the pixel
            core_actions
                .update_pixel(
                    player,
                    system,
                    PixelUpdate {
                        x: position.x,
                        y: position.y,
                        color: Option::Some(default_params.color),
                        alert: Option::None,
                        timestamp: Option::None,
                        text: Option::None,
                        app: Option::Some(system),
                        owner: Option::Some(player),
                        action: Option::None  // Not using this feature for paint
                    }
                );

            'put_color DONE'.print();
        }


        /// Put color on a certain position
        ///
        /// # Arguments
        ///
        /// * `position` - Position of the pixel.
        /// * `new_color` - Color to set the pixel to.
        fn fade(
            self: @ContractState,
            default_params: DefaultParameters
        ) {
            'fade'.print();

            let world = self.world_dispatcher.read();
            let core_actions = get_core_actions(world);
            let position = default_params.position;
            let player = core_actions.get_player_address( default_params.for_player);
            let system = core_actions.get_system_address( default_params.for_system);
            let pixel = get!(world, (position.x, position.y), Pixel);


            let (r, g, b) = decode_color(pixel.color);

            // If the color is 0,0,0 , let's stop the process, fading is done.
            if r == 0 && g == 0 && b == 0 {
                'fading is done'.print();

                return;
            }

            // Fade the color
            let FADE_STEP = 5;
            let new_color = encode_color(
                subu8(r, FADE_STEP), subu8(g, FADE_STEP), subu8(b, FADE_STEP)
            );

            let FADE_SECONDS = 0;

            // We implement fading by scheduling a new put_fading_color
            let queue_timestamp = starknet::get_block_timestamp() + FADE_SECONDS;
            let mut calldata: Array<felt252> = ArrayTrait::new();

            let THIS_CONTRACT_ADDRESS = get_contract_address();

            // Calldata[0]: Calling player
            calldata.append(player.into());

            // Calldata[1]: Calling system
            calldata.append(THIS_CONTRACT_ADDRESS.into());

            // Calldata[2,3] : Position[x,y]
            calldata.append(position.x.into());
            calldata.append(position.y.into());

            // Calldata[4] : Color
            calldata.append(new_color.into());

            core_actions
                .schedule_queue(
                    queue_timestamp, // When to fade next
                    THIS_CONTRACT_ADDRESS, // This contract address
                    get_execution_info().unbox().entry_point_selector, // This selector
                    calldata.span() // The calldata prepared
                );
            'put_fading_color DONE'.print();
        }


    }
}
