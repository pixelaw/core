#!/bin/bash
set -uo pipefail

export PROFILE=${1:-"sepolia"}

source ./scripts/lib/functions.sh

read -sp "Enter keystore password: " DOJO_KEYSTORE_PASSWORD
export DOJO_KEYSTORE_PASSWORD
echo # just to add a newline after the input

#sozo_account_deploy
#sozo account new deployer.account.json
#
sozo_rebuild
#
#
#
sozo_migrate

init_actions
