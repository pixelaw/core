use core::{poseidon::poseidon_hash_span};
use dojo::event::{Event};
use dojo::model::{ModelStorage};
use dojo::world::world::Event as WorldEvent;
use pixelaw::apps::snake::{ISnakeActionsDispatcherTrait};
use pixelaw::core::{
    actions::{IActionsDispatcherTrait}, events::{QueueScheduled}, models::pixel::{Pixel},
    utils::{DefaultParameters, Direction, Position, SNAKE_MOVE_ENTRYPOINT},
};
use pixelaw_testing::helpers::{
    drop_all_events, set_caller, setup_apps_initialized, setup_core_initialized,
};
use starknet::{testing::{set_block_timestamp}};
const SPAWN_PIXEL_ENTRYPOINT: felt252 =
    0x01c199924ae2ed5de296007a1ac8aa672140ef2a973769e4ad1089829f77875a;

#[test]
fn test_process_queue() {
    let (world, core_actions, _player_1, _player_2) = setup_core_initialized();
    let position = Position { x: 0, y: 0 };

    let mut calldata: Array<felt252> = ArrayTrait::new();
    calldata.append('snake');
    position.serialize(ref calldata);
    calldata.append('snake');
    calldata.append(0);
    let id = poseidon_hash_span(
        array![
            0.into(),
            core_actions.contract_address.into(),
            SPAWN_PIXEL_ENTRYPOINT.into(),
            poseidon_hash_span(calldata.span()),
        ]
            .span(),
    );

    core_actions
        .process_queue(
            id, 0, core_actions.contract_address.into(), SPAWN_PIXEL_ENTRYPOINT, calldata.span(),
        );

    let pixel: Pixel = world.read_model((position.x, position.y));

    // check timestamp
    assert(pixel.created_at == starknet::get_block_timestamp(), 'incorrect timestamp.created_at');
    assert(pixel.updated_at == starknet::get_block_timestamp(), 'incorrect timestamp.updated_at');
    assert(pixel.x == position.x, 'incorrect timestamp.x');
    assert(pixel.y == position.y, 'incorrect timestamp.y');
}


#[test]
fn test_queue_full() {
    let (world, core_actions, player_1, _player_2) = setup_core_initialized();
    let (_, snake_actions, _player_actions) = setup_apps_initialized(world);

    let SNAKE_COLOR = 0xFF00FF;

    set_caller(player_1);
    let position = Position { x: 234, y: 432 };

    let event_contract = world.dispatcher.contract_address;

    // Pop all the previous events from the log so only the following one will be there
    drop_all_events(event_contract);

    let timestamp = 1729297000;
    set_block_timestamp(timestamp);

    snake_actions
        .interact(
            DefaultParameters {
                player_override: Option::None,
                system_override: Option::None,
                area_hint: Option::None,
                position,
                color: SNAKE_COLOR,
            },
            Direction::Right,
        );

    // Pop the 3 previous events we're not handling right now
    let _ = starknet::testing::pop_log_raw(event_contract); // Store Snake model
    let _ = starknet::testing::pop_log_raw(event_contract); // Store Segment model
    let _ = starknet::testing::pop_log_raw(event_contract); // Store Pixel model

    // Prep the expected event struct
    let called_system = snake_actions.contract_address;
    let selector = SNAKE_MOVE_ENTRYPOINT;
    let calldata: Span<felt252> = array![player_1.into()].span();
    let id = poseidon_hash_span(
        array![timestamp.into(), called_system.into(), selector, poseidon_hash_span(calldata)]
            .span(),
    );

    let event = starknet::testing::pop_log::<WorldEvent>(world.dispatcher.contract_address);
    assert(event.is_some(), 'no event');

    if let WorldEvent::EventEmitted(event) = event.unwrap() {
        assert(
            event.selector == Event::<QueueScheduled>::selector(world.namespace_hash),
            'bad event selector',
        );

        let _expected_scheduled_event = QueueScheduled {
            id, timestamp, called_system, selector, calldata,
        };
        assert(event.system_address == core_actions.contract_address, 'bad system address');
        assert(*event.keys.at(0) == id, 'bad keys');
        // TODO complete test
    //   assert(event.values == [3, 4].span(), 'bad values');
    } else {
        core::panic_with_felt252('no EventEmitted event');
    }

    // Pop all the previous events from the log so only the following one will be there
    drop_all_events(event_contract);
    core_actions.process_queue(id, timestamp, called_system, selector, calldata);

    let _log_0 = starknet::testing::pop_log_raw(event_contract); // store existing segment
    let _log_1 = starknet::testing::pop_log_raw(event_contract); // store new segment
    let _log_2 = starknet::testing::pop_log_raw(event_contract); // Store Pixel model new segment
    let _log_3 = starknet::testing::pop_log_raw(event_contract); // Store Pixel model new segment
    let _log_4 = starknet::testing::pop_log_raw(event_contract); // ?
    let _log_5 = starknet::testing::pop_log_raw(event_contract); // store pixel
    let _log_6 = starknet::testing::pop_log_raw(event_contract); // delete segment?
    // let _log_7 = starknet::testing::pop_log_raw(event_contract); // processed

    let event = starknet::testing::pop_log::<WorldEvent>(world.dispatcher.contract_address);
    assert(event.is_some(), 'no event');
    // TODO fix the test: confirm the QueueItem was deleted
// if let WorldEvent::EventEmitted(event) = event.unwrap() {
//     let _expected_processed_event = QueueProcessed { id, result: 0 }; // Fixme: result
//     assert(
//         event.selector == Event::<QueueProcessed>::selector(world.namespace_hash),
//         'bad event selector',
//     );
//     // TODO complete test
//     assert(event.system_address == core_actions.contract_address, 'bad system address');
//     assert(*event.keys.at(0) == id, 'bad keys');
//     //   assert(event.values == [3, 4].span(), 'bad values');
// } else {
//     core::panic_with_felt252('no EventEmitted event');
// }
}

