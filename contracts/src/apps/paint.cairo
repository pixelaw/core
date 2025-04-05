//use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
use pixelaw::core::models::{pixel::{PixelUpdate}, registry::{App}};
use pixelaw::core::utils::{DefaultParameters};
use starknet::{ContractAddress};

#[starknet::interface]
pub trait IPaintActions<T> {
    /// Initializes the Paint App.
    ///
    /// # Arguments
    ///
    /// * `world` - A reference to the world dispatcher.
    fn init(ref self: T);

    fn on_pre_update(
        ref self: T, pixel_update: PixelUpdate, app_caller: App, player_caller: ContractAddress,
    ) -> Option<PixelUpdate>;

    fn on_post_update(
        ref self: T, pixel_update: PixelUpdate, app_caller: App, player_caller: ContractAddress,
    );

    /// Interacts with a pixel based on default parameters.
    ///
    /// # Arguments
    ///
    /// * `world` - A reference to the world dispatcher.
    /// * `default_params` - The default parameters including position and color.
    fn interact(ref self: T, default_params: DefaultParameters);

    /// Applies a color to a specified position.
    ///
    /// # Arguments
    ///
    /// * `world` - A reference to the world dispatcher.
    /// * `default_params` - The default parameters including position and color.
    fn put_color(ref self: T, default_params: DefaultParameters);

    /// Initiates the fading process for a pixel.
    ///
    /// # Arguments
    ///
    /// * `world` - A reference to the world dispatcher.
    /// * `default_params` - The default parameters including position and color.
    fn fade(ref self: T, default_params: DefaultParameters);

    /// Updates a row of pixels with provided image data.
    ///
    /// # Arguments
    ///
    /// * `world` - A reference to the world dispatcher.
    /// * `default_params` - The default parameters including position.
    /// * `image_data` - A span of felt252 representing the image data.
    fn pixel_row(ref self: T, default_params: DefaultParameters, image_data: Span<felt252>);
}

pub const APP_KEY: felt252 = 'paint';
const APP_ICON: felt252 = 0xf09f8ea8; // 🎨
const PIXELS_PER_FELT: u16 = 7;

#[dojo::contract]
pub mod paint_actions {
    use dojo::model::{ModelStorage};

    use pixelaw::core::actions::{IActionsDispatcherTrait as ICoreActionsDispatcherTrait};

    use pixelaw::core::models::pixel::{Pixel, PixelUpdate, PixelUpdateResultTrait};
    use pixelaw::core::models::registry::App;
    use pixelaw::core::utils::{
        DefaultParameters, decode_rgba, encode_rgba, get_callers, get_core_actions, subu8,
    };
    use starknet::{ContractAddress, contract_address_const, get_contract_address};
    use super::IPaintActions;

    use super::{APP_ICON, APP_KEY, PIXELS_PER_FELT};

    #[abi(embed_v0)]
    impl Actions of IPaintActions<ContractState> {
        /// Initializes the Paint App.
        ///
        /// This function registers the app with core actions
        ///
        /// # Arguments
        ///
        /// * `world` - A reference to the world dispatcher.
        fn init(ref self: ContractState) {
            let mut world = self.world(@"pixelaw");
            let core_actions = get_core_actions(ref world);

            core_actions.new_app(contract_address_const::<0>(), APP_KEY, APP_ICON);
        }

        /// Hook called before a pixel update.
        ///
        /// # Arguments
        ///
        /// * `world` - A reference to the world dispatcher.
        /// * `pixel_update` - The proposed update to the pixel.
        /// * `app_caller` - The app initiating the update.
        /// * `player_caller` - The player initiating the update.
        fn on_pre_update(
            ref self: ContractState,
            pixel_update: PixelUpdate,
            app_caller: App,
            player_caller: ContractAddress,
        ) -> Option<PixelUpdate> {
            let mut _world = self.world(@"pixelaw");

            let mut result = Option::None; //Default is to not allow anything

            // Check which app is calling
            if app_caller.name == 'snake' {
                if pixel_update.owner.is_some() || pixel_update.app.is_some() {
                    // If Snake wants to change the owner or app, we don't allow that.
                    result = Option::None;
                } else {
                    // Anything else is okay unmodified
                    result = Option::Some(pixel_update);
                }
            }

            result
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
            ref self: ContractState,
            pixel_update: PixelUpdate,
            app_caller: App,
            player_caller: ContractAddress,
        ) {
            // Do nothing
            //let mut _world = self.world(@"pixelaw");

            // Check which app is calling
            if app_caller
                .name == 'snake' { // TODO Something that happens when Snake tries to update a Paint pixel..
            // Maybe nice example is to keep a counter of "snakebites" for the paint app
            }
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
        fn interact(ref self: ContractState, default_params: DefaultParameters) {
            let mut world = self.world(@"pixelaw");
            let position = default_params.position;

            // Load the Pixel
            let mut pixel: Pixel = world.read_model((position.x, position.y));

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
        fn put_color(ref self: ContractState, default_params: DefaultParameters) {
            let mut world = self.world(@"pixelaw");
            // Load important variables
            let core_actions = get_core_actions(ref world);
            let position = default_params.position;
            let (player, system) = get_callers(ref world, default_params);

            // Load the Pixel
            let mut pixel: Pixel = world.read_model((position.x, position.y));

            // TODO: Load Paint App Settings like the fade step time
            // For example for the cooldown feature
            let COOLDOWN_SECS = 0;

            // Check if 5 seconds have passed or if the sender is the owner
            assert!(
                pixel.owner == contract_address_const::<0>()
                    || pixel.owner == player
                    || starknet::get_block_timestamp()
                    - pixel.timestamp >= COOLDOWN_SECS,
                "Cooldown not over",
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
                        action: Option::None // Not using this feature for paint
                    },
                    Option::None, // TODO area_hint
                    false,
                )
                .unwrap();
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
            ref self: ContractState, default_params: DefaultParameters, image_data: Span<felt252>,
        ) {
            let mut world = self.world(@"pixelaw");
            // row_length determines how many pixels are in a row
            // row_offset determines how far to the right the position started. Next row will
            // continue (x - offset) to the left

            if image_data.is_empty() {
                return;
            }

            let core_actions = get_core_actions(ref world);
            let position = default_params.position;

            let (player, system) = get_callers(ref world, default_params);

            let mut felt_index = 0;
            let mut pixel_index: u16 = 0;
            let mut felt: u256 = (*image_data.at(felt_index)).into();
            let mut stop = false;

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
                                extract(felt.into(), pixel_index % PIXELS_PER_FELT),
                            ),
                            timestamp: Option::None,
                            text: Option::None,
                            app: Option::Some(system),
                            owner: Option::Some(player),
                            action: Option::None // Not using this feature for paint
                        },
                        Option::None, // area_hint
                        false,
                    )
                    .unwrap();

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
        fn fade(ref self: ContractState, default_params: DefaultParameters) {
            let mut world = self.world(@"pixelaw");
            let core_actions = get_core_actions(ref world);
            let position = default_params.position;

            let (player, system) = get_callers(ref world, default_params);

            let pixel: Pixel = world.read_model((position.x, position.y));

            let (r, g, b, a) = decode_rgba(pixel.color);

            // If the color is 0,0,0, fading is done.
            if r == 0 && g == 0 && b == 0 {
                world.erase_model(@pixel);
                return;
            }

            // Fade the color
            let FADE_STEP = 50;

            let new_color = encode_rgba(
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
                        action: Option::None,
                    },
                    Option::None,
                    false,
                )
                .unwrap();

            let FADE_SECONDS = 0;

            // Implement fading by scheduling a new fade call
            let queue_timestamp = starknet::get_block_timestamp() + FADE_SECONDS;
            let mut calldata: Array<felt252> = ArrayTrait::new();

            let THIS_CONTRACT_ADDRESS = get_contract_address();

            // Prepare calldata
            // Calldata[0]: player_override option:None
            calldata.append(0x0);
            calldata.append(player.into());

            // Calldata[1]: Calling system
            calldata.append(0x0);
            calldata.append(THIS_CONTRACT_ADDRESS.into());

            // Calldata[2]: Area Hint
            calldata.append(0x1);

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
                    calldata.span() // The prepared calldata
                );
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
    fn extract(felt: u256, index: u16) -> u32 {
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
        result
    }
}
