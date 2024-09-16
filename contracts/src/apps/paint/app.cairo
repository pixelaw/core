use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
use pixelaw::core::models::pixel::{Pixel, PixelUpdate};
use pixelaw::core::utils::{get_core_actions, Direction, Position, DefaultParameters};
use starknet::{get_caller_address, get_contract_address, get_execution_info, ContractAddress};

#[dojo::interface]
trait IPaintActions<TContractState> {
    /// Initializes the Paint App.
    ///
    /// # Arguments
    ///
    /// * `world` - A reference to the world dispatcher.
    fn init(ref world: IWorldDispatcher);

    /// Interacts with a pixel based on default parameters.
    ///
    /// # Arguments
    ///
    /// * `world` - A reference to the world dispatcher.
    /// * `default_params` - The default parameters including position and color.
    fn interact(ref world: IWorldDispatcher, default_params: DefaultParameters);

    /// Applies a color to a specified position.
    ///
    /// # Arguments
    ///
    /// * `world` - A reference to the world dispatcher.
    /// * `default_params` - The default parameters including position and color.
    fn put_color(ref world: IWorldDispatcher, default_params: DefaultParameters);

    /// Initiates the fading process for a pixel.
    ///
    /// # Arguments
    ///
    /// * `world` - A reference to the world dispatcher.
    /// * `default_params` - The default parameters including position and color.
    fn fade(ref world: IWorldDispatcher, default_params: DefaultParameters);

    /// Updates a row of pixels with provided image data.
    ///
    /// # Arguments
    ///
    /// * `world` - A reference to the world dispatcher.
    /// * `default_params` - The default parameters including position.
    /// * `image_data` - A span of felt252 representing the image data.
    fn pixel_row(
        ref world: IWorldDispatcher, default_params: DefaultParameters, image_data: Span<felt252>,
    );
}

pub const APP_KEY: felt252 = 'paint';
const APP_ICON: felt252 = 'U+1F58C';
const PIXELS_PER_FELT: u32 = 7;
const APP_MANIFEST: felt252 = 'BASE/manifests/paint';

#[dojo::contract(namespace: "pixelaw", nomapping: true)]
mod paint_actions {
    use starknet::{
        get_tx_info, get_caller_address, get_contract_address, get_execution_info, ContractAddress,
        contract_address_const,
    };

    use super::IPaintActions;
    use pixelaw::core::models::pixel::{Pixel, PixelUpdate};

    use pixelaw::core::models::permissions::Permission;
    use pixelaw::core::actions::{
        IActionsDispatcher as ICoreActionsDispatcher,
        IActionsDispatcherTrait as ICoreActionsDispatcherTrait,
    };
    use super::{APP_KEY, APP_ICON, APP_MANIFEST, PIXELS_PER_FELT};
    use pixelaw::core::utils::{
        get_core_actions, decode_color, encode_color, subu8, Direction, Position, DefaultParameters,
    };
    use pixelaw::core::traits::IInteroperability;
    use pixelaw::core::models::registry::App;

    #[abi(embed_v0)]
    impl ActionsInteroperability of IInteroperability<ContractState> {
        /// Hook called before a pixel update.
        ///
        /// # Arguments
        ///
        /// * `world` - A reference to the world dispatcher.
        /// * `pixel_update` - The proposed update to the pixel.
        /// * `app_caller` - The app initiating the update.
        /// * `player_caller` - The player initiating the update.
        fn on_pre_update(
            ref world: IWorldDispatcher,
            pixel_update: PixelUpdate,
            app_caller: App,
            player_caller: ContractAddress,
        ) {
            // Do nothing
            let _world = world;
        }

        /// Hook called after a pixel update.
        ///
        /// # Arguments
        ///
        /// * `world` - A reference to the world dispatcher.
        /// * `pixel_update` - The update that was applied to the pixel.
        /// * `app_caller` - The app that performed the update.
        /// * `player_caller` - The player that performed the update.
        fn on_post_update(
            ref world: IWorldDispatcher,
            pixel_update: PixelUpdate,
            app_caller: App,
            player_caller: ContractAddress,
        ) {
            // Do nothing
            let _world = world;
        }
    }

    #[abi(embed_v0)]
    impl ActionsImpl of IPaintActions<ContractState> {
        /// Initializes the Paint App.
        ///
        /// This function registers the app with core actions and sets up initial permissions.
        ///
        /// # Arguments
        ///
        /// * `world` - A reference to the world dispatcher.
        fn init(ref world: IWorldDispatcher) {
            let core_actions = pixelaw::core::utils::get_core_actions(world);

            core_actions.new_app(contract_address_const::<0>(), APP_KEY, APP_ICON);
            // // TODO: Replace this with proper granting of permission
        // core_actions
        //     .update_permission(
        //         'snake',
        //         Permission {
        //             app: true,
        //             color: true,
        //             owner: false,
        //             text: true,
        //             timestamp: false,
        //             action: false,
        //         },
        //     );
        }

        /// Interacts with a pixel based on default parameters.
        ///
        /// If the pixel's current color matches the desired color, it initiates a fade.
        /// Otherwise, it applies the new color.
        ///
        /// # Arguments
        ///
        /// * `world` - A reference to the world dispatcher.
        /// * `default_params` - The default parameters including position and color.
        fn interact(ref world: IWorldDispatcher, default_params: DefaultParameters) {
            println!("interact");

            let position = default_params.position;

            // Load the Pixel
            let mut pixel = get!(world, (position.x, position.y), (Pixel));

            if pixel.color == default_params.color {
                self.fade(default_params);
            } else {
                self.put_color(default_params);
            }
        }

        /// Applies a color to a specified position.
        ///
        /// Checks for cooldown and ownership before applying the color.
        ///
        /// # Arguments
        ///
        /// * `world` - A reference to the world dispatcher.
        /// * `default_params` - The default parameters including position and color.
        fn put_color(ref world: IWorldDispatcher, default_params: DefaultParameters) {
            println!("put_color");

            // Load important variables
            let core_actions = get_core_actions(world);
            let position = default_params.position;
            let player = core_actions.get_player_address(default_params.for_player);
            let system = core_actions.get_system_address(default_params.for_system);

            // Load the Pixel
            let mut pixel = get!(world, (position.x, position.y), (Pixel));

            // TODO: Load Paint App Settings like the fade step time
            // For example for the cooldown feature
            let COOLDOWN_SECS = 5;

            // Check if 5 seconds have passed or if the sender is the owner
            assert!(
                pixel.owner == contract_address_const::<0>()
                    || pixel.owner == player
                    || starknet::get_block_timestamp()
                    - pixel.timestamp >= COOLDOWN_SECS,
                "Cooldown not over"
            );

            // Update color of the pixel
            core_actions
                .update_pixel(
                    player,
                    system,
                    PixelUpdate {
                        x: position.x,
                        y: position.y,
                        color: Option::Some(default_params.color),
                        timestamp: Option::None,
                        text: Option::None,
                        app: Option::Some(system),
                        owner: Option::Some(player),
                        action: Option::None, // Not using this feature for paint
                    },
                );

            println!("put_color DONE");
        }

        /// Updates a row of pixels with provided image data.
        ///
        /// Processes the image data and updates each pixel accordingly.
        ///
        /// # Arguments
        ///
        /// * `world` - A reference to the world dispatcher.
        /// * `default_params` - The default parameters including position.
        /// * `image_data` - A span of felt252 representing the image data.
        fn pixel_row(
            ref world: IWorldDispatcher,
            default_params: DefaultParameters,
            image_data: Span<felt252>,
        ) {
            // row_length determines how many pixels are in a row
            // row_offset determines how far to the right the position started. Next row will
            // continue (x - offset) to the left

            if image_data.is_empty() {
                println!("image_data empty");
                return;
            }

            let core_actions = get_core_actions(world);
            let position = default_params.position;
            let player = core_actions.get_player_address(default_params.for_player);
            let system = core_actions.get_system_address(default_params.for_system);

            let mut felt_index = 0;
            let mut pixel_index = 0;
            let mut felt: u256 = (*image_data.at(felt_index)).into();
            let mut stop = false;
            println!("first felt: {}", felt);

            while !stop {
                // Each felt contains 7 pixels of 4 bytes each, so 224 bits. The leftmost 28 bits
                // are 0 padded.
                // We unpack 4 bytes at a time and use them

                core_actions
                    .update_pixel(
                        player,
                        system,
                        PixelUpdate {
                            x: position.x + pixel_index,
                            y: position.y,
                            color: Option::Some(
                                extract(felt.into(), pixel_index % PIXELS_PER_FELT)
                            ),
                            timestamp: Option::None,
                            text: Option::None,
                            app: Option::Some(system),
                            owner: Option::Some(player),
                            action: Option::None, // Not using this feature for paint
                        },
                    );

                pixel_index += 1;

                // Get a new felt if we processed all pixels
                if pixel_index % PIXELS_PER_FELT == 0 {
                    felt_index += 1;

                    if felt_index == image_data.len() {
                        // Break if we processed all the image data
                        stop = true;
                        break;
                    } else {
                        felt = (*image_data.at(felt_index)).into();
                    }
                }
            }
        }

        /// Initiates the fading process for a pixel.
        ///
        /// Decreases the RGB values by a fade step and schedules the next fade if necessary.
        ///
        /// # Arguments
        ///
        /// * `world` - A reference to the world dispatcher.
        /// * `default_params` - The default parameters including position and color.
        fn fade(ref world: IWorldDispatcher, default_params: DefaultParameters) {
            println!("fade");

            let core_actions = get_core_actions(world);
            let position = default_params.position;
            let player = core_actions.get_player_address(default_params.for_player);
            let system = core_actions.get_system_address(default_params.for_system);
            let pixel = get!(world, (position.x, position.y), Pixel);

            println!("decode_color");

            let (r, g, b, a) = decode_color(pixel.color);

            // If the color is 0,0,0, fading is done.
            if r == 0 && g == 0 && b == 0 {
                println!("fading is done");
                delete!(world, (pixel));
                return;
            }

            // Fade the color
            let FADE_STEP = 5;

            println!("encode_color");
            let new_color = encode_color(
                subu8(r, FADE_STEP), subu8(g, FADE_STEP), subu8(b, FADE_STEP), a,
            );

            // Update color of the pixel
            core_actions
                .update_pixel(
                    player,
                    system,
                    PixelUpdate {
                        x: position.x,
                        y: position.y,
                        color: Option::Some(new_color),
                        timestamp: Option::None,
                        text: Option::None,
                        app: Option::Some(system),
                        owner: Option::Some(player),
                        action: Option::None, // Not using this feature for paint
                    },
                );

            let FADE_SECONDS = 4;

            // Implement fading by scheduling a new fade call
            let queue_timestamp = starknet::get_block_timestamp() + FADE_SECONDS;
            let mut calldata: Array<felt252> = ArrayTrait::new();

            let THIS_CONTRACT_ADDRESS = get_contract_address();

            // Prepare calldata
            // Calldata[0]: Calling player
            calldata.append(player.into());

            // Calldata[1]: Calling system
            calldata.append(THIS_CONTRACT_ADDRESS.into());

            // Calldata[2,3]: Position[x,y]
            calldata.append(position.x.into());
            calldata.append(position.y.into());

            // Calldata[4]: Color
            calldata.append(new_color.into());

            core_actions
                .schedule_queue(
                    queue_timestamp, // When to fade next
                    THIS_CONTRACT_ADDRESS, // This contract address
                    0x89ce6748d77414b79f2312bb20f6e67d3aa4a9430933a0f461fedc92983084, // Selector for fade
                    calldata.span(), // The prepared calldata
                );
            println!("put_fading_color DONE");
        }
    }

    const MASK_32: u256 = 0xffffffff;

    const TWO_POW_032: u256 = 0x100000000;
    const TWO_POW_064: u256 = 0x10000000000000000;
    const TWO_POW_096: u256 = 0x1000000000000000000000000;
    const TWO_POW_128: u256 = 0x100000000000000000000000000000000;
    const TWO_POW_160: u256 = 0x10000000000000000000000000000000000000000;
    const TWO_POW_192: u256 = 0x1000000000000000000000000000000000000000000000000;
    const TWO_POW_224: u256 = 0x100000000000000000000000000000000000000000000000000000000;

    /// Extracts a 32-bit value from a felt at a specified index.
    ///
    /// Each felt represents multiple 32-bit values; this function extracts one of them.
    ///
    /// # Arguments
    ///
    /// * `felt` - The felt from which to extract the value.
    /// * `index` - The index of the value to extract (0 to 6).
    ///
    /// # Returns
    ///
    /// * `u32` - The extracted 32-bit value.
    fn extract(felt: u256, index: u32) -> u32 {
        let result: u32 = if index == 0 {
            (felt / TWO_POW_192).try_into().unwrap()
        } else if index == 1 {
            ((felt / TWO_POW_160) & MASK_32).try_into().unwrap()
        } else if index == 2 {
            ((felt / TWO_POW_128) & MASK_32).try_into().unwrap()
        } else if index == 3 {
            ((felt / TWO_POW_096) & MASK_32).try_into().unwrap()
        } else if index == 4 {
            ((felt / TWO_POW_064) & MASK_32).try_into().unwrap()
        } else if index == 5 {
            ((felt / TWO_POW_032) & MASK_32).try_into().unwrap()
        } else if index == 6 {
            (felt & MASK_32).try_into().unwrap()
        } else {
            0
        };
        println!("{}", result);
        result
    }
}
