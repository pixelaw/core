#!/bin/bash
set -euo pipefail
pushd $(dirname "$0")/..

sozo execute --profile $SCARB_PROFILE pixelaw-actions init --wait
sozo execute --profile $SCARB_PROFILE pixelaw-snake_actions init --wait
sozo execute --profile $SCARB_PROFILE pixelaw-paint_actions init --wait
