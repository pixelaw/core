#!/bin/bash
set -euo pipefail
pushd $(dirname "$0")/..

WORLD_NAME=$1
BASE_URL="https://api.cartridge.gg/x/${WORLD_NAME}"
RPC_URL="${BASE_URL}/katana"
TORII_URL="${BASE_URL}/torii"
TARGET_DIRECTORY="target/dev/$WORLD_NAME"
TOTAL_ACCOUNTS=4

echo "---------------------------------------------------------------------------------------------"
echo "WORLD_NAME: $WORLD_NAME"
echo "BASE_URL: $BASE_URL"
echo "TARGET_DIRECTORY: $TARGET_DIRECTORY"
echo "---------------------------------------------------------------------------------------------"

echo "Deploying slot katana"
slot deployments create $WORLD_NAME katana --invoke-max-steps 4000000000
if [ ! -d "$TARGET_DIRECTORY" ]; then
    mkdir -p $TARGET_DIRECTORY
fi
sleep 10
slot deployments logs $WORLD_NAME katana > $TARGET_DIRECTORY/katana-logs.txt

# Read the input text from a file
logs=$(cat $TARGET_DIRECTORY/katana-logs.txt)

# Extract the first account address and remove spaces
ACCOUNT_ADDRESS=$(echo "$logs" | grep '| Account address |' | awk -F '|' '{print $3}' | head -n 1 | tr -d ' ')

# Extract the first private key and remove spaces
PRIVATE_KEY=$(echo "$logs" | grep '| Private key     |' | awk -F '|' '{print $3}' | head -n 1 | tr -d ' ')

# Extract the accounts seed
SEED=$(echo "$logs" | grep 'ACCOUNTS SEED' -A 2 | tail -n 1 | tr -d ' ')

sed -i 's#rpc_url = ".*"#rpc_url = "'"$RPC_URL"'"#' Scarb.toml
sed -i "s/account_address = ".*"/account_address = \""$ACCOUNT_ADDRESS\""/" Scarb.toml
sed -i "s/private_key = ".*"/private_key = \""$PRIVATE_KEY\""/" Scarb.toml

echo "Deploying world"
sozo migrate --name $WORLD_NAME

# Get world address from manifest
WORLD_ADDRESS=$(cat target/dev/manifest.json | jq -r '.world.address')

echo "Deploying torii"
slot deployments create $WORLD_NAME torii --rpc $RPC_URL --world $WORLD_ADDRESS --start-block 0

echo "Running post deployment"
scarb run slot_post_deploy

echo -e "{\
\n\t\"PUBLIC_NODE_URL\": \"$RPC_URL\", \
\n\t\"PUBLIC_TORII\": \"$TORII_URL\", \
\n\t\"SLOT_KATANA\": \"$RPC_URL\", \
\n\t\"SLOT_TORII\": \"$TORII_URL\", \
\n\t\"SEED\": $SEED, \
\n\t\"TOTAL_ACCOUNTS\": $TOTAL_ACCOUNTS, \
\n\t\"WORLD_ADDRESS\": \"$WORLD_ADDRESS\" \
\n}" > $TARGET_DIRECTORY/deployment.json



