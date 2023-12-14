#!/bin/bash
set -euo pipefail
pushd $(dirname "$0")/..

# export DOJO_WORLD_ADDRESS="0x26065106fa319c3981618e7567480a50132f23932226a51c219ffb8e47daa84";
export DOJO_WORLD_ADDRESS="0x43a5bdc44469900f1d070a439c7fdfba764370d97305e73550b7eca535b89c2"
export DOJO_ACCOUNT_ADDRESS="0x033c627a3e5213790e246a917770ce23d7e562baa5b4d2917c23b1be6d91961c"
export DOJO_ACCOUNT_PRIVATE_KEY="0x0333803103001800039980190300d206608b0070db0012135bd1fb5f6282170b"

sozo execute put_color_system -c 1,1,0,128,0