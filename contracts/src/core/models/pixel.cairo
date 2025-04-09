use pixelaw::core::utils::{MAX_DIMENSION, Position};
use starknet::{ContractAddress};

#[derive(Debug, Copy, Drop, Serde, PartialEq)]
#[dojo::model]
pub struct Pixel {
    // System properties
    #[key]
    pub position: Position,
    // User-changeable properties
    pub app: ContractAddress,
    pub color: u32,
    pub created_at: u64,
    pub updated_at: u64,
    pub timestamp: u64,
    pub owner: ContractAddress,
    pub text: felt252,
    pub action: felt252,
}


#[derive(Drop, Copy, Serde)]
pub enum PixelUpdateResult {
    Ok: PixelUpdate,
    NotAllowed: PixelUpdate,
    Error: (PixelUpdate, felt252),
}

pub trait PixelUpdateResultTrait<PixelUpdateResult> {
    fn is_ok(self: PixelUpdateResult) -> bool;
    fn is_err(self: PixelUpdateResult) -> bool;
    fn unwrap(self: PixelUpdateResult) -> PixelUpdate;
}

pub impl PixelUpdateResultTraitImpl of PixelUpdateResultTrait<PixelUpdateResult> {
    fn is_ok(self: PixelUpdateResult) -> bool {
        match self {
            PixelUpdateResult::Ok(_) => true,
            _ => false,
        }
    }

    /// Returns true if the result is `Error`.
    fn is_err(self: PixelUpdateResult) -> bool {
        match self {
            PixelUpdateResult::Error(_) => true,
            _ => false,
        }
    }
    fn unwrap(self: PixelUpdateResult) -> PixelUpdate {
        match self {
            PixelUpdateResult::Ok(value) => value,
            PixelUpdateResult::NotAllowed(value) => panic!(
                "{}_{} NotAllowed", value.position.x, value.position.y,
            ),
            PixelUpdateResult::Error((
                value, msg,
            )) => panic!("{}_{} Error: {}", value.position.x, value.position.y, msg),
        }
    }
}

#[derive(PartialEq, Debug, Copy, Drop, Serde, Introspect)]
pub struct PixelUpdate {
    pub position: Position,
    pub color: Option<u32>,
    pub owner: Option<ContractAddress>,
    pub app: Option<ContractAddress>,
    pub text: Option<felt252>,
    pub timestamp: Option<u64>,
    pub action: Option<felt252>,
}


pub trait PixelUpdateTrait<PixelUpdate> {
    fn validate(self: PixelUpdate);
    fn add_to_calldata(self: PixelUpdate, ref calldata: Array<felt252>);
}

pub impl PixelUpdateTraitImpl of PixelUpdateTrait<PixelUpdate> {
    fn validate(self: PixelUpdate) {
        assert(
            self.position.x <= MAX_DIMENSION && self.position.y <= MAX_DIMENSION,
            'position overflow',
        );
    }

    fn add_to_calldata(self: PixelUpdate, ref calldata: Array<felt252>) {
        calldata.append(self.position.x.into());
        calldata.append(self.position.y.into());
        match self.color {
            Option::Some(value) => {
                calldata.append(0.into());
                calldata.append(value.into());
            },
            Option::None => { calldata.append(1.into()); },
        }
        match self.owner {
            Option::Some(value) => {
                calldata.append(0.into());
                calldata.append(value.into());
            },
            Option::None => { calldata.append(1.into()); },
        }
        match self.app {
            Option::Some(value) => {
                calldata.append(0.into());
                calldata.append(value.into());
            },
            Option::None => { calldata.append(1.into()); },
        }
        match self.text {
            Option::Some(value) => {
                calldata.append(0.into());
                calldata.append(value.into());
            },
            Option::None => { calldata.append(1.into()); },
        }
        match self.timestamp {
            Option::Some(value) => {
                calldata.append(0.into());
                calldata.append(value.into());
            },
            Option::None => { calldata.append(1.into()); },
        }
        match self.action {
            Option::Some(value) => {
                calldata.append(0.into());
                calldata.append(value.into());
            },
            Option::None => { calldata.append(1.into()); },
        }
    }
}
