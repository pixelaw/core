#!/bin/bash
source /root/.bashrc

torii \
  --rpc "http://0.0.0.0:5050" \
  --world $WORLD_ADDRESS \
  --database $TORII_DB \
  --events-chunk-size 10000 \
  --allowed-origins "*"
