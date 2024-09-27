#!/bin/bash
set -uo pipefail

function paint() {
  sozo \
    execute \
    --profile $SCARB_PROFILE \
    pixelaw-paint_actions \
    interact \
    -c 0,0,$1
}

# Function to display usage information
function usage() {
  echo "Usage: $0 <json_file> [x_offset y_offset]"
  echo "  <json_file> : Path to the JSON file containing pixel data."
  echo "  [x_offset]  : (Optional) X-axis offset. Default is 0."
  echo "  [y_offset]  : (Optional) Y-axis offset. Default is 0."
}

# Check if at least one argument is provided
if [ $# -lt 1 ]; then
  usage
  exit 1
fi

json_file="$1"

# Set default offsets
x_offset=0
y_offset=0

# Assign offsets if provided
if [ $# -ge 3 ]; then
  x_offset="$2"
  y_offset="$3"
elif [ $# -ge 2 ]; then
  echo "Error: Both x_offset and y_offset should be provided."
  usage
  exit 1
fi

# Check if the JSON file exists
if [ ! -f "$json_file" ]; then
  echo "File not found: $json_file"
  exit 1
fi

# Read the JSON file and process each pixel
jq -c '.[]' "$json_file" | while read -r pixel; do
  x=$(echo "$pixel" | jq -r '.x')
  y=$(echo "$pixel" | jq -r '.y')
  color=$(echo "$pixel" | jq -r '.color')

  # Calculate the new coordinates with offset
  new_x=$((x + x_offset))
  new_y=$((y + y_offset))

  # Call the paint function with the new coordinates and color
  paint $new_x,$new_y,$color
done

echo "Pixel art drawing completed with offset ($x_offset, $y_offset)."
