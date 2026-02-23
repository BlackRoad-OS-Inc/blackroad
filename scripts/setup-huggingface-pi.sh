#!/bin/bash
# Setup HuggingFace CLI on Pi (lucidia primary)
set -euo pipefail
GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'

HF_TOKEN="${1:-${HF_TOKEN:-}}"
PI_HOST="${2:-lucidia}"

ssh "$PI_HOST" "
  python3 -m pip install --user huggingface_hub 2>&1 | tail -2
  python3 -m pip install --user transformers 2>&1 | tail -2
  
  # Install huggingface-cli
  python3 -m pip install --user 'huggingface_hub[cli]' 2>&1 | tail -2
  export PATH=~/.local/bin:\$PATH
  
  # Auth if token provided
  [[ -n '${HF_TOKEN}' ]] && \
    huggingface-cli login --token '${HF_TOKEN}' && echo 'HF authenticated' || \
    echo 'No HF_TOKEN provided - run: huggingface-cli login'
  
  echo 'export PATH=~/.local/bin:\$PATH' >> ~/.bashrc
  huggingface-cli --version 2>/dev/null && echo '✓ HuggingFace CLI ready'
" 2>&1 | tail -8
