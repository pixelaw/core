use pixelaw::core::models::{pixel::{PixelUpdate}, registry::{App}};
use pixelaw::core::utils::{DefaultParameters, Position};
use starknet::{ContractAddress};

/// House Model to keep track of houses and their owners
#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct House {
    #[key]
    pub position: Position,
    pub owner: ContractAddress,
    pub created_at: u64,
    pub last_life_generated: u64,
}

/// Model to track if a player already has a house
#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct PlayerHouse {
    #[key]
    pub player: ContractAddress,
    pub has_house: bool,
    pub house_position: Position,
}

#[starknet::interface]
pub trait IHouseActions<T> {
    fn on_pre_update(
        ref self: T, pixel_update: PixelUpdate, app_caller: App, player_caller: ContractAddress,
    ) -> Option<PixelUpdate>;
    fn on_post_update(
        ref self: T, pixel_update: PixelUpdate, app_caller: App, player_caller: ContractAddress,
    );
    fn build_house(ref self: T, default_params: DefaultParameters);
    fn collect_life(ref self: T, default_params: DefaultParameters);
}

/// House app constants
pub const APP_KEY: felt252 = 'house';
pub const APP_ICON: felt252 = 0x1f3e0; // 🏠 emoji
pub const HOUSE_SIZE: u8 = 3; // 3x3 house
pub const LIFE_REGENERATION_TIME: u64 = 120; // every 2 minutes can collect a life

/// House actions contract
#[dojo::contract]
pub mod house_actions {
    use dojo::model::{ModelStorage};
    use pixelaw::apps::player::{Player};
    use pixelaw::core::actions::{IActionsDispatcherTrait as ICoreActionsDispatcherTrait};
    use pixelaw::core::models::pixel::{Pixel, PixelUpdate, PixelUpdateResultTrait};
    use pixelaw::core::models::registry::App;
    use pixelaw::core::utils::{DefaultParameters, Position, get_callers, get_core_actions};
    use starknet::{
        ContractAddress, contract_address_const, get_block_timestamp, get_contract_address,
    };
    use super::{APP_ICON, APP_KEY, HOUSE_SIZE, LIFE_REGENERATION_TIME};
    use super::{House, IHouseActions, PlayerHouse};

    /// Initialize the House App
    fn dojo_init(ref self: ContractState) {
        let mut world = self.world(@"pixelaw");
        let core_actions = get_core_actions(ref world);
        core_actions.new_app(contract_address_const::<0>(), APP_KEY, APP_ICON);
    }

    // impl: implement functions specified in trait
    #[abi(embed_v0)]
    impl Actions of IHouseActions<ContractState> {
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
            // Default is to not allow anything
            Option::None
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
        ) { // No action needed
        }
        /// Build a new house at the specified position
        ///
        /// # Arguments
        ///
        /// * `default_params` - Default parameters including position
        fn build_house(ref self: ContractState, default_params: DefaultParameters) {
            let mut world = self.world(@"pixelaw");

            // Load important variables
            let core_actions = get_core_actions(ref world);
            let (player, system) = get_callers(ref world, default_params);

            let position = default_params.position;
            let current_timestamp = get_block_timestamp();

            // Check if player already has a house
            let mut player_house: PlayerHouse = world.read_model(player);
            assert!(!player_house.has_house, "Player already has a house");

            // Ensure the area is free (3x3)
            let mut is_area_free = true;
            let mut x = 0;
            while x < HOUSE_SIZE {
                let mut y = 0;
                while y < HOUSE_SIZE {
                    let check_position = Position {
                        x: position.x + x.into(), y: position.y + y.into(),
                    };
                    let pixel: Pixel = world.read_model(check_position);
                    if pixel.app != contract_address_const::<0>() {
                        is_area_free = false;
                        break;
                    }
                    y += 1;
                };
                if !is_area_free {
                    break;
                }
                x += 1;
            };
            assert!(is_area_free, "Area is not free for building a house");

            // Create house record
            let house = House {
                position,
                owner: player,
                created_at: current_timestamp,
                last_life_generated: current_timestamp,
            };
            world.write_model(@house);

            // Mark player as having a house
            player_house.has_house = true;
            player_house.house_position = position;
            world.write_model(@player_house);

            // Place house pixels (3x3 grid)
            let mut x = 0;
            while x < HOUSE_SIZE {
                let mut y = 0;
                while y < HOUSE_SIZE {
                    let house_position = Position {
                        x: position.x + x.into(), y: position.y + y.into(),
                    };

                    // Generate different appearance for different parts of the house
                    let (color, text) = if x == 1 && y == 1 {
                        // Center is the main part
                        (0x8B4513FF, 0x1f3e0) // Brown with house emoji
                    } else if x == 1 && y == 0 {
                        // Door
                        (0x8B4513FF, 0x1f6aa) // Brown with door emoji
                    } else if (x == 0 || x == 2) && (y == 0 || y == 2) {
                        // Corners
                        (0x8B4513FF, 0x1f3e0) // Brown with house emoji
                    } else {
                        // Walls
                        (0x8B4513FF, 0x1f9f1) // Brown with brick emoji
                    };

                    core_actions
                        .update_pixel(
                            player,
                            system,
                            PixelUpdate {
                                position: house_position,
                                color: Option::Some(color),
                                timestamp: Option::None,
                                text: Option::Some(text),
                                app: Option::Some(get_contract_address()),
                                owner: Option::Some(player),
                                action: Option::None,
                            },
                            Option::None,
                            false,
                        )
                        .unwrap();

                    y += 1;
                };
                x += 1;
            };

            // Emit notification instead of direct event
            core_actions
                .notification(
                    position,
                    default_params.color,
                    Option::Some(player),
                    Option::None,
                    'House built!',
                );
        }

        /// Collect a life from your house (once per day)
        ///
        /// # Arguments
        ///
        /// * `default_params` - Default parameters including position
        fn collect_life(ref self: ContractState, default_params: DefaultParameters) {
            let mut world = self.world(@"pixelaw");

            // Load important variables
            let core_actions = get_core_actions(ref world);
            let (player, _system) = get_callers(ref world, default_params);

            let current_timestamp = get_block_timestamp();

            // Check if player is already max lives
            let mut player_data: Player = world.read_model(player);
            assert!(player_data.lives < 5, "Player already has max lives");

            // Check if player has a house
            let player_house: PlayerHouse = world.read_model(player);
            assert!(player_house.has_house, "Player does not have a house");

            // Get the house data
            let mut house: House = world.read_model(player_house.house_position);
            assert!(house.owner == player, "Not the owner of this house");

            // Check if enough time has passed for life regeneration
            assert!(
                current_timestamp >= house.last_life_generated + LIFE_REGENERATION_TIME,
                "Life not ready yet",
            );

            // Update house last_life_generated timestamp
            house.last_life_generated = current_timestamp;
            world.write_model(@house);

            // Get player data and increment lives
            player_data.lives += 1;
            world.write_model(@player_data);

            // Send notification instead of direct event
            core_actions
                .notification(
                    player_house.house_position,
                    default_params.color,
                    Option::Some(player),
                    Option::None,
                    'Life collected!',
                );
        }
    }
}
