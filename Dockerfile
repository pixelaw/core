################################################################################
# PixeLAW Core Dockerfile
#
# This Dockerfile creates a complete PixeLAW development environment that runs:
# 1. Katana - Local Starknet blockchain node (port 5050)
# 2. Torii - World state indexer with GraphQL API (port 8080)
# 3. Server - PixeLAW backend API (port 3000)
#
# All three services are managed by PM2 process manager.
#
# Build process:
# - Compiles Cairo contracts using Dojo/Scarb
# - Generates a pre-initialized blockchain snapshot (storage_init/)
# - Final image contains only runtime binaries + pre-built state
################################################################################

# ==============================================================================
# Import Stages: Pull binaries from official images
# ==============================================================================

# Base: Dojo toolchain (sozo, scarb, cairo compiler)
FROM ghcr.io/dojoengine/dojo:v1.7.0 AS dojo
RUN apt-get update && \
  apt-get install -y \
  jq git procps nano net-tools sqlite3 curl build-essential make zip \
  && rm -rf /var/lib/apt/lists/*

# Install asdf version manager (required by Dojo installer)
ENV ASDF_DIR=/root/.asdf
RUN git clone https://github.com/asdf-vm/asdf.git ${ASDF_DIR} --branch v0.15.0 && \
  echo ". ${ASDF_DIR}/asdf.sh" >> ~/.bashrc

# Set PATH to include asdf binaries
ENV PATH="${ASDF_DIR}/bin:${ASDF_DIR}/shims:${PATH}"

# Verify asdf installation
RUN asdf --version

# Install scarb via asdf manually (Dojo installer has compatibility issues with asdf v0.15.0)
# Scarb is required by sozo for building contracts
RUN asdf plugin add scarb && \
  asdf install scarb 2.12.2 && \
  asdf global scarb 2.12.2 && \
  asdf reshim

# Verify scarb installation
RUN scarb --version

# Katana: Starknet development node
FROM ghcr.io/dojoengine/katana:v1.7.0 AS katana

# Torii: World state indexer
FROM ghcr.io/dojoengine/torii:v1.8.7 AS torii

# Node.js: Runtime for PM2 process manager
FROM sitespeedio/node:ubuntu-24-04-nodejs-22.13.0 AS nodejs
RUN npm install -g yarn ts-node pm2

# PixeLAW Server: Backend API
FROM ghcr.io/pixelaw/server:0.5.1 AS server

# ==============================================================================
# Build Stage: Compile contracts and generate blockchain snapshot
# ==============================================================================

FROM dojo AS builder

# Install katana and torii binaries needed for building snapshot
# The create_snapshot_docker.sh script starts a temporary Katana instance
# and uses Torii to index the deployed contracts
COPY --from=katana /usr/local/bin/katana /usr/local/bin/katana
COPY --from=torii /usr/local/bin/torii /usr/local/bin/torii

# Ensure Dojo binaries and Cairo toolchain (scarb) are in PATH
# starkup installs scarb via asdf to ~/.asdf/shims/scarb
# Setting $SCARB ensures sozo uses the correct scarb version (prevents version mismatch errors)
ENV PATH="/root/.asdf/shims:/root/.asdf/bin:/root/.dojo/bin:$PATH"
ENV SCARB="/root/.asdf/shims/scarb"
ENV ASDF_DIR="/root/.asdf"
ENV ASDF_DATA_DIR="/root/.asdf"

# Copy contract source code and dependencies
# Note: contracts/ includes manifest_dev.json which is used since
COPY ./DOJO_WORLD_ADDRESS /pixelaw/
COPY ./pixelaw_test_utils /pixelaw/pixelaw_test_utils
COPY ./contracts /pixelaw/contracts

WORKDIR /pixelaw/contracts

# Build and deploy contracts to temporary Katana instance
# Generates /pixelaw/storage_init/ containing:
#   - katana_db.zip: Pre-initialized blockchain database
#   - manifest.json: Contract deployment manifest
#   - genesis.json: Genesis block configuration
# Required tools: katana, torii, sozo, starkli, jq, zip, sqlite3
# Note: network=host allows scarb to fetch git dependencies
RUN --mount=type=cache,id=scarb_cache,target=/root/.cache/scarb \
    --mount=type=secret,id=DOJO_KEYSTORE_PASSWORD \
    --network=host \
    bash scripts/create_snapshot_docker.sh dev

# ==============================================================================
# Runtime Stage: Combine binaries and pre-built artifacts
# ==============================================================================

FROM dojo AS runtime

# Install runtime binaries
COPY --from=katana /usr/local/bin/katana /usr/local/bin/katana
COPY --from=torii /usr/local/bin/torii /usr/local/bin/torii
COPY --from=nodejs /usr/local/bin/node /usr/local/bin/node
COPY --from=nodejs /usr/local/bin/npm /usr/local/bin/npm
COPY --from=nodejs /usr/local/bin/yarn /usr/local/bin/yarn
COPY --from=nodejs /usr/local/lib/node_modules /usr/local/lib/node_modules

# Create symlinks for pm2 and ts-node
RUN ln -s /usr/local/lib/node_modules/pm2/bin/pm2 /usr/local/bin/pm2 && \
    ln -s /usr/local/lib/node_modules/ts-node/dist/bin.js /usr/local/bin/ts-node

# Install PixeLAW server
COPY --from=server /app /pixelaw/server/

# Copy pre-built blockchain snapshot from builder
# This contains the deployed contracts and initialized state
COPY --from=builder /pixelaw/storage_init /pixelaw/storage_init

# Copy runtime configuration
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
ENV CORE_VERSION=VERSION
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

# Start all services via PM2
CMD ["bash", "./scripts/startup.sh"]
