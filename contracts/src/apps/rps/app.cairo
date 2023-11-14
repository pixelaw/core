use starknet::{ContractAddress, ClassHash};
use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

use pixelaw::core::utils::{get_core_actions, Direction, Position, DefaultParameters};

const APP_KEY: felt252 = 'rps';
const APP_ICON: felt252 = 'U+270A';

/// BASE means using the server's default manifest.json handler
const APP_MANIFEST: felt252 = 'BASE/manifests/rps';

const GAME_MAX_DURATION: u64 = 20000;


#[derive(Serde, Copy, Drop, PartialEq, Introspect)]
enum State {
    None: (),
    Created: (),
    Joined: (),
    Finished: ()
}

#[derive(Serde, Copy, Drop, PartialEq, Introspect)]
enum Move {
    None: (),
    Rock: (),
    Paper: (),
    Scissors: (),
}

impl MoveIntoFelt252 of Into<Move, felt252> {
    fn into(self: Move) -> felt252 {
        match self {
            Move::None(()) => 0,
            Move::Rock(()) => 1,
            Move::Paper(()) => 2,
            Move::Scissors(()) => 3,
        }
    }
}

#[derive(Model, Copy, Drop, Serde, SerdeLen)]
struct Game {
    #[key]
    x: u64,
    #[key]
    y: u64,
    id: u32,
    state: State,
    player1: ContractAddress,
    player2: ContractAddress,
    player1_commit: felt252,
    player1_move: Move,
    player2_move: Move,
    started_timestamp: u64
}

#[derive(Model, Copy, Drop, Serde, SerdeLen)]
struct Player {
    #[key]
    player_id: felt252,
    wins: u32
}


#[starknet::interface]
trait IRpsActions<TContractState> {
    fn init(self: @TContractState);
    fn secondary(self: @TContractState, default_params: DefaultParameters);
    fn interact(self: @TContractState, default_params: DefaultParameters, cr_Move_move: felt252);
    fn join(self: @TContractState, default_params: DefaultParameters, player2_move: Move);
    fn finish(self: @TContractState, default_params: DefaultParameters, rv_move: Move, rs_move: felt252);
}

#[dojo::contract]
mod rps_actions {
    use poseidon::poseidon_hash_span;
    use debug::PrintTrait;
    use starknet::{ContractAddress, get_caller_address, ClassHash, get_contract_address};
    use dojo::executor::{IExecutorDispatcher, IExecutorDispatcherTrait};


    use pixelaw::core::models::pixel::{Pixel, PixelUpdate};
    use pixelaw::core::utils::{get_core_actions, Direction, Position, DefaultParameters};

    use pixelaw::core::actions::{actions, IActionsDispatcher, IActionsDispatcherTrait};

    use super::IRpsActions;
    use super::{APP_KEY, APP_ICON, APP_MANIFEST, GAME_MAX_DURATION, Move, State};
    use super::{Game, Player};
    // use super::{STATE_NONE, State::Created, State::Joined, State::Finished};

    use zeroable::Zeroable;

    #[derive(Drop, starknet::Event)]
    struct GameCreated {
        game_id: u32,
        creator: ContractAddress
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        GameCreated: GameCreated
    }


    #[external(v0)]
    impl RpsActionsImpl of IRpsActions<ContractState> {
        /// Initialize the Paint App (TODO I think, do we need this??)
        fn init(self: @ContractState) {
            let core_actions = get_core_actions(self.world_dispatcher.read());

            core_actions.update_app(APP_KEY, APP_ICON, APP_MANIFEST);
        }


        fn interact(self: @ContractState, default_params: DefaultParameters, cr_Move_move: felt252) {

            // Load important variables
            let world = self.world_dispatcher.read();
            let core_actions = get_core_actions(world);
            let position = default_params.position;
            let player = core_actions.get_player_address(default_params.for_player);
            let system = core_actions.get_system_address(default_params.for_system);

            let pixel = get!(world, (position.x, position.y), Pixel);

            // Bail if the caller is not allowed here
            assert(pixel.owner.is_zero() || pixel.owner == player, 'Pixel is not players');

            // Load the game
            let mut game = get!(world, (position.x, position.y), Game);

            if game.id != 0 {
                // Bail if we're waiting for other player
                assert(game.state == State::Created, 'cannot reset rps game');

                // Player1 changing their commit
                game.player1_commit = cr_Move_move;
            } else {
              let mut id = world.uuid();
              if id == 0 {
                id = world.uuid();
              }

              game =
                    Game {
                        x: position.x,
                        y: position.y,
                        id,
                        state: State::Created,
                        player1: player,
                        player2: Zeroable::zero(),
                        player1_commit: cr_Move_move,
                        player1_move: Move::None,
                        player2_move: Move::None,
                        started_timestamp: starknet::get_block_timestamp()
                    };
                // Emit event
                emit!(world, GameCreated { game_id: game.id, creator: player });
            }

            // game entity
            set!(world, (game));

            core_actions
                .update_pixel(
                    player,
                    get_contract_address(),
                    PixelUpdate {
                        x: position.x,
                        y: position.y,
                        color: Option::Some(default_params.color),
                        alert: Option::None, // TODO figure out how we use alert
                        timestamp: Option::None,
                        text: Option::Some(
                            'U+2753'
                        ), // TODO better approach, for now copying unicode codepoint
                        app: Option::Some(get_contract_address().into()),
                        owner: Option::Some(player.into()),
                        action: Option::Some('join')
                    }
                );
        }


        fn join(self: @ContractState, default_params: DefaultParameters, player2_move: Move) {

            // Load important variables
            let world = self.world_dispatcher.read();
            let core_actions = get_core_actions(world);
            let position = default_params.position;
            let player = core_actions.get_player_address(default_params.for_player);
            let system = core_actions.get_system_address( default_params.for_system);

            let pixel = get!(world, (position.x, position.y), Pixel);

            // Load the game
            let mut game = get!(world, (position.x, position.y), Game);

            // Bail if theres no game at all
            assert(game.id != 0, 'No game to join');

            // Bail if wrong gamestate
            assert(game.state == State::Created, 'Wrong gamestate');


            // Bail if the player is joining their own game
            assert(game.player1 != player, 'Cant join own game');


            // Update the game
            game.player2 = player;
            game.player2_move = player2_move;
            game.state = State::Joined;

            // game entity
            set!(world, (game));

            core_actions
                .update_pixel(
                    player,
                    get_contract_address(),
                    PixelUpdate {
                        x: position.x,
                        y: position.y,
                        color: Option::None,
                        alert: Option::Some('!'), // TODO figure out how we use alert
                        timestamp: Option::None,
                        text: Option::Some(
                            'U+2757'
                        ), // TODO better approach, for now copying unicode codepoint
                        app: Option::None,
                        owner: Option::None,
                        action: Option::Some('finish')
                    }
                );
        }


        fn finish(
            self: @ContractState, default_params: DefaultParameters, rv_move: Move, rs_move: felt252
        ) {

            // Load important variables
            let world = self.world_dispatcher.read();
            let core_actions = get_core_actions(world);
            let position = default_params.position;
            let player = core_actions.get_player_address(default_params.for_player);
            let system = core_actions.get_system_address( default_params.for_system);

            let pixel = get!(world, (position.x, position.y), Pixel);

            // Load the game
            let mut game = get!(world, (position.x, position.y), Game);

            // Bail if theres no game at all
            assert(game.id != 0, 'No game to finish');

            // Bail if wrong gamestate
            assert(game.state == State::Joined, 'Wrong gamestate');

            // Bail if another player is finishing (has to be player1)
            assert(game.player1 == player, 'Cant finish others game');

            // Check player1's move
            assert(
                validate_commit(game.player1_commit, rv_move, rs_move), 'player1 cheating'
            );

            // Decide the winner
            let winner = decide(rv_move, game.player2_move);

            if winner == 0 { // No winner: Wipe the pixel
                core_actions
                    .update_pixel(
                        player,
                        get_contract_address(),
                        PixelUpdate {
                            x: position.x,
                            y: position.y,
                            color: Option::None,
                            alert: Option::Some(0),
                            timestamp: Option::None,
                            text: Option::Some(0),
                            app: Option::Some(Zeroable::zero()),
                            owner: Option::Some(Zeroable::zero()),
                            action: Option::Some(Zeroable::zero())
                        }
                    );
            // TODO emit event
            } else {
                // Update the game
                game.player1_move = rv_move;
                game.state = State::Finished;

                if winner == 2 {
                    // Change ownership of Pixel to player2
                    // TODO refactor, this could be cleaner
                    core_actions
                        .update_pixel(
                            player,
                            get_contract_address(),
                            PixelUpdate {
                                x: position.x,
                                y: position.y,
                                color: Option::None,
                                alert: Option::Some(0),
                                timestamp: Option::None,
                                text: Option::Some(get_unicode_for_rps(game.player2_move)),
                                app: Option::None,
                                owner: Option::Some(game.player2),
                                action: Option::Some('finish')  // TODO, probably want to change color still
                            }
                        );
                } else {
                    core_actions
                        .update_pixel(
                            player,
                            get_contract_address(),
                            PixelUpdate {
                                x: position.x,
                                y: position.y,
                                color: Option::None,
                                alert: Option::Some(0),
                                timestamp: Option::None,
                                text: Option::Some(get_unicode_for_rps(game.player1_move)),
                                app: Option::None,
                                owner: Option::None,
                                action: Option::Some('finish')  // TODO, probably want to change color still
                            }
                        );
                }
            }

            // game entity
            set!(world, (game));
        }

        fn secondary(self: @ContractState, default_params: DefaultParameters) {

            // Load important variables
            let world = self.world_dispatcher.read();
            let core_actions = get_core_actions(world);
            let position = default_params.position;
            let player = core_actions.get_player_address(default_params.for_player);
            let system = core_actions.get_system_address( default_params.for_system);
            let pixel = get!(world, (position.x, position.y), Pixel);
            let game = get!(world, (position.x, position.y), Game);

            // reset the pixel in the right circumstances
            assert(pixel.owner == player, 'player doesnt own pixel');

            let game_id_felt: felt252 = game.id.into();
            world.delete_entity('Game'.into(), array![game_id_felt.into()].span());

            core_actions
                .update_pixel(
                    player,
                    get_contract_address(),
                    PixelUpdate {
                        x: position.x,
                        y: position.y,
                        color: Option::Some(0),
                        alert: Option::Some(Zeroable::zero()),
                        timestamp: Option::None,
                        text: Option::Some(Zeroable::zero()),
                        app: Option::Some(Zeroable::zero()),
                        owner: Option::Some(Zeroable::zero()),
                        action: Option::Some(Zeroable::zero())
                    }
                );

        }

    }

    fn get_unicode_for_rps(move: Move) -> felt252 {
        let mut result = 'U+1FAA8';
        match move {
            Move::None => '',
            Move::Rock => 'U+1FAA8',
            Move::Paper => 'U+1F9FB',
            Move::Scissors => 'U+2702',
        }
    }

    fn validate_commit(committed_hash: felt252, move: Move, salt: felt252) -> bool {
        let mut hash_span = ArrayTrait::<felt252>::new();
        hash_span.append(move.into());
        hash_span.append(salt.into());

        let computed_hash: felt252 = poseidon_hash_span(hash_span.span());

        committed_hash == computed_hash
    }

    fn decide(player1_commit: Move, player2_commit: Move) -> u8 {
        if player1_commit == Move::Rock && player2_commit == Move::Paper {
            2
        } else if player1_commit == Move::Paper && player2_commit == Move::Rock {
            1
        } else if player1_commit == Move::Rock && player2_commit == Move::Scissors {
            1
        } else if player1_commit == Move::Scissors && player2_commit == Move::Rock {
            2
        } else if player1_commit == Move::Scissors && player2_commit == Move::Paper {
            1
        } else if player1_commit == Move::Paper && player2_commit == Move::Scissors {
            2
        } else {
            0
        }
    }

    // TODO: implement proper psuedo random number generator
    fn random(seed: felt252, min: u128, max: u128) -> u128 {
        let seed: u256 = seed.into();
        let range = max - min;

        (seed.low % range) + min
    }

    fn hash_commit(commit: u8, salt: felt252) -> felt252 {
        let mut hash_span = ArrayTrait::<felt252>::new();
        hash_span.append(commit.into());
        hash_span.append(salt.into());

        poseidon_hash_span(hash_span.span())
    }
}
