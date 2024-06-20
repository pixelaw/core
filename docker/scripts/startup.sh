#!/bin/bash

echo "World address: $WORLD_ADDRESS"
echo "Server port: $SERVER_PORT"

source /root/.bashrc

# Not sure if this helps on MacOs to wait for disk mount?
sleep 2

if [ ! -f "$GENESIS" ]; then
  mkdir -p $LOG_DIR
  mkdir -p $STORAGE_DIR
  touch $KATANA_LOG && touch $TORII_LOG
  unzip $KATANA_DB_ZIP -d $STORAGE_DIR
  unzip $TORII_DB_ZIP -d $STORAGE_DIR

  cp "$STORAGE_INIT_DIR/genesis.json" $GENESIS

fi

# Start all applications defined in ecosystem.config.js with PM2
pm2 start /pixelaw/core/docker/ecosystem.config.js

echo "ready"

# Keep the container running
tail -f /dev/null








