use starknet::{ContractAddress, ClassHash};

#[derive(Copy, Drop, Serde)]
#[dojo::model(namespace: "pixelaw", nomapping: true)]
pub struct QueueItem {
    #[key]
    pub id: felt252,
    pub valid: bool
}
