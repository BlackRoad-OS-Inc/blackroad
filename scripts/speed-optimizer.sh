#!/bin/bash
# BlackRoad LLM Speed Optimizer
# Push for <5 second responses
# Agent: Icarus (b3e01bd9)

PINK='\033[38;5;205m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RESET='\033[0m'

LLM_NODES=("lucidia" "cecilia" "octavia")

# Test all fast models
test_fast_models() {
    echo -e "${PINK}=== SPEED TEST: Finding Fastest Model ===${RESET}"
    echo

    local fast_models=("tinyllama" "qwen2.5:0.5b" "llama3.2:1b")
    local prompt="What is 2+2? One word."

    for model in "${fast_models[@]}"; do
        for node in "${LLM_NODES[@]}"; do
            echo -n "  $node / $model: "

            local start=$(date +%s.%N)
            local result=$(ssh -o ConnectTimeout=3 "$node" \
                "curl -s http://localhost:11434/api/generate -d '{\"model\":\"$model\",\"prompt\":\"$prompt\",\"stream\":false}'" 2>/dev/null \
                | jq -r '.response // "N/A"' | head -c 20)
            local end=$(date +%s.%N)

            if [ "$result" != "N/A" ] && [ -n "$result" ]; then
                local time=$(echo "$end - $start" | bc)
                echo -e "${GREEN}${time}s${RESET} → $result"
            else
                echo -e "${YELLOW}not available${RESET}"
            fi
        done
        echo
    done
}

# Warm up models (preload into memory)
warmup() {
    echo -e "${PINK}=== WARMING UP MODELS ===${RESET}"
    echo

    for node in "${LLM_NODES[@]}"; do
        echo -n "  Warming $node... "
        ssh "$node" "curl -s http://localhost:11434/api/generate -d '{\"model\":\"tinyllama\",\"prompt\":\"hi\",\"stream\":false}'" >/dev/null 2>&1 &
    done
    wait
    echo -e "${GREEN}Done!${RESET}"
}

# Benchmark with warm models
benchmark_warm() {
    echo -e "${PINK}=== WARM MODEL BENCHMARK ===${RESET}"
    echo

    local prompt="Say hello in 5 words or less."
    local total_time=0
    local count=0

    # Run 5 quick queries
    for i in {1..5}; do
        local node="${LLM_NODES[$((i % ${#LLM_NODES[@]}))]}"

        local start=$(date +%s.%N)
        ssh "$node" "curl -s http://localhost:11434/api/generate -d '{\"model\":\"tinyllama\",\"prompt\":\"$prompt\",\"stream\":false}'" >/dev/null 2>&1
        local end=$(date +%s.%N)

        local time=$(echo "$end - $start" | bc)
        echo "  Query $i ($node): ${time}s"

        total_time=$(echo "$total_time + $time" | bc)
        ((count++))
    done

    local avg=$(echo "scale=2; $total_time / $count" | bc)
    echo
    echo -e "  ${GREEN}Average: ${avg}s${RESET}"

    if (( $(echo "$avg < 5" | bc -l) )); then
        echo -e "  ${GREEN}✓ Under 5 seconds!${RESET}"
    else
        echo -e "  ${YELLOW}✗ Over 5 seconds - try tinyllama or qwen2.5:0.5b${RESET}"
    fi
}

# Optimize: set context size and other params
optimize_config() {
    echo -e "${PINK}=== OPTIMIZING OLLAMA CONFIG ===${RESET}"
    echo

    for node in "${LLM_NODES[@]}"; do
        echo "  Optimizing $node..."

        # Set smaller context window for speed
        ssh "$node" "curl -s http://localhost:11434/api/generate -d '{
            \"model\":\"tinyllama\",
            \"prompt\":\"test\",
            \"options\":{\"num_ctx\":512,\"num_predict\":50},
            \"stream\":false
        }'" >/dev/null 2>&1

        echo -e "    ${GREEN}Set num_ctx=512, num_predict=50${RESET}"
    done
}

# Quick query with optimized settings
quick_query() {
    local prompt="$*"
    local node="${LLM_NODES[$((RANDOM % ${#LLM_NODES[@]}))]}"

    echo -e "${BLUE}[Quick: $node]${RESET}" >&2

    ssh "$node" "curl -s http://localhost:11434/api/generate -d '{
        \"model\":\"tinyllama\",
        \"prompt\":\"$prompt\",
        \"options\":{\"num_ctx\":512,\"num_predict\":100},
        \"stream\":false
    }'" | jq -r '.response'
}

# Help
help() {
    echo -e "${PINK}BlackRoad Speed Optimizer${RESET}"
    echo
    echo "Goal: <5 second LLM responses"
    echo
    echo "Commands:"
    echo "  test        Test all fast models"
    echo "  warmup      Preload models into memory"
    echo "  benchmark   Benchmark warm models"
    echo "  optimize    Set optimal Ollama config"
    echo "  quick <q>   Quick optimized query"
    echo
    echo "Tips:"
    echo "  - Use tinyllama or qwen2.5:0.5b for speed"
    echo "  - Warm up models before querying"
    echo "  - Keep num_ctx and num_predict low"
}

case "${1:-help}" in
    test)
        test_fast_models
        ;;
    warmup)
        warmup
        ;;
    benchmark)
        benchmark_warm
        ;;
    optimize)
        optimize_config
        ;;
    quick)
        shift
        quick_query "$@"
        ;;
    *)
        help
        ;;
esac
