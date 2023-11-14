#!/bin/bash

SYSTEMS=("paint" "minesweeper" "snake" "rps")
BASE_URL="http://localhost:3000/manifests"
JSON_FILE="./target/dev/manifest.json"

echo "Upload manifests for system"
for system in ${SYSTEMS[@]}; do
    echo "Upload manifest for" $system
    URL="${BASE_URL}/${system}"
    curl -X POST -H "Content-Type: application/json" -d @"$JSON_FILE" "$URL"
    echo "Upload manifest for" $system ": DONE"
done
