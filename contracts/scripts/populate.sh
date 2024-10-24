#!/bin/bash
set -uo pipefail

export PROFILE=${1:-"dev"}
export NO_PACKING=${2:-"0"}
export STARKNET_RPC=${3:-"http://127.0.0.1:5050/"}

source ./scripts/lib/functions.sh

populate
