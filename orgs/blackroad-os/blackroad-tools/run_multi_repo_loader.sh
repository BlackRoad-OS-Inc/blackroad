#!/usr/bin/env bash
set -euo pipefail

# Load env (optional)
if [ -f ".env" ]; then
  # shellcheck disable=SC2046
  export $(grep -v '^#' .env | xargs -I {} echo {})
fi

python3 tools/codex_multi_repo_loader.py --config config/repos.json
