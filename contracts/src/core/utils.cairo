use starknet::{ContractAddress, get_caller_address, ClassHash, get_contract_address};
use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
use pixelaw::core::models::pixel::{Pixel};

#[derive(Serde, Copy, Drop, Introspect)]
pub enum Direction {
    None: (),
    Left: (),
    Right: (),
    Up: (),
    Down: (),
}

#[derive(Debug, Copy, Drop, Serde, Introspect, PartialEq)]
pub struct Position {
    pub x: u32,
    pub y: u32
}


#[derive(Copy, Drop, Serde)]
pub struct DefaultParameters {
    pub for_player: ContractAddress,
    pub for_system: ContractAddress,
    pub position: Position,
    pub color: u32
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
pub fn starknet_keccak(data: Span<felt252>) -> felt252 {
    let mut u256_data: Array<u256> = array![];

    let mut i = 0_usize;
    loop {
        if i == data.len() {
            break;
        }
        u256_data.append((*data[i]).into());
        i += 1;
    };

    let mut hash = core::keccak::keccak_u256s_be_inputs(u256_data.span());
    let low = core::integer::u128_byte_reverse(hash.high);
    let high = core::integer::u128_byte_reverse(hash.low);
    hash = u256 { low, high };
    hash = hash & 0x03ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff_u256;
    hash.try_into().expect('starknet keccak overflow')
}


pub fn get_position(direction: Direction, position: Position) -> Position {
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

use pixelaw::core::actions::{IActionsDispatcher, IActionsDispatcherTrait, CORE_ACTIONS_KEY};
use pixelaw::core::models::registry::{App, AppName, CoreActionsAddress};
/// Returns the PixeLAW Core actions as Dispatcher, ready to use
pub fn get_core_actions_address(world: IWorldDispatcher) -> ContractAddress {
    let address = get!(world, CORE_ACTIONS_KEY, (CoreActionsAddress));
    address.value
}

pub fn get_core_actions(world: IWorldDispatcher) -> IActionsDispatcher {
    let address = get_core_actions_address(world);
    IActionsDispatcher { contract_address: address }
}

pub fn subu8(nr: u8, sub: u8) -> u8 {
    if nr >= sub {
        return nr - sub;
    } else {
        return 0x000000FF;
    }
}


// RGBA
// 0xFF FF FF FF
// empty: 0x 00 00 00 00
// normal color (opaque): 0x FF FF FF FF
pub fn encode_color(r: u8, g: u8, b: u8, a: u8) -> u32 {
    (r.into() * 0x1000000) + (g.into() * 0x10000) + (b.into() * 0x100) + a.into()
}

pub fn decode_color(color: u32) -> (u8, u8, u8, u8) {
    let r: u32 = (color / 0x1000000);
    let g: u32 = (color / 0x10000) & 0xff;
    let b: u32 = (color / 0x100) & 0xff;
    let a: u32 = color & 0xff;

    let r: Option<u8> = r.try_into();
    let g: Option<u8> = g.try_into();
    let b: Option<u8> = b.try_into();
    let a: Option<u8> = a.try_into();

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

    let a: u8 = match a {
        Option::Some(a) => a,
        Option::None => 0xFF,
    };

    (r, g, b, a)
}

pub fn is_pixel_color(world: IWorldDispatcher, position: Position, color: u32) -> bool {
    let pixel: Pixel = get!(world, (position.x, position.y), (Pixel));
    pixel.color == color
}
