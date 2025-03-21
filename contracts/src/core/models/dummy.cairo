// A Dummy model to try to avoid this bug:
// https://github.com/dojoengine/dojo/issues/3066
// Typescript bindings: structs not exported

use pixelaw::core::models::pixel::{PixelUpdate};
use pixelaw::core::utils::{Bounds, DefaultParameters};

#[dojo::model]
#[derive(Copy, Drop, Serde, Debug)]
pub struct Dummy {
    #[key]
    pub id: u64,
    pub defaultParams: DefaultParameters,
    pub bounds: Bounds,
    pub pixelUpdate: PixelUpdate,
}
