#!/bin/bash
source /root/.bashrc
katana \
  --genesis $GENESIS \
  --invoke-max-steps 4294967295 \
  --dev \
  --dev.no-fee \
  --block-time 2000 \
  --db-dir $KATANA_DB \
  --http.cors_origins "*"
