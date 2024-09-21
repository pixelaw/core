use core::starknet::storage_access::StorePacking;
use starknet::{ContractAddress, ClassHash};
use pixelaw::core::utils::{
    MASK_16, MASK_32, MASK_64, MASK_96, POW_2_16, POW_2_30, POW_2_31, POW_2_32, POW_2_48, POW_2_64,
    POW_2_96
};


pub const TWO_POW_188: u256 = 0x100000000000000000000000000000000000000000000000;
pub const TWO_POW_124: u256 = 0x10000000000000000000000000000000;
pub const TWO_POW_62: u256 = 0x4000000000000000;
const TWO_POW_47: u64 = 0x800000000000;
const TWO_POW_32: u64 = 0x100000000;
const TWO_POW_17: u64 = 0x20000;
const TWO_POW_2: u64 = 0x4;
const TWO_POW_1: u64 = 0x2;
const MASK_15: u64 = 0x7FFF;
const MASK_62: u64 = 0x3fffffffffffffff;
const MASK_1: u64 = 0x1;


#[dojo::model(namespace: "pixelaw", nomapping: true)]
#[derive(Copy, Drop, Serde, Debug, PartialEq, Introspect)]
pub struct RTree {
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
pub struct RTreeNode {
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

pub trait RTreeChildren<T, T2> {
    fn get_children(self: T) -> T2;
    // fn count_children(self: T) -> u8;
}

// A bunch of helpers with the packed children
pub impl RTreeChildrenImpl of RTreeChildren<RTree, Span<u64>> {
    fn get_children(self: RTree) -> Span<u64> {
        self.children.unpack()
    }
    // fn count_children(self: RTree) -> u8{

    // }
}

pub impl ChildrenPackableImpl of Packable<Span<u64>, felt252> {
    fn pack(self: Span<u64>) -> felt252 {
        let mut out: u256 = 0;

        if self.len() > 0 {
            out += (*self[0]).try_into().unwrap() * TWO_POW_188;
            if self.len() > 1 {
                out += (*self[1]).try_into().unwrap() * TWO_POW_124;
                if self.len() > 2 {
                    out += (*self[2]).try_into().unwrap() * TWO_POW_62;
                    if self.len() > 3 {
                        out += (*self[3]).try_into().unwrap();
                    }
                }
            }
        }

        out.try_into().unwrap()
    }

    fn unpack(self: felt252) -> Span<u64> {
        let val: u256 = self.into();
        let mut out: Array<u64> = array![];

        let val1 = ((val / TWO_POW_188.into()) & MASK_62.into()).try_into().unwrap();
        if val1 > 0 {
            out.append(val1);
            let val2 = ((val / TWO_POW_124.into()) & MASK_62.into()).try_into().unwrap();
            if val2 > 0 {
                out.append(val2);
                let val3 = ((val / TWO_POW_62.into()) & MASK_62.into()).try_into().unwrap();
                if val3 > 0 {
                    out.append(val3);
                    let val4 = (val & MASK_62.into()).try_into().unwrap();
                    if val4 > 0 {
                        out.append(val4);
                    }
                }
            }
        };

        out.span()
    }
}

pub impl RTreeNodePackableImpl of Packable<RTreeNode, u64> {
    fn pack(self: RTreeNode) -> u64 {
        ((self.x_min.into() * TWO_POW_47))
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

    fn unpack(self: u64) -> RTreeNode {
        let x_min: u16 = ((self / TWO_POW_47) & MASK_15).try_into().unwrap();
        let y_min: u16 = ((self / TWO_POW_32) & MASK_15).try_into().unwrap();
        let x_max: u16 = ((self / TWO_POW_17) & MASK_15).try_into().unwrap();
        let y_max: u16 = ((self / TWO_POW_2) & MASK_15).try_into().unwrap();
        let is_leaf: bool = ((self / 2) & MASK_1) == 1;
        let is_area: bool = ((self) & MASK_1) == 1;

        RTreeNode { x_min, y_min, x_max, y_max, is_leaf, is_area }
    }
}

