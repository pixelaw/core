#!/bin/bash
#
# Shared functions for Docker image builds
# Used by build-core.sh and build-populated.sh
#

set -euo pipefail

# Configuration
export PROFILE=${PROFILE:-"dev"}
export STORAGE_DIR=${STORAGE_DIR:-"/pixelaw/storage"}

# Paths (relative to /pixelaw)
CONTRACTS_DIR="/pixelaw/contracts"
STORAGE_INIT_DIR="/pixelaw/storage_init"

KATANA_DB="$STORAGE_DIR/katana_db"
KATANA_DB_ZIP="$STORAGE_DIR/katana_db.zip"
KATANA_LOG="$STORAGE_DIR/katana.log"
TORII_DB="$STORAGE_DIR/torii.sqlite"
TORII_LOG="$STORAGE_DIR/torii.log"

GENESIS_TEMPLATE="$CONTRACTS_DIR/genesis_template.json"
MANIFEST="$CONTRACTS_DIR/manifest_$PROFILE.json"
DEPLOY_SCARB="$CONTRACTS_DIR/Scarb_deploy.toml"

export DOJO_WORLD_ADDRESS=${DOJO_WORLD_ADDRESS:-$(cat /pixelaw/DOJO_WORLD_ADDRESS)}
export STARKNET_RPC="http://localhost:5050/"

# Check required commands
check_commands() {
    local commands=("jq" "katana" "zip" "sozo" "sqlite3")
    for cmd in "${commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            echo "Error: $cmd is not available"
            exit 1
        fi
    done
}

# Wait for log file to contain expected content
wait_for_log() {
    local log_file=$1
    local pattern=$2
    local timeout=${3:-60}
    local elapsed=0

    echo "Waiting for '$pattern' in $log_file (timeout: ${timeout}s)..."

    while [ $elapsed -lt $timeout ]; do
        if [ -f "$log_file" ] && grep -q "$pattern" "$log_file" 2>/dev/null; then
            return 0
        fi
        sleep 1
        elapsed=$((elapsed + 1))
    done

    echo "ERROR: Timeout waiting for '$pattern' in $log_file"
    echo "Log contents:"
    cat "$log_file" 2>/dev/null || echo "(no log file)"
    return 1
}

# Katana management
start_katana() {
    echo "katana: starting..."
    mkdir -p "$STORAGE_DIR"

    # Clear any existing log
    rm -f "$KATANA_LOG"
    touch "$KATANA_LOG"

    katana \
        --invoke-max-steps 4294967295 \
        --http.addr 0.0.0.0 \
        --db-dir "$KATANA_DB" \
        --http.cors_origins "*" \
        --dev \
        --dev.seed 0 \
        --dev.no-fee \
        --dev.accounts 10 \
        > "$KATANA_LOG" 2>&1 &

    # Wait for katana to be ready (wait for log file to have content)
    local timeout=30
    local elapsed=0
    while [ $elapsed -lt $timeout ]; do
        # Check if log has meaningful content (accounts generated)
        if [ -s "$KATANA_LOG" ] && grep -q "Account" "$KATANA_LOG" 2>/dev/null; then
            echo "katana: running"
            return 0
        fi
        sleep 1
        elapsed=$((elapsed + 1))
    done

    echo "ERROR: Katana failed to start within ${timeout}s"
    echo "Log contents:"
    cat "$KATANA_LOG" 2>/dev/null || echo "(no log file)"
    exit 1
}

stop_katana() {
    echo "katana: stopping..."
    pkill -f 'katana --invoke-max-steps' || true
    sleep 1
}

# Torii management
start_torii() {
    echo "torii: starting..."

    # Clear any existing log
    rm -f "$TORII_LOG"
    touch "$TORII_LOG"

    torii \
        --world "$DOJO_WORLD_ADDRESS" \
        --rpc "$STARKNET_RPC" \
        --http.addr 0.0.0.0 \
        --db-dir "$TORII_DB" \
        --http.cors_origins "*" \
        --indexing.pending \
        > "$TORII_LOG" 2>&1 &

    # Wait for torii to be ready (wait for log file to have content)
    local timeout=30
    local elapsed=0
    while [ $elapsed -lt $timeout ]; do
        if [ -s "$TORII_LOG" ]; then
            sleep 2  # Give it a moment to fully initialize
            echo "torii: running"
            return 0
        fi
        sleep 1
        elapsed=$((elapsed + 1))
    done

    echo "ERROR: Torii failed to start within ${timeout}s"
    echo "Log contents:"
    cat "$TORII_LOG" 2>/dev/null || echo "(no log file)"
    exit 1
}

stop_torii() {
    echo "torii: stopping..."
    pkill -f 'torii --world' || true
    sleep 1
}

stop_all() {
    stop_torii
    stop_katana
}

# Sozo operations
sozo_build() {
    echo "sozo: building contracts..."
    cd "$CONTRACTS_DIR"

    sozo clean
    sozo \
        --profile "$PROFILE" \
        --manifest-path "$DEPLOY_SCARB" \
        build

    echo "sozo: build complete"
}

sozo_migrate() {
    echo "sozo: migrating contracts..."
    cd "$CONTRACTS_DIR"

    sozo \
        --profile "$PROFILE" \
        --manifest-path "$DEPLOY_SCARB" \
        migrate \
        --wait

    sleep 1
    echo "sozo: migration complete"
}

# Database operations
zip_katana_db() {
    echo "zipping katana database..."
    cd "$STORAGE_DIR"
    zip -1 -r katana_db.zip katana_db/
    echo "zip complete: $KATANA_DB_ZIP"
}

# Copy artifacts to storage_init (for Docker image)
copy_to_storage_init() {
    echo "copying artifacts to storage_init..."
    mkdir -p "$STORAGE_INIT_DIR"

    cp "$GENESIS_TEMPLATE" "$STORAGE_INIT_DIR/genesis.json"
    cp "$MANIFEST" "$STORAGE_INIT_DIR/manifest.json"
    cp "$KATANA_DB_ZIP" "$STORAGE_INIT_DIR/katana_db.zip"

    echo "artifacts copied to $STORAGE_INIT_DIR"
}

# Cleanup
cleanup() {
    echo "cleaning up..."
    rm -rf "$STORAGE_DIR"
}

check_commands
