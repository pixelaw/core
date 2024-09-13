use starknet::{ContractAddress, ClassHash};

// TODO is this using packing? If not, try to use bitmasking approach
#[derive(Copy, Drop, Serde, Introspect, PartialEq)]
pub struct Permission {
    pub app: bool,
    pub color: bool,
    pub owner: bool,
    pub text: bool,
    pub timestamp: bool,
    pub action: bool
}

#[derive(Copy, Drop, Serde)]
#[dojo::model(namespace: "pixelaw", nomapping: true)]
pub struct Permissions {
    #[key]
    pub allowing_app: ContractAddress,
    #[key]
    pub allowed_app: ContractAddress,
    // The permissions
    pub permission: Permission
}
