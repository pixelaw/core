use pixelaw::core::utils::{Direction, DefaultParameters};
use starknet::{ContractAddress};

/// Calculates the next position based on the current coordinates and direction.
///
/// # Arguments
///
/// * `x` - Current x-coordinate.
/// * `y` - Current y-coordinate.
/// * `direction` - Direction to move in.
///
/// # Returns
///
/// * `Option<(u16, u16)>` - The next position as an `Option`. Returns `None` if the move is
/// invalid.
fn next_position(x: u16, y: u16, direction: Direction) -> Option<(u16, u16)> {
    match direction {
        Direction::None(()) => Option::Some((x, y)),
        Direction::Left(()) => { if x == 0 {
            Option::None
        } else {
            Option::Some((x - 1, y))
        } },
        Direction::Right(()) => Option::Some((x + 1, y)),
        Direction::Up(()) => { if y == 0 {
            Option::None
        } else {
            Option::Some((x, y - 1))
        } },
        Direction::Down(()) => Option::Some((x, y + 1)),
    }
}

/// Represents a Snake in the game.
///
/// Each snake has an owner, length, and a linked list of segments.
///
/// Fields:
///
/// * `owner` - The owner of the snake.
/// * `length` - The length of the snake.
/// * `first_segment_id` - The ID of the first segment (head).
/// * `last_segment_id` - The ID of the last segment (tail).
/// * `direction` - The current direction of the snake.
/// * `color` - The color of the snake.
/// * `text` - Any text associated with the snake.
/// * `is_dying` - A flag indicating whether the snake is dying.
#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct Snake {
    #[key]
    pub owner: ContractAddress,
    pub length: u8,
    pub first_segment_id: u32,
    pub last_segment_id: u32,
    pub direction: Direction,
    pub color: u32,
    pub text: felt252,
    pub is_dying: bool,
}

/// Represents a segment of a Snake.
///
/// Fields:
///
/// * `id` - The unique identifier of the segment.
/// * `previous_id` - The ID of the previous segment.
/// * `next_id` - The ID of the next segment.
/// * `x` - The x-coordinate of the segment.
/// * `y` - The y-coordinate of the segment.
/// * `pixel_original_color` - The original color of the pixel before the segment occupied it.
/// * `pixel_original_text` - The original text of the pixel.
/// * `pixel_original_app` - The original app associated with the pixel.
#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct SnakeSegment {
    #[key]
    pub id: u32,
    pub previous_id: u32,
    pub next_id: u32,
    pub x: u16,
    pub y: u16,
    pub pixel_original_color: u32,
    pub pixel_original_text: felt252,
    pub pixel_original_app: ContractAddress,
}

pub const APP_KEY: felt252 = 'snake';
pub const APP_ICON: felt252 = 'U+1F40D';

/// Interface for Snake actions.
#[starknet::interface]
pub trait ISnakeActions<T> {
    /// Initializes the Snake App.
    ///
    /// # Arguments
    ///
    /// * `world` - A reference to the world dispatcher.
    fn init(ref self: T);

    /// Starts or interacts with a snake.
    ///
    /// # Arguments
    ///
    /// * `world` - A reference to the world dispatcher.
    /// * `default_params` - Default parameters including position and color.
    /// * `direction` - The direction to move the snake.
    ///
    /// # Returns
    ///
    /// * `u32` - The ID of the snake's first segment.
    fn interact(ref self: T, default_params: DefaultParameters, direction: Direction,) -> u32;

    /// Moves the snake owned by the specified owner.
    ///
    /// # Arguments
    ///
    /// * `world` - A reference to the world dispatcher.
    /// * `owner` - The contract address of the snake's owner.
    fn move(ref self: T, owner: ContractAddress);
}

#[dojo::contract]
pub mod snake_actions {
    use dojo::event::EventStorage;
    use dojo::model::{ModelStorage};
    use dojo::world::storage::WorldStorage;
    use dojo::world::{IWorldDispatcherTrait};
    use pixelaw::core::actions::{
        IActionsDispatcher as ICoreActionsDispatcher,
        IActionsDispatcherTrait as ICoreActionsDispatcherTrait,
    };
    use pixelaw::core::models::pixel::{Pixel, PixelUpdate, PixelUpdateResultTrait};
    use pixelaw::core::utils::{
        MOVE_SELECTOR, get_callers, get_core_actions, Direction, Position, DefaultParameters
    };
    use starknet::{
        ContractAddress, get_contract_address, get_execution_info, contract_address_const,
    };
    use super::ISnakeActions;
    use super::next_position;

    use super::{APP_KEY, APP_ICON};
    use super::{Snake, SnakeSegment};


    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct Died {
        #[key]
        owner: ContractAddress,
        x: u16,
        y: u16,
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct Moved {
        #[key]
        pub owner: ContractAddress,
        pub direction: Direction,
    }

    const SNAKE_MAX_LENGTH: u8 = 255;


    /// Implementation of the Snake actions.
    #[abi(embed_v0)]
    impl ActionsImpl of ISnakeActions<ContractState> {
        /// Initializes the Snake App.
        ///
        /// Registers the app with core actions
        ///
        /// # Arguments
        ///
        /// * `world` - A reference to the world dispatcher.
        fn init(ref self: ContractState) {
            let mut world = self.world(@"pixelaw");
            let core_actions = get_core_actions(ref world);

            core_actions.new_app(contract_address_const::<0>(), APP_KEY, APP_ICON);
        }


        /// Starts a new snake or changes the direction of an existing snake.
        ///
        /// # Arguments
        ///
        /// * `world` - A reference to the world dispatcher.
        /// * `default_params` - Default parameters including position and color.
        /// * `direction` - The direction to move the snake.
        ///
        /// # Returns
        ///
        /// * `u32` - The ID of the snake's first segment.
        fn interact(
            ref self: ContractState, default_params: DefaultParameters, direction: Direction,
        ) -> u32 {
            let mut world = self.world(@"pixelaw");
            let core_actions = get_core_actions(ref world);
            let position = default_params.position;

            let (player, system) = get_callers(ref world, default_params);

            // Check if there is already a Snake or SnakeSegment here
            let pixel: Pixel = world.read_model((position.x, position.y));
            let mut snake: Snake = world.read_model(player);
            //let mut snake = get!(world, player, Snake);

            // Change direction if snake already exists
            if snake.length > 0 {
                snake.direction = direction;

                world.write_model(@snake);

                return snake.first_segment_id;
            }
            // TODO: Check if the pixel is unowned or player owned

            let mut id = world.dispatcher.uuid();
            if id == 0 {
                id = world.dispatcher.uuid();
            }

            let color = default_params.color;
            let text = ''; // TODO
            // Initialize the Snake model
            snake =
                Snake {
                    owner: player,
                    length: 1,
                    first_segment_id: id,
                    last_segment_id: id,
                    direction: direction,
                    color,
                    text,
                    is_dying: false,
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
                pixel_original_app: pixel.app,
            };

            // Store the dojo model for the Snake
            world.write_model(@snake);
            world.write_model(@segment);

            // Call core_actions to update the color
            let _ = core_actions
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
                        action: Option::None, // Not using this feature for snake
                    },
                    Option::None,
                    false
                );

            let MOVE_SECONDS = 0;
            let queue_timestamp = starknet::get_block_timestamp() + MOVE_SECONDS;
            let mut calldata: Array<felt252> = ArrayTrait::new();
            let THIS_CONTRACT_ADDRESS = get_contract_address();

            // Calldata[0]: Owner address
            calldata.append(player.into());

            // Schedule the next move
            core_actions
                .schedule_queue(
                    queue_timestamp, // When to move next
                    THIS_CONTRACT_ADDRESS, // This contract address
                    MOVE_SELECTOR, // The move function
                    calldata.span(), // The prepared calldata
                );

            id
        }

        /// Moves the snake owned by the specified owner.
        ///
        /// Handles the movement logic including moving, growing, shrinking, or dying.
        ///
        /// # Arguments
        ///
        /// * `world` - A reference to the world dispatcher.
        /// * `owner` - The contract address of the snake's owner.
        fn move(ref self: ContractState, owner: ContractAddress) {
            let mut world = self.world(@"pixelaw");
            let core_actions = get_core_actions(ref world);

            // Load the Snake
            let mut snake: Snake = world.read_model(owner);

            assert!(snake.length > 0, "no snake");
            let first_segment: SnakeSegment = world.read_model(snake.first_segment_id);

            // If the snake is dying, handle that
            if snake.is_dying {
                snake.last_segment_id = remove_last_segment(ref world, core_actions, snake);
                snake.length -= 1;
                if snake.length == 0 {
                    let position = Position { x: first_segment.x, y: first_segment.y, };
                    core_actions.alert_player(position, snake.owner, 'Snake died here');

                    world
                        .emit_event(
                            @Died { owner: snake.owner, x: first_segment.x, y: first_segment.y }
                        );

                    // Delete the snake
                    world.erase_model(@snake);
                    return;
                }
            }

            // Determine next pixel the head will move to
            let next_move = next_position(first_segment.x, first_segment.y, snake.direction);

            if next_move.is_some() && !snake.is_dying {
                let (next_x, next_y) = next_move.unwrap();

                // Load next pixel
                let next_pixel: Pixel = world.read_model((next_x, next_y));

                let has_write_access = core_actions
                    .can_update_pixel(
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
                            action: Option::None, // Not using this feature for snake
                        },
                        Option::None,
                        false
                    )
                    .is_ok();

                // Determine what happens to the snake
                // MOVE, GROW, SHRINK, DIE
                if next_pixel.owner == contract_address_const::<0>() {
                    // Snake just moves
                    // Add a new segment on the next pixel and update the snake

                    snake
                        .first_segment_id =
                            create_new_segment(
                                ref world, core_actions, next_pixel, snake, first_segment,
                            );
                    snake.last_segment_id = remove_last_segment(ref world, core_actions, snake);
                } else if !has_write_access {
                    // Snake hit a pixel that is not allowing anything: DIE
                    snake.is_dying = true;
                } else if next_pixel.owner == snake.owner {
                    // Next pixel is owned by snake owner: GROW

                    // Add a new segment
                    snake
                        .first_segment_id =
                            create_new_segment(
                                ref world, core_actions, next_pixel, snake, first_segment,
                            );

                    // No growth if max length was reached
                    if snake.length >= SNAKE_MAX_LENGTH {
                        // Revert last segment pixel
                        snake.last_segment_id = remove_last_segment(ref world, core_actions, snake);
                    } else {
                        snake.length += 1;
                    }
                    // We leave the tail as is
                } else {
                    // Next pixel is not owned but can be used temporarily
                    // SHRINK, though
                    if snake.length == 1 {
                        snake.is_dying = true;
                    } else {
                        // Add a new segment
                        create_new_segment(
                            ref world, core_actions, next_pixel, snake, first_segment,
                        );

                        // Remove last segment (this is normal for "moving")
                        snake.last_segment_id = remove_last_segment(ref world, core_actions, snake);

                        // Remove another last segment (for shrinking)
                        snake.last_segment_id = remove_last_segment(ref world, core_actions, snake);
                    }
                }
            } else {
                // Snake hit a pixel that is not allowing anything: DIE
                snake.is_dying = true;
            }

            // Save the snake
            world.write_model(@snake);

            // Bot can execute this Queue as soon as possible
            let MOVE_SECONDS = 0;
            let queue_timestamp = starknet::get_block_timestamp() + MOVE_SECONDS;
            let mut calldata: Array<felt252> = ArrayTrait::new();
            let THIS_CONTRACT_ADDRESS = get_contract_address();

            // Calldata[0]: Owner
            calldata.append(snake.owner.into());

            // Schedule the next move
            core_actions
                .schedule_queue(
                    queue_timestamp, // When to move next
                    THIS_CONTRACT_ADDRESS, // This contract address
                    get_execution_info().unbox().entry_point_selector, // This selector
                    calldata.span(), // The prepared calldata
                );
        }
    }

    /// Removes the last segment of the snake and reverts the pixel to its original state.
    ///
    /// # Arguments
    ///
    /// * `world` - A reference to the world dispatcher.
    /// * `core_actions` - A reference to the core actions dispatcher.
    /// * `snake` - The snake from which to remove the last segment.
    ///
    /// # Returns
    ///
    /// * `u32` - The new `last_segment_id` for the snake.
    fn remove_last_segment(
        ref world: WorldStorage, core_actions: ICoreActionsDispatcher, snake: Snake,
    ) -> u32 {
        let last_segment: SnakeSegment = world.read_model(snake.last_segment_id);
        let pixel: Pixel = world.read_model((last_segment.x, last_segment.y));

        // Write the changes to the pixel
        let _ = core_actions
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
                    action: Option::None, // Not using this feature for snake
                },
                Option::None, // TODO area_hint
                false
            );

        let result = last_segment.previous_id;

        world.erase_model(@last_segment);

        // Return the new last_segment_id for the snake
        result
    }

    /// Creates a new segment on the given pixel and updates the snake.
    ///
    /// # Arguments
    ///
    /// * `world` - A reference to the world dispatcher.
    /// * `core_actions` - A reference to the core actions dispatcher.
    /// * `pixel` - The pixel where the new segment will be placed.
    /// * `snake` - The snake to which the new segment will be added.
    /// * `existing_segment` - The existing segment (head) that will be updated.
    ///
    /// # Returns
    ///
    /// * `u32` - The ID of the new segment created.
    fn create_new_segment(
        ref world: WorldStorage,
        core_actions: ICoreActionsDispatcher,
        pixel: Pixel,
        snake: Snake,
        mut existing_segment: SnakeSegment,
    ) -> u32 {
        let id = world.dispatcher.uuid();

        // Update the existing Segment
        // It is no longer the first, so now its previous_id will point to the new
        existing_segment.previous_id = id;
        world.write_model(@existing_segment);

        // Save the new Segment
        world
            .write_model(
                @SnakeSegment {
                    id,
                    previous_id: id, // The first segment has no previous, so it's itself
                    next_id: existing_segment.id,
                    x: pixel.x,
                    y: pixel.y,
                    pixel_original_color: pixel.color,
                    pixel_original_text: pixel.text,
                    pixel_original_app: pixel.app,
                }
            );

        // Write the changes to the pixel
        let _pu = core_actions
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
                    action: Option::None, // Not using this feature for snake
                },
                Option::None,
                false
            );
        id
    }
}
