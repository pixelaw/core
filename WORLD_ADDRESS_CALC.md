# World Address Calculation for PixeLAW

## Current World Address

**Dojo 1.8.0**: `0x04101f5a29dc3e9dc48e2d8918e8121315757f2d2bc56fb6213dfc949344c071`

## How World Address is Calculated

The world address is deterministic and computed from:

1. **World seed**: `"pixelaw"` (from `contracts/dojo_dev.toml`)
2. **World class hash**: Changes with each Dojo version

Formula (from Dojo source code):
```
salt = poseidon_hash_single(cairo_short_string_to_felt("pixelaw"))
world_address = get_contract_address(
    salt,
    world_class_hash,  // This changes per Dojo version
    [],                // Empty constructor calldata
    0x0                // Deployer address
)
```

## When to Update

Update `DOJO_WORLD_ADDRESS` file whenever you:
- Upgrade Dojo version (via Nix - see ~/CLAUDE.md)
- Change world seed in `dojo_dev.toml`

## How to Get New Address

### Method 1: From Migration Output (Easiest)

Run a fresh migration and look for the deterministic address:

```bash
cd core/contracts
# Start Katana
katana --invoke-max-steps 4294967295 --dev --dev.seed 0 --dev.no-fee &
sleep 2

# Run migrate (will show deterministic address)
sozo --profile dev --manifest-path Scarb_deploy.toml migrate 2>&1 | grep -A2 "deterministic address"

# Clean up
pkill katana
```

Look for output like:
```
warning: The world address computed from the seed is different from the address provided in config:
  - deterministic address: 0x05da35c...
  - config address       : 0x04101f...
```

### Method 2: Automated Task

```bash
cd /home/pixelaw/dev
just update-world-address
```

This builds a clean Dojo container and extracts the address automatically.

### Method 3: Manual Calculation

Using Dojo's source code tools (advanced):
```bash
sozo hash compute "pixelaw"  # Get salt
# Then manually calculate using world class hash from build artifacts
```

## Historical Addresses

| Dojo Version | World Address                                                      |
|--------------|-------------------------------------------------------------------|
| 1.8.0        | `0x04101f5a29dc3e9dc48e2d8918e8121315757f2d2bc56fb6213dfc949344c071` |
| 1.7.1        | (not recorded) |

## Related Files

- `/home/pixelaw/dev/core/DOJO_WORLD_ADDRESS` - Current address (auto-read by scripts)
- `/home/pixelaw/dev/core/contracts/dojo_dev.toml` - World configuration (seed, name)
- `/home/pixelaw/dev/core/DOJO_VERSION` - Current Dojo version
