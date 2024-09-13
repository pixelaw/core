use starknet::{ContractAddress, ClassHash};

#[derive(Copy, Drop, Serde)]
pub struct PixelUpdate {
    pub x: u32,
    pub y: u32,
    pub color: Option<u32>,
    pub owner: Option<ContractAddress>,
    pub app: Option<ContractAddress>,
    pub text: Option<felt252>,
    pub timestamp: Option<u64>,
    pub action: Option<felt252>
}

#[derive(Copy, Drop, Serde, PartialEq)]
#[dojo::model(namespace: "pixelaw", nomapping: true)]
pub struct Pixel {
    // System properties
    #[key]
    pub x: u32,
    #[key]
    pub y: u32,
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
