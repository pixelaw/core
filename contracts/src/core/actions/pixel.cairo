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
    let app_caller = get!(world, for_system, (App));

    // If the pixel is assigned an app contract, try calling the hook
    if current_pixel_app != contract_address_const::<0>() {
        call_hook(
            world, current_pixel_app, ON_PRE_UPDATE_HOOK, pixel_update, app_caller, for_player
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
            world, current_pixel_app, ON_POST_UPDATE_HOOK, pixel_update, app_caller, for_player
        );
    }
}
fn call_hook(
    world: IWorldDispatcher,
    contract_address: ContractAddress,
    entrypoint: felt252,
    pixel_update: PixelUpdate,
    app_caller: App,
    for_player: ContractAddress
) {
    let mut calldata: Array<felt252> = array![];

    pixel_update.add_to_calldata(ref calldata);
    app_caller.add_to_calldata(ref calldata);
    calldata.append(for_player.into());

    let result = call_contract_syscall(contract_address, entrypoint, calldata.span());
    // println!("result {:?}", result);
    if result.is_err() {
        if let Option::Some(err) = result.err() {
            // Panic on any other error than ENTRYPOINT_NOT_FOUND (which means hook wasnt enabled)
            assert(*err.at(0) == 'ENTRYPOINT_NOT_FOUND', *err.at(0));
        }
    }
}
