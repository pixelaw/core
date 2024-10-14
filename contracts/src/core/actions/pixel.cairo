use core::poseidon::poseidon_hash_span;
use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
use pixelaw::core::models::area::{
    BoundsTraitImpl, RTreeTraitImpl, ROOT_ID, RTreeNode, RTree, Area, RTreeNodePackableImpl
};
use pixelaw::core::models::permissions::{Permission, Permissions};
use pixelaw::core::models::pixel::{Pixel, PixelUpdate, PixelUpdateTrait};
use pixelaw::core::models::queue::QueueItem;

use pixelaw::core::models::registry::{App, AppName, CoreActionsAddress, Instruction};
use pixelaw::core::traits::{IHooksDispatcher, IHooksDispatcherTrait};
use pixelaw::core::utils::{get_core_actions_address, Position, MAX_DIMENSION, Bounds};
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

    let old_pixel_app = pixel.app;

    if old_pixel_app != contract_address_const::<0>() {
        let interoperable_app = IHooksDispatcher { contract_address: old_pixel_app };
        let app_caller = get!(world, for_system, (App));
        interoperable_app.on_pre_update(pixel_update, app_caller, for_player);
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

    if old_pixel_app != contract_address_const::<0>() {
        let interoperable_app = IHooksDispatcher { contract_address: old_pixel_app };
        let app_caller = get!(world, for_system, (App));
        interoperable_app.on_post_update(pixel_update, app_caller, for_player);
    }
}
