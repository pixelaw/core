#!/bin/bash

###########################################################
# Prerequisites for running this script:
# 1. The script should be executed from the 'contracts/' directory.
# 2. Ensure the following tools are installed:
#    - katana
#    - starkli
#    - jq
###########################################################

TARGET=${1:-"target/dev"}

export STARKNET_RPC="http://localhost:5050/"


GENESIS_TEMPLATE=genesis_template.json
GENESIS_OUT=genesis.json
KATANA_LOG=katana.log
MANIFEST=$TARGET/manifest.json
TORII_DB=torii_db.sqlite
TORII_LOG=torii.log


# Clear the target
rm -rf $TARGET



# Start Katana
katana \
  --genesis $GENESIS_TEMPLATE \
  --disable-fee \
  --disable-validate \
  --json-log \
 > $KATANA_LOG 2>&1 &

# Sozo build
sozo build

# Sozo migrate
sozo migrate

# Setup PixeLAW auth and init
declare "WORLD"=$(cat $MANIFEST | jq -r '.world.address')
declare "CORE_ACTIONS"=$(cat $MANIFEST | jq -r '.contracts[] | select(.name=="pixelaw::core::actions::actions") | .address')
declare "PAINT_ACTIONS"=$(cat $MANIFEST | jq -r '.contracts[] | select(.name=="pixelaw::apps::paint::app::paint_actions") | .address')
declare "SNAKE_ACTIONS"=$(cat $MANIFEST | jq -r '.contracts[] | select(.name=="pixelaw::apps::snake::app::snake_actions") | .address')

CORE_MODELS=("App" "AppName" "CoreActionsAddress" "Pixel" "Permissions" "QueueItem")
SNAKE_MODELS=("Snake" "SnakeSegment")


echo "Write permissions for CORE_ACTIONS"
for model in ${CORE_MODELS[@]}; do
    sleep 0.1
    sozo auth writer $model $CORE_ACTIONS --rpc-url $STARKNET_RPC --world $WORLD
done
echo "Write permissions for CORE_ACTIONS: Done"

echo "Write permissions for SNAKE_ACTIONS"
for model in ${SNAKE_MODELS[@]}; do
    sleep 0.1
    sozo auth writer $model $SNAKE_ACTIONS --rpc-url $STARKNET_RPC --world $WORLD
done
echo "Write permissions for SNAKE_ACTIONS: Done"


echo "Initialize CORE_ACTIONS : $CORE_ACTIONS"
sleep 0.1
sozo execute $CORE_ACTIONS init --rpc-url $STARKNET_RPC
echo "Initialize CORE_ACTIONS: Done"

echo "Initialize SNAKE_ACTIONS: Done"
sleep 0.1
sozo execute $SNAKE_ACTIONS init --rpc-url $STARKNET_RPC
echo "Initialize SNAKE_ACTIONS: Done"

echo "Initialize PAINT_ACTIONS: Done"
sleep 0.1
sozo execute $PAINT_ACTIONS init --rpc-url $STARKNET_RPC
sleep 1
echo "Initialize PAINT_ACTIONS: Done"

# ---------------------------------------------------

# Get the last block number from the katana log
last_block_number=$(tail -n 1 $KATANA_LOG | jq -r '.fields.message' | grep -oP '(\d+)' | head -n 1)


# Prep genesis out
cat $GENESIS_TEMPLATE > $GENESIS_OUT



## Contracts
for i in $(seq 1 $last_block_number)
do

   output=$(starkli state-update $i)

   # Process deployed_contracts
   length=$(echo $output | jq '.state_diff.deployed_contracts | length')
   for j in $(seq 0 $(($length-1)))
   do
      address=$(echo $output | jq -r ".state_diff.deployed_contracts[$j].address")
      class_hash=$(echo $output | jq -r ".state_diff.deployed_contracts[$j].class_hash")
      jq --arg addr "$address" --arg class "$class_hash" \
         '.contracts[$addr] = {"class": $class}' $GENESIS_OUT > tmp.json && mv tmp.json $GENESIS_OUT
   done

   # Process storage_diffs
   length=$(echo $output | jq '.state_diff.storage_diffs | length')
   for j in $(seq 0 $(($length-1)))
   do
      address=$(echo $output | jq -r ".state_diff.storage_diffs[$j].address")
      entries_length=$(echo $output | jq ".state_diff.storage_diffs[$j].storage_entries | length")
      for k in $(seq 0 $(($entries_length-1)))
      do
         key=$(echo $output | jq -r ".state_diff.storage_diffs[$j].storage_entries[$k].key")
         value=$(echo $output | jq -r ".state_diff.storage_diffs[$j].storage_entries[$k].value")
         jq --arg addr "$address" --arg key "$key" --arg val "$value" \
            '.contracts[$addr].storage[$key] = $val' $GENESIS_OUT > tmp.json && mv tmp.json $GENESIS_OUT
      done
   done
done

## Classes of Dojo contracts
## World
read -r class_hash <<<$(jq -r '.world.class_hash' $MANIFEST)
jq --arg ch "$class_hash" --slurpfile cc "${TARGET}/dojo::world::world.json" '.classes += [{"class_hash": $ch, "class": $cc[0]}]' $GENESIS_OUT > $GENESIS_OUT.tmp && mv $GENESIS_OUT.tmp $GENESIS_OUT

## Base
read -r class_hash <<<$(jq -r '.base.class_hash' $MANIFEST)
jq --arg ch "$class_hash" --slurpfile cc "${TARGET}/dojo::base::base.json" '.classes += [{"class_hash": $ch, "class": $cc[0]}]' $GENESIS_OUT > $GENESIS_OUT.tmp && mv $GENESIS_OUT.tmp $GENESIS_OUT

## Executor
read -r class_hash <<<$(jq -r '.executor.class_hash' $MANIFEST)
jq --arg ch "$class_hash" --slurpfile cc "${TARGET}/dojo::executor::executor.json" '.classes += [{"class_hash": $ch, "class": $cc[0]}]' $GENESIS_OUT > $GENESIS_OUT.tmp && mv $GENESIS_OUT.tmp $GENESIS_OUT


## Classes of Contracts
for row in $(cat $MANIFEST | jq -r '.contracts[] | @base64'); do
    _jq() {
     echo ${row} | base64 --decode | jq -r ${1}
    }

   address=$(_jq '.address')
   class_hash=$(_jq '.class_hash')
   jq --arg ch "$class_hash" --slurpfile cc "${TARGET}/$(_jq '.name').json" '.classes += [{"class_hash": $ch, "class": $cc[0]}]' $GENESIS_OUT > $GENESIS_OUT.tmp && mv $GENESIS_OUT.tmp $GENESIS_OUT
   jq --arg addr "$address" --arg ch "$class_hash" '.contracts[$addr].class = $ch' $GENESIS_OUT > $GENESIS_OUT.tmp && mv $GENESIS_OUT.tmp $GENESIS_OUT
done


## Models
for row in $(cat $MANIFEST | jq -r '.models[] | @base64'); do
    _jq() {
     echo ${row} | base64 --decode | jq -r ${1}
    }

   class_hash=$(_jq '.class_hash')
   jq --arg ch "$class_hash" --slurpfile cc "${TARGET}/$(_jq '.name').json" '.classes += [{"class_hash": $ch, "class": $cc[0]}]' $GENESIS_OUT > $GENESIS_OUT.tmp && mv $GENESIS_OUT.tmp $GENESIS_OUT
done

echo "Populating Torii db"
# Wipe Torii DB
rm -f $TORII_DB

# Start Torii
torii \
  --world $WORLD \
  --rpc $STARKNET_RPC \
  --database $TORII_DB \
 > $TORII_LOG 2>&1 &

# Watch the torii log until the last block, then kill it

tail -f $TORII_LOG | while read LOGLINE
do
   [[ "${LOGLINE}" == *"processed block: ${last_block_number}"* ]] && pkill -f "torii"
done

# Kill katana
pkill -f katana

echo "Done"
