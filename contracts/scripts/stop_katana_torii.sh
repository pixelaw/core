#!/bin/bash
set -uo pipefail

export PROFILE=${1:-"dev"}

source ./scripts/lib/functions.sh

kill_katana_torii
