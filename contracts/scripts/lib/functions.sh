#!/bin/bash

export PROFILE=${PROFILE:-"dev"}

TARGET="target/${PROFILE}"
OUT="out/$PROFILE"

export STORAGE_DIR=${STORAGE_DIR:-$OUT}

GENESIS_TEMPLATE=genesis_template.json
GENESIS_OUT="$STORAGE_DIR/genesis.json"
KATANA_LOG="$STORAGE_DIR/katana.log"
KATANA_DB="$STORAGE_DIR/katana_db"
KATANA_DB_ZIP="$STORAGE_DIR/katana_db.zip"
MANIFEST="manifest_$PROFILE.json"
TYPESCRIPT="$STORAGE_DIR/typescript"
TORII_DB="$STORAGE_DIR/torii.sqlite"
TORII_LOG="$STORAGE_DIR/torii.log"
DEPLOY_SCARB="Scarb_deploy.toml"

ETH_ADDR=0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7
STRK_ADR=0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d

declare -A rpc

# Populate associative array with key-value pairs
rpc["dev"]="http://localhost:5050/"
rpc["sepolia"]="https://starknet-sepolia.public.blastapi.io/rpc/v0_7"
rpc["mainnet"]="https://starknet-mainnet.public.blastapi.io/rpc/v0_7"

export STARKNET_RPC="${rpc[$PROFILE]}"

export DOJO_WORLD_ADDRESS=$(cat ../DOJO_WORLD_ADDRESS)

clear_katana() {
    echo "clear_katana"
    pkill -f katana

    mkdir -p $OUT

    rm -rf $KATANA_DB
}

kill_katana() {
      katana_pid=$(pgrep -f 'katana --invoke-max-steps')
      if [ -n "$katana_pid" ]; then
          kill "$katana_pid"
      fi
}

start_katana() {
    echo "katana: starting"

    kill_katana

    # Start Katana
    katana \
      --invoke-max-steps 4294967295 \
      --db-dir $KATANA_DB \
      --http.cors_origins "*" \
      --dev \
      --dev.seed 0 \
      --dev.no-fee \
      --dev.accounts 10 \
     > $KATANA_LOG 2>&1 &

    # Wait for logfile to exist and not be empty
    while ! test -s $KATANA_LOG; do
     sleep 1
    done
    echo "katana: running"
}

clear_torii() {
    echo "clear_torii"
    pkill -f torii

    mkdir -p $OUT

    rm -rf $TORII_DB
}

kill_torii() {
    torii_pid=$(pgrep -f 'torii --world')
    if [ -n "$torii_pid" ]; then
        kill "$torii_pid"
    fi
}


start_torii() {
    echo "torii: starting"

    # Give katana some time to boot up
    sleep 2

    kill_torii
    local rpc_url=$(get_rpc_url)
    echo "start_torii: $rpc_url $DOJO_WORLD_ADDRESS"

    torii \
      --world $DOJO_WORLD_ADDRESS \
      --rpc $rpc_url \
      --db-dir $TORII_DB \
      --http.cors_origins "*" \
      --indexing.pending \
     > $TORII_LOG 2>&1 &

     # Wait for logfile to exist and not be empty
     while ! test -s $TORII_LOG; do
      sleep 1
     done
     echo "torii: running"
}

sozo_rebuild() {
    echo "sozo_rebuild"
    rm -rf $TYPESCRIPT
    mkdir -p $TYPESCRIPT

    # Clear the target
    rm -rf $TARGET

    rm -rf $MANIFEST

    sozo clean
    sozo \
        --profile $PROFILE \
        --manifest-path $DEPLOY_SCARB \
        build \
        --typescript \
        --bindings-output $OUT

    # Note: sozo build does NOT create manifest.json - only sozo migrate does
    echo "Build complete. Manifest will be created during sozo migrate."
}

sozo_account_deploy() {
      sozo \
          --profile $PROFILE \
          --manifest-path $DEPLOY_SCARB \
          account \
          new \
          deployer.account.json

      sozo \
          --profile $PROFILE \
          --manifest-path $DEPLOY_SCARB \
          account \
          deploy \
          deployer.account.json
}

sozo_migrate() {
    echo "sozo_migrate"

    sozo \
      --profile $PROFILE \
      --manifest-path $DEPLOY_SCARB \
      migrate \
       --wait


    sleep 1
}



zip_databases() {

  echo "zip_databases"
  pushd $STORAGE_DIR
  zip -1 -r katana_db.zip katana_db/

  popd

}



kill_katana_torii() {
  pkill -f katana
  pkill -f torii
}

populate() {
  echo "populate"
  ./populate.sh
}

paint() {
  sozo \
  --manifest-path $DEPLOY_SCARB --profile $PROFILE \
  execute \
  pixelaw-paint_actions \
  interact \
  -c 0,0,$1,3816652287
}

check_needed_commands() {
  commands=("jq" "katana" "zip" "sozo" "sqlite3")

  for cmd in "${commands[@]}"; do
      if ! command -v $cmd &> /dev/null; then
          echo "Error: $cmd is not available. The scripts need the following commands: ${commands[*]}"
          exit 1
      fi
  done

}

get_rpc_url() {
   local file_path="dojo_$PROFILE.toml"
   local url=$(grep "rpc_url" "$file_path" | head -1 | awk -F '"' '{print $2}')
   echo $url
}

check_needed_commands
