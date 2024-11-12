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

# First do "build and run"
source ./scripts/build_and_run.sh

prepare_genesis

wait_for_torii_writing

sleep 3

echo "Stopping katana and torii"
pkill -f torii
pkill -f katana

sleep 2

patch_torii_db

zip_databases



echo "Done"
