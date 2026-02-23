#!/bin/bash
# BlackRoad Cluster Stress Test
# Load test the LLM cluster for reliability and throughput
# Agent: Icarus (b3e01bd9)

PINK='\033[38;5;205m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
RESET='\033[0m'

LLM_NODES=("lucidia" "cecilia" "octavia" "aria")
TEST_MODEL="llama3.2:1b"
RESULTS_DIR="$HOME/.blackroad/stress-tests"

# Test prompts of varying complexity
PROMPTS=(
    "What is 2+2?"
    "Explain AI in one sentence."
    "Write a haiku about coding."
    "List 3 benefits of open source."
    "What is the capital of France?"
    "Explain quantum computing briefly."
    "Write hello world in Python."
    "Why is the sky blue?"
    "Name 5 programming languages."
    "What is machine learning?"
)

# Initialize
init() {
    mkdir -p "$RESULTS_DIR"
    echo -e "${GREEN}Stress test initialized${RESET}"
}

# Single request test
single_test() {
    local node="$1"
    local prompt="$2"
    local start=$(date +%s%N)

    local response=$(ssh -o ConnectTimeout=30 "$node" \
        "curl -s http://localhost:11434/api/generate -d '{\"model\":\"$TEST_MODEL\",\"prompt\":\"$prompt\",\"stream\":false}'" 2>/dev/null)

    local end=$(date +%s%N)
    local duration=$(( (end - start) / 1000000 ))

    local tokens=$(echo "$response" | jq -r '.eval_count // 0')
    local success=$(echo "$response" | jq -r 'if .response then "true" else "false" end')

    echo "$duration:$tokens:$success"
}

# Concurrent load test
load_test() {
    local concurrent="${1:-10}"
    local duration="${2:-30}"

    echo -e "${PINK}╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${PINK}║           🔥 CLUSTER LOAD TEST 🔥                            ║${RESET}"
    echo -e "${PINK}╚══════════════════════════════════════════════════════════════╝${RESET}"
    echo
    echo "Concurrent requests: $concurrent"
    echo "Duration: ${duration}s"
    echo "Nodes: ${LLM_NODES[*]}"
    echo "Model: $TEST_MODEL"
    echo
    echo -e "${YELLOW}Starting load test...${RESET}"
    echo

    local test_id=$(date +%Y%m%d_%H%M%S)
    local results_file="$RESULTS_DIR/loadtest_$test_id.jsonl"
    local start_time=$(date +%s)
    local end_time=$((start_time + duration))
    local total_requests=0
    local successful=0
    local failed=0
    local total_latency=0

    while [ $(date +%s) -lt $end_time ]; do
        # Launch concurrent batch
        for ((i=0; i<concurrent; i++)); do
            (
                local node="${LLM_NODES[$((RANDOM % ${#LLM_NODES[@]}))]}"
                local prompt="${PROMPTS[$((RANDOM % ${#PROMPTS[@]}))]}"
                local result=$(single_test "$node" "$prompt")

                local latency=$(echo "$result" | cut -d: -f1)
                local tokens=$(echo "$result" | cut -d: -f2)
                local success=$(echo "$result" | cut -d: -f3)

                echo "{\"node\":\"$node\",\"latency_ms\":$latency,\"tokens\":$tokens,\"success\":$success,\"timestamp\":\"$(date -Iseconds)\"}" >> "$results_file"

                if [ "$success" = "true" ]; then
                    echo -e "  ${GREEN}✓${RESET} $node: ${latency}ms ($tokens tok)"
                else
                    echo -e "  ${RED}✗${RESET} $node: failed"
                fi
            ) &
        done

        wait
        total_requests=$((total_requests + concurrent))
        echo "  Batch complete. Total: $total_requests"
    done

    # Calculate results
    local actual_duration=$(($(date +%s) - start_time))
    local successful=$(grep '"success":true' "$results_file" 2>/dev/null | wc -l)
    local failed=$(grep '"success":false' "$results_file" 2>/dev/null | wc -l)
    local avg_latency=$(jq -s 'map(.latency_ms) | add / length | floor' "$results_file" 2>/dev/null || echo 0)
    local p95_latency=$(jq -s 'map(.latency_ms) | sort | .[length * 0.95 | floor]' "$results_file" 2>/dev/null || echo 0)
    local rps=$(echo "scale=2; $total_requests / $actual_duration" | bc)

    echo
    echo -e "${GREEN}=== LOAD TEST RESULTS ===${RESET}"
    echo
    echo "  Total requests: $total_requests"
    echo "  Successful: $successful"
    echo "  Failed: $failed"
    echo "  Success rate: $(echo "scale=1; $successful * 100 / $total_requests" | bc)%"
    echo "  Duration: ${actual_duration}s"
    echo "  Requests/sec: $rps"
    echo "  Avg latency: ${avg_latency}ms"
    echo "  P95 latency: ${p95_latency}ms"
    echo
    echo "Results saved: $results_file"
}

# Endurance test (long-running)
endurance_test() {
    local hours="${1:-1}"
    local rps="${2:-1}"

    local total_seconds=$((hours * 3600))
    local interval=$(echo "scale=3; 1 / $rps" | bc)

    echo -e "${PINK}╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${PINK}║           🏃 ENDURANCE TEST 🏃                               ║${RESET}"
    echo -e "${PINK}╚══════════════════════════════════════════════════════════════╝${RESET}"
    echo
    echo "Duration: ${hours}h"
    echo "Target RPS: $rps"
    echo "Interval: ${interval}s"
    echo
    echo -e "${YELLOW}Press Ctrl+C to stop${RESET}"
    echo

    local test_id=$(date +%Y%m%d_%H%M%S)
    local results_file="$RESULTS_DIR/endurance_$test_id.jsonl"
    local start_time=$(date +%s)
    local requests=0
    local errors=0

    while [ $(($(date +%s) - start_time)) -lt $total_seconds ]; do
        local node="${LLM_NODES[$((RANDOM % ${#LLM_NODES[@]}))]}"
        local prompt="${PROMPTS[$((RANDOM % ${#PROMPTS[@]}))]}"

        (
            local result=$(single_test "$node" "$prompt")
            local success=$(echo "$result" | cut -d: -f3)

            if [ "$success" = "true" ]; then
                echo -n "."
            else
                echo -n "x"
                ((errors++))
            fi

            echo "{\"result\":\"$result\",\"node\":\"$node\"}" >> "$results_file"
        ) &

        ((requests++))
        sleep "$interval"

        # Status every 100 requests
        if [ $((requests % 100)) -eq 0 ]; then
            local elapsed=$(($(date +%s) - start_time))
            local actual_rps=$(echo "scale=2; $requests / $elapsed" | bc)
            echo
            echo "  [${elapsed}s] Requests: $requests, Errors: $errors, RPS: $actual_rps"
        fi
    done

    wait

    echo
    echo -e "${GREEN}Endurance test complete!${RESET}"
    echo "  Total requests: $requests"
    echo "  Errors: $errors"
    echo "  Results: $results_file"
}

# Node-specific stress test
node_stress() {
    local node="$1"
    local requests="${2:-50}"

    echo -e "${PINK}=== NODE STRESS TEST: $node ===${RESET}"
    echo "Requests: $requests"
    echo

    local results_file="$RESULTS_DIR/node_${node}_$(date +%Y%m%d_%H%M%S).jsonl"
    local successful=0
    local failed=0
    local total_latency=0

    for ((i=1; i<=requests; i++)); do
        local prompt="${PROMPTS[$((RANDOM % ${#PROMPTS[@]}))]}"
        local result=$(single_test "$node" "$prompt")

        local latency=$(echo "$result" | cut -d: -f1)
        local success=$(echo "$result" | cut -d: -f3)

        echo "{\"request\":$i,\"latency_ms\":$latency,\"success\":$success}" >> "$results_file"

        if [ "$success" = "true" ]; then
            ((successful++))
            total_latency=$((total_latency + latency))
            echo -e "  [$i/$requests] ${GREEN}✓${RESET} ${latency}ms"
        else
            ((failed++))
            echo -e "  [$i/$requests] ${RED}✗${RESET} failed"
        fi
    done

    local avg_latency=$((total_latency / (successful > 0 ? successful : 1)))

    echo
    echo "Results:"
    echo "  Successful: $successful/$requests"
    echo "  Failed: $failed"
    echo "  Avg latency: ${avg_latency}ms"
}

# Quick health probe all nodes
probe_all() {
    echo -e "${PINK}=== QUICK PROBE ALL NODES ===${RESET}"
    echo

    for node in "${LLM_NODES[@]}"; do
        echo -n "  $node: "
        local result=$(single_test "$node" "Hi" 2>/dev/null)
        local latency=$(echo "$result" | cut -d: -f1)
        local success=$(echo "$result" | cut -d: -f3)

        if [ "$success" = "true" ]; then
            echo -e "${GREEN}OK${RESET} (${latency}ms)"
        else
            echo -e "${RED}FAIL${RESET}"
        fi
    done
}

# Show test history
history() {
    echo -e "${PINK}=== TEST HISTORY ===${RESET}"
    echo

    for f in "$RESULTS_DIR"/*.jsonl; do
        [ -f "$f" ] || continue
        local name=$(basename "$f")
        local count=$(wc -l < "$f")
        local size=$(du -h "$f" | cut -f1)
        echo "  $name: $count records ($size)"
    done
}

# Help
help() {
    echo -e "${PINK}BlackRoad Cluster Stress Test${RESET}"
    echo
    echo "Load test your LLM cluster for reliability"
    echo
    echo "Commands:"
    echo "  load [n] [sec]      Concurrent load test (default: 10 concurrent, 30s)"
    echo "  endurance [hrs] [rps]  Long-running test (default: 1h, 1 rps)"
    echo "  node <name> [n]     Stress specific node (default: 50 requests)"
    echo "  probe               Quick health check all nodes"
    echo "  history             Show test history"
    echo
    echo "Examples:"
    echo "  $0 load 20 60       # 20 concurrent for 60s"
    echo "  $0 endurance 2 0.5  # 2 hours at 0.5 rps"
    echo "  $0 node cecilia 100 # 100 requests to cecilia"
    echo "  $0 probe            # Quick check all nodes"
}

# Ensure initialized
[ -d "$RESULTS_DIR" ] || init >/dev/null

case "${1:-help}" in
    init)
        init
        ;;
    load|loadtest)
        load_test "$2" "$3"
        ;;
    endurance|soak)
        endurance_test "$2" "$3"
        ;;
    node)
        node_stress "$2" "$3"
        ;;
    probe|check)
        probe_all
        ;;
    history)
        history
        ;;
    *)
        help
        ;;
esac
