use starknet::{ContractAddress, ClassHash};

// TODO is this using packing? If not, try to use bitmasking approach
#[derive(Copy, Drop, Serde, Introspect)]
struct Permission {
    app: bool,
    color: bool,
    owner: bool,
    text: bool,
    timestamp: bool,
    action: bool
}

#[derive(Model, Copy, Drop, Serde)]
struct Permissions {
    #[key]
    allowing_app: ContractAddress,
    #[key]
    allowed_app: ContractAddress,
    // The permissions
    permission: Permission
}


