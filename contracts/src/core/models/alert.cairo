use starknet::{ContractAddress, ClassHash};

#[derive(Model, Copy, Drop, Serde)]
struct Alert {
    // System properties
    #[key]
    x: u64,
    #[key]
    y: u64,
    alert: felt252,

}

