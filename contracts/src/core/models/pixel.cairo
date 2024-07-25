use starknet::{ContractAddress, ClassHash};

#[derive(Copy, Drop, Serde)]
struct PixelUpdate {
    x: u32,
    y: u32,
    color: Option<u32>,
    owner: Option<ContractAddress>,
    app: Option<ContractAddress>,
    text: Option<felt252>,
    timestamp: Option<u64>,
    action: Option<felt252>
}

#[derive(Copy, Drop, Serde)]
#[dojo::model]
struct Pixel {
    // System properties
    #[key]
    x: u32,
    #[key]
    y: u32,
    // User-changeable properties
    app: ContractAddress,
    color: u32,
    created_at: u64,
    updated_at: u64,
    timestamp: u64,
    owner: ContractAddress,
    text: felt252,
    action: felt252
}

