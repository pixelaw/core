use core::poseidon::poseidon_hash_span;
use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
use pixelaw::core::models::area::{
    BoundsTraitImpl, RTreeTraitImpl, ROOT_ID, RTreeNode, RTree, Area, RTreeNodePackableImpl
};
use pixelaw::core::models::permissions::{Permission, Permissions};
use pixelaw::core::models::pixel::{Pixel, PixelUpdate};
use pixelaw::core::models::queue::QueueItem;

use pixelaw::core::models::registry::{App, AppName, CoreActionsAddress, Instruction};
use pixelaw::core::utils::{get_core_actions_address, Position, MAX_DIMENSION, Bounds};
use pixelaw::core::utils;
use starknet::{
    ContractAddress, get_caller_address, get_contract_address, get_tx_info, contract_address_const,
    syscalls::{call_contract_syscall},
};

pub fn update_permission(world: IWorldDispatcher, app_key: felt252, permission: Permission,) {
    let caller_address = get_caller_address();

    // TODO maybe check that the caller is indeed an app?

    // Retrieve the App of the `for_system`
    let allowed_app = get!(world, app_key, (AppName));
    let allowed_app = allowed_app.system;

    set!(world, Permissions { allowing_app: caller_address, allowed_app, permission });
}

pub fn has_write_access(
    world: IWorldDispatcher,
    for_player: ContractAddress,
    for_system: ContractAddress,
    pixel: Pixel,
    pixel_update: PixelUpdate,
    area_id_hint: Option<u64>
) -> bool {
    // The originator of the transaction
    let caller_account = get_tx_info().unbox().account_contract_address;

    // The address making this call. Could be a System of an App
    let caller_address = get_caller_address();

    // Check if the pixel belongs to an Area
    let area_result = super::area::find_area_for_position(
        world, Position { x: pixel.x, y: pixel.y }, area_id_hint
    );

    if let Option::Some(area) = area_result {
        if area.owner == caller_account || area.owner == contract_address_const::<0>() {
            return true;
        } else if caller_account == caller_address {
            // The caller is not a System, and not owner, so no reason to keep looking.
            return false;
        }
    }

    // Can we grant based on direct ownership?
    // If caller is owner or not owned by anyone, allow
    if pixel.owner == caller_account || pixel.owner == contract_address_const::<0>() {
        return true;
    } else if caller_account == caller_address {
        // The caller is not a System, and not owner, so no reason to keep looking.
        return false;
    }
    // Deal with Scheduler calling

    // The `caller_address` is a System, let's see if it has access

    // Retrieve the App of the calling System
    let caller_app = get!(world, caller_address, (App));

    // TODO: Decide whether an App by default has write on a pixel with same App

    // If it's the same app, always allow.
    // It's the responsibility of the App developer to ensure separation of ownership
    if pixel.app == caller_app.system {
        return true;
    }

    let permissions = get!(world, (pixel.app, caller_app.system).into(), (Permissions));

    if pixel_update.app.is_some() && !permissions.permission.app {
        return false;
    };
    if pixel_update.color.is_some() && !permissions.permission.color {
        return false;
    };
    if pixel_update.owner.is_some() && !permissions.permission.owner {
        return false;
    };
    if pixel_update.text.is_some() && !permissions.permission.text {
        return false;
    };
    if pixel_update.timestamp.is_some() && !permissions.permission.timestamp {
        return false;
    };
    if pixel_update.action.is_some() && !permissions.permission.action {
        return false;
    };

    // Since we checked all the permissions and no assert fired, we can return true
    true
}
