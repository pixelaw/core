use core::poseidon::poseidon_hash_span;
use dojo::model::{ModelStorage};
use dojo::world::storage::WorldStorage;
use pixelaw::core::events::{QueueScheduled};
use pixelaw::core::models::area::{BoundsTraitImpl, RTreeNodePackableImpl, RTreeTraitImpl};
use pixelaw::core::models::queue::{QueueItem};
use starknet::{ContractAddress, syscalls::{call_contract_syscall}};

pub fn schedule_queue(
    ref world: WorldStorage,
    timestamp: u64,
    called_system: ContractAddress,
    selector: felt252,
    calldata: Span<felt252>,
) -> QueueScheduled {
    // TODO: Review security

    // hash the call and store the hash for verification
    let id = poseidon_hash_span(
        array![timestamp.into(), called_system.into(), selector, poseidon_hash_span(calldata)]
            .span(),
    );

    let queueItem = QueueItem { id, valid: true };
    world.write_model(@queueItem);

    // Emit the event, so an external scheduler can pick it up
    QueueScheduled { id, timestamp, called_system, selector, calldata: calldata }
}


pub fn process_queue(
    ref world: WorldStorage,
    id: felt252,
    timestamp: u64,
    called_system: ContractAddress,
    selector: felt252,
    calldata: Span<felt252>,
) {
    // A quick check on the timestamp so we know it's not too early for this one
    assert!(timestamp <= starknet::get_block_timestamp(), "timestamp still in the future");

    // Recreate the id to check the integrity
    let calculated_id = poseidon_hash_span(
        array![timestamp.into(), called_system.into(), selector, poseidon_hash_span(calldata)]
            .span(),
    );

    // Only valid when the queue item was found by the hash
    assert!(calculated_id == id, "Invalid Id");

    // Make the call itself
    let _result = call_contract_syscall(called_system, selector, calldata);

    // TODO handle the result if that makes sense.

    let queueItem: QueueItem = world.read_model(id);

    world.erase_model(@queueItem);
}
