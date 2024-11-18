#!/bin/bash
source /root/.bashrc

# Wait for Katana to start
while ! netstat -tuln | grep ':5050 ' > /dev/null; do
  sleep 1
done

torii \
  --rpc "http://0.0.0.0:5050" \
  --world $WORLD_ADDRESS \
  --http.cors_origins "*" \
  --db-dir $TORII_DB
