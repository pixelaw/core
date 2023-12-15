#!/bin/bash
set -euo pipefail
pushd $(dirname "$0")/..


declare "CORE_ACTIONS"=$(cat target/dev/manifest.copy.json | jq -r '.contracts[] | select(.name=="pixelaw::core::actions::actions") | .address')
declare "PAINT_ACTIONS"=$(cat target/dev/manifest.copy.json | jq -r '.contracts[] | select(.name=="pixelaw::apps::paint::app::paint_actions") | .address')
declare "SNAKE_ACTIONS"=$(cat target/dev/manifest.copy.json | jq -r '.contracts[] | select(.name=="pixelaw::apps::snake::app::snake_actions") | .address')
