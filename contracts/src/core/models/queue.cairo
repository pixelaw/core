use starknet::{ContractAddress, ClassHash};

#[derive(Copy, Drop, Serde)]
#[dojo::model(namespace: "pixelaw", nomapping: true)]
pub struct QueueItem {
    #[key]
    id: felt252,
    valid: bool
}
