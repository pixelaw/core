use starknet::{ContractAddress, ClassHash};

#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct QueueItem {
    #[key]
    pub id: felt252,
    pub valid: bool
}
