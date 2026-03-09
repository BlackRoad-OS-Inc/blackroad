#!/usr/bin/env bash
log="/workspace/blackroad-prism-console/ritual/reflections.log"
mkdir -p "$(dirname "$log")"
echo "$(date -u +"%Y-%m-%d") — $*" >> "$log"
echo "Logged."
