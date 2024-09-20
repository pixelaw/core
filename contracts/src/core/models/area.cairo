use core::starknet::storage_access::StorePacking;
use starknet::{ContractAddress, ClassHash};
use pixelaw::core::utils::{
    MASK_16, MASK_32, MASK_64, MASK_96, POW_2_16, POW_2_30, POW_2_31, POW_2_32, POW_2_48, POW_2_64,
    POW_2_96
};

const TWO_POW_47: u64 = 0x800000000000;
const TWO_POW_32: u64 = 0x4000000000000;
const TWO_POW_17: u64 = 0x800000;
const TWO_POW_2: u64 = 0x4;
const TWO_POW_1: u64 = 0x2;
const MASK_15: u64 = 0x7FFF;
const MASK_1: u64 = 0x1;


#[dojo::model(namespace: "pixelaw", nomapping: true)]
#[derive(Copy, Drop, Serde, Debug, PartialEq, Introspect)]
pub struct Rect {
    #[key]
    pub id: u64, // Only 62 bits used so we can cram 4 in a felt252
    // 00000000000000000000000000000000000000000000000000000000000000
    // xxxxxxxxxxxxxxxyyyyyyyyyyyyyyywwwwwwwwwwwwwwwhhhhhhhhhhhhhhhla
    // x_min: u16,  << 47
    // y_min: u16,  << 32
    // x_max: u16   << 17
    // y_max: u16   << 2
    // is_leaf: 1   << 1
    // is_area: 1
    pub children: felt252
}

#[derive(Copy, Drop, Serde, Debug, PartialEq)]
pub struct Rectangle {
    pub x_min: u16,
    pub y_min: u16,
    pub x_max: u16,
    pub y_max: u16,
    pub is_leaf: bool,
    pub is_area: bool,
}

#[dojo::model(namespace: "pixelaw", nomapping: true)]
#[derive(Copy, Drop, Serde, Debug, PartialEq, Introspect)]
pub struct Area {
    #[key]
    id: u64,
    owner: ContractAddress,
    allow_nesting: bool
}

pub trait Packable<T, PackedT> {
    fn pack(self: T) -> PackedT;
    fn unpack(self: PackedT) -> T;
}

pub impl RectPackableImpl of Packable<Rectangle, u64> {
    fn pack(self: Rectangle) -> u64 {
        (self.x_min.into() * TWO_POW_47)
            + (self.y_min.into() * TWO_POW_32)
            + (self.x_max.into() * TWO_POW_17)
            + (self.y_max.into() * TWO_POW_2)
            + (match self.is_leaf {
                true => 2,
                false => 0
            })
            + (match self.is_area {
                true => 1,
                false => 0
            })
    }

    fn unpack(self: u64) -> Rectangle {
        let x_min: u16 = ((self / TWO_POW_47) & MASK_15).try_into().unwrap();
        let y_min: u16 = ((self / TWO_POW_32) & MASK_15).try_into().unwrap();
        let x_max: u16 = ((self / TWO_POW_17) & MASK_15).try_into().unwrap();
        let y_max: u16 = ((self / TWO_POW_2) & MASK_15).try_into().unwrap();
        let is_leaf: bool = ((self / 2) & MASK_1) == 1;
        let is_area: bool = ((self) & MASK_1) == 1;

        Rectangle { x_min, y_min, x_max, y_max, is_leaf, is_area }
    }
}

