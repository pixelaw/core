# PixeLAW Core Contracts - Development Notes

## Dojo Source Code Reference

For deep understanding of Dojo internals, the complete Dojo 1.8.0 source code is available at:

```
~/reference/dojo/
```

Key directories:
- `crates/dojo/core/src/` - Core Cairo contracts (world, model, event)
- `crates/dojo/world/` - Rust world implementation
- `crates/sozo/ops/` - Migration and deployment logic
- `examples/` - Example Dojo projects

Useful when debugging:
- World contract deployment issues
- Permission/writer configuration
- Model registration
- World address calculation
- Breaking changes between versions

## Quick References

### World Constructor (Dojo 1.8.0)

The world constructor changed in Dojo 1.8.0:
- **No longer accepts** `world_class_hash` parameter
- Constructor signature: `fn constructor(ref self: ContractState)`
- World class hash is retrieved via syscall during construction

Source: `~/reference/dojo/crates/dojo/core/src/world/world_contract.cairo:293`

### Deployment Process

Deployment happens via UDC with **empty constructor calldata**:
```rust
deployer.deploy_via_udc(
    world_class_hash,
    salt,
    &[],  // Empty calldata - world constructor takes no args
    Felt::ZERO,
)
```

Source: `~/reference/dojo/crates/sozo/ops/src/migrate/mod.rs:1196`

Permissions from `[writers]` in `dojo_dev.toml` are applied **after** world deployment via separate transactions.

### World Address Calculation

Formula:
```
salt = poseidon_hash_single(cairo_short_string_to_felt(seed))
world_address = get_contract_address(salt, world_class_hash, [], 0x0)
```

Source: `~/reference/dojo/crates/dojo/world/src/utils.rs:7-14`

## Version Information

Current setup:
- Dojo: 1.8.0
- Cairo: 2.13.1
- Scarb: 2.13.1
- Starknet: 2.13.1

See parent `CLAUDE.md` for build/test/deployment commands.
