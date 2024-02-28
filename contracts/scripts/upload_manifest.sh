#!/bin/bash

SYSTEMS=("core" "paint" "snake")
DEFAULT_BASE_URL="http://localhost:3000/manifests"
JSON_FILE="./target/dev/manifest.json"

# Check if a command line argument is provided
if [ "$#" -ne 0 ]; then
    BASE_URL="$1"
else
    BASE_URL="$DEFAULT_BASE_URL"
fi

echo "---------------------------------------------------------------------------"
echo BASE_URL : $BASE_URL
echo "---------------------------------------------------------------------------"

echo "Uploading manifests for system"
echo " "
for system in ${SYSTEMS[@]}; do
    echo "Uploading manifest for" $system
    URL="${BASE_URL}/${system}"
    curl -X POST -H "Content-Type: application/json" -d @"$JSON_FILE" "$URL"
    echo " "
    echo "Uploading manifest for" $system ": DONE"
    echo " "
done
