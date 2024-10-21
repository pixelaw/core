#!/bin/bash
set -uo pipefail

###########################################################
# Prerequisites for running this script:
# 1. The script should be executed from the 'contracts/' directory.
# 2. Ensure the following tools are installed:
#    - katana
#    - starkli
#    - jq
###########################################################




export PROFILE=${1:-"dev"}
export NO_PACKING=${2:-"0"}
export TARGET="target/${PROFILE}"
export STARKNET_RPC="http://127.0.0.1:5050/"

OUT="out/$PROFILE"
GENESIS_TEMPLATE=genesis_template.json
GENESIS_OUT="$OUT/genesis.json"
KATANA_LOG="$OUT/katana.log"
KATANA_DB="$OUT/katana_db"
KATANA_DB_ZIP="$OUT/katana_db.zip"
MANIFEST="manifests/$PROFILE/deployment/manifest.json"
TORII_DB="$OUT/torii.sqlite"
TORII_DB_ZIP="$OUT/torii.sqlite.zip"
TORII_LOG="$OUT/torii.log"
DEPLOY_SCARB="Scarb_deploy.toml"

# Stop existing katana/torii
pkill -f katana
pkill -f torii

# TODO Ensure katana and torii are really stopped

# Ensure a clean last_block dir exist
rm -rf $OUT
mkdir -p $OUT

# Clear the target
rm -rf $TARGET


# Start Katana
katana \
  --genesis $GENESIS_TEMPLATE \
  --invoke-max-steps 4294967295 \
  --disable-fee \
  --json-log \
  --db-dir $KATANA_DB \
  --allowed-origins "*" \
 > $KATANA_LOG 2>&1 &

# Wait for logfile to exist and not be empty
while ! test -s $KATANA_LOG; do
  sleep 1
done


sozo clean
# Sozo build
echo "sozo build"

sozo \
  --profile $PROFILE \
  --manifest-path $DEPLOY_SCARB \
   build \
  --typescript \
  --bindings-output $OUT
echo "sozo migrate plan"
#starkli account deploy dev-account.json --keystore dev-keystore.json --rpc $STARKNET_RPC

## Sozo migrate
sozo \
  --profile $PROFILE \
  --manifest-path $DEPLOY_SCARB \
  migrate \
  plan

sozo \
  --profile $PROFILE \
  --manifest-path $DEPLOY_SCARB \
  migrate \
  apply

# sozo \
#   build \
#   --typescript \
#   --manifest-path $DEPLOY_SCARB \
#   --bindings-output $OUT

sleep 1

# Setup PixeLAW auth and init
declare "WORLD"=$(cat $MANIFEST | jq -r '.world.address')

CORE_MODELS=("pixelaw-App" "pixelaw-AppName" "pixelaw-CoreActionsAddress" "pixelaw-Pixel" "pixelaw-QueueItem" "pixelaw-RTree" "pixelaw-Area" "pixelaw-Snake")
SNAKE_MODELS=("pixelaw-Snake" "pixelaw-SnakeSegment")

echo "Start Torii"
unset LS_COLORS && torii \
  --world $WORLD \
  --rpc $STARKNET_RPC \
  --database $TORII_DB \
  --events-chunk-size 10000 \
  --allowed-origins "*" \
 > $TORII_LOG 2>&1 &


#Usage: sozo auth grant owner [OPTIONS] <resource,owner_address>...
#
#Arguments:
#  <resource,owner_address>...
#          A list of resources and owners to grant ownership to.
#          Comma separated values to indicate resource identifier and owner address.
#          A resource identifier must use the following format: <contract|c|namespace|ns|model|m>:<tag_or_name>.
#

echo "Write permissions for CORE_ACTIONS"
for model in ${CORE_MODELS[@]}; do
    sozo --manifest-path $DEPLOY_SCARB --profile $PROFILE auth grant --wait writer model:$model,pixelaw-actions
done
echo "Write permissions for CORE_ACTIONS: Done"

echo "Write permissions for SNAKE_ACTIONS"
for model in ${SNAKE_MODELS[@]}; do
    sozo --manifest-path $DEPLOY_SCARB --profile $PROFILE auth grant --wait writer model:$model,pixelaw-snake_actions
done
echo "Write permissions for SNAKE_ACTIONS: Done"


echo "Initialize CORE_ACTIONS"
sozo --manifest-path $DEPLOY_SCARB --profile $PROFILE execute --wait pixelaw-actions init
echo "Initialize CORE_ACTIONS: Done"

echo "Initialize SNAKE_ACTIONS: Done"
sozo --manifest-path $DEPLOY_SCARB --profile $PROFILE execute --wait pixelaw-snake_actions init
echo "Initialize SNAKE_ACTIONS: Done"

echo "Initialize PAINT_ACTIONS: Done"
sozo --manifest-path $DEPLOY_SCARB --profile $PROFILE execute --wait pixelaw-paint_actions init
echo "Initialize PAINT_ACTIONS: Done"


## Populating
if [ "$PROFILE" == "dev-pop" ]; then
   echo "Drawing an image"
    ./scripts/populate.sh
    sleep 1
fi

# Generating genesis.json

# Prep genesis out
cat $GENESIS_TEMPLATE > $GENESIS_OUT

echo "Genesis for the last block number"
last_block=$(starkli block)

echo $last_block

jq \
  --arg block_number "$(echo $last_block | jq -r '.block_number')" \
  --arg parent_hash "$(echo $last_block | jq -r '.parent_hash')" \
  --arg timestamp "$(echo $last_block | jq -r '.timestamp')" \
  '.parentHash = $parent_hash | .timestamp = ($timestamp  | tonumber) | .number = ($block_number  | tonumber)' \
  $GENESIS_OUT > temp.json \
  && mv temp.json $GENESIS_OUT






# Wait for 5 seconds so torii can process the katana events
echo "Waiting for Torii db to update"

prev_size=$(du -b "$TORII_LOG" | cut -f1)

while true; do
    sleep 5
    new_size=$(du -b "$TORII_LOG" | cut -f1)
    if [ $new_size -eq $prev_size ]; then
        break
    else
        prev_size=$new_size
    fi
done


sleep 3

echo "Stopping katana and torii"
pkill -f torii
pkill -f katana

sleep 1
# Patch the torii DB
echo "Patching Torii db"
sqlite3 $TORII_DB  "UPDATE contracts SET head = 0;"


# ---------------------------------------------------
if [ "$NO_PACKING" == "1" ]; then
   echo "Running in dev mode.. not zipping but keeping everything running"
   # Stop existing katana/torii
   pkill -f katana
   pkill -f torii

  katana \
    --genesis $GENESIS_OUT \
    --invoke-max-steps 4294967295 \
    --disable-fee \
    --block-time 2000 \
    --json-log \
    --db-dir $KATANA_DB \
    --allowed-origins "*" \
   > $KATANA_LOG 2>&1 &

  unset LS_COLORS && torii \
    --world $WORLD \
    --rpc $STARKNET_RPC \
    --database $TORII_DB \
    --events-chunk-size 10000 \
    --allowed-origins "*" \
   > $TORII_LOG 2>&1 &

   exit
fi

cd $OUT

echo "Creating zip file for katana_db"
zip -1 -r katana_db.zip katana_db

echo "Creating zip file for torii db"
zip -1 torii.sqlite.zip torii.sqlite


echo "Done"
