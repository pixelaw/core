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


GENESIS_TEMPLATE=genesis_template.json
GENESIS_OUT=genesis_1.json
KATANA_LOG=katana.log

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

# Get the last block number from the katana log
last_block_number=$(tail -n 1 $KATANA_LOG | jq -r '.fields.message' | grep -oP '(\d+)' | head -n 1)
echo $last_block_number

# Prep genesis out
cat $GENESIS_TEMPLATE > $GENESIS_OUT

export STARKNET_RPC="http://localhost:5050/"


## Contracts
for i in $(seq 1 $last_block_number)
do

   output=$(starkli state-update $i)
  echo $output
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
read -r class_hash <<<$(jq -r '.world.class_hash' $TARGET/manifest.json)
jq --arg ch "$class_hash" --slurpfile cc "${TARGET}/dojo::world::world.json" '.classes += [{"class_hash": $ch, "class": $cc[0]}]' $GENESIS_OUT > $GENESIS_OUT.tmp && mv $GENESIS_OUT.tmp $GENESIS_OUT

## Base
read -r class_hash <<<$(jq -r '.base.class_hash' $TARGET/manifest.json)
jq --arg ch "$class_hash" --slurpfile cc "${TARGET}/dojo::base::base.json" '.classes += [{"class_hash": $ch, "class": $cc[0]}]' $GENESIS_OUT > $GENESIS_OUT.tmp && mv $GENESIS_OUT.tmp $GENESIS_OUT

## Executor
read -r class_hash <<<$(jq -r '.executor.class_hash' $TARGET/manifest.json)
jq --arg ch "$class_hash" --slurpfile cc "${TARGET}/dojo::executor::executor.json" '.classes += [{"class_hash": $ch, "class": $cc[0]}]' $GENESIS_OUT > $GENESIS_OUT.tmp && mv $GENESIS_OUT.tmp $GENESIS_OUT


## Classes of Contracts
for row in $(cat $TARGET/manifest.json | jq -r '.contracts[] | @base64'); do
    _jq() {
     echo ${row} | base64 --decode | jq -r ${1}
    }

   address=$(_jq '.address')
   class_hash=$(_jq '.class_hash')
   jq --arg ch "$class_hash" --slurpfile cc "${TARGET}/$(_jq '.name').json" '.classes += [{"class_hash": $ch, "class": $cc[0]}]' $GENESIS_OUT > $GENESIS_OUT.tmp && mv $GENESIS_OUT.tmp $GENESIS_OUT
   jq --arg addr "$address" --arg ch "$class_hash" '.contracts[$addr].class = $ch' $GENESIS_OUT > $GENESIS_OUT.tmp && mv $GENESIS_OUT.tmp $GENESIS_OUT
done


## Models
for row in $(cat $TARGET/manifest.json | jq -r '.models[] | @base64'); do
    _jq() {
     echo ${row} | base64 --decode | jq -r ${1}
    }

   class_hash=$(_jq '.class_hash')
   jq --arg ch "$class_hash" --slurpfile cc "${TARGET}/$(_jq '.name').json" '.classes += [{"class_hash": $ch, "class": $cc[0]}]' $GENESIS_OUT > $GENESIS_OUT.tmp && mv $GENESIS_OUT.tmp $GENESIS_OUT
done


# Kill katana
pkill -f katana
