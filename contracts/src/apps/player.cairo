//use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
use pixelaw::core::models::{pixel::{PixelUpdate}, registry::{App}};
use pixelaw::core::utils::{DefaultParameters, Emoji, Position};
use starknet::{ContractAddress};

#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct PlayerPosition {
    #[key]
    pub position: Position,
    pub player: felt252,
}

#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct Player {
    #[key]
    pub owner: ContractAddress,
    pub name: felt252,
    pub position: Position,
    pub text: felt252,
    pub pixel_original_text: felt252,
    pub pixel_original_app: ContractAddress,
}


#[starknet::interface]
pub trait IPlayerActions<T> {
    /// Initializes the Player App.
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

    fn configure(ref self: T, default_params: DefaultParameters, text: Emoji);
}

pub const APP_KEY: felt252 = 'player';
const APP_ICON: felt252 = 0xf09f9883; // 😃

#[dojo::contract]
pub mod player_actions {
    use dojo::model::{ModelStorage};
    // use dojo::world::{IWorldDispatcherTrait, WorldStorageTrait, WorldStorage};

    use pixelaw::core::actions::{IActionsDispatcherTrait as ICoreActionsDispatcherTrait};

    use pixelaw::core::models::pixel::{Pixel, PixelUpdate, PixelUpdateResultTrait};
    use pixelaw::core::models::registry::App;
    use pixelaw::core::utils::{DefaultParameters, Emoji, Position, get_callers, get_core_actions};
    use starknet::{ContractAddress, contract_address_const, get_contract_address};
    use super::IPlayerActions;

    use super::{APP_ICON, APP_KEY};
    use super::{Player};

    #[abi(embed_v0)]
    impl Actions of IPlayerActions<ContractState> {
        /// Initializes the Player App.
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

        fn configure(
            ref self: ContractState, default_params: DefaultParameters, text: Emoji,
        ) { // TODO
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

            let core_actions = get_core_actions(ref world);
            let (playerAddress, system) = get_callers(ref world, default_params);

            // Load the Pixel
            let mut pixel: Pixel = world.read_model((position.x, position.y));

            // Load Player
            let mut player: Player = world.read_model(playerAddress);

            // Check if Player exists yet
            // TODO its either a bug or feature... when Player is on 0,0 it can "teleport"
            if player.position.x == 0 && player.position.y == 0 {
                // Player is probably new, just handle that
                player.position = position;
                world.write_model(@player);
                return;
            }

            // Determine if Player is on the Pixel clicked or not
            if (position == player.position) {
                core_actions.alert_player(position, playerAddress, 'Interacted with Player :-)');
                return;
            }

            let new_pos = move_towards(player.position, position);

            // Load pixel we want to move to
            let mut moveto_pixel: Pixel = world.read_model((new_pos.x, new_pos.y));

            // TODO Check if there is a Player on the destination pixel (then cannot move there)

            // Move to the new position
            core_actions
                .update_pixel(
                    playerAddress,
                    get_contract_address(),
                    PixelUpdate {
                        x: new_pos.x,
                        y: new_pos.y,
                        color: Option::None,
                        timestamp: Option::None,
                        text: Option::Some(player.text),
                        app: Option::Some(get_contract_address()),
                        owner: Option::None,
                        action: Option::None,
                    },
                    Option::None,
                    false,
                )
                .unwrap();

            player.position = new_pos;
            player.pixel_original_text = moveto_pixel.text;
            player.pixel_original_app = moveto_pixel.app;

            world.write_model(@player);

            // Restore the previous pixel
            let _ = core_actions
                .update_pixel(
                    playerAddress,
                    get_contract_address(),
                    PixelUpdate {
                        x: pixel.x,
                        y: pixel.y,
                        color: Option::None,
                        timestamp: Option::None,
                        text: Option::Some(player.pixel_original_text),
                        app: Option::Some(player.pixel_original_app),
                        owner: Option::None,
                        action: Option::None,
                    },
                    Option::None, // TODO area_hint
                    false,
                );

            println!("Clicked outside Player, moving!")
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

