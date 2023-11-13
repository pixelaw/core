#!/bin/bash
set -euo pipefail
pushd $(dirname "$0")/..

# export DOJO_WORLD_ADDRESS="0x26065106fa319c3981618e7567480a50132f23932226a51c219ffb8e47daa84";
export DOJO_WORLD_ADDRESS="0x43a5bdc44469900f1d070a439c7fdfba764370d97305e73550b7eca535b89c2"
# Get the component of a pixel
sozo component entity "$@" 2,2
