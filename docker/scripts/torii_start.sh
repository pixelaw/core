#!/bin/bash
source /root/.bashrc

torii \
  --world $WORLD_ADDRESS \
  --database $TORII_DB \
  --events-chunk-size 10000 \
  --allowed-origins "*"
