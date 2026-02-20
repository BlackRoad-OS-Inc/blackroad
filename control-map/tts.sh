#!/usr/bin/env bash
set -euo pipefail

TEXT="${1:-}"
if [[ -z "$TEXT" ]]; then
  echo "usage: $0 \"text to speak\""
  exit 1
fi

ACCOUNT_ID="848cf0b18d51e0170e0d1537aec3505a"
MODEL="@cf/deepgram/aura-2-en"
OUT="out.mp3"
TMP="$(mktemp)"

# Get OAuth token from wrangler
TOKEN="$(wrangler auth token)"

# Call Cloudflare AI (JSON response)
curl -s "https://api.cloudflare.com/client/v4/accounts/${ACCOUNT_ID}/ai/run/${MODEL}" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d "$(jq -n --arg text "$TEXT" '{text: $text}')" \
  > "$TMP"

# Decode base64 audio → mp3
jq -r '.result.audio' "$TMP" | base64 --decode > "$OUT"

rm -f "$TMP"

echo "written: $OUT"
