use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
use starknet::{ContractAddress, ClassHash};
use pixelaw::core::utils::{Direction, Position, DefaultParameters, starknet_keccak};


fn next_position(x: u32, y: u32, direction: Direction) -> Option<(u32, u32)> {
    match direction {
        Direction::None(()) => { Option::Some((x, y)) },
        Direction::Left(()) => {
          if x == 0 { Option::None }
          else { Option::Some((x - 1, y)) }
        },
        Direction::Right(()) => { Option::Some((x + 1, y)) },
        Direction::Up(()) => {
          if y == 0 { Option::None }
          else { Option::Some((x, y - 1)) }
        },
        Direction::Down(()) => { Option::Some((x, y + 1)) },
    }
}


#[derive(Model, Copy, Drop, Serde)]
struct Snake {
    #[key]
    owner: ContractAddress,
    length: u8,
    first_segment_id: u32,
    last_segment_id: u32,
    direction: Direction,
    color: u32,
    text: felt252,
    is_dying: bool
}

#[derive(Model, Copy, Drop, Serde)]
struct SnakeSegment {
    #[key]
    id: u32,
    previous_id: u32,
    next_id: u32,
    x: u32,
    y: u32,
    pixel_original_color: u32,
    pixel_original_text: felt252,
    pixel_original_app: ContractAddress
}


#[starknet::interface]
trait ISnakeActions<TContractState> {
    fn init(self: @TContractState);
    fn interact(self: @TContractState, default_params: DefaultParameters, direction: Direction) -> u32;
    fn move(self: @TContractState, owner: ContractAddress);
}


#[dojo::contract]
mod snake_actions {
    use starknet::{ContractAddress, get_caller_address, get_contract_address, get_execution_info};
    use pixelaw::core::models::pixel::{Pixel, PixelUpdate};

    use super::{Snake, SnakeSegment};
    use pixelaw::core::utils::{get_core_actions, Direction, Position, DefaultParameters, starknet_keccak, get_core_actions_address};
    use super::next_position;
    use super::ISnakeActions;
    use pixelaw::core::actions::{
        IActionsDispatcher as ICoreActionsDispatcher,
        IActionsDispatcherTrait as ICoreActionsDispatcherTrait
    };
    use pixelaw::core::traits::IInteroperability;

    use dojo::database::introspect::Introspect;
    use pixelaw::core::models::registry::App;

    use debug::PrintTrait;
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Moved: Moved,
        // Longer: Longer,
        // Shorter: Shorter,
        Died: Died
    }


    #[derive(Drop, starknet::Event)]
    struct Died {
        owner: ContractAddress,
        x: u32,
        y: u32
    }

    #[derive(Drop, starknet::Event)]
    struct Moved {
        owner: ContractAddress,
        direction: Direction
    }

    const SNAKE_MAX_LENGTH: u8 = 255;
    const APP_KEY: felt252 = 'snake';
    const APP_ICON: felt252 = 'U+1F40D';

    /// BASE means using the server's default manifest.json handler
    const APP_MANIFEST: felt252 = 'BASE/manifests/snake';

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

        let core_actions_address = get_core_actions_address(self.world_dispatcher.read());
        assert(core_actions_address == get_caller_address(), 'caller is not core_actions');

        // when the snake is reverting
        if pixel_update.app.is_some() && app_caller.system == get_contract_address() {
          let old_app = pixel_update.app.unwrap();
          let world = self.world_dispatcher.read();
          let old_app = get!(world, old_app, (App));
          if old_app.name == 'paint' {
            let mut calldata: Array<felt252> = ArrayTrait::new();
            let pixel = get!(world, (pixel_update.x, pixel_update.y), (Pixel));
            calldata.append(pixel.owner.into());
            calldata.append(old_app.system.into());
            calldata.append(pixel_update.x.into());
            calldata.append(pixel_update.y.into());
            calldata.append(pixel_update.color.unwrap().into());
            let _result = starknet::call_contract_syscall(old_app.system, 0x89ce6748d77414b79f2312bb20f6e67d3aa4a9430933a0f461fedc92983084, calldata.span());
          }
        }
      }
    }


    // impl: implement functions specified in trait
    #[abi(embed_v0)]
    impl ActionsImpl of ISnakeActions<ContractState> {
        fn init(self: @ContractState) {
            let core_actions = get_core_actions(self.world_dispatcher.read());

            core_actions.update_app(APP_KEY, APP_ICON, APP_MANIFEST);

            // TODO should use something like: starknet_keccak(array!['interact'].span())
            let INTERACT_SELECTOR = 0x476d5e1b17fd9d508bd621909241c5eb4c67380f3651f54873c5c1f2b891f4;
            let INTERACT_INSTRUCTION = 'select direction for snake';
            core_actions.set_instruction(INTERACT_SELECTOR, INTERACT_INSTRUCTION);
        }


        // A new snake starts
        fn interact(self: @ContractState, default_params: DefaultParameters, direction: Direction) -> u32 {
            'snake: interact'.print();
            let world = self.world_dispatcher.read();
            let core_actions = get_core_actions(world);
            let position = default_params.position;

            let player = core_actions.get_player_address(default_params.for_player);
            let system = core_actions.get_system_address(default_params.for_system);

            // Check if there is already a Snake or SnakeSegment here
            let pixel = get!(world, (position.x, position.y), Pixel);
            let mut snake = get!(world, player, Snake);

            // change direction if snake already exists
            if snake.length > 0 {
              snake.direction = direction;
              set!(world, (snake));
              return snake.first_segment_id;
            }


            // TODO check if the pixel is unowned or player owned

            let mut id = world.uuid();
            if id == 0 {
              id = world.uuid();
            }

            let color = default_params.color;
            let text = ''; //TODO
            // Initialize the Snake model
            snake = Snake {
                owner: player,
                length: 1,
                first_segment_id: id,
                last_segment_id: id,
                direction: direction,
                color,
                text,
                is_dying: false
            };

            // Initialize the first SnakeSegment model (the head)
            let segment = SnakeSegment {
                id,
                previous_id: id,
                next_id: id,
                x: position.x,
                y: position.y,
                pixel_original_color: pixel.color,
                pixel_original_text: pixel.text,
                pixel_original_app: pixel.app
            };

            // Store the dojo model for the Snake
            set!(world, (snake, segment));

            // Call core_actions to update the color
            core_actions
                .update_pixel(
                    player,
                    system,
                    PixelUpdate {
                        x: position.x,
                        y: position.y,
                        color: Option::Some(color),
                        timestamp: Option::None,
                        text: Option::Some(text),
                        app: Option::Some(get_contract_address()),
                        owner: Option::None,
                        action: Option::None  // Not using this feature for snake
                    }
                );

            let MOVE_SECONDS = 0;
            let queue_timestamp = starknet::get_block_timestamp() + MOVE_SECONDS;
            let mut calldata: Array<felt252> = ArrayTrait::new();
            let THIS_CONTRACT_ADDRESS = get_contract_address();

            // Calldata[0] : owner address
            calldata.append(player.into());

            // TODO should use something like: starknet_keccak(array!['move'].span())
            let MOVE_SELECTOR = 0x239e4c8fbd11b680d7214cfc26d1780d5c099453f0832beb15fd040aebd4ebb;

            // Schedule the next move
            core_actions
                .schedule_queue(
                    queue_timestamp, // When to fade next
                    THIS_CONTRACT_ADDRESS, // This contract address
                    MOVE_SELECTOR, // The move function
                    calldata.span() // The calldata prepared
                );

            id
        }

        fn move(self: @ContractState, owner: ContractAddress) {
            'snake: move'.print();
            let world = self.world_dispatcher.read();
            let core_actions = get_core_actions(self.world_dispatcher.read());

            // Load the Snake
            let mut snake = get!(world, (owner), (Snake));

            assert(snake.length > 0, 'no snake');
            let first_segment = get!(world, (snake.first_segment_id), SnakeSegment);

            // If the snake is dying, handle that
            if snake.is_dying {
                'snake shrinks due to dying'.print();
                snake.last_segment_id = remove_last_segment(world, core_actions, snake);
                snake.length -= 1;

                if snake.length == 0 {
                    'snake is dead: deleting'.print();
                    let position = Position { x: first_segment.x, y: first_segment.y };
                    core_actions.alert_player(position, snake.owner, 'Snake died here');
                    emit!(world, Died { owner: snake.owner, x: first_segment.x, y: first_segment.y });

                    // TODO Properly use the delete functionality of Dojo.
                    set!(world, (Snake {
                            owner: snake.owner,
                            length: 0,
                            first_segment_id: 0,
                            last_segment_id: 0,
                            direction: Direction::None,
                            color: 0,
                            text: Zeroable::zero(),
                            is_dying: false
                    }));

                    // According to answer on
                    // https://discord.com/channels/1062934010722005042/1062934060898459678/1182202590260363344
                    // This is the right approach, but it doesnt seem to work.
                    let snake_owner_felt: felt252 = snake.owner.into();
                    let mut layout = array![];
                    Introspect::<Snake>::layout(ref layout);
                    world.delete_entity('Snake'.into(), array![snake_owner_felt.into()].span(), layout.span());
                    return;
                }

            }

            // Determine next pixel the head will move to
            let next_move = next_position(first_segment.x, first_segment.y, snake.direction);

            if next_move.is_some() && !snake.is_dying {
              let (next_x, next_y) = next_move.unwrap();

                // Load next pixel
                let next_pixel = get!(world, (next_x, next_y), Pixel);

                let has_write_access = core_actions
                  .has_write_access(
                    snake.owner,
                    get_contract_address(),
                    next_pixel,
                    PixelUpdate {
                      x: next_x,
                      y: next_y,
                      color: Option::Some(snake.color),
                      timestamp: Option::None,
                      text: Option::Some(snake.text),
                      app: Option::Some(get_contract_address()),
                      owner: Option::None,
                      action: Option::None  // Not using this feature for snake
                    }
                );

                // Determine what happens to the snake
                // MOVE, GROW, SHRINK, DIE
                if next_pixel.owner.is_zero() { // Snake just moves
                    'snake moves'.print();
                    // Add a new segment on the next pixel and update the snake
                    snake
                        .first_segment_id =
                            create_new_segment(world, core_actions, next_pixel, snake, first_segment);
                    snake.last_segment_id = remove_last_segment(world, core_actions, snake);

                } else if !has_write_access {
                  'snake will die'.print();
                  // Snake hit a pixel that is not allowing anyting: DIE
                  snake.is_dying = true;
                } else if next_pixel.owner == snake.owner {
                    'snake grows'.print();
                    // Next pixel is owned by snake owner: GROW

                    // Add a new segment
                    snake
                        .first_segment_id =
                            create_new_segment(world, core_actions, next_pixel, snake, first_segment);

                    // No growth if max length was reached
                    if snake.length >= SNAKE_MAX_LENGTH {
                        // Revert last segment pixel
                        snake.last_segment_id = remove_last_segment(world, core_actions, snake);
                    } else {
                        snake.length = snake.length + 1;
                    }
                // We leave the tail as is

                } else {
                    'snake shrinks'.print();
                    // Next pixel is not owned but can be used temporarily
                    // SHRINK, though
                    if snake.length == 1 {
                        snake.is_dying = true;
                    } else {
                        // Add a new segment
                        create_new_segment(world, core_actions, next_pixel, snake, first_segment);

                        // Remove last segment (this is normal for "moving")
                        snake.last_segment_id = remove_last_segment(world, core_actions, snake);

                        // Remove another last segment (for shrinking)
                        snake.last_segment_id = remove_last_segment(world, core_actions, snake);
                    }
                }
            } else {
              'snake will die'.print();
              // Snake hit a pixel that is not allowing anyting: DIE
              snake.is_dying = true;
            }

            // Save the snake
            set!(world, (snake));

            // Bot can execute this Queue as soon as possible
            let MOVE_SECONDS = 0;
            let queue_timestamp = starknet::get_block_timestamp() + MOVE_SECONDS;
            let mut calldata: Array<felt252> = ArrayTrait::new();
            let THIS_CONTRACT_ADDRESS = get_contract_address();

            // Calldata[0] : owner
            calldata.append(snake.owner.into());

            // Schedule the next move
            core_actions
                .schedule_queue(
                    queue_timestamp, // When to fade next
                    THIS_CONTRACT_ADDRESS, // This contract address
                    get_execution_info().unbox().entry_point_selector, // This selector
                    calldata.span() // The calldata prepared
                );
        }
    }


    // Removes the last segment of the snake and reverts the pixel
    fn remove_last_segment(
        world: IWorldDispatcher, core_actions: ICoreActionsDispatcher, snake: Snake
    ) -> u32 {
        let last_segment = get!(world, (snake.last_segment_id), SnakeSegment);
        let pixel = get!(world, (last_segment.x, last_segment.y), Pixel);

        // Write the changes to the pixel
        core_actions
            .update_pixel(
                snake.owner,
                get_contract_address(),
                PixelUpdate {
                    x: pixel.x,
                    y: pixel.y,
                    color: Option::Some(last_segment.pixel_original_color),
                    timestamp: Option::None,
                    text: Option::Some(last_segment.pixel_original_text),
                    app: Option::Some(last_segment.pixel_original_app),
                    owner: Option::None,
                    action: Option::None  // Not using this feature for snake
                }
            );

        let result = last_segment.previous_id;

        let segment_id_felt: felt252 = snake.last_segment_id.into();
        let mut layout = array![];
        Introspect::<SnakeSegment>::layout(ref layout);
        world.delete_entity('SnakeSegment'.into(), array![segment_id_felt.into()].span(), layout.span());

        // Return the new last_segment_id for the snake
        result
    }

    // Creates a new Segment on the given pixel
    fn create_new_segment(
        world: IWorldDispatcher,
        core_actions: ICoreActionsDispatcher,
        pixel: Pixel,
        snake: Snake,
        mut existing_segment: SnakeSegment
    ) -> u32 {
        let id = world.uuid();

        // Update the existing Segment
        // It is no longer the first, so now its previous_id will point to the new
        existing_segment.previous_id = id;
        set!(world, (existing_segment));

        // Save the new Segment
        set!(
            world,
            SnakeSegment {
                id,
                previous_id: id, // The first segment has no previous, so its itself
                next_id: existing_segment.id,
                x: pixel.x,
                y: pixel.y,
                pixel_original_color: pixel.color,
                pixel_original_text: pixel.text,
                pixel_original_app: pixel.app
            }
        );

        // Write the changes to the pixel
        core_actions
            .update_pixel(
                snake.owner,
                get_contract_address(),
                PixelUpdate {
                    x: pixel.x,
                    y: pixel.y,
                    color: Option::Some(snake.color),
                    timestamp: Option::None,
                    text: Option::Some(snake.text),
                    app: Option::Some(get_contract_address()),
                    owner: Option::None,
                    action: Option::None  // Not using this feature for snake
                }
            );
        id
    }
}
