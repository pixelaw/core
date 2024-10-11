use pixelaw::core::utils::{
    MASK_16, MASK_32, MASK_64, MASK_96, POW_2_16, POW_2_30, POW_2_31, POW_2_32, POW_2_48, POW_2_64,
    POW_2_96, MAX_DIMENSION
};
use starknet::{ContractAddress, ClassHash};

#[derive(Copy, Drop, Serde, PartialEq)]
#[dojo::model(namespace: "pixelaw", nomapping: true)]
pub struct Pixel {
    // System properties
    #[key]
    pub x: u16, // only 15 bits used, to a max of 32767
    #[key]
    pub y: u16, // only 15 bits used, to a max of 32767
    // User-changeable properties
    pub app: ContractAddress,
    pub color: u32,
    pub created_at: u64,
    pub updated_at: u64,
    pub timestamp: u64,
    pub owner: ContractAddress,
    pub text: felt252,
    pub action: felt252
}

#[derive(Copy, Drop, Serde)]
pub struct PixelUpdate {
    pub x: u16, // only 15 bits used, to a max of 32767
    pub y: u16, // only 15 bits used, to a max of 32767
    pub color: Option<u32>,
    pub owner: Option<ContractAddress>,
    pub app: Option<ContractAddress>,
    pub text: Option<felt252>,
    pub timestamp: Option<u64>,
    pub action: Option<felt252>
}

pub trait PixelUpdateTrait<PixelUpdate> {
    fn validate(self: PixelUpdate);
}

pub impl PixelUpdateTraitImpl of PixelUpdateTrait<PixelUpdate> {
    fn validate(self: PixelUpdate) {
        assert(self.x <= MAX_DIMENSION && self.y <= MAX_DIMENSION, 'position overflow');
    }
}
