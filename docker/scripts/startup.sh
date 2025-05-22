#!/bin/bash

echo "World address: $WORLD_ADDRESS"
echo "Server port: $SERVER_PORT"

source /root/.bashrc

# Not sure if this helps on MacOs to wait for disk mount?
sleep 2

if [ "$DISABLE_KATANA" != "1" ] && [ ! -f "$GENESIS" ]; then
  mkdir -p "$LOG_DIR" "$STORAGE_DIR"
  touch "$KATANA_LOG" "$TORII_LOG"
  unzip "$KATANA_DB_ZIP" -d "$STORAGE_DIR"
  cp "$STORAGE_INIT_DIR/genesis.json" "$GENESIS"
fi

#pushd /pixelaw/web && sh vite-envs.sh && popd

# Start all applications defined in ecosystem.config.js with PM2
if [ "$DISABLE_KATANA" == "1" ]; then
  pm2 start /pixelaw/core/docker/ecosystem.config.js --only "torii,server" --silent
else
  pm2 start /pixelaw/core/docker/ecosystem.config.js --silent
fi

echo "ready"

# Keep the container running
if [ "$PREVENT_EXIT" == "1" ]; then
  tail -f /dev/null
fi







