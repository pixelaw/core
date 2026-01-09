################################################################################
# PixeLAW Core Dockerfile
#
# This Dockerfile creates a complete PixeLAW development environment that runs:
# 1. Katana - Local Starknet blockchain node (port 5050)
# 2. Torii - World state indexer with GraphQL API (port 8080)
# All services are managed by s6-overlay process supervisor.
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

FROM ghcr.io/pixelaw/base:latest AS dojo

# ==============================================================================
# Build Stage: Compile contracts and generate blockchain snapshot
# ==============================================================================

FROM dojo AS builder

# Copy contract source code and dependencies
COPY ./DOJO_WORLD_ADDRESS /pixelaw/
COPY ./pixelaw_test_utils /pixelaw/pixelaw_test_utils
COPY ./contracts /pixelaw/contracts

WORKDIR /pixelaw/contracts

RUN sozo --version

# Note: --network=host allows scarb to fetch git dependencies during build
RUN --mount=type=cache,id=scarb_cache,target=/root/.cache/scarb \
    --mount=type=secret,id=DOJO_KEYSTORE_PASSWORD \
    --network=host \
    bash scripts/create_snapshot_docker.sh dev

# ==============================================================================
# Runtime Stage: Combine binaries and pre-built artifacts
# ==============================================================================

FROM dojo AS runtime

# s6-overlay version for process supervision
ARG S6_OVERLAY_VERSION=3.2.0.2

# Install s6-overlay for proper init and process supervision
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz /tmp
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-x86_64.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz && \
    tar -C / -Jxpf /tmp/s6-overlay-x86_64.tar.xz && \
    rm /tmp/s6-overlay-*.tar.xz

# Install netcat for service health checks
RUN apt-get update && \
    apt-get install -y netcat-openbsd && \
    rm -rf /var/lib/apt/lists/*

# Copy pre-built blockchain snapshot from builder
COPY --from=builder /pixelaw/storage_init /pixelaw/storage_init

# Copy runtime configuration files
COPY docker/scripts/ /pixelaw/scripts/
COPY docker/.env.example /pixelaw/core/docker/
COPY docker/.bashrc /root/
COPY ./tools/ /pixelaw/tools/

# Copy s6-overlay service definitions
COPY docker/s6-rc.d /etc/s6-overlay/s6-rc.d

# Make all scripts executable
RUN chmod +x /pixelaw/scripts/*.sh && \
    chmod +x /etc/s6-overlay/s6-rc.d/*/run 2>/dev/null || true

# Copy DOJO_WORLD_ADDRESS file (read by .bashrc, can be overridden via docker-compose.yml)
COPY ./DOJO_WORLD_ADDRESS /pixelaw/
RUN echo "export DOJO_WORLD_ADDRESS=$(cat /pixelaw/DOJO_WORLD_ADDRESS)" >> /root/.bashrc

# Create directories for persistent data
RUN mkdir -p /pixelaw/log /pixelaw/storage

WORKDIR /pixelaw

# Environment variables (can be overridden via docker-compose.yml)
ENV HOME=/root
ENV PATH="/opt/asdf/shims:/opt/asdf/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
ENV PUBLIC_TORII=http://localhost:8080
ENV STARKNET_RPC=http://localhost:5050

# Health check: Verify services are responding
# Start period allows services time to initialize before checks begin
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl --fail http://localhost:5050 && \
        curl --fail http://localhost:8080 || exit 1

LABEL org.opencontainers.image.description="PixeLAW core container with Katana and Torii"

# Katana RPC
EXPOSE 5050
# Torii GraphQL/gRPC
EXPOSE 8080

# s6-overlay handles process supervision
ENTRYPOINT ["/init"]
