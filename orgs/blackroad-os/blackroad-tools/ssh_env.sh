#!/usr/bin/env bash
# Exports GIT_SSH_COMMAND to force strict host-key checking and chosen key.
set -euo pipefail
KEY_PATH="${CODEX_SSH_KEY:-$HOME/.ssh/id_ed25519}"
KNOWN_HOSTS="${CODEX_KNOWN_HOSTS:-$(pwd)/secrets/known_hosts}"
export GIT_SSH_COMMAND="ssh -i $KEY_PATH -o UserKnownHostsFile=$KNOWN_HOSTS -o StrictHostKeyChecking=yes"
echo "GIT_SSH_COMMAND set with key=$KEY_PATH, known_hosts=$KNOWN_HOSTS"
