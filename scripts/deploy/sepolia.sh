#!/bin/bash
#
# Deploy contracts to Starknet Sepolia testnet
#
# Usage: scripts/deploy/sepolia.sh
#
# Prerequisites:
#   - DOJO_KEYSTORE_PASSWORD environment variable or interactive prompt
#   - Account configured in contracts/dojo_sepolia.toml
#

set -euo pipefail

cd "$(dirname "$0")/../../contracts"

export PROFILE="sepolia"
DEPLOY_SCARB="Scarb_deploy.toml"

echo "=== Deploying to Sepolia ==="

# Get keystore password
if [ -z "${DOJO_KEYSTORE_PASSWORD:-}" ]; then
    read -sp "Enter keystore password: " DOJO_KEYSTORE_PASSWORD
    echo
fi
export DOJO_KEYSTORE_PASSWORD
export STARKNET_KEYSTORE_PASSWORD="$DOJO_KEYSTORE_PASSWORD"

# Build
echo "Building contracts..."
sozo clean
sozo --profile "$PROFILE" --manifest-path "$DEPLOY_SCARB" build

# Migrate
echo "Migrating contracts..."
sozo --profile "$PROFILE" --manifest-path "$DEPLOY_SCARB" migrate --wait

echo "=== Deployment Complete ==="
echo "World address can be found in manifest_sepolia.json"
