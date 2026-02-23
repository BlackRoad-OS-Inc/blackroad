#!/usr/bin/env bash
set -euo pipefail

AGENT="${1:-default}"
shift || true
PROMPT="$*"

CFG="$HOME/.blackroad/agents/$AGENT/agent.json"
[[ ! -f "$CFG" ]] && { echo "agent not found: $AGENT"; exit 1; }

model=$(jq -r '.providers.local.model' "$CFG")

exec br-local.sh "$model" "$PROMPT"
