#!/usr/bin/env bash
set -euo pipefail

: "${GOOGLE_API_KEY:?set GOOGLE_API_KEY}"
: "${GOOGLE_CX:?set GOOGLE_CX}"

QUERY="$*"
[[ -z "$QUERY" ]] && { echo "usage: br google search <query>"; exit 1; }

curl -s "https://www.googleapis.com/customsearch/v1" \
  --get \
  --data-urlencode "q=$QUERY" \
  --data "key=$GOOGLE_API_KEY" \
  --data "cx=$GOOGLE_CX" \
| jq -r '.items[] | "\(.title)\n\(.link)\n"'
