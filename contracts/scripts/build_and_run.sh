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

source ./scripts/lib/functions.sh

clear_katana
clear_torii

start_katana

sozo_rebuild

#export WORLD_ADDRESS=$(cat $MANIFEST | jq -r '.world.address')

start_torii

sozo_migrate



#init_actions

if [ "$PROFILE" == "dev-pop" ]; then
    populate
fi

echo "Now running"

