#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENT_DIR="${SCRIPT_DIR}/../agents"

if ! command -v rg >/dev/null 2>&1; then
  echo 'Error: rg is required for tokenless agent checks' >&2
  exit 2
fi

matches=$(
  rg -n \
    -e 'OPENAI_API_KEY' \
    -e 'ANTHROPIC_API_KEY' \
    -e 'CLOUDFLARE_API_TOKEN' \
    -e 'api.openai.com' \
    -e 'api.anthropic.com' \
    -e 'api.cloudflare.com' \
    -e 'openai.com' \
    -e 'anthropic.com' \
    -e 'cloudflare.com' \
    "$AGENT_DIR" || true
)

if [ -n "$matches" ]; then
  echo 'Forbidden vendor references detected in agent code:' >&2
  echo "$matches" >&2
  exit 1
fi

echo 'OK: agents are tokenless and vendor-agnostic.'
