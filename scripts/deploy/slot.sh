#!/bin/bash
#
# Deploy contracts to Cartridge Slot
#
# Usage: scripts/deploy/slot.sh <world_name>
#
# Prerequisites:
#   - slot CLI installed and authenticated
#   - jq installed
#

set -euo pipefail

if [ $# -eq 0 ]; then
    echo "Usage: $0 <world_name>"
    exit 1
fi

cd "$(dirname "$0")/../../contracts"

WORLD_NAME=$1
BASE_URL="https://api.cartridge.gg/x/${WORLD_NAME}"
RPC_URL="${BASE_URL}/katana"
TORII_URL="${BASE_URL}/torii"
TARGET_DIR="target/slot/$WORLD_NAME"
TOTAL_ACCOUNTS=4

echo "=== Deploying to Slot ==="
echo "World Name: $WORLD_NAME"
echo "RPC URL: $RPC_URL"

# Create target directory
mkdir -p "$TARGET_DIR"

# Deploy katana
echo "Deploying Slot katana..."
slot deployments create "$WORLD_NAME" katana --invoke-max-steps 4000000000
sleep 10

# Get deployment logs
slot deployments logs "$WORLD_NAME" katana > "$TARGET_DIR/katana-logs.txt"
logs=$(cat "$TARGET_DIR/katana-logs.txt")

# Extract credentials
ACCOUNT_ADDRESS=$(echo "$logs" | grep '| Account address |' | awk -F '|' '{print $3}' | head -n 1 | tr -d ' ')
PRIVATE_KEY=$(echo "$logs" | grep '| Private key     |' | awk -F '|' '{print $3}' | head -n 1 | tr -d ' ')
SEED=$(echo "$logs" | grep 'ACCOUNTS SEED' -A 2 | tail -n 1 | tr -d ' ')

echo "Account: $ACCOUNT_ADDRESS"

# Update Scarb.toml with slot credentials
sed -i "s#rpc_url = \".*\"#rpc_url = \"$RPC_URL\"#" Scarb.toml
sed -i "s/account_address = \".*\"/account_address = \"$ACCOUNT_ADDRESS\"/" Scarb.toml
sed -i "s/private_key = \".*\"/private_key = \"$PRIVATE_KEY\"/" Scarb.toml

# Deploy world
echo "Deploying world..."
sozo migrate --name "$WORLD_NAME"

# Get world address
DOJO_WORLD_ADDRESS=$(jq -r '.world.address' target/dev/manifest.json)
echo "World Address: $DOJO_WORLD_ADDRESS"

# Deploy torii
echo "Deploying Slot torii..."
slot deployments create "$WORLD_NAME" torii --rpc "$RPC_URL" --world "$DOJO_WORLD_ADDRESS" --start-block 0

# Run post deployment
echo "Running post deployment..."
scarb run slot_post_deploy || true

# Save deployment info
cat > "$TARGET_DIR/deployment.json" << EOF
{
    "PUBLIC_NODE_URL": "$RPC_URL",
    "PUBLIC_TORII": "$TORII_URL",
    "SLOT_KATANA": "$RPC_URL",
    "SLOT_TORII": "$TORII_URL",
    "SEED": $SEED,
    "TOTAL_ACCOUNTS": $TOTAL_ACCOUNTS,
    "DOJO_WORLD_ADDRESS": "$DOJO_WORLD_ADDRESS"
}
EOF

echo "=== Deployment Complete ==="
echo "Deployment info saved to: $TARGET_DIR/deployment.json"
