#!/usr/bin/env bash
set -e

NODES_FILE="$(dirname "$0")/../devices/nodes.yaml"

echo "SSH PROBE — READ ONLY"
echo "===================="
date
echo

# Extract node names from indented YAML
grep -E "^[[:space:]]*- name:" "$NODES_FILE" \
  | sed 's/^[[:space:]]*- name: //' \
  | while read -r NODE; do
      echo "---- $NODE ----"
      ssh -o BatchMode=yes -o ConnectTimeout=5 pi@"$NODE" \
        "hostname && uname -a && uptime" \
        || echo "UNREACHABLE"
      echo
    done
