#!/bin/bash
set -euo pipefail

###########################################################
# Calculate deterministic world address for PixeLAW
#
# Extracts it from sozo migrate output which computes:
# address = get_contract_address(
#   salt = poseidon_hash("pixelaw"),
#   world_class_hash,
#   constructor_calldata = [],
#   deployer = 0x0
# )
###########################################################

export PROFILE=${1:-"dev"}

source ./scripts/lib/functions.sh

echo "Building contracts with profile: $PROFILE" >&2
sozo_rebuild > /dev/null 2>&1

echo "" >&2
echo "Starting Katana temporarily..." >&2
mkdir -p $OUT

# Start Katana without waiting for log file (container-friendly)
katana \
  --invoke-max-steps 4294967295 \
  --db-dir $KATANA_DB \
  --http.cors_origins "*" \
  --dev \
  --dev.seed 0 \
  --dev.no-fee \
  --dev.accounts 10 \
  > $KATANA_LOG 2>&1 &

# Wait for Katana to be ready (check RPC)
for i in {1..30}; do
  if curl -s -X POST http://localhost:5050 \
    -H "Content-Type: application/json" \
    -d '{"jsonrpc":"2.0","method":"starknet_chainId","params":[],"id":1}' \
    > /dev/null 2>&1; then
    echo "Katana ready" >&2
    break
  fi
  sleep 1
done

echo "Running sozo migrate to compute world address..." >&2

# Capture migrate output (it will fail but shows the deterministic address)
echo "Calling sozo migrate (30s timeout)..." >&2
MIGRATE_LOG="/tmp/migrate_output.log"
timeout 30 sozo \
  --profile $PROFILE \
  --manifest-path $DEPLOY_SCARB \
  migrate > $MIGRATE_LOG 2>&1 || true
MIGRATE_OUTPUT=$(cat $MIGRATE_LOG)

echo "Migrate command completed, cleaning up..." >&2

# Kill Katana
pkill -f katana > /dev/null 2>&1 || true
sleep 1

# Extract deterministic address
echo "Extracting deterministic address from output..." >&2

# Try to find "Overriding deterministic address `0x...`" pattern
DETERMINISTIC_ADDR=$(grep "Overriding deterministic address" $MIGRATE_LOG 2>/dev/null | grep -o '`0x[0-9a-f]\{63,64\}`' | tr -d '`' | head -1)

# If not found, try old warning message format
if [ -z "$DETERMINISTIC_ADDR" ]; then
  DETERMINISTIC_ADDR=$(grep "deterministic address:" $MIGRATE_LOG 2>/dev/null | awk '{print $4}' | head -1)
fi

# If still not found, extract from error message (world contract address)
if [ -z "$DETERMINISTIC_ADDR" ]; then
  DETERMINISTIC_ADDR=$(grep -o "0x[0-9a-f]\{63,64\}" $MIGRATE_LOG 2>/dev/null | sort -u | tail -1)
fi

if [ -z "$DETERMINISTIC_ADDR" ]; then
  echo "ERROR: Could not extract deterministic address" >&2
  echo "" >&2
  echo "=== Full Migration Output ===" >&2
  echo "$MIGRATE_OUTPUT" >&2
  echo "=== End Migration Output ===" >&2
  echo "" >&2
  echo "Looking for 'deterministic address:' in output..." >&2
  echo "$MIGRATE_OUTPUT" | grep -i "determin" || echo "No matches found" >&2
  exit 1
fi

echo "" >&2
echo "========================================"  >&2
echo "WORLD ADDRESS (Dojo $(sozo --version | awk '{print $2}')):" >&2
echo "$DETERMINISTIC_ADDR" >&2
echo "========================================" >&2

# Output just the address to stdout for capture
echo "$DETERMINISTIC_ADDR"
