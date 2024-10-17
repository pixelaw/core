use pixelaw::core::utils::{
    MASK_16, MASK_32, MASK_64, MASK_96, POW_2_16, POW_2_30, POW_2_31, POW_2_32, POW_2_48, POW_2_64,
    POW_2_96, MAX_DIMENSION
};
use starknet::{ContractAddress, ClassHash};

#[derive(Debug, Copy, Drop, Serde, PartialEq)]
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

#[derive(Debug, Default, Copy, Drop, Serde)]
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
    fn add_to_calldata(self: PixelUpdate, ref calldata: Array<felt252>);
}

pub impl PixelUpdateTraitImpl of PixelUpdateTrait<PixelUpdate> {
    fn validate(self: PixelUpdate) {
        assert(self.x <= MAX_DIMENSION && self.y <= MAX_DIMENSION, 'position overflow');
    }

    fn add_to_calldata(self: PixelUpdate, ref calldata: Array<felt252>) {
        calldata.append(self.x.into());
        calldata.append(self.y.into());
        match self.color {
            Option::Some(value) => {
                calldata.append(0.into());
                calldata.append(value.into());
            },
            Option::None => { calldata.append(1.into()); },
        }
        match self.owner {
            Option::Some(value) => {
                calldata.append(0.into());
                calldata.append(value.into());
            },
            Option::None => { calldata.append(1.into()); },
        }
        match self.app {
            Option::Some(value) => {
                calldata.append(0.into());
                calldata.append(value.into());
            },
            Option::None => { calldata.append(1.into()); },
        }
        match self.text {
            Option::Some(value) => {
                calldata.append(0.into());
                calldata.append(value.into());
            },
            Option::None => { calldata.append(1.into()); },
        }
        match self.timestamp {
            Option::Some(value) => {
                calldata.append(0.into());
                calldata.append(value.into());
            },
            Option::None => { calldata.append(1.into()); },
        }
        match self.action {
            Option::Some(value) => {
                calldata.append(0.into());
                calldata.append(value.into());
            },
            Option::None => { calldata.append(1.into()); },
        }
    }
}
