use dojo::model::{ModelStorage};
use dojo::world::storage::WorldStorage;

//use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
use pixelaw::core::models::area::{Area, BoundsTraitImpl, RTreeNodePackableImpl, RTreeTraitImpl};
use pixelaw::core::models::pixel::{Pixel, PixelUpdate, PixelUpdateResult, PixelUpdateTrait};


use pixelaw::core::models::registry::{App, AppCalldataTrait};
use pixelaw::core::utils::{
    ON_POST_UPDATE_HOOK, ON_PRE_UPDATE_HOOK, Position, get_core_actions_address,
};
use starknet::{
    ContractAddress, contract_address_const, get_contract_address, get_tx_info,
    syscalls::{call_contract_syscall},
};


pub fn can_update_pixel(
    ref world: WorldStorage,
    for_player: ContractAddress,
    for_system: ContractAddress,
    pixel: Pixel,
    pixel_update: PixelUpdate,
    area_id_hint: Option<u64>,
    allow_modify: bool,
) -> PixelUpdateResult {
    // 1. Is there an owner of pixel or area?
    if pixel.owner == for_player {
        return PixelUpdateResult::Ok(pixel_update);
    }

    // Load the area
    let area_result = super::area::find_area_for_position(
        ref world, Position { x: pixel.x, y: pixel.y }, area_id_hint,
    );
    if let Option::Some(area) = area_result {
        // Return true if the player is owner of the area
        if area.owner == for_player {
            return PixelUpdateResult::Ok(pixel_update);
        }
        // Return true if neither area nor pixel have an owner
        if area.owner == contract_address_const::<0>()
            && pixel.owner == contract_address_const::<0>() {
            return PixelUpdateResult::Ok(pixel_update);
        }
        // Return true if there is no area and pixel has no owner
    } else if pixel.owner == contract_address_const::<0>() {
        return PixelUpdateResult::Ok(pixel_update);
    }

    // Get the pixel_app from either the pixel or maybe the area
    let pixel_app = determine_app(pixel, area_result);

    // Return if the pixel has no app (hook is not going to work)
    if pixel_app == contract_address_const::<0>() {
        return PixelUpdateResult::NotAllowed(pixel_update);
    }

    // At this point its likely that the pixel and/or area have a different owner
    // We can still try to call the hook on the pixel's App and see if that allows anything

    // Retrieve the App for the calling system
    let mut caller_app: App = world.read_model(for_system);

    // 2. Return the result of the hook call
    call_on_pre_update(ref world, pixel.app, pixel_update, caller_app, for_player, allow_modify)
}

pub fn update_pixel(
    ref world: WorldStorage,
    for_player: ContractAddress,
    for_system: ContractAddress,
    pixel_update: PixelUpdate,
    area_id_hint: Option<u64>,
    allow_modify: bool,
) -> PixelUpdateResult {
    // Check if the pixel_update values are valid (x and y)
    pixel_update.validate();

    // validate that for_player is not different from the actual caller unless the
    // calling contract is the core.
    // TODO is there an exploit by doing this through a hook then?
    validate_callers(ref world, for_player);

    // Load the pixel
    let mut pixel: Pixel = world.read_model((pixel_update.x, pixel_update.y));

    let update_result = can_update_pixel(
        ref world, for_player, for_system, pixel, pixel_update, area_id_hint, allow_modify,
    );

    // println!("update_pixel {:?}", update_result);
    let new_pixel_update = match update_result {
        PixelUpdateResult::Error((_, _)) => { return update_result; },
        PixelUpdateResult::NotAllowed(_) => { return update_result; },
        PixelUpdateResult::Ok(result) => result,
    };

    apply_pixel_update(ref pixel, new_pixel_update);

    // If the pixel has no owner set yet, do that now.
    if pixel.created_at == 0 {
        let now = starknet::get_block_timestamp();

        pixel.created_at = now;
        pixel.updated_at = now;
    }
    // Store the Pixel
    world.write_model(@pixel);

    // Call on_post_update if the pixel has an app
    if pixel.app != contract_address_const::<0>() {
        let mut caller_app: App = world.read_model(for_system);

        if let Result::Err(err) =
            call_on_post_update(ref world, pixel.app, pixel_update, caller_app, for_player) {
            return PixelUpdateResult::Error((pixel_update, err.into()));
        }
    }

    PixelUpdateResult::Ok(new_pixel_update)
}

fn apply_pixel_update(ref pixel: Pixel, pixel_update: PixelUpdate) {
    if let Option::Some(app) = pixel_update.app {
        pixel.app = app;
    }

    if let Option::Some(color) = pixel_update.color {
        pixel.color = color;
    }

    if let Option::Some(owner) = pixel_update.owner {
        pixel.owner = owner;
    }

    if let Option::Some(text) = pixel_update.text {
        pixel.text = text;
    }

    if let Option::Some(timestamp) = pixel_update.timestamp {
        pixel.timestamp = timestamp;
    }

    if let Option::Some(action) = pixel_update.action {
        pixel.action = action;
    }
}

fn call_on_pre_update(
    ref world: WorldStorage,
    contract_address: ContractAddress,
    pixel_update: PixelUpdate,
    app_caller: App,
    for_player: ContractAddress,
    allow_modify: bool,
) -> PixelUpdateResult {
    let mut calldata: Array<felt252> = array![];
    let mut result = PixelUpdateResult::Ok(pixel_update);

    pixel_update.add_to_calldata(ref calldata);
    app_caller.add_to_calldata(ref calldata);
    calldata.append(for_player.into());

    // println!("call_on_pre_update {:?}", pixel_update);
    let out = call_contract_syscall(contract_address, ON_PRE_UPDATE_HOOK, calldata.span());

    if out.is_err() {
        if let Option::Some(err) = out.err() {
            if *err.at(0) != 'ENTRYPOINT_NOT_FOUND' && *err.at(0) != 'CONTRACT_NOT_DEPLOYED' {
                result = PixelUpdateResult::Error((pixel_update, *err.at(0)));
            }
        }
    } else {
        if let Option::Some(returned_update) = parseHookOutput(out.unwrap()) {
            if returned_update == pixel_update
                || (returned_update != pixel_update && !allow_modify) {
                return PixelUpdateResult::Ok(returned_update);
            } else {
                return PixelUpdateResult::NotAllowed(pixel_update);
            }
        } else {
            return PixelUpdateResult::NotAllowed(pixel_update);
        }
    }
    result
}

fn call_on_post_update(
    ref world: WorldStorage,
    contract_address: ContractAddress,
    pixel_update: PixelUpdate,
    app_caller: App,
    for_player: ContractAddress,
) -> Result<(), felt252> {
    let mut calldata: Array<felt252> = array![];
    let mut result = Result::Ok(());

    pixel_update.add_to_calldata(ref calldata);
    app_caller.add_to_calldata(ref calldata);
    calldata.append(for_player.into());

    let out = call_contract_syscall(contract_address, ON_POST_UPDATE_HOOK, calldata.span());

    if out.is_err() {
        if let Option::Some(err) = out.err() {
            if *err.at(0) != 'ENTRYPOINT_NOT_FOUND' && *err.at(0) != 'CONTRACT_NOT_DEPLOYED' {
                result = Result::Err(*err.at(0));
            }
        }
    }
    result
}

fn parseHookOutput(data: Span<felt252>) -> Option<PixelUpdate> {
    let mut color: Option<u32> = Option::None;
    let mut owner: Option<ContractAddress> = Option::None;
    let mut app: Option<ContractAddress> = Option::None;
    let mut text: Option<felt252> = Option::None;
    let mut timestamp: Option<u64> = Option::None;
    let mut action: Option<felt252> = Option::None;

    // println!("parse: {:?}", data);
    if data.at(0).deref() == 1 {
        return Option::None;
    }
    let x: u16 = data.at(1).deref().try_into().unwrap();
    let y: u16 = data.at(2).deref().try_into().unwrap();

    let mut i = 3;
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

    // Now it just panics when trying to read outside of index
    Option::Some(PixelUpdate { x, y, color, owner, app, text, timestamp, action })
}

// Gives the appropriate App, based on availability in Pixel or Area
fn determine_app(pixel: Pixel, area_result: Option<Area>) -> ContractAddress {
    let mut result = contract_address_const::<0>();
    if pixel.app == contract_address_const::<0>() {
        if let Option::Some(area) = area_result {
            result = area.app;
        }
    } else {
        result = pixel.app;
    }
    result
}

fn validate_callers(ref world: WorldStorage, for_player: ContractAddress) {
    let core_address = get_core_actions_address(ref world);

    let caller_account = get_tx_info().unbox().account_contract_address;
    let caller_contract = get_contract_address();

    if for_player != caller_account {
        assert(caller_contract == core_address, 'unauthorized caller_account');
    }
}
