//use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
use pixelaw::core::models::{pixel::{PixelUpdate}, registry::{App}};
use pixelaw::core::utils::{DefaultParameters, Emoji, Position};
use starknet::{ContractAddress};

#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct PositionPlayer {
    #[key]
    pub position: Position,
    pub player: ContractAddress,
}

#[derive(Debug, Copy, Drop, Serde, Introspect)]
#[dojo::model]
pub struct Player {
    #[key]
    pub owner: ContractAddress,
    pub name: felt252,
    pub emoji: felt252,
    pub position: Position,
    pub color: u32,
    pub pixel_original_color: u32,
    pub pixel_original_app: ContractAddress,
    pub pixel_original_text: felt252,
    pub pixel_original_action: felt252,
    pub lives: u32,
}


#[starknet::interface]
pub trait IPlayerActions<T> {
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

    fn configure(ref self: T, default_params: DefaultParameters, emoji: Emoji);
}

pub const APP_KEY: felt252 = 'player';
const APP_ICON: felt252 = 0xf09f9883; // 😃
pub const PLAYER_LIVES: u32 = 5;

#[dojo::contract]
pub mod player_actions {
    use dojo::model::{ModelStorage};
    // use dojo::world::{IWorldDispatcherTrait, WorldStorageTrait, WorldStorage};

    use pixelaw::core::actions::{IActionsDispatcherTrait as ICoreActionsDispatcherTrait};

    use pixelaw::core::models::pixel::{Pixel, PixelUpdate, PixelUpdateResultTrait};
    use pixelaw::core::models::registry::App;
    use pixelaw::core::utils::{
        DefaultParameters, Emoji, Position, get_callers, get_core_actions, panic_at_position,
    };
    use starknet::{ContractAddress, contract_address_const, get_contract_address};
    use super::IPlayerActions;

    use super::{APP_ICON, APP_KEY, PLAYER_LIVES};
    use super::{Player, PositionPlayer};
    fn dojo_init(ref self: ContractState) {
        let mut world = self.world(@"pixelaw");
        let core_actions = get_core_actions(ref world);

        core_actions.new_app(contract_address_const::<0>(), APP_KEY, APP_ICON);
    }
    #[abi(embed_v0)]
    impl Actions of IPlayerActions<ContractState> {
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
            //Default is to not allow anything
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
        ) { // No action
        }

        fn configure(ref self: ContractState, default_params: DefaultParameters, emoji: Emoji) {
            // TODO maybe check if the pixel clicked was the actual player position? maybe not..
            let mut world = self.world(@"pixelaw");

            let core_actions = get_core_actions(ref world);

            let (playerAddress, _system) = get_callers(ref world, default_params);

            // Load Player
            let mut player: Player = world.read_model(playerAddress);
            //let mut positionPlayer: PositionPlayer = world.read_model(player.position);

            // Overwrite the emoji on the player
            player.emoji = emoji.value;
            world.write_model(@player);

            // Overwrite the text of the pixel
            core_actions
                .update_pixel(
                    playerAddress,
                    get_contract_address(),
                    PixelUpdate {
                        position: player.position,
                        color: Option::None,
                        timestamp: Option::None,
                        text: Option::Some(emoji.value),
                        app: Option::None,
                        owner: Option::None,
                        action: Option::None,
                    },
                    Option::None,
                    false,
                )
                .unwrap();

            core_actions
                .notification(
                    player.position,
                    default_params.color,
                    Option::None,
                    Option::Some(playerAddress),
                    'Player changed something',
                );
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
            let clicked_position = default_params.position;

            let core_actions = get_core_actions(ref world);
            let (playerAddress, _system) = get_callers(ref world, default_params);

            // Load Player
            let mut player: Player = world.read_model(playerAddress);
            let mut positionPlayer: PositionPlayer = world.read_model(player.position);

            // Check if Player exists yet
            // Its either a bug or feature... when Player is on 0,0 it can "teleport"
            // now he would also recover to full lives :'D
            if player.position.x == 0 && player.position.y == 0 {
                // just try to create the Player on the Pixel clicked, if it panics its ok
                core_actions
                    .update_pixel(
                        playerAddress,
                        get_contract_address(),
                        PixelUpdate {
                            position: clicked_position,
                            color: Option::Some(default_params.color),
                            timestamp: Option::None,
                            text: Option::Some(0xefb88ff09fa78de2808de29980efb88f), // ️👶
                            app: Option::Some(get_contract_address()),
                            owner: Option::None,
                            action: Option::Some('configure'),
                        },
                        Option::None,
                        false,
                    )
                    .unwrap();

                player.position = clicked_position;
                player.color = default_params.color;
                player.emoji = 0xefb88ff09fa78de2808de29980efb88f; // ️👶
                player.lives = PLAYER_LIVES;
                world.write_model(@player);

                positionPlayer.player = playerAddress;
                world.write_model(@positionPlayer);

                //println!("Created new Player");
                return;
            }

            // Determine if Player is on the Pixel clicked or not
            if (clicked_position == player.position) {
                // TODO this is not supposed to happen, most likely a UI malfunction
                // since the action is supposed to be "configure" for the Player's Pixel
                panic_at_position(clicked_position, "Supposed to use 'configure'");
            }

            // Restore the previous pixel
            // We do this first so we can overwrite player.pixel_original_* later
            core_actions
                .update_pixel(
                    playerAddress,
                    get_contract_address(),
                    PixelUpdate {
                        position: player.position,
                        color: Option::Some(player.pixel_original_color),
                        timestamp: Option::None,
                        text: Option::Some(player.pixel_original_text),
                        app: Option::Some(player.pixel_original_app),
                        owner: Option::None,
                        action: Option::Some(player.pixel_original_action),
                    },
                    Option::None, // TODO area_hint
                    false,
                )
                .unwrap();

            let moveto_pos = move_towards(player.position, clicked_position);

            // Check if there is a Player on the destination pixel (then cannot move there)
            let mut moveto_playerpos: PositionPlayer = world.read_model(moveto_pos);

            if moveto_playerpos.player != contract_address_const::<0x0>() {
                // Another Player is already here. Whoops.
                // TODO for now panic so it doesnt cost gas
                panic_at_position(moveto_pos, "Another player is here");
            }

            // Step 1: Trigger hooks without visual changes - this will reveal maze cells
            core_actions
                .update_pixel(
                    playerAddress,
                    get_contract_address(),
                    PixelUpdate {
                        position: moveto_pos,
                        color: Option::None,           // Don't change color yet
                        timestamp: Option::None,
                        text: Option::None,           // Don't change text yet
                        app: Option::Some(get_contract_address()), // Claim for player app (triggers hooks)
                        owner: Option::None,
                        action: Option::Some('configure'),
                    },
                    Option::None,
                    false,
                )
                .unwrap();

            // Step 2: Read post-hook pixel state (after maze reveal, etc.)
            let revealed_pixel: Pixel = world.read_model(moveto_pos);

            // Step 3: Save the correct restoration state (post-hook state)
            player.position = moveto_pos;
            player.pixel_original_text = revealed_pixel.text;      // Post-hook revealed text
            player.pixel_original_app = revealed_pixel.app;        // Should be player app now  
            player.pixel_original_color = revealed_pixel.color;    // Post-hook revealed color
            player.pixel_original_action = revealed_pixel.action;

            world.write_model(@player);

            // Step 4: Apply player visual appearance on top of the revealed pixel
            core_actions
                .update_pixel(
                    playerAddress,
                    get_contract_address(),
                    PixelUpdate {
                        position: moveto_pos,
                        color: Option::Some(player.color),        // Now apply player color
                        timestamp: Option::None,
                        text: Option::Some(player.emoji),         // Now apply player emoji  
                        app: Option::None,                        // Already set to player app
                        owner: Option::None,
                        action: Option::None,                     // Keep existing action
                    },
                    Option::None,
                    false,
                )
                .unwrap();

            // Write the old and new PositionPlayer
            moveto_playerpos.player = playerAddress;
            world.write_model(@moveto_playerpos);

            positionPlayer.player = contract_address_const::<0x0>();
            world.write_model(@positionPlayer);
            //println!("Moving Player!")
        }
    }

    fn move_towards(player: Position, click: Position) -> Position {
        let mut new_x = player.x;
        let mut new_y = player.y;

        if click.x > player.x {
            new_x += 1;
        } else if click.x < player.x {
            new_x -= 1;
        }

        if click.y > player.y {
            new_y += 1;
        } else if click.y < player.y {
            new_y -= 1;
        }

        Position { x: new_x, y: new_y }
    }
}

