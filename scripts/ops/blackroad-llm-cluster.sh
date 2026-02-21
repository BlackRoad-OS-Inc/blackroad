#!/bin/bash
# BlackRoad Distributed LLM Cluster
# Parallel inference across multiple Pi nodes via SSH
# Agent: Icarus (b3e01bd9)

# Colors
PINK='\033[38;5;205m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RESET='\033[0m'

# LLM Nodes (SSH hostname)
LLM_NODES=("lucidia" "cecilia" "octavia" "aria")
DEFAULT_MODEL="llama3.2:1b"

# Check node health via SSH
check_node() {
    local host="$1"
    ssh -o ConnectTimeout=2 -o BatchMode=yes "$host" \
        "curl -s http://localhost:11434/api/tags" >/dev/null 2>&1
}

# Get healthy nodes
get_healthy_nodes() {
    local healthy=()
    for node in "${LLM_NODES[@]}"; do
        if check_node "$node"; then
            healthy+=("$node")
        fi
    done
    echo "${healthy[@]}"
}

# Query node via SSH
query_node() {
    local host="$1"
    local model="$2"
    local prompt="$3"

    ssh -o ConnectTimeout=5 "$host" \
        "curl -s http://localhost:11434/api/generate -d '{\"model\":\"$model\",\"prompt\":\"$prompt\",\"stream\":false}'" \
        2>/dev/null | jq -r '.response // "Error: No response"'
}

# Query with stats
query_node_stats() {
    local host="$1"
    local model="$2"
    local prompt="$3"

    ssh -o ConnectTimeout=5 "$host" \
        "curl -s http://localhost:11434/api/generate -d '{\"model\":\"$model\",\"prompt\":\"$prompt\",\"stream\":false}'" \
        2>/dev/null | jq '{response: .response, tokens: .eval_count, time_sec: (.eval_duration/1000000000), tokens_per_sec: (.eval_count / (.eval_duration/1000000000))}'
}

# Load-balanced query
query() {
    local model="${1:-$DEFAULT_MODEL}"
    local prompt="$2"

    local healthy=($(get_healthy_nodes))
    if [ ${#healthy[@]} -eq 0 ]; then
        echo "ERROR: No healthy LLM nodes"
        return 1
    fi

    # Pick random node
    local idx=$((RANDOM % ${#healthy[@]}))
    local host="${healthy[$idx]}"

    echo -e "${BLUE}[Using $host]${RESET}" >&2
    query_node "$host" "$model" "$prompt"
}

# Parallel query to ALL healthy nodes with SAME prompt
parallel_same() {
    local model="${1:-$DEFAULT_MODEL}"
    local prompt="$2"

    local healthy=($(get_healthy_nodes))
    echo -e "${BLUE}Querying ${#healthy[@]} nodes in parallel...${RESET}" >&2

    for host in "${healthy[@]}"; do
        (
            local start=$(date +%s.%N)
            local result=$(query_node "$host" "$model" "$prompt")
            local end=$(date +%s.%N)
            local time=$(echo "$end - $start" | bc)
            echo -e "${GREEN}[$host - ${time}s]${RESET}"
            echo "$result"
            echo
        ) &
    done
    wait
}

# Parallel query - different prompts to different nodes
parallel_multi() {
    local model="${1:-$DEFAULT_MODEL}"
    shift
    local prompts=("$@")

    local healthy=($(get_healthy_nodes))

    for i in "${!prompts[@]}"; do
        if [ $i -lt ${#healthy[@]} ]; then
            local host="${healthy[$i]}"
            (
                echo -e "${GREEN}=== $host ===${RESET}"
                query_node "$host" "$model" "${prompts[$i]}"
                echo
            ) &
        fi
    done
    wait
}

# Stream response
stream() {
    local model="${1:-$DEFAULT_MODEL}"
    local prompt="$2"

    local healthy=($(get_healthy_nodes))
    if [ ${#healthy[@]} -eq 0 ]; then
        echo "ERROR: No healthy nodes"
        return 1
    fi

    local host="${healthy[0]}"
    echo -e "${BLUE}[Streaming from $host]${RESET}" >&2

    ssh "$host" "curl -s http://localhost:11434/api/generate -d '{\"model\":\"$model\",\"prompt\":\"$prompt\",\"stream\":true}'" \
        | while read -r line; do
            echo "$line" | jq -r '.response // empty' 2>/dev/null | tr -d '\n'
        done
    echo
}

# Cluster status
status() {
    echo -e "${PINK}╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${PINK}║           🤖 BLACKROAD LLM CLUSTER STATUS 🤖                 ║${RESET}"
    echo -e "${PINK}╚══════════════════════════════════════════════════════════════╝${RESET}"
    echo

    local online=0
    local total=${#LLM_NODES[@]}
    local total_models=0

    for host in "${LLM_NODES[@]}"; do
        echo -n "  $host: "

        if check_node "$host"; then
            local models=$(ssh "$host" "curl -s http://localhost:11434/api/tags" 2>/dev/null | jq -r '.models[].name' | tr '\n' ' ')
            local count=$(echo "$models" | wc -w)
            echo -e "${GREEN}ONLINE${RESET} - $models"
            ((online++))
            ((total_models+=count))
        else
            echo -e "${YELLOW}OFFLINE${RESET}"
        fi
    done

    echo
    echo -e "  ${GREEN}Healthy: $online/$total nodes${RESET}"
    echo -e "  ${BLUE}Models: $total_models total${RESET}"
    echo -e "  ${BLUE}Default: $DEFAULT_MODEL${RESET}"
}

# Benchmark
benchmark() {
    local model="${1:-$DEFAULT_MODEL}"
    local prompt="What is 2+2? Reply with just the number."

    echo -e "${PINK}╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${PINK}║           🚀 LLM CLUSTER BENCHMARK 🚀                        ║${RESET}"
    echo -e "${PINK}╚══════════════════════════════════════════════════════════════╝${RESET}"
    echo
    echo "Model: $model"
    echo

    local healthy=($(get_healthy_nodes))
    local num_nodes=${#healthy[@]}
    echo "Healthy nodes: $num_nodes"
    echo

    if [ $num_nodes -eq 0 ]; then
        echo "No healthy nodes!"
        return 1
    fi

    # Single node latency
    echo "=== Single Node Latency ==="
    local start=$(date +%s.%N)
    query_node "${healthy[0]}" "$model" "$prompt" >/dev/null
    local end=$(date +%s.%N)
    local single=$(echo "$end - $start" | bc)
    echo "  ${healthy[0]}: ${single}s"
    echo

    # Parallel - same prompt to all nodes
    echo "=== Parallel (all nodes, same prompt) ==="
    start=$(date +%s.%N)
    for host in "${healthy[@]}"; do
        query_node "$host" "$model" "$prompt" >/dev/null &
    done
    wait
    end=$(date +%s.%N)
    local parallel=$(echo "$end - $start" | bc)
    echo "  Time: ${parallel}s for $num_nodes responses"
    echo "  Effective: $(echo "scale=2; $num_nodes / $parallel" | bc) responses/sec"
    echo

    # Throughput test - 10 requests distributed
    echo "=== Throughput (10 requests, distributed) ==="
    start=$(date +%s.%N)
    for i in {1..10}; do
        local idx=$(( (i-1) % num_nodes ))
        query_node "${healthy[$idx]}" "$model" "$prompt" >/dev/null &
    done
    wait
    end=$(date +%s.%N)
    local total=$(echo "$end - $start" | bc)
    local rps=$(echo "scale=2; 10 / $total" | bc)
    echo "  Total: ${total}s"
    echo "  RPS: $rps requests/sec"
    echo

    # Token speed per node
    echo "=== Token Speed Per Node ==="
    for host in "${healthy[@]}"; do
        local stats=$(query_node_stats "$host" "$model" "Write exactly 50 words about AI." 2>/dev/null)
        local tps=$(echo "$stats" | jq -r '.tokens_per_sec // 0')
        echo "  $host: ${tps} tokens/sec"
    done
}

# Interactive chat
chat() {
    local model="${1:-$DEFAULT_MODEL}"

    echo -e "${PINK}╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${PINK}║              🤖 BLACKROAD LLM CHAT 🤖                        ║${RESET}"
    echo -e "${PINK}╚══════════════════════════════════════════════════════════════╝${RESET}"
    echo
    echo "Model: $model"
    echo "Commands: 'exit', 'status', 'model <name>'"
    echo

    local healthy=($(get_healthy_nodes))
    echo "Connected to ${#healthy[@]} nodes: ${healthy[*]}"
    echo

    while true; do
        echo -n -e "${GREEN}You: ${RESET}"
        read -r input

        case "$input" in
            exit|quit|q)
                echo "Goodbye!"
                break
                ;;
            status)
                status
                ;;
            model\ *)
                model="${input#model }"
                echo "Switched to model: $model"
                ;;
            *)
                echo -n -e "${BLUE}AI: ${RESET}"
                stream "$model" "$input"
                echo
                ;;
        esac
    done
}

# Ask (simple one-shot query)
ask() {
    local prompt="$*"
    query "$DEFAULT_MODEL" "$prompt"
}

# Help
help() {
    echo -e "${PINK}BlackRoad LLM Cluster${RESET}"
    echo
    echo "Usage: $0 <command> [args]"
    echo
    echo "Commands:"
    echo "  status                Show cluster status"
    echo "  ask <prompt>          Quick query (load-balanced)"
    echo "  query <model> <prompt> Query specific model"
    echo "  stream <prompt>       Stream response"
    echo "  chat [model]          Interactive chat"
    echo "  parallel <prompt>     Same prompt to all nodes"
    echo "  benchmark [model]     Benchmark throughput"
    echo
    echo "Examples:"
    echo "  $0 status"
    echo "  $0 ask 'What is the capital of France?'"
    echo "  $0 chat llama3.2:3b"
    echo "  $0 benchmark"
    echo "  $0 parallel 'Tell me a joke'"
}

# Main
case "${1:-help}" in
    status)
        status
        ;;
    ask)
        shift
        ask "$@"
        ;;
    query)
        query "$2" "$3"
        ;;
    stream)
        stream "$DEFAULT_MODEL" "$2"
        ;;
    chat)
        chat "${2:-$DEFAULT_MODEL}"
        ;;
    parallel)
        parallel_same "$DEFAULT_MODEL" "$2"
        ;;
    benchmark)
        benchmark "${2:-$DEFAULT_MODEL}"
        ;;
    help|--help|-h)
        help
        ;;
    *)
        help
        ;;
esac
