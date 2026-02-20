#!/usr/bin/env bash
set -euo pipefail

CMD="${1:-start}"
NOTE=""
if [[ "$#" -gt 1 ]]; then
  NOTE="${*:2}"
fi

# Prefer repo root if inside git
REPO_ROOT="${REPO_ROOT:-}"
if [[ -z "${REPO_ROOT}" ]]; then
  if git rev-parse --show-toplevel >/dev/null 2>&1; then
    REPO_ROOT="$(git rev-parse --show-toplevel)"
  else
    REPO_ROOT="$(pwd)"
  fi
fi

PY="${PYTHON:-python3}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

exec "$PY" "$SCRIPT_DIR/memory.py" \
  --cmd "$CMD" \
  --repo-root "$REPO_ROOT" \
  --note "$NOTE"
