#!/bin/bash
set -euo pipefail
pushd $(dirname "$0")/..

export TARGET=${1:-"manifests/dev"}
export STARKNET_RPC="http://localhost:5050/"

GENESIS_TEMPLATE=genesis_template.json
GENESIS_OUT=genesis.json
KATANA_LOG=katana.log
MANIFEST=$TARGET/manifest.json
TORII_DB=torii.sqlite
TORII_LOG=torii.log

declare "WORLD_ADDRESS"=$(cat $MANIFEST | jq -r '.world.address')

source scripts/update_contracts.sh

## Set RPC_URL with default value
#RPC_URL="http://localhost:5050"

# Check if a command line argument is supplied
if [ $# -gt 0 ]; then
    # If an argument is supplied, use it as the RPC_URL
    RPC_URL=$1
fi

# make sure all components/systems are deployed
CORE_MODELS=("App" "AppName" "CoreActionsAddress" "Pixel" "Permissions" "QueueItem")

SNAKE_MODELS=("Snake" "SnakeSegment")

echo "Write permissions for CORE_ACTIONS"
for model in ${CORE_MODELS[@]}; do
    sleep 0.1
    sozo  --profile $SCARB_PROFILE auth grant writer $model,$CORE_ACTIONS
done
echo "Write permissions for CORE_ACTIONS: Done"

echo "Write permissions for SNAKE_ACTIONS"
for model in ${SNAKE_MODELS[@]}; do
    sleep 0.1
    sozo --profile $SCARB_PROFILE auth grant writer  $model,$SNAKE_ACTIONS
done
echo "Write permissions for SNAKE_ACTIONS: Done"


echo "Initialize CORE_ACTIONS : $CORE_ACTIONS"
sleep 0.1
sozo --profile $SCARB_PROFILE execute $CORE_ACTIONS init
echo "Initialize CORE_ACTIONS: Done"

echo "Initialize SNAKE_ACTIONS: Done"
sleep 0.1
sozo --profile $SCARB_PROFILE execute $SNAKE_ACTIONS init
echo "Initialize SNAKE_ACTIONS: Done"

echo "Initialize PAINT_ACTIONS: Done"
sleep 0.1
sozo --profile $SCARB_PROFILE execute $PAINT_ACTIONS init
echo "Initialize PAINT_ACTIONS: Done"
