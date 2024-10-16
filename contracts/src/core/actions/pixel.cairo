use core::poseidon::poseidon_hash_span;
use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
use pixelaw::core::models::area::{
    BoundsTraitImpl, RTreeTraitImpl, ROOT_ID, RTreeNode, RTree, Area, RTreeNodePackableImpl
};
use pixelaw::core::models::permissions::{Permission, Permissions};
use pixelaw::core::models::pixel::{Pixel, PixelUpdate, PixelUpdateTrait};
use pixelaw::core::models::queue::QueueItem;

use pixelaw::core::models::registry::{
    AppCalldataTrait, App, AppName, CoreActionsAddress, Instruction
};
use pixelaw::core::utils::{
    ON_PRE_UPDATE_HOOK, ON_POST_UPDATE_HOOK, starknet_keccak, get_core_actions_address, Position,
    MAX_DIMENSION, Bounds
};
use pixelaw::core::utils;
use starknet::{
    ContractAddress, get_caller_address, get_contract_address, get_tx_info, contract_address_const,
    syscalls::{call_contract_syscall},
};


pub fn update_pixel(
    world: IWorldDispatcher,
    for_player: ContractAddress,
    for_system: ContractAddress,
    pixel_update: PixelUpdate,
) {
    pixel_update.validate();

    let mut pixel = get!(world, (pixel_update.x, pixel_update.y), (Pixel));

    assert!(
        super::permissions::has_write_access(
            world, for_player, for_system, pixel, pixel_update, Option::None
        ),
        "No access!"
    );
    let current_pixel_app = pixel.app;
    let mut app_caller = get!(world, for_system, (App));
    let mut pixel_update = pixel_update;
    let mut for_player = for_player;

    // If the pixel is assigned an app contract, try calling the hook
    if current_pixel_app != contract_address_const::<0>() {
        call_hook(
            world,
            current_pixel_app,
            ON_PRE_UPDATE_HOOK,
            ref pixel_update,
            ref app_caller,
            ref for_player
        );
    }

    // If the pixel has no owner set yet, do that now.
    if pixel.created_at == 0 {
        let now = starknet::get_block_timestamp();

        pixel.created_at = now;
        pixel.updated_at = now;
    }

    if pixel_update.app.is_some() {
        pixel.app = pixel_update.app.unwrap();
    }

    if pixel_update.color.is_some() {
        pixel.color = pixel_update.color.unwrap();
    }

    if pixel_update.owner.is_some() {
        pixel.owner = pixel_update.owner.unwrap();
    }

    if pixel_update.text.is_some() {
        pixel.text = pixel_update.text.unwrap();
    }

    if pixel_update.timestamp.is_some() {
        pixel.timestamp = pixel_update.timestamp.unwrap();
    }

    if pixel_update.action.is_some() {
        pixel.action = pixel_update.action.unwrap()
    }

    // Set Pixel
    set!(world, (pixel));

    if current_pixel_app != contract_address_const::<0>() {
        call_hook(
            world,
            current_pixel_app,
            ON_POST_UPDATE_HOOK,
            ref pixel_update,
            ref app_caller,
            ref for_player
        );
    }
}
fn call_hook(
    world: IWorldDispatcher,
    contract_address: ContractAddress,
    entrypoint: felt252,
    ref pixel_update: PixelUpdate,
    ref app_caller: App,
    ref for_player: ContractAddress
) {
    let mut calldata: Array<felt252> = array![];

    pixel_update.add_to_calldata(ref calldata);
    app_caller.add_to_calldata(ref calldata);
    calldata.append(for_player.into());

    let out = call_contract_syscall(contract_address, entrypoint, calldata.span());

    if out.is_err() {
        if let Option::Some(err) = out.err() {
            // Panic on any other error than ENTRYPOINT_NOT_FOUND (which means hook wasnt enabled)
            assert(*err.at(0) == 'ENTRYPOINT_NOT_FOUND', *err.at(0));
        }
    } else {
        // assemble the output from the raw values
        // Ok([123, 321, 0, 2936078335, 0, 4919, 0,
        // 599683841819055043807870040764827848153960037270322986500076169224417352594, 1, 1, 1,
        // 599683841819055043807870040764827848153960037270322986500076169224417352594, 4919])

        let (new_pixel_update, new_app_caller, new_for_player) = parseHookOutput(out.unwrap());
        pixel_update = new_pixel_update;

        if app_caller.system != new_app_caller {
            app_caller = get!(world, new_app_caller, (App));
        }

        for_player = new_for_player;
    }
}

fn parseHookOutput(data: Span<felt252>) -> (PixelUpdate, ContractAddress, ContractAddress) {
    let mut color: Option<u32> = Option::None;
    let mut owner: Option<ContractAddress> = Option::None;
    let mut app: Option<ContractAddress> = Option::None;
    let mut text: Option<felt252> = Option::None;
    let mut timestamp: Option<u64> = Option::None;
    let mut action: Option<felt252> = Option::None;

    let x: u16 = data.at(0).deref().try_into().unwrap();
    let y: u16 = data.at(1).deref().try_into().unwrap();

    let mut i = 2;

    if data.at(i).deref() == 0 {
        i += 1;
        color = Option::Some(data.at(i).deref().try_into().unwrap());
    }
    i += 1;
    if data.at(i).deref() == 0 {
        i += 1;
        owner = Option::Some(data.at(i).deref().try_into().unwrap());
    }
    i += 1;
    if data.at(i).deref() == 0 {
        i += 1;
        app = Option::Some(data.at(i).deref().try_into().unwrap());
    }
    i += 1;
    if data.at(i).deref() == 0 {
        i += 1;
        text = Option::Some(data.at(i).deref().try_into().unwrap());
    }
    i += 1;
    if data.at(i).deref() == 0 {
        i += 1;
        timestamp = Option::Some(data.at(i).deref().try_into().unwrap());
    }
    i += 1;
    if data.at(i).deref() == 0 {
        i += 1;
        action = Option::Some(data.at(i).deref().try_into().unwrap())
    }

    i += 1;
    let app_caller: ContractAddress = data.at(i).deref().try_into().unwrap();

    i += 1;
    let player_caller: ContractAddress = data.at(i).deref().try_into().unwrap();

    (PixelUpdate { x, y, color, owner, app, text, timestamp, action }, app_caller, player_caller)
}
