#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  planner.sh [--intent <intent>] [--context <json>] [--raw] [input...]

If no input is provided, the agent reads from stdin.
EOF
}

intent='analyze'
context_json='{}'
raw_output='false'

while [ $# -gt 0 ]; do
  case "$1" in
    --intent)
      intent="${2:-}"
      shift 2
      ;;
    --context)
      context_json="${2:-}"
      shift 2
      ;;
    --raw)
      raw_output='true'
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    --)
      shift
      break
      ;;
    *)
      break
      ;;
  esac
done

if [ $# -gt 0 ]; then
  input="$*"
else
  input="$(cat)"
fi

if [ -z "$input" ]; then
  echo 'Error: input is required' >&2
  exit 1
fi

for name in $(env | cut -d= -f1); do
  case "$name" in
    *_API_KEY|*_TOKEN)
      echo "Refusing to run: token-like env var ${name} detected. Use a clean env." >&2
      exit 2
      ;;
  esac
done

gateway_url="${BLACKROAD_GATEWAY_URL:-http://127.0.0.1:8787}"

request="$(
  BR_AGENT_INPUT="$input" \
  BR_AGENT_INTENT="$intent" \
  BR_AGENT_CONTEXT="$context_json" \
  python3 - <<'PY'
import json
import os

input_text = os.environ.get('BR_AGENT_INPUT', '')
intent = os.environ.get('BR_AGENT_INTENT', 'analyze')
context_raw = os.environ.get('BR_AGENT_CONTEXT', '{}')

try:
    context = json.loads(context_raw) if context_raw else {}
except Exception:
    context = {'_raw': context_raw}

payload = {
    'agent': 'planner',
    'intent': intent,
    'input': input_text,
    'context': context
}

print(json.dumps(payload))
PY
)"

response="$(
  curl -sS --fail \
    -X POST "${gateway_url}/v1/agent" \
    -H 'Content-Type: application/json' \
    -d "$request"
)" || {
  echo 'Error: BlackRoad Gateway unavailable' >&2
  exit 3
}

if [ "$raw_output" = 'true' ]; then
  echo "$response"
  exit 0
fi

python3 - <<'PY' <<<"$response"
import json
import sys

data = json.load(sys.stdin)
if data.get('status') != 'ok':
    sys.stderr.write((data.get('error') or 'Gateway error') + '\n')
    sys.exit(1)

print(data.get('output', ''))
PY
