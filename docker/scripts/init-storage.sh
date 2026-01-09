#!/bin/bash
set -e
export HOME=/root
source /root/.bashrc

echo "World address: $DOJO_WORLD_ADDRESS"
echo "Initializing storage..."

if [ "$DISABLE_KATANA" != "1" ] && [ ! -f "$GENESIS" ]; then
    mkdir -p "$LOG_DIR" "$STORAGE_DIR"
    touch "$KATANA_LOG" "$TORII_LOG"
    unzip "$KATANA_DB_ZIP" -d "$STORAGE_DIR"
    cp "$STORAGE_INIT_DIR/genesis.json" "$GENESIS"
    echo "Storage initialized from snapshot"
else
    echo "Storage already initialized or katana disabled"
fi
