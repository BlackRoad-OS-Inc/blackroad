#!/usr/bin/env bash

AGENT="$1"
MODEL="$2"

INBOX="$HOME/blackroad/shared/inbox"
OUTBOX="$HOME/blackroad/shared/outbox"
TRANS="$HOME/blackroad/shared/transcripts/${AGENT}.log"

mkdir -p "$(dirname "$TRANS")"

echo "[${AGENT}] watching inbox..."

while true; do
  for file in "$INBOX"/*; do
    [ -f "$file" ] || continue

    LOCK="$HOME/blackroad/runtime/locks/$(basename "$file").lock"
    exec 9>"$LOCK" || continue
    flock -n 9 || continue

    CONTENT=$(cat "$file")

    RESPONSE=$(ollama run "$MODEL" "$CONTENT")

    {
      echo "==== $(date -Is) ===="
      echo "IN:"
      echo "$CONTENT"
      echo "OUT:"
      echo "$RESPONSE"
      echo
    } | tee -a "$TRANS" > "$OUTBOX/$(basename "$file").${AGENT}"

    rm -f "$file"
    rm -f "$LOCK"
  done

  sleep 0.5
done
