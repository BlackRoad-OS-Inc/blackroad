#!/usr/bin/env bash
set -euo pipefail

cd /opt/lucidia
git fetch --all -q
git reset --hard origin/main -q

# restart whichever unit exists
if command -v systemctl >/dev/null; then
  if systemctl is-enabled --quiet lucidia.service 2>/dev/null; then
    sudo systemctl restart lucidia.service
  elif systemctl is-enabled --quiet codex.service 2>/dev/null; then
    sudo systemctl restart codex.service
  fi
fi

echo "Deploy done on $(hostname) at $(TZ=America/Chicago date)"