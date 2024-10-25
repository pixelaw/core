#!/bin/bash
set -uo pipefail

export PROFILE=${1:-"sepolia"}
export STARKNET_RPC=${2:-"https://starknet-sepolia.public.blastapi.io/rpc/v0_7"}

source ./scripts/lib/functions.sh

#sozo_account_deploy
#sozo account new deployer.account.json
#
#sozo_rebuild
#
#
#
sozo_migrate

init_actions
