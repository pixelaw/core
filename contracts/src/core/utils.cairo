use dojo::model::{ModelStorage};
use dojo::world::storage::WorldStorage;
use pixelaw::core::actions::{IActionsDispatcher, CORE_ACTIONS_KEY};
use pixelaw::core::models::registry::{CoreActionsAddress};
use pixelaw::core::models::{
    pixel::{Pixel},
    {area::{RTreeTraitImpl, RTreeNodePackableImpl, ChildrenPackableImpl, BoundsTraitImpl}}
};
use starknet::{ContractAddress, contract_address_const, get_tx_info, get_contract_address};


pub const POW_2_96: u128 = 0x1000000000000000000000000_u128;
pub const POW_2_64: u128 = 0x10000000000000000_u128;
pub const POW_2_48: u128 = 0x1000000000000_u128;
pub const POW_2_32: u128 = 0x100000000_u128;
pub const POW_2_31: u128 = 0x80000000_u128;
pub const POW_2_30: u128 = 0x40000000_u128;
pub const POW_2_16: u128 = 0x10000_u128;
pub const POW_2_15: u128 = 0x8000_u128;

pub const MASK_96: u128 = 0xFFFFFFFFFFFFFFFFFFFFFFFF;
pub const MASK_64: u128 = 0xFFFFFFFFFFFFFFFF;
pub const MASK_32: u128 = 0xFFFFFFFF;
pub const MASK_16: u128 = 0xFFFF;

pub const MAX_DIMENSION: u16 = 32767; // 2**15 -1 (so all bits utilized)
const U32_MAX: u32 = 0xFFFFFFFF;

pub const ON_PRE_UPDATE_HOOK: felt252 =
    0x3aaf17d2bb02c9d23c8c0c465fb64d421430b1a9e838ada90d7ca34b766efbb;

pub const ON_POST_UPDATE_HOOK: felt252 =
    0x3484ad2e032768c324059cc216083c643765f60c00f2b9b0561bc98ceb1c92;

pub const SNAKE_MOVE_ENTRYPOINT: felt252 =
    0x239e4c8fbd11b680d7214cfc26d1780d5c099453f0832beb15fd040aebd4ebb;

pub const INTERACT_SELECTOR: felt252 =
    0x476d5e1b17fd9d508bd621909241c5eb4c67380f3651f54873c5c1f2b891f4;

pub const MOVE_SELECTOR: felt252 =
    0x239e4c8fbd11b680d7214cfc26d1780d5c099453f0832beb15fd040aebd4ebb;

#[derive(Debug, PartialEq, Serde, Copy, Drop, Introspect)]
pub enum Direction {
    None: (),
    Left: (),
    Right: (),
    Up: (),
    Down: (),
}

#[derive(Debug, Copy, Drop, Serde, Introspect, PartialEq)]
pub struct Position {
    pub x: u16,
    pub y: u16
}


#[derive(Debug, Copy, Drop, Serde, Introspect, PartialEq)]
pub struct Bounds {
    pub x_min: u16,
    pub y_min: u16,
    pub x_max: u16,
    pub y_max: u16
}


#[derive(Copy, Drop, Serde)]
pub struct DefaultParameters {
    pub player_override: Option<ContractAddress>,
    pub system_override: Option<ContractAddress>,
    pub area_hint: Option<u64>,
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


// Returns the current (account and system) callers
// Taking into account overrides from DefaultParams
pub fn get_callers(
    ref world: WorldStorage, params: DefaultParameters
) -> (ContractAddress, ContractAddress) {
    let mut player = contract_address_const::<0>();
    let mut system = contract_address_const::<0>();

    let core_address = get_core_actions_address(ref world);
    let caller_contract = get_contract_address();

    if let Option::Some(override) = params.player_override {
        assert(caller_contract == core_address, 'only core can override');
        player = override;
    } else {
        player = get_tx_info().unbox().account_contract_address;
    }
    if let Option::Some(override) = params.system_override {
        assert(caller_contract == core_address, 'only core can override');
        system = override;
    } else {
        system = caller_contract;
    }
    (player, system)
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
            if position.x == 0xFFFF {
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
            if position.y == 0xFFFF {
                position
            } else {
                Position { x: position.x, y: position.y + 1 }
            }
        },
    }
}
/// Returns the PixeLAW Core actions as Dispatcher, ready to use
pub fn get_core_actions_address(ref world: WorldStorage) -> ContractAddress {
    let address: CoreActionsAddress = world.read_model(CORE_ACTIONS_KEY);
    address.value
}

pub fn get_core_actions(ref world: WorldStorage) -> IActionsDispatcher {
    let address = get_core_actions_address(ref world);
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

pub fn encode_rgba(r: u8, g: u8, b: u8, a: u8) -> u32 {
    (r.into() * 0x1000000) + (g.into() * 0x10000) + (b.into() * 0x100) + a.into()
}

pub fn decode_rgba(self: u32) -> (u8, u8, u8, u8) {
    let r: u32 = (self / 0x1000000);
    let g: u32 = (self / 0x10000) & 0xff;
    let b: u32 = (self / 0x100) & 0xff;
    let a: u32 = self & 0xff;

    (
        r.try_into().unwrap_or(0),
        g.try_into().unwrap_or(0),
        b.try_into().unwrap_or(0),
        a.try_into().unwrap_or(0xFF)
    )
}


pub fn is_pixel_color(ref world: WorldStorage, position: Position, color: u32) -> bool {
    let pixel: Pixel = world.read_model((position.x, position.y));
    pixel.color == color
}

pub fn min<T, +PartialOrd<T>, +Copy<T>, +Drop<T>>(a: T, b: T) -> T {
    if a < b {
        a
    } else {
        b
    }
}

pub fn max<T, +PartialOrd<T>, +Copy<T>, +Drop<T>>(a: T, b: T) -> T {
    if a > b {
        a
    } else {
        b
    }
}
