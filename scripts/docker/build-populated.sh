#!/bin/bash
#
# Build script for ghcr.io/pixelaw/core-populated Docker image
#
# This script runs during `docker build` on top of the core image to:
# 1. Extract the existing katana_db snapshot
# 2. Start katana and torii
# 3. Execute pixel art drawing commands
# 4. Create updated katana_db.zip snapshot
#
# Usage: scripts/docker/build-populated.sh
#

set -euxo pipefail

export PROFILE=${1:-"dev"}

# Source shared functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/functions.sh"

STORAGE_INIT_DIR="/pixelaw/storage_init"

echo "=== Building PixeLAW Populated Image ==="
echo "Profile: $PROFILE"

# Extract existing snapshot
echo "Extracting katana database snapshot..."
mkdir -p "$STORAGE_DIR"
unzip "$STORAGE_INIT_DIR/katana_db.zip" -d "$STORAGE_DIR"

# Get world address from storage_init manifest
export DOJO_WORLD_ADDRESS=$(jq -r '.world.address' "$STORAGE_INIT_DIR/manifest.json")
echo "World Address: $DOJO_WORLD_ADDRESS"

# Build contracts to generate ABIs in target/dev
echo "Building contracts..."
cd /pixelaw/contracts
sozo build --profile "$PROFILE"

# Copy deployment manifest (has contract addresses from core build)
cp "$STORAGE_INIT_DIR/manifest.json" "/pixelaw/contracts/manifest_$PROFILE.json"

# Start services
start_katana
start_torii

# Execute pixel art data (must run from contracts dir for sozo)
echo "Drawing pixel art..."
cd /pixelaw/contracts

# Create sozo wrapper that adds --diff flag (resolves tags from chain)
REAL_SOZO=$(which sozo)
cat > /tmp/sozo << 'WRAPPER'
#!/bin/bash
if [ "$1" = "execute" ]; then
    shift
    exec /usr/local/bin/sozo execute --diff "$@"
else
    exec /usr/local/bin/sozo "$@"
fi
WRAPPER
chmod +x /tmp/sozo
export PATH="/tmp:$PATH"

source "$SCRIPT_DIR/../data/pixel-art.sh"
draw_all

# Give time for transactions to be indexed
sleep 3

# Stop services
stop_all

# Create updated snapshot
zip_katana_db

# Replace snapshot in storage_init
mv "$KATANA_DB_ZIP" "$STORAGE_INIT_DIR/katana_db.zip"

# Cleanup
cleanup

echo "=== Populated Build Complete ==="
