#!/bin/bash
set -euxo pipefail

echo $1
PROFILE=$1

export DOJO_KEYSTORE_PASSWORD=$(cat /run/secrets/DOJO_KEYSTORE_PASSWORD)
export STARKNET_KEYSTORE_PASSWORD=$(cat /run/secrets/DOJO_KEYSTORE_PASSWORD)

source scripts/lib/functions.sh

scripts/create_snapshot.sh $PROFILE

#export WORLD_ADDRESS=$(cat $MANIFEST | jq -r '.world.address')

STORAGE_INIT_WORLD="/pixelaw/storage_init"

mkdir -p $STORAGE_INIT_WORLD

cp $GENESIS_TEMPLATE $STORAGE_INIT_WORLD/genesis.json
cp manifest_$PROFILE.json $STORAGE_INIT_WORLD/manifest.json

cp $KATANA_DB_ZIP $STORAGE_INIT_WORLD/katana_db.zip

rm -rf $OUT

