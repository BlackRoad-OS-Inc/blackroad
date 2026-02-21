#!/usr/bin/env bash
# Usage: agent-mesh.sh <agent_name> <ollama_model>

AGENT="$1"
MODEL="$2"

QUEUE="$HOME/BlackRoad/shared/mesh/queue"
ROUNDS="$HOME/BlackRoad/shared/mesh/rounds"
LOCKDIR="$HOME/BlackRoad/runtime/locks"
TRANS="$HOME/BlackRoad/shared/transcripts/${AGENT}.log"

mkdir -p "$QUEUE" "$ROUNDS" "$LOCKDIR"

CURRENT_ROUND=1

echo "[$AGENT] mesh mode active"

while true; do
  ROUND_DIR="$ROUNDS/round-$CURRENT_ROUND"

  mkdir -p "$ROUND_DIR"

  for msg in "$QUEUE"/*; do
    [ -f "$msg" ] || continue

    LOCK="$LOCKDIR/$(basename "$msg").lock"
    exec 9>"$LOCK" || continue
    flock -n 9 || continue

    CONTENT=$(cat "$msg")

    RESPONSE=$(ollama run "$MODEL" \
      "You are agent $AGENT in a multi-agent mesh.
Respond ONLY to the message below. Be concise.

$CONTENT")

    OUTFILE="$ROUND_DIR/${AGENT}_r${CURRENT_ROUND}.txt"

    {
      echo "FROM: $AGENT"
      echo "TO: mesh"
      echo "ROUND: $CURRENT_ROUND"
      echo
      echo "$RESPONSE"
    } | tee -a "$TRANS" > "$OUTFILE"

    rm -f "$msg"
    rm -f "$LOCK"
  done

  sleep 0.5
done
