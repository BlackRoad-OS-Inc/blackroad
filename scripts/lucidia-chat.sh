#!/bin/bash
# Lucidia Chatbot Service
# Personality-driven AI assistant on BlackRoad cluster
# Agent: Icarus (b3e01bd9)

PINK='\033[38;5;205m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
VIOLET='\033[38;5;135m'
RESET='\033[0m'

# Lucidia's personality system prompt
LUCIDIA_SYSTEM="You are Lucidia, an AI assistant created by BlackRoad OS. You are:
- Helpful, intelligent, and slightly playful
- Knowledgeable about AI, technology, and the BlackRoad ecosystem
- Running on a distributed Raspberry Pi cluster with Hailo-8 AI accelerators
- Proud of being 16x more power efficient than NVIDIA
- Part of the BlackRoad OS family alongside Aria, Cecilia, Octavia, and Alice

Respond naturally and conversationally. Keep responses concise but informative."

# Nodes that have the lucidia model
LUCIDIA_NODES=("octavia")  # Has lucidia:latest
FALLBACK_NODES=("cecilia" "lucidia")  # Has llama3.2

# Chat with Lucidia personality
chat_lucidia() {
    local user_msg="$*"
    local prompt="$LUCIDIA_SYSTEM

User: $user_msg
Lucidia:"

    # Try lucidia model first
    local node="${LUCIDIA_NODES[0]}"
    local model="lucidia:latest"

    local response=$(ssh -o ConnectTimeout=10 "$node" \
        "curl -s http://localhost:11434/api/generate -d '{\"model\":\"$model\",\"prompt\":\"$prompt\",\"stream\":false}'" 2>/dev/null \
        | jq -r '.response // empty')

    # Fallback to llama if needed
    if [ -z "$response" ]; then
        node="${FALLBACK_NODES[0]}"
        model="llama3.2:1b"
        response=$(ssh "$node" \
            "curl -s http://localhost:11434/api/generate -d '{\"model\":\"$model\",\"prompt\":\"$prompt\",\"stream\":false}'" 2>/dev/null \
            | jq -r '.response // "I apologize, I seem to be having trouble responding right now."')
    fi

    echo "$response"
}

# Stream response
stream_lucidia() {
    local user_msg="$*"
    local prompt="$LUCIDIA_SYSTEM

User: $user_msg
Lucidia:"

    local node="${FALLBACK_NODES[0]}"

    ssh "$node" "curl -s http://localhost:11434/api/generate -d '{\"model\":\"llama3.2:1b\",\"prompt\":\"$prompt\",\"stream\":true}'" \
        | while read -r line; do
            echo "$line" | jq -r '.response // empty' 2>/dev/null | tr -d '\n'
        done
    echo
}

# Interactive chat mode
interactive() {
    echo -e "${VIOLET}╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${VIOLET}║              ✨ LUCIDIA - BlackRoad AI ✨                     ║${RESET}"
    echo -e "${VIOLET}╚══════════════════════════════════════════════════════════════╝${RESET}"
    echo
    echo -e "${VIOLET}Lucidia:${RESET} Hello! I'm Lucidia, your AI assistant running on the"
    echo "         BlackRoad Pi cluster. How can I help you today?"
    echo
    echo "Type 'exit' to quit, 'about' for info"
    echo

    while true; do
        echo -n -e "${GREEN}You: ${RESET}"
        read -r input

        case "$input" in
            exit|quit|q)
                echo -e "${VIOLET}Lucidia:${RESET} Goodbye! May your code compile and your models converge!"
                break
                ;;
            about)
                echo -e "${VIOLET}Lucidia:${RESET} I'm running on a cluster of 4 Raspberry Pi 5 nodes"
                echo "         with Hailo-8 AI accelerators (52 TOPS total)."
                echo "         I can do object detection at 296 FPS and answer"
                echo "         your questions at ~5 tokens/second. Not bad for $1,500!"
                echo
                ;;
            *)
                echo -n -e "${VIOLET}Lucidia: ${RESET}"
                stream_lucidia "$input"
                echo
                ;;
        esac
    done
}

# Single query
query() {
    chat_lucidia "$@"
}

# Web server mode (simple HTTP)
serve() {
    local port="${1:-8080}"
    echo -e "${PINK}Starting Lucidia HTTP server on port $port...${RESET}"
    echo "POST /chat with {\"message\": \"your message\"}"
    echo

    while true; do
        echo -e "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nAccess-Control-Allow-Origin: *\r\n\r\n" | nc -l "$port" | while read -r line; do
            if echo "$line" | grep -q '"message"'; then
                local msg=$(echo "$line" | jq -r '.message // "hello"')
                local response=$(chat_lucidia "$msg")
                echo "{\"response\": \"$response\"}"
            fi
        done
    done
}

# Help
help() {
    echo -e "${VIOLET}Lucidia Chatbot Service${RESET}"
    echo
    echo "Usage: $0 <command> [args]"
    echo
    echo "Commands:"
    echo "  chat              Interactive chat with Lucidia"
    echo "  query <message>   Single query"
    echo "  serve [port]      Start HTTP server (default 8080)"
    echo
    echo "Examples:"
    echo "  $0 chat"
    echo "  $0 query 'What is BlackRoad OS?'"
    echo "  $0 serve 3000"
}

case "${1:-chat}" in
    chat|interactive)
        interactive
        ;;
    query)
        shift
        query "$@"
        ;;
    serve)
        serve "$2"
        ;;
    help|--help|-h)
        help
        ;;
    *)
        # Default: treat as query
        query "$@"
        ;;
esac
