#!/bin/zsh
#===============================================================================
# BR Code — Local Coding Assistant (Ollama-powered)
# Usage: br code [--model <name>] [initial prompt]
#===============================================================================

BR_LIB="/Users/alexa/blackroad/lib"
source "${BR_LIB}/colors.sh"
source "${BR_LIB}/ollama.sh"

# Verify Ollama is running
check_ollama_or_die

# Resolve model: flag > env var > default
MODEL="${BR_CODE_MODEL:-blackroad-code}"
OLLAMA_URL="${BR_OLLAMA_URL:-http://localhost:11434}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

ARGS=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --model|-m) MODEL="$2"; shift 2 ;;
        --url)      OLLAMA_URL="$2"; shift 2 ;;
        *)          ARGS+=("$1"); shift ;;
    esac
done

exec python3 "${SCRIPT_DIR}/br-code.py" \
    --model "$MODEL" \
    --ollama-url "$OLLAMA_URL" \
    "${ARGS[@]}"
