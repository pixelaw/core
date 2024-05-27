#!/bin/bash

echo "World address: $WORLD_ADDRESS"
echo "Server port: $SERVER_PORT"

cat << EOF >> ~/.bashrc
 export STORAGE_DIR="/pixelaw/storage/$WORLD_ADDRESS"
 export LOG_DIR="$STORAGE_DIR/log"
 export STORAGE_INIT_DIR="/pixelaw/storage_init/$WORLD_ADDRESS"
 export KATANA_DB_ZIP="$STORAGE_INIT_DIR/katana_db.zip"
 export TORII_DB_ZIP="$STORAGE_INIT_DIR/torii.sqlite.zip"
 export KATANA_DB="$STORAGE_DIR/katana_db"
 export TORII_DB="$STORAGE_DIR/torii.sqlite"
 export KATANA_LOG="$LOG_DIR/katana.log.json"
 export TORII_LOG="$LOG_DIR/torii.log"
 export SERVER_LOG="$LOG_DIR/server.log"
 export GENESIS="$STORAGE_DIR/genesis.json"
 export STARKNET_RPC="http://localhost:5050"
 export WEB_DIR="/pixelaw/web"
EOF

source ~/.bashrc

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








