#!/bin/bash
set -euo pipefail
pushd $(dirname "$0")/..

# Get world address from manifest
WORLD_ADDRESS=$(cat target/dev/manifest.json | jq -r '.world.address')

# Check if WORLD_ADDRESS is not "null"
if [ "$WORLD_ADDRESS" != "null" ]; then
  # Update Scarb.toml
  # Note: Using '' after -i to work with macOS sed, and corrected quotes around variables
  sed -i '' "s/world_address = \".*\"/world_address = \"$WORLD_ADDRESS\"/" Scarb.toml
fi

echo "Scarb.toml has been updated with address(es)"