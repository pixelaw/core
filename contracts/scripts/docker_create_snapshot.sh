#!/bin/bash
#set -euxo pipefail

echo $1
PROFILE=$1
GENERATE_POPULATED_CORE=$2

## We stop execution if PROFILE is "dev-pop" and GENERATE_POPULATED_CORE is false or not set
if [ "$PROFILE" = "dev-pop" ] && [ "$GENERATE_POPULATED_CORE" != "true" ]; then
  echo "Exiting because PROFILE is dev-pop and GENERATE_POPULATED_CORE is not true or is unset."
  exit 0
fi

export DOJO_KEYSTORE_PASSWORD=$(cat /run/secrets/DOJO_KEYSTORE_PASSWORD)
export STARKNET_KEYSTORE_PASSWORD=$(cat /run/secrets/DOJO_KEYSTORE_PASSWORD)


source scripts/lib/functions.sh

scripts/create_snapshot.sh $PROFILE

STORAGE_INIT_WORLD="/pixelaw/storage_init/$WORLD_ADDRESS"

echo $WORLD_ADDRESS

mkdir -p $STORAGE_INIT_WORLD

cp $GENESIS_OUT $STORAGE_INIT_WORLD/genesis.json
cp manifests/$PROFILE/deployment/manifest.json $STORAGE_INIT_WORLD/manifest.json

cp $KATANA_DB_ZIP $STORAGE_INIT_WORLD/katana_db.zip
cp $TORII_DB_ZIP $STORAGE_INIT_WORLD/torii.sqlite.zip
#rm -rf $OUT
