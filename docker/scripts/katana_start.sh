#!/bin/bash
source /root/.bashrc
katana \
  --genesis $GENESIS \
  --invoke-max-steps 4294967295 \
  --disable-fee \
  --disable-validate \
  --json-log \
  --block-time 2000 \
  --db-dir $KATANA_DB \
  --allowed-origins "*"
