#!/bin/bash

 echo $WORLD_ADDRESS
 echo $SERVER_PORT

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
 export STARKNET_RPC="http://127.0.0.1:5050/"

if [ ! -f "$GENESIS" ]; then
  mkdir -p $LOG_DIR
  touch $KATANA_LOG && touch $TORII_LOG
  unzip $KATANA_DB_ZIP -d $STORAGE_DIR
  unzip $TORII_DB_ZIP -d $STORAGE_DIR

  cp "$STORAGE_INIT_DIR/genesis.json" $GENESIS

fi

RUST_BACKTRACE=1

supervisord -c /pixelaw/supervisord.conf
#
#echo "Starting Katana"
#nohup katana \
#  --genesis $GENESIS \
#  --invoke-max-steps 4294967295 \
#  --disable-fee \
#  --disable-validate \
#  --json-log \
#  --block-time 2000 \
#  --db-dir $KATANA_DB \
#  --allowed-origins "*" \
# > $KATANA_LOG 2>&1 &
#
#echo "Starting Torii"
#unset LS_COLORS && nohup torii \
#  --world $WORLD_ADDRESS \
#  --rpc $STARKNET_RPC \
#  --database $TORII_DB \
#  --events-chunk-size 10000 \
#  --allowed-origins "*" \
# > $TORII_LOG 2>&1 &
#
#echo "Starting server"
#nohup yarn --cwd /pixelaw/server server > $SERVER_LOG 2>&1 &

echo "ready"

if [ -z "$1" ]; then
  wait
fi
#/bin/bash







