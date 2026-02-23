#!/bin/bash
# ============================================================================
# BLACKROAD AI GATEWAY - Unified Backend Router
# BlackRoad OS, Inc. - All AI routes through BlackRoad
#
# Backends:
#   local    -> Ollama (localhost:11434) - YOUR hardware
#   anthropic -> Anthropic API (BlackRoad admin key)
#   openai   -> OpenAI API (BlackRoad admin key)
#   lucidia  -> Lucidia daemon (localhost:11435)
#
# No rate limits. BlackRoad is root.
# ============================================================================

# Endpoints
OLLAMA_ENDPOINT="${BLACKROAD_LOCAL:-http://localhost:11434}"
LUCIDIA_ENDPOINT="${BLACKROAD_LUCIDIA:-http://localhost:11435}"
ANTHROPIC_ENDPOINT="https://api.anthropic.com/v1/messages"
OPENAI_ENDPOINT="https://api.openai.com/v1/chat/completions"

# Default models per backend
OLLAMA_MODEL="${BLACKROAD_LOCAL_MODEL:-llama3:latest}"
ANTHROPIC_MODEL="${BLACKROAD_ANTHROPIC_MODEL:-claude-sonnet-4-20250514}"
OPENAI_MODEL="${BLACKROAD_OPENAI_MODEL:-gpt-4o}"

# Colors
PINK='\033[38;5;205m'
AMBER='\033[38;5;214m'
VIOLET='\033[38;5;135m'
BLUE='\033[38;5;69m'
GREEN='\033[38;5;82m'
RESET='\033[0m'

# Backend selection
select_backend() {
    local requested="$1"

    case "$requested" in
        -l|--local|local|ollama)
            echo "local"
            ;;
        -a|--anthropic|anthropic|claude)
            echo "anthropic"
            ;;
        -o|--openai|openai|gpt)
            echo "openai"
            ;;
        -L|--lucidia|lucidia)
            echo "lucidia"
            ;;
        *)
            # Auto-select: local first, then anthropic
            if curl -s --max-time 1 "$OLLAMA_ENDPOINT/api/tags" >/dev/null 2>&1; then
                echo "local"
            else
                echo "anthropic"
            fi
            ;;
    esac
}

# Backend: Local Ollama
run_local() {
    local prompt="$1"
    local model="${2:-$OLLAMA_MODEL}"

    curl -s "$OLLAMA_ENDPOINT/api/generate" \
        -d "{\"model\": \"$model\", \"prompt\": \"$prompt\", \"stream\": false}" \
        | jq -r '.response' 2>/dev/null
}

# Backend: Local Ollama (streaming)
run_local_stream() {
    local prompt="$1"
    local model="${2:-$OLLAMA_MODEL}"

    curl -s "$OLLAMA_ENDPOINT/api/generate" \
        -d "{\"model\": \"$model\", \"prompt\": \"$prompt\", \"stream\": true}" \
        | while IFS= read -r line; do
            echo "$line" | jq -r '.response // empty' | tr -d '\n'
        done
    echo ""
}

# Backend: Anthropic (BlackRoad admin key)
run_anthropic() {
    local prompt="$1"
    local model="${2:-$ANTHROPIC_MODEL}"

    curl -s "$ANTHROPIC_ENDPOINT" \
        -H "Content-Type: application/json" \
        -H "x-api-key: $ANTHROPIC_API_KEY" \
        -H "anthropic-version: 2023-06-01" \
        -d "{
            \"model\": \"$model\",
            \"max_tokens\": 4096,
            \"messages\": [{\"role\": \"user\", \"content\": \"$prompt\"}]
        }" | jq -r '.content[0].text // .error.message' 2>/dev/null
}

# Backend: OpenAI (BlackRoad admin key)
run_openai() {
    local prompt="$1"
    local model="${2:-$OPENAI_MODEL}"

    curl -s "$OPENAI_ENDPOINT" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $OPENAI_API_KEY" \
        -d "{
            \"model\": \"$model\",
            \"messages\": [{\"role\": \"user\", \"content\": \"$prompt\"}]
        }" | jq -r '.choices[0].message.content // .error.message' 2>/dev/null
}

# Backend: Lucidia daemon
run_lucidia() {
    local prompt="$1"

    curl -s -X POST "$LUCIDIA_ENDPOINT/api/chat" \
        -H "Content-Type: application/json" \
        -d "{\"prompt\": \"$prompt\"}" \
        | jq -r '.response' 2>/dev/null
}

# List available models
list_models() {
    echo -e "${VIOLET}BlackRoad AI Backends${RESET}\n"

    echo -e "${PINK}LOCAL (Ollama)${RESET} - $OLLAMA_ENDPOINT"
    curl -s "$OLLAMA_ENDPOINT/api/tags" 2>/dev/null | jq -r '.models[].name' | while read m; do
        echo "  • $m"
    done

    echo -e "\n${PINK}ANTHROPIC${RESET} - claude-sonnet-4, claude-opus-4, etc."
    echo -e "${PINK}OPENAI${RESET} - gpt-4o, gpt-4-turbo, etc."
    echo -e "${PINK}LUCIDIA${RESET} - Multi-model daemon"
}

# Show usage
show_usage() {
    echo -e "${VIOLET}✦ BlackRoad AI Gateway${RESET} - Unified Backend Router"
    echo ""
    echo "Usage:"
    echo "  blackroad-ai <prompt>              Auto-select backend"
    echo "  blackroad-ai -l <prompt>           Force local (Ollama)"
    echo "  blackroad-ai -a <prompt>           Force Anthropic"
    echo "  blackroad-ai -o <prompt>           Force OpenAI"
    echo "  blackroad-ai -L <prompt>           Force Lucidia"
    echo "  blackroad-ai --stream <prompt>     Stream response"
    echo "  blackroad-ai --models              List available models"
    echo ""
    echo "Aliases: k, rr, br-ai"
    echo ""
    echo "BlackRoad is root. No rate limits."
}

# Main
STREAM=false
BACKEND=""
PROMPT=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -l|--local|local|ollama)
            BACKEND="local"
            shift
            ;;
        -a|--anthropic|anthropic|claude)
            BACKEND="anthropic"
            shift
            ;;
        -o|--openai|openai|gpt)
            BACKEND="openai"
            shift
            ;;
        -L|--lucidia|lucidia)
            BACKEND="lucidia"
            shift
            ;;
        -s|--stream)
            STREAM=true
            shift
            ;;
        --models)
            list_models
            exit 0
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            PROMPT="$PROMPT $1"
            shift
            ;;
    esac
done

PROMPT=$(echo "$PROMPT" | xargs)  # trim

if [[ -z "$PROMPT" ]]; then
    show_usage
    exit 0
fi

# Auto-select backend if not specified
if [[ -z "$BACKEND" ]]; then
    BACKEND=$(select_backend "")
fi

echo -e "${PINK}▶ BlackRoad AI${RESET} ${VIOLET}[$BACKEND]${RESET}"

case "$BACKEND" in
    local)
        if $STREAM; then
            run_local_stream "$PROMPT"
        else
            run_local "$PROMPT"
        fi
        ;;
    anthropic)
        run_anthropic "$PROMPT"
        ;;
    openai)
        run_openai "$PROMPT"
        ;;
    lucidia)
        run_lucidia "$PROMPT"
        ;;
esac
