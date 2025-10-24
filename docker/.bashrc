
export STORAGE_DIR="/pixelaw/storage"
export LOG_DIR="/pixelaw/log"
export STORAGE_INIT_DIR="/pixelaw/storage_init"
export KATANA_DB_ZIP="$STORAGE_INIT_DIR/katana_db.zip"
export KATANA_DB="$STORAGE_DIR/katana_db"
export TORII_DB="$STORAGE_DIR/torii.sqlite"
export KATANA_LOG="$LOG_DIR/katana.log"
export TORII_LOG="$LOG_DIR/torii.log"
export SERVER_LOG="$LOG_DIR/server.log"
export GENESIS="$STORAGE_DIR/genesis.json"
export STARKNET_RPC="http://localhost:5050"
export WEB_DIR="/pixelaw/web"

alias katana_start="/pixelaw/scripts/katana_start.sh"
alias torii_start="/pixelaw/scripts/torii_start.sh"
alias server_start="/pixelaw/scripts/server_start.sh"

alias deploy_local="/pixelaw/tools/local_deploy.sh"

alias klog="tail -f $KATANA_LOG -n 50 | grep -v \"DEBUG\""
alias tlog="tail -f $TORII_LOG -n 50"
alias slog="tail -f $SERVER_LOG -n 50"

alias ll="ls -lah"

echo "View logs with klog, tlog and slog commands"
