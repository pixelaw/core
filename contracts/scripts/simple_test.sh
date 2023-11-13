#!/bin/bash
set -euo pipefail
source scripts/update_accounts.sh
source scripts/update_contracts.sh

pushd $(dirname "$0")/..




# Player 1 Spawn pixel 1,1
#sozo execute $CORE_ACTIONS spawn_pixel \
#  --private-key $ACCOUNT_2_PRIVATE_KEY \
#  --account-address $ACCOUNT_2_ADDRESS \
#  -c 1,1,1,482670636660,0

sleep 0.1

## Player 1 put_color pixel 1,1
#sozo execute $PAINT_ACTIONS put_fading_color \
#  --private-key $ACCOUNT_2_PRIVATE_KEY \
#  --account-address $ACCOUNT_2_ADDRESS \
#  -c 0,0,1,1,255,255,255


TIMESTAMP=0x6541da5f
CALLEDSYS=0x3b98614125bc4a46cbf98bf65117ac8116db9910303933354ed14f8fdbbab0c
SELECTOR=0x25d55f433721123c34655663adc4f32f53e312a8c108d68376b9b940db479db
PLAYER=0x765149d6bc63271df7b0316537888b81aa021523f9516a05306f10fd36914da

CALLDATA="$TIMESTAMP,$CALLEDSYS,$SELECTOR,$PLAYER,$CALLEDSYS,1,1"

echo $CALLDATA

# Player 1 put_color pixel 1,1
sozo execute $CORE_ACTIONS process_queue \
  --private-key $ACCOUNT_2_PRIVATE_KEY \
  --account-address $ACCOUNT_2_ADDRESS \
  -c $CALLDATA




