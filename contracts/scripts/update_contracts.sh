#!/bin/bash
set -euo pipefail
pushd $(dirname "$0")/..


declare "CORE_ACTIONS"=$(cat manifests/dev/deployment/manifest.json | jq -r '.contracts[] | select(.tag=="pixelaw-actions") | .address')
declare "PAINT_ACTIONS"=$(cat manifests/dev/deployment/manifest.json | jq -r '.contracts[] | select(.tag=="pixelaw-paint_actions") | .address')
declare "SNAKE_ACTIONS"=$(cat manifests/dev/deployment/manifest.json | jq -r '.contracts[] | select(.tag=="pixelaw-snake_actions") | .address')
