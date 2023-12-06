use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
use starknet::{ContractAddress, ClassHash};
use pixelaw::core::utils::{Direction, Position, DefaultParameters, starknet_keccak};


fn next_position(x: u64, y: u64, direction: Direction) -> Option<(u64, u64)> {
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
    x: u64,
    y: u64,
    pixel_original_color: u32,
    pixel_original_text: felt252
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
    use pixelaw::core::utils::{get_core_actions, Direction, Position, DefaultParameters, starknet_keccak};
    use super::next_position;
    use super::ISnakeActions;
    use pixelaw::core::actions::{
        IActionsDispatcher as ICoreActionsDispatcher,
        IActionsDispatcherTrait as ICoreActionsDispatcherTrait
    };

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
        x: u64,
        y: u64
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


    #[external(v0)]
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
                pixel_original_text: pixel.text
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
                        app: Option::None,
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

            assert(!snake.owner.is_zero(), 'no snake');
            let first_segment = get!(world, (snake.first_segment_id), SnakeSegment);

            // If the snake is dying, handle that
            if snake.is_dying {

                snake.last_segment_id = remove_last_segment(world, core_actions, snake);
                snake.length -= 1;

                if snake.length == 0 {
                    let position = Position { x: first_segment.x, y: first_segment.y };
                    core_actions.alert_player(position, snake.owner, 'Snake died here');
                    emit!(world, Died { owner: snake.owner, x: first_segment.x, y: first_segment.y });
                    set!(world, (snake));
                    // Since we return immediately, the next Queue for move will never be set
                    // This will stop the movement loop
                    // TODO handle situation where someone manually calls 'move', it will
                    // spam Died events..
                    let snake_owner_felt: felt252 = snake.owner.into();
                    world.delete_entity('Snake'.into(), array![snake_owner_felt.into()].span());
                    return;
                }

            }

            // Load the current pixel
            let mut current_pixel = get!(world, (first_segment.x, first_segment.y), Pixel);

            // Determine next pixel the head will move to
            let next_move = next_position(first_segment.x, first_segment.y, snake.direction);

            if next_move.is_some() {
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
                      app: Option::None,
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
                    app: Option::None,
                    owner: Option::None,
                    action: Option::None  // Not using this feature for snake
                }
            );

        let result = last_segment.previous_id;

        let segment_id_felt: felt252 = snake.last_segment_id.into();
        world.delete_entity('SnakeSegment'.into(), array![segment_id_felt.into()].span());

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
                pixel_original_text: pixel.text
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
                    app: Option::None,
                    owner: Option::None,
                    action: Option::None  // Not using this feature for snake
                }
            );
        id
    }
}
