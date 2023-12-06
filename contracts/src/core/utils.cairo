use starknet::{ContractAddress, get_caller_address, ClassHash, get_contract_address};
use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

#[derive(Serde, Copy, Drop, Introspect)]
enum Direction {
    None: (),
    Left: (),
    Right: (),
    Up: (),
    Down: (),
}

#[derive(Copy, Drop, Serde, SerdeLen)]
struct Position {
    x: u32,
    y: u32
}


#[derive(Copy, Drop, Serde, SerdeLen)]
struct DefaultParameters {
    for_player: ContractAddress,
    for_system: ContractAddress,
    position: Position,
    color: u32
}


impl DirectionIntoFelt252 of Into<Direction, felt252> {
    fn into(self: Direction) -> felt252 {
        match self {
            Direction::None(()) => 0,
            Direction::Left(()) => 1,
            Direction::Right(()) => 2,
            Direction::Up(()) => 3,
            Direction::Down(()) => 4,
        }
    }
}
const U32_MAX: u32 = 0xFFFFFFFF;


/// Computes the starknet keccak to have a hash that fits in one felt.
fn starknet_keccak(data: Span<felt252>) -> felt252 {
    let mut u256_data: Array<u256> = array![];

    let mut i = 0_usize;
    loop {
        if i == data.len() {
            break;
        }
        u256_data.append((*data[i]).into());
        i += 1;
    };

    let mut hash = keccak::keccak_u256s_be_inputs(u256_data.span());
    let low = integer::u128_byte_reverse(hash.high);
    let high = integer::u128_byte_reverse(hash.low);
    hash = u256 { low, high };
    hash = hash & 0x03ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff_u256;
    hash.try_into().expect('starknet keccak overflow')
}


fn get_position(direction: Direction, position: Position) -> Position {
    match direction {
        Direction::None => { position },
        Direction::Left => {
            if position.x == 0 {
                position
            } else {
                Position { x: position.x - 1, y: position.y }
            }
        },
        Direction::Right => {
            if position.x == U32_MAX {
                position
            } else {
                Position { x: position.x + 1, y: position.y }
            }
        },
        Direction::Up => {
            if position.y == 0 {
                position
            } else {
                Position { x: position.x, y: position.y - 1 }
            }
        },
        Direction::Down => {
            if position.y == U32_MAX {
                position
            } else {
                Position { x: position.x, y: position.y + 1 }
            }
        },
    }
}

use pixelaw::core::actions::{IActionsDispatcher,IActionsDispatcherTrait, CORE_ACTIONS_KEY};
    use pixelaw::core::models::registry::{App, AppName, CoreActionsAddress};
/// Returns the PixeLAW Core actions as Dispatcher, ready to use
fn get_core_actions_address(world: IWorldDispatcher) -> ContractAddress {
    let address = get!(world, CORE_ACTIONS_KEY, (CoreActionsAddress));
    address.value
}

fn get_core_actions(world: IWorldDispatcher) -> IActionsDispatcher {
  let address = get!(world, CORE_ACTIONS_KEY, (CoreActionsAddress));
  IActionsDispatcher { contract_address: address.value }
}
