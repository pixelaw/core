################################################################################
# PixeLAW Base Dockerfile
#
# Provides a clean Dojo development environment with correct toolchain versions:
# - Dojo: 1.8.0 (sozo, katana, torii)
# - Cairo: 2.13.1
# - Scarb: 2.13.1
# - Starknet: 2.13.1
#
# This base image is used by:
# 1. Dockerfile - Main application container
# 2. Scripts - World address calculation and other build tasks
################################################################################

# Start with official Dojo image (has katana 1.7.0, torii 1.8.3, but wrong sozo 1.7.1)
FROM ghcr.io/dojoengine/dojo:v1.8.0

# Install additional system dependencies
RUN apt-get update && \
  apt-get install -y \
  jq git procps nano net-tools sqlite3 curl build-essential make zip \
  && rm -rf /var/lib/apt/lists/*

# Install correct sozo 1.8.0 directly (bypass asdf)
RUN DOJO_VERSION=1.8.0 && \
  ARCH=$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/') && \
  curl -L "https://github.com/dojoengine/dojo/releases/download/v${DOJO_VERSION}/dojo_v${DOJO_VERSION}_linux_${ARCH}.tar.gz" \
    -o /tmp/dojo.tar.gz && \
  tar -xzf /tmp/dojo.tar.gz -C /usr/local/bin && \
  chmod +x /usr/local/bin/sozo && \
  rm -rf /tmp/dojo* && \
  echo "=== Installed Dojo versions ===" && \
  /usr/local/bin/sozo --version && \
  /usr/local/bin/katana --version 2>/dev/null || katana --version && \
  /usr/local/bin/torii --version 2>/dev/null || torii --version

# Ensure /usr/local/bin is first in PATH (override asdf)
ENV PATH="/usr/local/bin:$PATH"

# Install Scarb directly from GitHub releases
RUN SCARB_VERSION=2.13.1 && \
  ARCH=$(uname -m) && \
  curl -L "https://github.com/software-mansion/scarb/releases/download/v${SCARB_VERSION}/scarb-v${SCARB_VERSION}-${ARCH}-unknown-linux-gnu.tar.gz" \
    -o /tmp/scarb.tar.gz && \
  tar -xzf /tmp/scarb.tar.gz -C /tmp && \
  mv /tmp/scarb-v${SCARB_VERSION}-${ARCH}-unknown-linux-gnu/bin/scarb /usr/local/bin/scarb && \
  chmod +x /usr/local/bin/scarb && \
  rm -rf /tmp/scarb* && \
  scarb --version

# Create working directory
WORKDIR /pixelaw

LABEL org.opencontainers.image.description="PixeLAW base image with Dojo 1.8.0 toolchain"
