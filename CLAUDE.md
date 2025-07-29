# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Build and Test
```bash
just build                    # Build contracts using sozo
just test                     # Run all contract tests with sozo
just test_filtered "filter"   # Run filtered tests (e.g., just test_filtered "house")
cd pixelaw_testing && sozo test  # Run tests from testing package
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
cd pixelaw_testing
sozo build                  # Build test contracts
sozo test                   # Run comprehensive test suite
sozo test --filter "house"  # Run filtered tests (e.g., house, player, area)
```

## Architecture

### Core Concepts
- **Pixel World**: 2D Cartesian plane where each position (x,y) represents a Pixel
- **Pixel Properties**: position, app, color, owner, text, alert, timestamp  
- **Apps**: Define pixel behavior and interactions (one app per pixel)
- **App2App**: Controlled interactions between different apps
- **Queued Actions**: Future actions that can be scheduled during execution

### Technology Stack
- **Cairo 2.10.1**: Smart contract language for Starknet
- **Dojo Framework 1.6.2**: ECS-based blockchain game development framework
- **Starknet 2.10.1**: Layer 2 blockchain platform
- **Scarb 2.10.1**: Package manager and build tool

### Project Structure
```
contracts/               # Main Cairo smart contracts
├── src/core/           # Core actions, events, models, utils
├── src/apps/           # Default apps (house, paint, player, snake)
├── Scarb.toml          # Main package configuration
└── Scarb_deploy.toml   # Deployment configuration

pixelaw_testing/        # Dedicated testing package
├── src/tests/          # Comprehensive test suite
└── Scarb.toml          # Testing package configuration

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
- `contracts/Scarb.toml`: Main package with Dojo dependencies
- `pixelaw_testing/Scarb.toml`: Testing package with test dependencies
- `docker-compose.yml`: Docker development environment, running Katana and Torii
- `VERSION`: Core version (0.7.7)
- `DOJO_VERSION`: Dojo version (1.6.2)

### Testing Strategy
- Unit tests embedded in source files using `#[cfg(test)]`
- Integration tests in dedicated `pixelaw_testing` package
- Comprehensive test coverage for all apps and core functionality
- Tests organized by component (area, interop, pixel_area, queue, etc.)
- Use `just test_filtered "pattern"` or `sozo test --filter "pattern"` for focused testing during development

### Development Guidelines
- Follow Cairo naming conventions (snake_case for functions, PascalCase for types)
- Use ECS patterns with Dojo components and systems
- Implement proper error handling with detailed error messages
- Write tests for all new functionality
- Use Cairo Coder MCP for Cairo-specific development tasks
- Always run `scarb build` after writing Cairo code to ensure compilation

### Error Handling Convention
- Use `panic!` for error conditions instead of `assert!` to match other apps
- **For position-related errors, use the `panic_at_position()` helper function from `pixelaw::core::utils`**
