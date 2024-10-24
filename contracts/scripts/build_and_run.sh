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
export STARKNET_RPC=${3:-"http://127.0.0.1:5050/"}

source ./scripts/lib/functions.sh


start_katana

sozo_rebuild


#starkli account deploy dev-account.json --keystore dev-keystore.json --rpc $STARKNET_RPC

sozo_migrate

declare "WORLD"=$(cat $MANIFEST | jq -r '.world.address')

start_torii

grant_write_permissions

init_actions

if [ "$PROFILE" == "dev-pop" ]; then
    populate
fi


echo "Now running"