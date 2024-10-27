#!/bin/bash
set -uo pipefail

export PROFILE="slot"

source ./scripts/lib/functions.sh

#sozo_account_deploy
#sozo account new deployer.account.json
#
sozo_rebuild
#
#
#
sozo_migrate

#init_actions
