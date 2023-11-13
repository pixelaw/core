#!/bin/bash
set -euo pipefail
pushd $(dirname "$0")/..

# Get world address from manifest
ACCOUNTS_JSON=$(curl --silent -X POST http://localhost:5050 -H "Content-Type: application/json" -d '{
                "jsonrpc": "2.0",
                "method": "katana_predeployedAccounts",
                "params": [],
                "id": 0
              }')

# Write the file
echo $(echo $ACCOUNTS_JSON | jq '.result') > target/dev/accounts.json

# Parse the JSON response with jq and get the number of elements
NUM_ELEMENTS=$(echo $ACCOUNTS_JSON | jq '.result | length')

# Loop over the elements and create a variable for each one
for (( i=0; i<$NUM_ELEMENTS; i++ ))
do
  # Create variables dynamically and assign the value of the current element's address and private_key to them
  declare "ACCOUNT_${i}_ADDRESS"=$(echo $ACCOUNTS_JSON | jq -r ".result[$i].address")
  declare "ACCOUNT_${i}_PRIVATE_KEY"=$(echo $ACCOUNTS_JSON | jq -r  ".result[$i].private_key")

done
