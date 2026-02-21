#!/bin/bash
# BlackRoad Smart Model Router
# Routes queries to the best model based on content
# Agent: Icarus (b3e01bd9)

PINK='\033[38;5;205m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RESET='\033[0m'

# Model routing rules
# coding -> codellama
# math -> llama3.2:3b
# quick -> tinyllama
# general -> llama3.2:1b

# Detect query type
detect_type() {
    local query="$1"
    local lower=$(echo "$query" | tr '[:upper:]' '[:lower:]')

    # Coding keywords
    if echo "$lower" | grep -qE 'code|function|class|def |import |const |let |var |python|javascript|rust|go |java|html|css|api|debug|error|bug|syntax'; then
        echo "coding"
    # Math keywords
    elif echo "$lower" | grep -qE 'calculate|math|equation|solve|formula|integral|derivative|algebra|geometry|statistics|probability|percent|multiply|divide|add|subtract'; then
        echo "math"
    # Quick answer keywords
    elif echo "$lower" | grep -qE '^what is|^who is|^when |^where |^yes or no|^true or false|one word|short answer|quick|brief'; then
        echo "quick"
    else
        echo "general"
    fi
}

# Get best model for type
get_model() {
    local type="$1"
    case "$type" in
        coding)
            echo "codellama:7b"
            ;;
        math)
            echo "llama3.2:3b"
            ;;
        quick)
            echo "tinyllama"
            ;;
        *)
            echo "llama3.2:1b"
            ;;
    esac
}

# Get best node for model
get_node() {
    local model="$1"
    case "$model" in
        codellama:7b)
            echo "cecilia"  # Has codellama
            ;;
        llama3.2:3b)
            echo "cecilia"  # Has 3b
            ;;
        tinyllama)
            echo "lucidia"  # Has tinyllama
            ;;
        *)
            echo "lucidia"  # Default
            ;;
    esac
}

# Smart query
smart_query() {
    local query="$*"

    # Detect type
    local type=$(detect_type "$query")
    local model=$(get_model "$type")
    local node=$(get_node "$model")

    echo -e "${BLUE}[Type: $type → Model: $model → Node: $node]${RESET}" >&2

    # Run query
    ssh "$node" "curl -s http://localhost:11434/api/generate -d '{\"model\":\"$model\",\"prompt\":\"$query\",\"stream\":false}'" \
        | jq -r '.response'
}

# Interactive mode
interactive() {
    echo -e "${PINK}╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${PINK}║           🧠 BLACKROAD SMART ROUTER 🧠                       ║${RESET}"
    echo -e "${PINK}╚══════════════════════════════════════════════════════════════╝${RESET}"
    echo
    echo "Auto-routes to best model based on your question"
    echo "  coding → codellama:7b"
    echo "  math → llama3.2:3b"
    echo "  quick → tinyllama"
    echo "  general → llama3.2:1b"
    echo
    echo "Type 'exit' to quit"
    echo

    while true; do
        echo -n -e "${GREEN}You: ${RESET}"
        read -r input

        [[ "$input" == "exit" ]] && break

        echo -n -e "${BLUE}AI: ${RESET}"
        smart_query "$input"
        echo
    done
}

# Test routing
test_routing() {
    echo -e "${PINK}=== SMART ROUTER TEST ===${RESET}"
    echo

    local tests=(
        "Write a Python function to sort a list"
        "What is 15% of 200?"
        "What is the capital of France?"
        "Explain quantum computing"
        "Debug this code: for i in range(10) print(i)"
        "Calculate the area of a circle with radius 5"
    )

    for query in "${tests[@]}"; do
        local type=$(detect_type "$query")
        local model=$(get_model "$type")
        echo -e "${GREEN}Q:${RESET} $query"
        echo -e "${BLUE}→ Type: $type, Model: $model${RESET}"
        echo
    done
}

case "${1:-help}" in
    query)
        shift
        smart_query "$@"
        ;;
    interactive|chat)
        interactive
        ;;
    test)
        test_routing
        ;;
    *)
        echo "BlackRoad Smart Model Router"
        echo
        echo "Usage: $0 <command>"
        echo
        echo "Commands:"
        echo "  query <text>   Smart query with auto-routing"
        echo "  interactive    Interactive chat mode"
        echo "  test           Test routing logic"
        ;;
esac
