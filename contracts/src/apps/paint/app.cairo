use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
use pixelaw::core::models::pixel::{Pixel, PixelUpdate};
use pixelaw::core::utils::{get_core_actions, Direction, Position, DefaultParameters};
use starknet::{get_caller_address, get_contract_address, get_execution_info, ContractAddress};


#[starknet::interface]
trait IPaintActions<TContractState> {
    fn init(self: @TContractState);
    fn interact(self: @TContractState, default_params: DefaultParameters);
    fn put_color(self: @TContractState, default_params: DefaultParameters);
    fn fade(self: @TContractState, default_params: DefaultParameters);
}

const APP_KEY: felt252 = 'paint';
const APP_ICON: felt252 = 'U+1F58C';

/// BASE means using the server's default manifest.json handler
const APP_MANIFEST: felt252 = 'BASE/manifests/paint';

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
    use super::{APP_KEY, APP_ICON, APP_MANIFEST};
    use pixelaw::core::utils::{get_core_actions, Direction, Position, DefaultParameters};
    use pixelaw::core::traits::IInteroperability;
    use pixelaw::core::models::registry::App;

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
      (0xff * 0x1000000) + (r.into() * 0x10000) + (g.into() * 0x100) + b.into()
    }

    fn decode_color(color: u32) -> (u8, u8, u8) {
        let r: u32 = (color / 0x10000);
        let g: u32 = (color / 0x100) & 0xff;
        let b: u32 = color & 0xff;

        let r: Option<u8> = r.try_into();
        let g: Option<u8> = g.try_into();
        let b: Option<u8> = b.try_into();

        let r: u8 = match r {
          Option::Some(r) => r,
          Option::None => 0
        };

        let g: u8 = match g {
          Option::Some(g) => g,
          Option::None => 0,
        };

        let b: u8 = match b {
          Option::Some(b) => b,
          Option::None => 0,
        };

      'rgb'.print();
      r.print();
      g.print();
      b.print();

    (r, g, b)
  }

    #[abi(embed_v0)]
    impl ActionsInteroperability of IInteroperability<ContractState> {
      fn on_pre_update(
        self: @ContractState,
        pixel_update: PixelUpdate,
        app_caller: App,
        player_caller: ContractAddress
      ) {
       // do nothing
      }

      fn on_post_update(
        self: @ContractState,
        pixel_update: PixelUpdate,
        app_caller: App,
        player_caller: ContractAddress
      ){
        // do nothing
      }
    }

    // impl: implement functions specified in trait
    #[abi(embed_v0)]
    impl ActionsImpl of IPaintActions<ContractState> {
        /// Initialize the Paint App (TODO I think, do we need this??)
        fn init(self: @ContractState) {
            let world = self.world_dispatcher.read();
            let core_actions = pixelaw::core::utils::get_core_actions(world);

            core_actions.update_app(APP_KEY, APP_ICON, APP_MANIFEST);


            // TODO: replace this with proper granting of permission

            core_actions.update_permission('snake',
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
        fn interact(
            self: @ContractState,
            default_params: DefaultParameters
        ) {
            'interact'.print();

            // Load important variables
            let world = self.world_dispatcher.read();
            let core_actions = get_core_actions(world);
            let position = default_params.position;
            let player = core_actions.get_player_address( default_params.for_player);


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

            if pixel.color == default_params.color {self.fade(default_params);}
            else { self.put_color(default_params); }
        }

        /// Put color on a certain position
        ///
        /// # Arguments
        ///
        /// * `position` - Position of the pixel.
        /// * `new_color` - Color to set the pixel to.
        fn put_color(
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

'decode_color'.print();

            let (r, g, b) = decode_color(pixel.color);

            // If the color is 0,0,0 , let's stop the process, fading is done.
            if r == 0 && g == 0 && b == 0 {
                'fading is done'.print();

                return;
            }

            // Fade the color
            let FADE_STEP = 5;

            'encode_color'.print();
            let new_color = encode_color(
                subu8(r, FADE_STEP), subu8(g, FADE_STEP), subu8(b, FADE_STEP)
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
      action: Option::None  // Not using this feature for paint
    }
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
0x89ce6748d77414b79f2312bb20f6e67d3aa4a9430933a0f461fedc92983084, // This selector
                    calldata.span() // The calldata prepared
                );
            'put_fading_color DONE'.print();
        }


    }
}
