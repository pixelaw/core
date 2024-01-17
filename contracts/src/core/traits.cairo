use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
use pixelaw::core::models::pixel::PixelUpdate;
use pixelaw::core::models::registry::App;
use starknet::ContractAddress;

#[starknet::interface]
trait IInteroperability<TContractState> {
  fn on_pre_update(
    self: @TContractState,
    pixel_update: PixelUpdate,
    app_caller: App,
    player_caller: ContractAddress
  );
  fn on_post_update(
    self: @TContractState,
    pixel_update: PixelUpdate,
    app_caller: App,
    player_caller: ContractAddress
  );
}
