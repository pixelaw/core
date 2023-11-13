use starknet::{ContractAddress, ClassHash};

#[derive(Model, Copy, Drop, Serde)]
struct QueueItem {
    #[key]
    id: felt252,
    valid: bool
}


