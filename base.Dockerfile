################################################################################
# PixeLAW Base Dockerfile
#
# Provides a clean Dojo development environment with correct toolchain versions:
# - Dojo: 1.8.5 (sozo, katana, torii)
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

# Extract tools from asdf installs to /usr/local/bin
# Base image has: katana 1.7.0, torii 1.8.3, sozo 1.7.1 (outdated)
RUN cp /opt/asdf/installs/katana/1.7.0/bin/katana /usr/local/bin/ && \
    cp /opt/asdf/installs/torii/1.8.3/bin/torii /usr/local/bin/ && \
    rm -rf /opt/asdf ~/.asdf ~/.tool-versions

# Set clean PATH without asdf
ENV PATH="/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# Install sozo 1.8.5 (newer than base image's 1.7.1)
RUN DOJO_VERSION=1.8.5 && \
    ARCH=$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/') && \
    curl -L "https://github.com/dojoengine/dojo/releases/download/sozo/v${DOJO_VERSION}/sozo_v${DOJO_VERSION}_linux_${ARCH}.tar.gz" \
      -o /tmp/sozo.tar.gz && \
    tar -xzf /tmp/sozo.tar.gz -C /usr/local/bin && \
    rm -rf /tmp/sozo* && \
    echo "=== Dojo toolchain ===" && \
    sozo --version && katana --version && torii --version

# Install Scarb directly from GitHub releases (all binaries including cairo-test)
RUN SCARB_VERSION=2.13.1 && \
    ARCH=$(uname -m) && \
    curl -L "https://github.com/software-mansion/scarb/releases/download/v${SCARB_VERSION}/scarb-v${SCARB_VERSION}-${ARCH}-unknown-linux-gnu.tar.gz" \
      -o /tmp/scarb.tar.gz && \
    tar -xzf /tmp/scarb.tar.gz -C /tmp && \
    mv /tmp/scarb-v${SCARB_VERSION}-${ARCH}-unknown-linux-gnu/bin/* /usr/local/bin/ && \
    rm -rf /tmp/scarb* && \
    scarb --version

# Create working directory
WORKDIR /pixelaw

LABEL org.opencontainers.image.description="PixeLAW base image with Dojo 1.8.5 toolchain"
