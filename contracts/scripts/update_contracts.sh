#!/bin/bash
set -euo pipefail
pushd $(dirname "$0")/..


declare "CORE_ACTIONS"=$(cat target/dev/manifest.copy.json | jq -r '.contracts[] | select(.name=="actions") | .address')
declare "PAINT_ACTIONS"=$(cat target/dev/manifest.copy.json | jq -r '.contracts[] | select(.name=="paint_actions") | .address')
declare "SNAKE_ACTIONS"=$(cat target/dev/manifest.copy.json | jq -r '.contracts[] | select(.name=="snake_actions") | .address')
