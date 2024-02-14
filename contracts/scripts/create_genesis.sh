#!/bin/bash

target=$1


# Clear the classes key in target.json
jq '.classes = []' genesis.json > temp.json && mv temp.json genesis.json

# --------------------------------------------
# World
read -r world_class_hash <<<$(jq -r '.world.class_hash, .world.name' $target/manifest.json)

# Append class hash and class contents to classes array in genesis.json
jq --arg ch "$world_class_hash" --slurpfile cc "${target}/dojo::world::world.json" '.classes += [{"class_hash": $ch, "class": $cc[0]}]' genesis.json > genesis.json.tmp && mv genesis.json.tmp genesis.json

# --------------------------------------------
# Base
read -r base_class_hash <<<$(jq -r '.base.class_hash, .base.name' $target/manifest.json)

# Append class hash and class contents to classes array in genesis.json
jq --arg ch "$base_class_hash" --slurpfile cc "${target}/dojo::base::base.json" '.classes += [{"class_hash": $ch, "class": $cc[0]}]' genesis.json > genesis.json.tmp && mv genesis.json.tmp genesis.json

# --------------------------------------------
# Executor
read -r executor_class_hash <<<$(jq -r '.executor.class_hash, .executor.name' $target/manifest.json)

# Append class hash and class contents to classes array in genesis.json
jq --arg ch "$executor_class_hash" --slurpfile cc "${target}/dojo::executor::executor.json" '.classes += [{"class_hash": $ch, "class": $cc[0]}]' genesis.json > genesis.json.tmp && mv genesis.json.tmp genesis.json

# --------------------------------------------


