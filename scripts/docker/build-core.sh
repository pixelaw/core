#!/bin/bash
#
# Build script for ghcr.io/pixelaw/core Docker image
#
# This script runs during `docker build` to:
# 1. Start a temporary katana instance
# 2. Build and migrate contracts
# 3. Create a katana_db.zip snapshot
# 4. Copy artifacts to /pixelaw/storage_init/
#
# Usage: scripts/docker/build-core.sh [profile]
#   profile: dev (default), sepolia, mainnet
#

set -euxo pipefail

export PROFILE=${1:-"dev"}

# Load secrets if available (Docker build secrets)
if [ -f /run/secrets/DOJO_KEYSTORE_PASSWORD ]; then
    export DOJO_KEYSTORE_PASSWORD=$(cat /run/secrets/DOJO_KEYSTORE_PASSWORD)
    export STARKNET_KEYSTORE_PASSWORD="$DOJO_KEYSTORE_PASSWORD"
fi

# Source shared functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/functions.sh"

echo "=== Building PixeLAW Core Image ==="
echo "Profile: $PROFILE"
echo "World Address: $DOJO_WORLD_ADDRESS"

# Build contracts
sozo_build

# Start katana with fresh database
start_katana

# Migrate contracts
sozo_migrate

# Start torii to verify indexing works
start_torii

# Give torii time to index
sleep 3

# Stop services
stop_all

# Create snapshot
zip_katana_db

# Copy to storage_init for runtime
copy_to_storage_init

# Cleanup working directory
cleanup

echo "=== Build Complete ==="
