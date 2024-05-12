#!/bin/bash
set -uo pipefail

function paint() {
  sozo \
  --profile dev-pop \
  execute \
  0x1f04b61e71f2afa9610c422db007807f73ebad6b4c069e72bb6e22ff032a93c \
  interact \
  -c 0,0,$1,"0xFFFFFF"

  sleep 0.3
}

# H
paint 0,0
paint 0,1
paint 0,2
paint 0,3
paint 0,4

paint 1,2

paint 2,0
paint 2,1
paint 2,2
paint 2,3
paint 2,4

# E
paint 4,0
paint 4,1
paint 4,2
paint 4,3
paint 4,4

paint 5,0
paint 5,2
paint 5,4

paint 6,0
paint 6,2
paint 6,4

# L
paint 8,0
paint 8,1
paint 8,2
paint 8,3
paint 8,4
paint 9,4
paint 10,4

# L
paint 12,0
paint 12,1
paint 12,2
paint 12,3
paint 12,4
paint 13,4
paint 14,4

# O
paint 16,0
paint 16,1
paint 16,2
paint 16,3
paint 16,4
paint 17,0
paint 17,4
paint 18,0
paint 18,1
paint 18,2
paint 18,3
paint 18,4
