#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/config.env"

while true; do
  echo "🧠 working..."
  sleep "$INTERVAL"
done
