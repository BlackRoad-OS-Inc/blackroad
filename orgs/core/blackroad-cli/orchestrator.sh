#!/bin/bash

while IFS= read -r line; do
  agent="${line%%|*}"
  rest="${line#*|}"
  type="${rest%%|*}"
  msg="${rest#*|}"

  ./render.sh "$agent" "$type" "$msg"
  ./voice.sh "$agent" "$msg"
done
