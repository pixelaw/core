use starknet::{ContractAddress, ClassHash};

// TODO is this using packing? If not, try to use bitmasking approach
#[derive(Copy, Drop, Serde, Introspect)]
pub struct Permission {
    app: bool,
    color: bool,
    owner: bool,
    text: bool,
    timestamp: bool,
    action: bool
}

#[derive(Copy, Drop, Serde)]
#[dojo::model(namespace: "pixelaw", nomapping: true)]
pub struct Permissions {
    #[key]
    allowing_app: ContractAddress,
    #[key]
    allowed_app: ContractAddress,
    // The permissions
    permission: Permission
}
