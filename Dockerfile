################################################################################
# PixeLAW Core Dockerfile
#
# This Dockerfile creates a complete PixeLAW development environment that runs:
# 1. Katana - Local Starknet blockchain node (port 5050)
# 2. Torii - World state indexer with GraphQL API (port 8080)
# 3. Server - PixeLAW backend API (port 3000)
# All services are managed by PM2 process manager.
#
# Version requirements (must match contracts/Scarb.toml):
# - Dojo: 1.8.0 (sozo, katana, torii)
# - Cairo: 2.13.1
# - Scarb: 2.13.1
# - Starknet: 2.13.1
#
# Build process:
# - Installs Dojo toolchain via asdf version manager
# - Compiles Cairo contracts using sozo/scarb
# - Generates a pre-initialized blockchain snapshot (storage_init/)
# - Final image contains toolchain + pre-built state
################################################################################

# ==============================================================================
# Base Stage: Set up Dojo toolchain
# ==============================================================================

# Base: Dojo v1.8.0 image with asdf version manager pre-installed
FROM ghcr.io/dojoengine/dojo:v1.8.0 AS dojo

# Install system dependencies required for building and running PixeLAW
RUN apt-get update && \
  apt-get install -y \
  jq git procps nano net-tools sqlite3 curl build-essential make zip \
  && rm -rf /var/lib/apt/lists/*

# Verify asdf is available (pre-installed in Dojo image)
RUN asdf --version

# Install Dojo toolchain with version-aligned components
RUN asdf plugin add scarb && \
  asdf install scarb 2.13.1 && \
  asdf install sozo 1.8.0 && \
  asdf set --home scarb 2.13.1 && \
  asdf set --home sozo 1.8.0 && \
  asdf reshim

# Verify all tools are installed and accessible via asdf shims
RUN asdf current

FROM ghcr.io/pixelaw/server:0.5.1 AS server

# ==============================================================================
# Build Stage: Compile contracts and generate blockchain snapshot
# ==============================================================================

FROM dojo AS builder

# Copy contract source code and dependencies
COPY ./DOJO_WORLD_ADDRESS /pixelaw/
COPY ./pixelaw_test_utils /pixelaw/pixelaw_test_utils
COPY ./contracts /pixelaw/contracts

WORKDIR /pixelaw/contracts
# Note: --network=host allows scarb to fetch git dependencies during build
RUN --mount=type=cache,id=scarb_cache,target=/root/.cache/scarb \
    --mount=type=secret,id=DOJO_KEYSTORE_PASSWORD \
    --network=host \
    bash scripts/create_snapshot_docker.sh dev

# ==============================================================================
# Runtime Stage: Combine binaries and pre-built artifacts
# ==============================================================================

FROM dojo AS runtime

# Install Node.js and PM2 for process management
# PM2 manages katana, torii, and server processes (see ecosystem.config.js)
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

    
COPY --from=server /app /pixelaw/server/
# Install PM2 and Yarn globally
RUN --mount=type=cache,target=/root/.npm \
    npm install -g pm2 yarn

# Copy pre-built blockchain snapshot from builder
COPY --from=builder /pixelaw/storage_init /pixelaw/storage_init

# Copy runtime configuration files
COPY docker/scripts/ /pixelaw/scripts/
COPY docker/ecosystem.config.js /pixelaw/core/docker/
COPY docker/.env.example /pixelaw/core/docker/
COPY docker/.bashrc /root/
COPY ./tools/ /pixelaw/tools/

# Copy DOJO_WORLD_ADDRESS file (read by .bashrc, can be overridden via docker-compose.yml)
COPY ./DOJO_WORLD_ADDRESS /pixelaw/
RUN echo "export DOJO_WORLD_ADDRESS=$(cat /pixelaw/DOJO_WORLD_ADDRESS)" >> /root/.bashrc

# Create directories for persistent data
RUN mkdir -p /pixelaw/log /pixelaw/storage

WORKDIR /pixelaw

# Environment variables (can be overridden via docker-compose.yml)
ENV PUBLIC_TORII=http://localhost:8080
ENV STARKNET_RPC=http://localhost:5050
ENV VITE_PUBLIC_ETH_CONTRACT_ADDRESS=0x49d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7

# Health check: Verify all three services are responding
HEALTHCHECK CMD curl --fail http://localhost:3000 && \
                curl --fail http://localhost:5050 && \
                curl --fail http://localhost:8080 || exit 1

LABEL org.opencontainers.image.description="PixeLAW core container with Katana, Torii, and Server"

# Katana RPC
EXPOSE 5050
# Torii GraphQL/gRPC
EXPOSE 8080
# PixeLAW Server API
EXPOSE 3000

# Start all services via startup script
CMD ["bash", "./scripts/startup.sh"]
