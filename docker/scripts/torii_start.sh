#!/bin/bash
source /root/.bashrc

# Wait for Katana to start
# TODO: this is not playing nice with katana not on the same server.
if [ ! "$DISABLE_KATANA" == "1" ]; then
  while ! netstat -tuln | grep ':5050 ' > /dev/null; do
    sleep 1
  done
fi

torii \
  --rpc $RPC_URL \
  --world $DOJO_WORLD_ADDRESS \
  --http.cors_origins "*" \
  --db-dir $TORII_DB \
  --http.addr 0.0.0.0 \
  --indexing.pending
