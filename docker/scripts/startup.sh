#!/bin/bash

echo "World address: $WORLD_ADDRESS"
echo "Server port: $SERVER_PORT"

source /root/.bashrc

# Not sure if this helps on MacOs to wait for disk mount?
sleep 2

if [ ! -f "$GENESIS" ]; then
  mkdir -p $LOG_DIR
  touch $KATANA_LOG && touch $TORII_LOG
  unzip $KATANA_DB_ZIP -d $STORAGE_DIR
  unzip $TORII_DB_ZIP -d $STORAGE_DIR

  cp "$STORAGE_INIT_DIR/genesis.json" $GENESIS

fi

supervisord -c /pixelaw/supervisord.conf

echo "ready"

# If there is no param, wait. Otherwise, it's a devcontainer that will take control.
if [ -z "$1" ]; then
  wait
fi








