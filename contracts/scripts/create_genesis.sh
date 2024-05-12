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
MANIFEST="manifests/$PROFILE/manifest.json"
TORII_DB="$OUT/torii.sqlite"
TORII_LOG="$OUT/torii.log"

# Stop existing katana/torii
pkill -f katana
pkill -f torii

# Ensure a clean output dir exist
rm -rf $OUT
mkdir -p $OUT

# Clear the target
rm -rf $TARGET


# Start Katana
katana \
  --genesis $GENESIS_TEMPLATE \
  --disable-fee \
  --disable-validate \
  --json-log \
  --allowed-origins "*" \
 > $KATANA_LOG 2>&1 &

# Wait for logfile to exist and not be empty
while ! test -s $KATANA_LOG; do
  sleep 1
done


# Sozo build
sozo \
  --offline \
  --profile $PROFILE \
   build

#starkli account deploy dev-account.json --keystore dev-keystore.json --rpc $STARKNET_RPC


# Sozo migrate
sozo \
  --profile $PROFILE \
  --offline \
  migrate plan \
  --name $PROFILE

sozo \
  --profile $PROFILE \
  --offline \
  migrate apply \
  --name $PROFILE


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
    sozo --profile $PROFILE auth grant writer $model,$CORE_ACTIONS
done
echo "Write permissions for CORE_ACTIONS: Done"

echo "Write permissions for SNAKE_ACTIONS"
for model in ${SNAKE_MODELS[@]}; do
    sleep 0.1
    sozo --profile $PROFILE auth grant writer $model,$SNAKE_ACTIONS
done
echo "Write permissions for SNAKE_ACTIONS: Done"


echo "Initialize CORE_ACTIONS : $CORE_ACTIONS"
sleep 0.1
sozo --profile $PROFILE execute $CORE_ACTIONS init
echo "Initialize CORE_ACTIONS: Done"

echo "Initialize SNAKE_ACTIONS: Done"
sleep 0.1
sozo --profile $PROFILE execute $SNAKE_ACTIONS init
echo "Initialize SNAKE_ACTIONS: Done"

echo "Initialize PAINT_ACTIONS: Done"
sleep 0.1
sozo --profile $PROFILE execute $PAINT_ACTIONS init
sleep 1
echo "Initialize PAINT_ACTIONS: Done"

# ---------------------------------------------------

# Get the last block number from the katana log
last_block_number=$(tail -n 1 $KATANA_LOG | jq -r '.fields.block_number')

echo "Last block number: ${last_block_number}"

echo "Generating $GENESIS_OUT"
# Prep genesis out
cat $GENESIS_TEMPLATE > $GENESIS_OUT


echo "Generating contracts in genesis from katana txns"
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

echo "Genesis for the last block number"
output=$(starkli block $last_block_number)

jq \
  --arg parent_hash "$(echo $output | jq -r '.parent_hash')" \
  --arg timestamp "$(echo $output | jq -r '.timestamp')" \
  '.parentHash = $parent_hash | .timestamp = ($timestamp  | tonumber)' \
  $GENESIS_OUT > temp.json \
  && mv temp.json $GENESIS_OUT



## Classes of Dojo contracts
## World
read -r class_hash <<<$(jq -r '.world.class_hash' $MANIFEST)
jq --arg ch "$class_hash" --slurpfile cc "${TARGET}/dojo::world::world.json" '.classes += [{"class_hash": $ch, "class": $cc[0]}]' $GENESIS_OUT > $GENESIS_OUT.tmp && mv $GENESIS_OUT.tmp $GENESIS_OUT

## Base
read -r class_hash <<<$(jq -r '.base.class_hash' $MANIFEST)
jq --arg ch "$class_hash" --slurpfile cc "${TARGET}/dojo::base::base.json" '.classes += [{"class_hash": $ch, "class": $cc[0]}]' $GENESIS_OUT > $GENESIS_OUT.tmp && mv $GENESIS_OUT.tmp $GENESIS_OUT

## resource_metadata
read -r class_hash <<<$(jq -r '.resource_metadata.class_hash' $MANIFEST)
jq --arg ch "$class_hash" --slurpfile cc "${TARGET}/dojo::resource_metadata::resource_metadata.json" '.classes += [{"class_hash": $ch, "class": $cc[0]}]' $GENESIS_OUT > $GENESIS_OUT.tmp && mv $GENESIS_OUT.tmp $GENESIS_OUT


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

## Painting "HELLO"
if [ "$PROFILE" == "dev-pop" ]; then
    ./scripts/paint.sh
fi

echo "Populating Torii db"

# Start Torii
unset LS_COLORS && torii \
  --world $WORLD \
  --rpc $STARKNET_RPC \
  --database $TORII_DB \
  --allowed-origins "*" \
 > $TORII_LOG 2>&1 &



# Wait for 5 seconds so torii can process the katana events
echo "Waiting for Torii db to update"
sleep 5

echo "Stopping katana and torii"
#pkill -f torii
#pkill -f katana


# Patch the torii DB
echo "Patching Torii db"
sqlite3 $TORII_DB  "UPDATE indexers SET head = 0 WHERE rowid = 1;"


echo "Done"
