#!/bin/bash
set -euo pipefail
pushd $(dirname "$0")/..

# Due to a bug in sozo migrate it now wipes contract addresses in manifest.json when using sozo migrate dev
# Now using a copy until that is fixed
cp target/dev/manifest.json target/dev/manifest.copy.json

source scripts/update_contracts.sh


# make sure all components/systems are deployed
CORE_MODELS=("App" "AppName" "CoreActionsAddress" "Pixel" "Permissions" "QueueItem")

APP_MODELS=("Game" "Player")

SNAKE_MODELS=("Snake" "SnakeSegment")

echo "Write permissions for CORE_ACTIONS"
for model in ${CORE_MODELS[@]}; do
    sleep 0.1
    sozo auth writer $model $CORE_ACTIONS
done
echo "Write permissions for CORE_ACTIONS: Done"

echo "Write permissions for PAINT_ACTIONS"
for model in ${APP_MODELS[@]}; do
    sleep 0.1
    sozo auth writer $model $PAINT_ACTIONS
done
echo "Write permissions for PAINT_ACTIONS: Done"

echo "Write permissions for SNAKE_ACTIONS"
for model in ${SNAKE_MODELS[@]}; do
    sleep 0.1
    sozo auth writer $model $SNAKE_ACTIONS
done
echo "Write permissions for SNAKE_ACTIONS: Done"

echo "Write permissions for RPS_ACTIONS"
for model in ${APP_MODELS[@]}; do
    sleep 0.1
    sozo auth writer $model $RPS_ACTIONS
done
echo "Write permissions for RPS_ACTIONS: Done"

#echo "Write permissions for MINESWEEPER_ACTIONS"
#for model in ${APP_MODELS[@]}; do
#    sleep 0.1
#    sozo auth writer $model $MINESWEEPER_ACTIONS
#done
#echo "Write permissions for MINESWEEPER_ACTIONS: Done"


echo "Initialize CORE_ACTIONS : $CORE_ACTIONS"
sleep 0.1
sozo execute $CORE_ACTIONS init
echo "Initialize CORE_ACTIONS: Done"

echo "Initialize SNAKE_ACTIONS: Done"
sleep 0.1
sozo execute $SNAKE_ACTIONS init
echo "Initialize SNAKE_ACTIONS: Done"

echo "Initialize PAINT_ACTIONS: Done"
sleep 0.1
sozo execute $PAINT_ACTIONS init
echo "Initialize PAINT_ACTIONS: Done"

echo "Initialize RPS_ACTIONS: Done"
sleep 0.1
sozo execute $RPS_ACTIONS init
echo "Initialize RPS_ACTIONS: Done"

#echo "Initialize MINESWEEPER: Done"
#sleep 0.1
#sozo execute $MINESWEEPER_ACTIONS init
#echo "Initialize MINESWEEPER_ACTIONS: Done"


