#!/bin/bash
source /root/.bashrc
katana \
  --invoke-max-steps 4294967295 \
  --dev \
  --dev.seed 0 \
  --dev.no-fee \
  --dev.accounts 10 \
  --block-time 2000 \
  --db-dir $KATANA_DB \
  --http.cors_origins "*"
