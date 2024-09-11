use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
use pixelaw::core::models::pixel::{Pixel, PixelUpdate};
use pixelaw::core::utils::{get_core_actions, Direction, Position, DefaultParameters};
use starknet::{get_caller_address, get_contract_address, get_execution_info, ContractAddress};


#[dojo::interface]
trait IPaintActions<TContractState> {
    fn init(ref world: IWorldDispatcher);
    fn interact(ref world: IWorldDispatcher, default_params: DefaultParameters);
    fn put_color(ref world: IWorldDispatcher, default_params: DefaultParameters);
    fn fade(ref world: IWorldDispatcher, default_params: DefaultParameters);
    fn pixel_row(
        ref world: IWorldDispatcher, default_params: DefaultParameters, image_data: Span<felt252>
    );
}

const APP_KEY: felt252 = 'paint';
const APP_ICON: felt252 = 'U+1F58C';
const PIXELS_PER_FELT: u32 = 7;

/// BASE means using the server's default manifest.json handler
const APP_MANIFEST: felt252 = 'BASE/manifests/paint';

#[dojo::contract(namespace: "pixelaw", nomapping: true)]
mod paint_actions {
    use starknet::{
        get_tx_info, get_caller_address, get_contract_address, get_execution_info, ContractAddress,
        contract_address_const
    };

    use super::IPaintActions;
    use pixelaw::core::models::pixel::{Pixel, PixelUpdate};

    use pixelaw::core::models::permissions::{Permission};
    use pixelaw::core::actions::{
        IActionsDispatcher as ICoreActionsDispatcher,
        IActionsDispatcherTrait as ICoreActionsDispatcherTrait
    };
    use super::{APP_KEY, APP_ICON, APP_MANIFEST, PIXELS_PER_FELT};
    use pixelaw::core::utils::{
        get_core_actions, decode_color, encode_color, subu8, Direction, Position, DefaultParameters
    };
    use pixelaw::core::traits::IInteroperability;
    use pixelaw::core::models::registry::App;


    #[abi(embed_v0)]
    impl ActionsInteroperability of IInteroperability<ContractState> {
        fn on_pre_update(
            ref world: IWorldDispatcher,
            pixel_update: PixelUpdate,
            app_caller: App,
            player_caller: ContractAddress
        ) {
            // do nothing
            let _world = world;
        }

        fn on_post_update(
            ref world: IWorldDispatcher,
            pixel_update: PixelUpdate,
            app_caller: App,
            player_caller: ContractAddress
        ) {
            // do nothing
            let _world = world;
        }
    }


    #[abi(embed_v0)]
    impl ActionsImpl of IPaintActions<ContractState> {
        /// Initialize the Paint App
        fn init(ref world: IWorldDispatcher) {
            let core_actions = pixelaw::core::utils::get_core_actions(world);

            core_actions.new_app(contract_address_const::<0>(),APP_KEY, APP_ICON, APP_MANIFEST);

            // TODO: replace this with proper granting of permission

            core_actions
                .update_permission(
                    'snake',
                    Permission {
                        app: true,
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
        fn interact(ref world: IWorldDispatcher, default_params: DefaultParameters) {
            println!("interact");

            // let core_actions = get_core_actions(world);
            let position = default_params.position;
            // let player = core_actions.get_player_address(default_params.for_player);

            // Load the Pixel
            let mut pixel = get!(world, (position.x, position.y), (Pixel));

            // TODO: Load Paint App Settings like the fade steptime
            // For example for the Cooldown feature
            // let COOLDOWN_SECS = 5;

            // Check if 5 seconds have passed or if the sender is the owner
            // TODO error message confusing, have to split this
            // assert(
            //     pixel.owner == ContractAddress(Felt::ZERO) || (pixel.owner) == player ||
            //     starknet::get_block_timestamp()
            //         - pixel.timestamp < COOLDOWN_SECS,
            //     'Cooldown not over'
            // );

            if pixel.color == default_params.color {
                self.fade(default_params);
            } else {
                self.put_color(default_params);
            }
        }

        /// Put color on a certain position
        ///
        /// # Arguments
        ///
        /// * `position` - Position of the pixel.
        /// * `new_color` - Color to set the pixel to.
        fn put_color(ref world: IWorldDispatcher, default_params: DefaultParameters) {
            println!("put_color");

            // Load important variables

            let core_actions = get_core_actions(world);
            let position = default_params.position;
            let player = core_actions.get_player_address(default_params.for_player);
            let system = core_actions.get_system_address(default_params.for_system);

            // Load the Pixel
            let mut pixel = get!(world, (position.x, position.y), (Pixel));

            // TODO: Load Paint App Settings like the fade steptime
            // For example for the Cooldown feature
            let COOLDOWN_SECS = 5;

            // Check if 5 seconds have passed or if the sender is the owner
            // TODO error message confusing, have to split this
            assert(
                pixel.owner == contract_address_const::<0>()
                    || (pixel.owner) == player
                    || starknet::get_block_timestamp()
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
                        timestamp: Option::None,
                        text: Option::None,
                        app: Option::Some(system),
                        owner: Option::Some(player),
                        action: Option::None // Not using this feature for paint
                    }
                );

            println!("put_color DONE");
        }


        fn pixel_row(
            ref world: IWorldDispatcher,
            default_params: DefaultParameters,
            image_data: Span<felt252>
        ) {
            // row_length determines how many pixels are in a row
            // row_offset determines how far to the right the position started. next row will
            // continue (x - offset) to the left

            if (image_data.is_empty()) {
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
                // TODO this can be optimized, maybe use the leftmost byte for processing
                // instructions?
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
                            action: Option::None // Not using this feature for paint
                        }
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


        /// Put color on a certain position
        ///
        /// # Arguments
        ///
        /// * `position` - Position of the pixel.
        /// * `new_color` - Color to set the pixel to.
        fn fade(ref world: IWorldDispatcher, default_params: DefaultParameters) {
            println!("fade");

            let core_actions = get_core_actions(world);
            let position = default_params.position;
            let player = core_actions.get_player_address(default_params.for_player);
            let system = core_actions.get_system_address(default_params.for_system);
            let pixel = get!(world, (position.x, position.y), Pixel);

            println!("decode_color");

            let (r, g, b, a) = decode_color(pixel.color);

            // If the color is 0,0,0 , let's stop the process, fading is done.
            if r == 0 && g == 0 && b == 0 {
                println!("fading is done");
                delete!(world, (pixel));
                return;
            }

            // Fade the color
            let FADE_STEP = 5;

            println!("encode_color");
            let new_color = encode_color(
                subu8(r, FADE_STEP), subu8(g, FADE_STEP), subu8(b, FADE_STEP), a
            );

            // We can now update color of the pixel
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
                        action: Option::None // Not using this feature for paint
                    }
                );

            let FADE_SECONDS = 4;

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
                    0x89ce6748d77414b79f2312bb20f6e67d3aa4a9430933a0f461fedc92983084, // This selector
                    calldata.span() // The calldata prepared
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

    fn extract(felt: u256, index: u32) -> u32 {
        let mut result: u32 = 0;
        if index == 0 {
            result = (felt / TWO_POW_192).try_into().unwrap();
        } else if index == 1 {
            result = ((felt / TWO_POW_160) & MASK_32).try_into().unwrap();
        } else if index == 2 {
            result = ((felt / TWO_POW_128) & MASK_32).try_into().unwrap();
        } else if index == 3 {
            result = ((felt / TWO_POW_096) & MASK_32).try_into().unwrap();
        } else if index == 4 {
            result = ((felt / TWO_POW_064) & MASK_32).try_into().unwrap();
        } else if index == 5 {
            result = ((felt / TWO_POW_032) & MASK_32).try_into().unwrap();
        } else if index == 6 {
            result = (felt & MASK_32).try_into().unwrap();
        }
        println!("{}", result);
        result
    }
}
