#!/bin/bash
set -euo pipefail
pushd $(dirname "$0")/..

# Read RPC_URL from the dojo_${SCARB_PROFILE}.toml file
RPC_URL=$(grep "rpc_url" dojo_${SCARB_PROFILE}.toml | cut -d '"' -f 2)
export STARKNET_RPC="$RPC_URL"


# make sure all components/systems are deployed
CORE_MODELS=("pixelaw-App" "pixelaw-AppName" "pixelaw-CoreActionsAddress" "pixelaw-Pixel" "pixelaw-Permissions" "pixelaw-QueueItem" "pixelaw-Snake" "pixelaw-Instruction")
SNAKE_MODELS=("pixelaw-Snake" "pixelaw-SnakeSegment")

echo "Write permissions for CORE_ACTIONS"
for model in ${CORE_MODELS[@]}; do
  sleep 0.1
  sozo --profile $SCARB_PROFILE auth grant writer model:$model,pixelaw-actions
done
echo "Write permissions for CORE_ACTIONS: Done"

echo "Write permissions for SNAKE_ACTIONS"
for model in ${SNAKE_MODELS[@]}; do
  sleep 0.1
  sozo --profile $SCARB_PROFILE auth grant writer model:$model,pixelaw-snake_actions
done
echo "Write permissions for SNAKE_ACTIONS: Done"

echo "Write permissions for PAINT_ACTIONS"
sleep 0.1
sozo --profile $SCARB_PROFILE auth grant writer model:pixelaw-Pixel,pixelaw-paint_actions
echo "Write permissions for PAINT_ACTIONS: Done"

echo "Initialize CORE_ACTIONS : pixelaw-actions"
sleep 0.1
sozo --profile $SCARB_PROFILE execute pixelaw-actions init
echo "Initialize CORE_ACTIONS: Done"

echo "Initialize SNAKE_ACTIONS: Done"
sleep 0.1
sozo --profile $SCARB_PROFILE execute pixelaw-snake_actions init
echo "Initialize SNAKE_ACTIONS: Done"

echo "Initialize PAINT_ACTIONS: Done"
sleep 0.1
sozo --profile $SCARB_PROFILE execute pixelaw-paint_actions init
echo "Initialize PAINT_ACTIONS: Done"
