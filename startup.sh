#!/bin/bash

# Define the first function (thread)
function run_bot() {
  mkdir -p log
  cd bots && npm run dev > ../log/bots.log 2>&1;
}

# Define the second function (thread)
function run_katana_torii() {
   echo $WORLD_ADDRESS
   export STORAGE_DIR="storage/$WORLD_ADDRESS"
   export LOG_DIR="$STORAGE_DIR/log"
   export STORAGE_INIT_DIR="storage_init/$WORLD_ADDRESS"
   export KATANA_DB_ZIP="$STORAGE_INIT_DIR/katana_db.zip"
   export TORII_DB_ZIP="$STORAGE_INIT_DIR/torii.sqlite.zip"
   export KATANA_DB="$STORAGE_DIR/katana_db"
   export TORII_DB="$STORAGE_DIR/torii.sqlite"
   export KATANA_LOG="$LOG_DIR/katana.log.json"
   export TORII_LOG="$LOG_DIR/torii.log"
   export BOT_LOG="$LOG_DIR/bot.log"
   export GENESIS="$STORAGE_DIR/genesis.json"
   export STARKNET_RPC="http://127.0.0.1:5050/"

  if [ ! -f "$GENESIS" ]; then
    mkdir -p $LOG_DIR
    touch $KATANA_LOG && touch $TORII_LOG
    unzip $KATANA_DB_ZIP -d $STORAGE_DIR
    unzip $TORII_DB_ZIP -d $STORAGE_DIR

    cp "$STORAGE_INIT_DIR/genesis.json" $GENESIS

  fi

  echo "ready"
  RUST_BACKTRACE=1

  echo "Starting Katana"
  katana \
    --genesis $GENESIS \
    --invoke-max-steps 4294967295 \
    --disable-fee \
    --disable-validate \
    --json-log \
    --db-dir $KATANA_DB \
    --allowed-origins "*" \
   > $KATANA_LOG 2>&1 &

  echo "Starting Torii"
  unset LS_COLORS && torii \
    --world $WORLD_ADDRESS \
    --rpc $STARKNET_RPC \
    --database $TORII_DB \
    --events-chunk-size 10000 \
    --allowed-origins "*" \
   > $TORII_LOG 2>&1 &


#  tail -f $KATANA_LOG

}
# expecting
# 0x38937c85771a65ee96dd2fcd37f28a159b7c9f553c17807fd30feae68506a67,

run_bot &

run_katana_torii


wait
#/bin/bash






