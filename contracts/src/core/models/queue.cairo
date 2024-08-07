use starknet::{ContractAddress, ClassHash};

#[derive(Copy, Drop, Serde)]
#[dojo::model]
struct QueueItem {
    #[key]
    id: felt252,
    valid: bool
}
