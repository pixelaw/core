# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Build and Test
```bash
just build                    # Build contracts using sozo
just test                     # Run all contract tests with sozo
just test_filtered "filter"   # Run filtered tests (e.g., just test_filtered "house")
cd contracts && sozo test     # Run tests directly with sozo
```

### Development Environment
```bash
docker compose up -d        # Start Keiko (includes Katana RPC, Torii indexer, dashboard)
docker compose down         # Stop Keiko
just shell                  # Access running Keiko container shell
```

### Docker Operations
```bash
just docker-build           # Build Docker image (requires .account file)
just docker-run             # Run Docker container with ports 3000, 5050, 8080
just docker-bash            # Run Docker container with bash shell
```

### Contract Development
```bash
cd contracts
sozo build                  # Build contracts (compiles Cairo code)
sozo migrate apply          # Deploy contracts to running Katana
scarb run init              # Initialize deployed contracts
```

### Testing-Specific Commands
```bash
cd contracts
sozo test                   # Run comprehensive test suite
sozo test --filter "house"  # Run filtered tests (e.g., house, player, area)
sozo test --filter "pixel"  # Run pixel-related tests
```

## Architecture

### Core Concepts
- **Pixel World**: 2D Cartesian plane where each position (x,y) represents a Pixel
- **Pixel Properties**: position, app, color, owner, text, alert, timestamp  
- **Apps**: Define pixel behavior and interactions (one app per pixel)
- **App2App**: Controlled interactions between different apps
- **Queued Actions**: Future actions that can be scheduled during execution

### Technology Stack
- **Cairo 2.12.2**: Smart contract language for Starknet
- **Dojo Framework 1.7.1**: ECS-based blockchain game development framework
- **Starknet 2.12.2**: Layer 2 blockchain platform
- **Scarb 2.12.2**: Package manager and build tool

### Project Structure
```
contracts/               # Main Cairo smart contracts
├── src/
│   ├── core/           # Core actions, events, models, utils
│   ├── apps/           # Default apps (house, paint, player, snake)
│   └── tests/          # Comprehensive test suite
│       ├── apps/       # App-specific tests
│       ├── core/       # Core functionality tests
│       └── helpers.cairo  # Test utilities
├── Scarb.toml          # Main package configuration
└── Scarb_deploy.toml   # Deployment configuration

docker/                 # Docker development configuration
scripts/                # Release and upgrade scripts
```

### Default Apps
- **Paint**: Color manipulation (`put_color`, `remove_color`, `put_fading_color`)
- **Snake**: Classic snake game with pixel collision detection
- **Player**: Player management and registration
- **House**: Building/housing system with area management

### Core Systems
- **Actions**: Define pixel behavior and state transitions
- **Models**: ECS components for game state (Pixel, Area, QueueItem, App, etc.)
- **Queue System**: Scheduled actions for future execution
- **Permission System**: App-based permissions for pixel property updates
- **Area Management**: Spatial organization using RTree data structure

### Development Tools
- **Katana**: Local Starknet development node (port 5050)
- **Torii**: World state indexer and GraphQL API (port 8080)
- **Keiko**: Combined development container with dashboard (port 3000)
- **Sozo**: Dojo CLI for building, testing, and deployment

### Key Configuration Files
- `contracts/Scarb.toml`: Main package with Dojo dependencies and test configuration
- `docker-compose.yml`: Docker development environment, running Katana and Torii
- `VERSION`: Core version (0.7.9)
- `DOJO_VERSION`: Dojo version (1.7.1)

### Testing Strategy
- All tests located in `contracts/src/tests/` directory
- Test organization:
  - `tests/core/` - Core functionality tests (area, pixel, queue, interop)
  - `tests/apps/` - App-specific tests (house, paint, player, snake)
  - `tests/helpers.cairo` - Shared test utilities and setup functions
- Comprehensive test coverage for all apps and core functionality (33 tests)
- Use `just test_filtered "pattern"` or `cd contracts && sozo test --filter "pattern"` for focused testing
- All tests use `dojo_cairo_test` for world setup and model access

### Development Guidelines
- Follow Cairo naming conventions (snake_case for functions, PascalCase for types)
- Use ECS patterns with Dojo components and systems
- Implement proper error handling with detailed error messages
- Write tests for all new functionality
- Use Cairo Coder MCP for Cairo-specific development tasks
- Always run `sozo build` after writing Cairo code to ensure compilation

### Cairo Patterns (Dojo 1.7.1)

#### ContractAddress Conversion
- **DEPRECATED**: `contract_address_const::<VALUE>()`
- **CURRENT**: Use `VALUE.try_into().unwrap()` for ContractAddress conversion
- Examples:
  ```cairo
  // Zero address
  let zero = 0.try_into().unwrap();
  let zero_hex = 0x0.try_into().unwrap();

  // Specific address
  let addr = 0x1337.try_into().unwrap();
  ```

#### WorldStorage and Models
- Import: `use dojo::world::storage::WorldStorage;`
- Import: `use dojo::model::{ModelStorage};`
- Read models: `world.read_model(key)`
- Write models: `world.write_model(@model)`
- Erase models: `world.erase_model(@model)`

#### Testing Patterns
- All tests in `contracts/src/tests/` directory
- Use `dojo_cairo_test` for test utilities
- Import test resources: `TestResource`, `NamespaceDef`, `ContractDef`
- Spawn test world: `spawn_test_world(world::TEST_CLASS_HASH, [namespace_defs].span())`
- Sync permissions: `world.sync_perms_and_inits(contract_defs)`
- Access contracts via DNS: `world.dns(@"contract_name").unwrap()`
- Use helper functions from `tests/helpers.cairo`: `setup_core()`, `setup_apps()`, `set_caller()`

### Error Handling Convention
- Use `panic!` for error conditions instead of `assert!` to match other apps
- **For position-related errors, use the `panic_at_position()` helper function from `pixelaw::core::utils`**

### Migration Notes (Dojo 1.5.0 → 1.7.1)
- All `contract_address_const` usages replaced with `.try_into().unwrap()` pattern
- Updated to Dojo 1.7.1 with WorldStorage and ModelStorage traits
- All 33 core tests passing after migration
- No breaking changes to app interfaces
