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

# Copy manifest file (manifest_$PROFILE.json from root or target/$PROFILE/manifest.json)
MANIFEST_FILE="manifest_$PROFILE.json"
if [ ! -f "$MANIFEST_FILE" ]; then
    MANIFEST_FILE="target/$PROFILE/manifest.json"
fi

cp $MANIFEST_FILE $STORAGE_INIT_WORLD/manifest.json

cp $KATANA_DB_ZIP $STORAGE_INIT_WORLD/katana_db.zip

rm -rf $OUT

