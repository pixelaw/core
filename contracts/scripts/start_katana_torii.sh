#!/bin/bash
set -uo pipefail

export PROFILE=${1:-"dev"}

source ./scripts/lib/functions.sh

start_katana

start_torii

echo "Now running "

