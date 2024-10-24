source ./scripts/params.sh
pkill -f katana

rm -rf $KATANA_DB

# Start Katana
katana \
  --genesis $GENESIS_TEMPLATE \
  --invoke-max-steps 4294967295 \
  --disable-fee \
  --db-dir $KATANA_DB \
  --allowed-origins "*"

