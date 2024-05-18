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
export TARGET="target/${PROFILE}"
export STARKNET_RPC="http://127.0.0.1:5050/"

OUT="out/$PROFILE"
GENESIS_TEMPLATE=genesis_template.json
GENESIS_OUT="$OUT/genesis.json"
KATANA_LOG="$OUT/katana.log"
KATANA_DB="$OUT/katana_db"
KATANA_DB_ZIP="$OUT/katana_db.zip"
MANIFEST="manifests/$PROFILE/manifest.json"
TORII_DB="$OUT/torii.sqlite"
TORII_DB_ZIP="$OUT/torii.sqlite.zip"
TORII_LOG="$OUT/torii.log"

# Stop existing katana/torii
pkill -f katana
pkill -f torii

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
  --disable-validate \
  --json-log \
  --db-dir $KATANA_DB \
  --allowed-origins "*" \
 > $KATANA_LOG 2>&1 &

# Wait for logfile to exist and not be empty
while ! test -s $KATANA_LOG; do
  sleep 1
done


# Sozo build
sozo \
  --profile $PROFILE \
   build

#starkli account deploy dev-account.json --keystore dev-keystore.json --rpc $STARKNET_RPC


# Sozo migrate
sozo \
  --profile $PROFILE \
  migrate plan \
  --name $PROFILE

sozo \
  --profile $PROFILE \
  migrate apply \
  --name $PROFILE

sleep 1

# Setup PixeLAW auth and init
declare "WORLD"=$(cat $MANIFEST | jq -r '.world.address')
declare "CORE_ACTIONS"=$(cat $MANIFEST | jq -r '.contracts[] | select(.name=="pixelaw::core::actions::actions") | .address')
declare "PAINT_ACTIONS"=$(cat $MANIFEST | jq -r '.contracts[] | select(.name=="pixelaw::apps::paint::app::paint_actions") | .address')
declare "SNAKE_ACTIONS"=$(cat $MANIFEST | jq -r '.contracts[] | select(.name=="pixelaw::apps::snake::app::snake_actions") | .address')

CORE_MODELS=("App" "AppName" "CoreActionsAddress" "Pixel" "Permissions" "QueueItem")
SNAKE_MODELS=("Snake" "SnakeSegment")

echo "Start Torii"
unset LS_COLORS && torii \
  --world $WORLD \
  --rpc $STARKNET_RPC \
  --database $TORII_DB \
  --events-chunk-size 10000 \
  --allowed-origins "*" \
 > $TORII_LOG 2>&1 &


echo "Write permissions for CORE_ACTIONS"
for model in ${CORE_MODELS[@]}; do
    sozo --profile $PROFILE auth grant writer $model,$CORE_ACTIONS
    sleep 0.2
done
echo "Write permissions for CORE_ACTIONS: Done"

echo "Write permissions for SNAKE_ACTIONS"
for model in ${SNAKE_MODELS[@]}; do
    sozo --profile $PROFILE auth grant writer $model,$SNAKE_ACTIONS
    sleep 0.2
done
echo "Write permissions for SNAKE_ACTIONS: Done"


echo "Initialize CORE_ACTIONS : $CORE_ACTIONS"
sozo --profile $PROFILE execute $CORE_ACTIONS init
sleep 0.2
echo "Initialize CORE_ACTIONS: Done"

echo "Initialize SNAKE_ACTIONS: Done"
sozo --profile $PROFILE execute $SNAKE_ACTIONS init
sleep 0.2
echo "Initialize SNAKE_ACTIONS: Done"

echo "Initialize PAINT_ACTIONS: Done"
sozo --profile $PROFILE execute $PAINT_ACTIONS init
sleep 0.2

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



# ---------------------------------------------------


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


# Patch the torii DB
echo "Patching Torii db"
sqlite3 $TORII_DB  "UPDATE indexers SET head = 0 WHERE rowid = 1;"

cd $OUT

echo "Creating zip file for katana_db"
zip -1 -r katana_db.zip katana_db

echo "Creating zip file for torii db"
zip -1 torii.sqlite.zip torii.sqlite


echo "Done"
