# PixeLAW Core Contracts

Cairo smart contracts for the PixeLAW pixel world framework, built with [Dojo](https://github.com/dojoengine/dojo).

## Version Compatibility

| Component | Version |
|-----------|---------|
| Dojo | 1.8.5 |
| Cairo | 2.13.1 |
| Scarb | 2.13.1 |

## Building and Testing

```bash
# Build contracts
sozo build

# Run tests
sozo test

# Run filtered tests
sozo test --filter "snake"
```

Or use Docker (recommended for consistent toolchain):

```bash
# From core/ directory
just docker-test
just docker-test-filtered "snake"
```

## Deployment

### Local (Katana)

```bash
# Start local environment
docker compose up -d

# Deploy contracts
sozo migrate apply

# Initialize
scarb run init
```

### Sepolia

```bash
sozo build --profile sepolia
sozo migrate apply --profile sepolia \
  --account-address $ACCOUNT_ADDRESS \
  --private-key $PRIVATE_KEY
```

## Default Apps

| App | Purpose |
|-----|---------|
| **Paint** | Basic pixel coloring (`put_color`, `remove_color`, `put_fading_color`) |
| **Snake** | Classic snake game with collision detection |
| **Player** | Player character representation |
| **House** | Building and area management |

See the [examples repository](../../examples/) for more game implementations.

## Project Structure

```
contracts/
├── src/
│   ├── lib.cairo           # Module declarations
│   ├── apps/               # Default apps (paint, snake, player, house)
│   ├── core/
│   │   ├── models/         # ECS models (pixel, area, queue, registry)
│   │   ├── actions/        # Core systems (pixel, queue, area, app)
│   │   └── utils.cairo     # Helper functions
│   └── tests/              # Test suite (33 tests)
├── Scarb.toml              # Package configuration
└── Scarb_deploy.toml       # Deployment configuration
```
