#!/bin/bash
set -euo pipefail
pushd $(dirname "$0")/..

WORLD_NAME=$1
BASE_URL="https://api.cartridge.gg/x/${WORLD_NAME}"
RPC_URL="${BASE_URL}/katana"
TORII_URL="${BASE_URL}/torii"
TARGET_DIRECTORY="target/dev/$WORLD_NAME"

echo "---------------------------------------------------------------------------------------------"
echo "WORLD_NAME: $WORLD_NAME"
echo "TARGET_DIRECTORY: $TARGET_DIRECTORY"
echo "---------------------------------------------------------------------------------------------"

echo "Deploying slot katana"
#slot deployments create $WORLD_NAME katana --invoke-max-steps 4000000000
if [ ! -d "$TARGET_DIRECTORY" ]; then
    mkdir -p $TARGET_DIRECTORY
fi
#slot deployments logs $WORLD_NAME katana > $TARGET_DIRECTORY/katana-logs.txt

# Initialize an empty JSON object
#json='{"accounts": [], "seed": 0}'
#
## Read the input text from a file
#input=$(cat $TARGET_DIRECTORY/katana-logs.txt)
#
## Parse the input text
#while IFS= read -r line; do
#    if [[ $line == "ACCOUNTS SEED"* ]]; then
#        read -r seed_line
#        seed=${seed_line##*=}
#        json=$(echo $json | jq --arg seed "$seed" '.seed = $seed')
#    elif [[ $line == *"|"* ]]; then
#        key=${line%%|*}
#        value=${line##*|}
#        if [[ $key == "Account address "* ]]; then
#            account='{"account_address": "", "private_key": "", "public_key": ""}'
#        fi
#        if [[ -n ${account+x} ]]; then
#            account=$(echo $account | jq --arg key "${key// /_}" --arg value "$value" '."$key" = $value')
#            if [[ $key == "Public key "* ]]; then
#                json=$(echo $json | jq --argjson account "$account" '.accounts += [$account]')
#                unset account
#            fi
#        fi
#    fi
#done <<< "$input"
#echo $json
#
## Write the JSON object to a file
#echo $json > $TARGET_DIRECTORY/accounts.json
#
#
#ACCOUNT_ADDRESS=($(cat $TARGET_DIRECTORY/accounts.json | jq -r '.accounts[] | first | .account_address'))
#PRIVATE_KEY=($(cat $TARGET_DIRECTORY/accounts.json | jq -r '.acoounts[] | first | .private_key'))
#SEED=($(cat $TARGET_DIRECTORY/accounts.json | jq -r '.seed'))
#
#sed -i "s/rpc_url = ".*"/rpc_url = "$RPC_URL"/" Scarb.toml
#sed -i "s/account_address = ".*"/account_address = "$ACCOUNT_ADDRESS"/" Scarb.toml
#sed -i "s/private_key = ".*"/private_key = "$PRIVATE_KEY"/" Scarb.toml
#
#echo "Deploying world"
#sozo migrate --name $WORLD_NAME

# Get world address from manifest
WORLD_ADDRESS=$(cat target/dev/manifest.json | jq -r '.world.address')

echo "Deploying torii"
#slot deployments create $WORLD_NAME torii --rpc $RPC_URL --world $WORLD_ADDRESS --start-block 0

echo "Running post deployment"
#scarb run slot_post_deploy

SEED=12551975208350626939

echo "{\"PUBLIC_NODE_URL\": \"$RPC_URL\", \"PUBLIC_TORII\": \"$TORII_URL\", \"SLOT_KATANA\": \"$RPC_URL\", \"SLOT_TORII\": \"$TORII_URL\", \"SEED\": $SEED, \"TOTAL_ACCOUNTS\": 4, \"WORLD_ADDRESS\": \"$WORLD_ADDRESS\" }" > $TARGET_DIRECTORY/deployment.json


