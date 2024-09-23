use core::starknet::storage_access::StorePacking;
use starknet::{ContractAddress, ClassHash};
use pixelaw::core::utils::{
    MASK_16, MASK_32, MASK_64, MASK_96, POW_2_16, POW_2_30, POW_2_31, POW_2_32, POW_2_48, POW_2_64,
    POW_2_96, MAX_DIMENSION
};
use pixelaw::core::utils::{min, max, Bounds, Position};

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

pub const ROOT_RTREENODE_EMPTY: RTreeNode =
    RTreeNode {
        bounds: Bounds { x_min: 0, y_min: 0, x_max: MAX_DIMENSION, y_max: MAX_DIMENSION },
        is_leaf: true,
        is_area: false
    };

pub const ROOT_RTREENODE: RTreeNode =
    RTreeNode {
        bounds: Bounds { x_min: 0, y_min: 0, x_max: MAX_DIMENSION, y_max: MAX_DIMENSION },
        is_leaf: false,
        is_area: false
    };

pub const FIRST_RTREENODE: RTreeNode =
    RTreeNode {
        bounds: Bounds { x_min: 0, y_min: 0, x_max: 10, y_max: 10 }, is_leaf: true, is_area: false
    };

pub const ROOT_EMPTY_ID: u64 = 4294967294; // for ROOT_RTREENODE_EMPTY
pub const ROOT_ID: u64 = 4294967292; // for ROOT_RTREENODE
pub const FIRST_ID: u64 = 1310762; // for FIRST_RTREENODE


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
    pub bounds: Bounds,
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

pub trait RTreeTrait<RTree> {
    fn get_node(self: RTree) -> RTreeNode;
    fn get_children(self: RTree) -> Span<u64>;
    fn add_child_id(self: RTree, child_id: u64) -> felt252;
    fn replace_child_id(self: RTree, child_id_existing: u64, child_id_new: u64) -> felt252;
    // fn remove_child_id(child_id: u64) -> felt252;
// fn change_to_leaf(child_id: u64) -> felt252;
// fn change_to_nonleaf(child_id: u64) -> felt252;
}

pub impl RTreeTraitImpl of RTreeTrait<RTree> {
    fn get_node(self: RTree) -> RTreeNode {
        self.id.unpack()
    }

    fn get_children(self: RTree) -> Span<u64> {
        self.children.unpack()
    }

    fn add_child_id(self: RTree, child_id: u64) -> felt252 {
        let children: Span<u64> = self.children.unpack();
        assert_lt!(children.len(), 4);

        let mut arr: Array<u64> = children.into();
        arr.append(child_id);

        let new_span: Span<u64> = arr.span();
        new_span.pack()
    }

    // Naive implementation of replacement
    fn replace_child_id(self: RTree, child_id_existing: u64, child_id_new: u64) -> felt252{
        let children: Span<u64> = self.children.unpack();

        let mut output: Array<u64> = array![];

        for child_id in children {
            if *child_id != child_id_existing {
                output.append(*child_id);
            }
        };
        output.append(child_id_new);
        output.span().pack()

    }
}

pub trait BoundsTrait<Bounds> {
    fn area(self: Bounds) -> u32;
    fn contains(self: Bounds, position: Position) -> bool;
    fn combine(self: Bounds, other: Bounds) -> Bounds;
}

pub impl BoundsTraitImpl of BoundsTrait<Bounds> {
    fn area(self: Bounds) -> u32 {
        (self.x_max - self.x_min).into() * (self.y_max - self.y_min).into()
    }
    fn contains(self: Bounds, position: Position) -> bool {
        position.x >= self.x_min
            && position.x <= self.x_max
            && position.y >= self.y_min
            && position.y <= self.y_max
    }
    fn combine(self: Bounds, other: Bounds) -> Bounds {
        Bounds {
            x_min: min(self.x_min, other.x_min),
            y_min: min(self.y_min, other.y_min),
            x_max: max(self.x_max, other.x_max),
            y_max: max(self.y_max, other.y_max)
        }
    }
}

pub trait Packable<T, PackedT> {
    fn pack(self: T) -> PackedT;
    fn unpack(self: PackedT) -> T;
}


pub impl ChildrenPackableImpl of Packable<Span<u64>, felt252> {
    fn pack(self: Span<u64>) -> felt252 {
        let mut out: u256 = 0;

        if self.len() > 0 {
            out += (*self[0]).try_into().unwrap();
            if self.len() > 1 {
                out += (*self[1]).try_into().unwrap() * TWO_POW_62;
                if self.len() > 2 {
                    out += (*self[2]).try_into().unwrap() * TWO_POW_124;
                    if self.len() > 3 {
                        out += (*self[3]).try_into().unwrap() * TWO_POW_188;
                    }
                }
            }
        }

        out.try_into().unwrap()
    }

    fn unpack(self: felt252) -> Span<u64> {
        let val: u256 = self.into();
        let mut out: Array<u64> = array![];

        let val1 = (val & MASK_62.into()).try_into().unwrap();

        if val1 > 0 {
            out.append(val1);
            let val2 = ((val / TWO_POW_62.into()) & MASK_62.into()).try_into().unwrap();
            if val2 > 0 {
                out.append(val2);
                let val3 = ((val / TWO_POW_124.into()) & MASK_62.into()).try_into().unwrap();
                if val3 > 0 {
                    out.append(val3);
                    let val4 = ((val / TWO_POW_188.into()) & MASK_62.into()).try_into().unwrap();
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
        ((self.bounds.x_min.into() * TWO_POW_47))
            + (self.bounds.y_min.into() * TWO_POW_32)
            + (self.bounds.x_max.into() * TWO_POW_17)
            + (self.bounds.y_max.into() * TWO_POW_2)
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
        let bounds = Bounds {
            x_min: ((self / TWO_POW_47) & MASK_15).try_into().unwrap(),
            y_min: ((self / TWO_POW_32) & MASK_15).try_into().unwrap(),
            x_max: ((self / TWO_POW_17) & MASK_15).try_into().unwrap(),
            y_max: ((self / TWO_POW_2) & MASK_15).try_into().unwrap()
        };

        let is_leaf: bool = ((self / 2) & MASK_1) == 1;
        let is_area: bool = ((self) & MASK_1) == 1;

        RTreeNode { bounds, is_leaf, is_area }
    }
}

