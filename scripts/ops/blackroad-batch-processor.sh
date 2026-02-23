#!/bin/bash
# BlackRoad Batch Processor
# Queue and process large LLM jobs across the cluster
# Agent: Icarus (b3e01bd9)

PINK='\033[38;5;205m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RESET='\033[0m'

QUEUE_DIR="$HOME/.blackroad/batch-queue"
RESULTS_DIR="$HOME/.blackroad/batch-results"
LLM_NODES=("lucidia" "cecilia" "octavia")

# Initialize
init() {
    mkdir -p "$QUEUE_DIR" "$RESULTS_DIR"
    echo -e "${GREEN}Batch processor initialized${RESET}"
    echo "  Queue: $QUEUE_DIR"
    echo "  Results: $RESULTS_DIR"
}

# Add job to queue
add_job() {
    local prompt="$1"
    local model="${2:-llama3.2:1b}"
    local job_id=$(date +%s%N | md5sum | head -c 8)

    cat > "$QUEUE_DIR/$job_id.json" << EOF
{
    "id": "$job_id",
    "prompt": "$prompt",
    "model": "$model",
    "status": "pending",
    "created": "$(date -Iseconds)"
}
EOF

    echo "$job_id"
}

# Add jobs from file (one prompt per line)
add_from_file() {
    local file="$1"
    local model="${2:-llama3.2:1b}"
    local count=0

    while IFS= read -r prompt; do
        [[ -z "$prompt" ]] && continue
        local job_id=$(add_job "$prompt" "$model")
        echo "  Added: $job_id"
        ((count++))
    done < "$file"

    echo -e "${GREEN}Added $count jobs to queue${RESET}"
}

# Process single job
process_job() {
    local job_file="$1"
    local node="$2"

    local job_id=$(jq -r '.id' "$job_file")
    local prompt=$(jq -r '.prompt' "$job_file")
    local model=$(jq -r '.model' "$job_file")

    # Update status
    jq '.status = "processing" | .node = "'$node'" | .started = "'$(date -Iseconds)'"' "$job_file" > "$job_file.tmp" && mv "$job_file.tmp" "$job_file"

    # Run query
    local response=$(ssh -o ConnectTimeout=30 "$node" \
        "curl -s http://localhost:11434/api/generate -d '{\"model\":\"$model\",\"prompt\":\"$prompt\",\"stream\":false}'" 2>/dev/null)

    local answer=$(echo "$response" | jq -r '.response // "ERROR"')
    local tokens=$(echo "$response" | jq -r '.eval_count // 0')

    # Save result
    cat > "$RESULTS_DIR/$job_id.json" << EOF
{
    "id": "$job_id",
    "prompt": "$prompt",
    "response": $(echo "$answer" | jq -Rs .),
    "model": "$model",
    "node": "$node",
    "tokens": $tokens,
    "completed": "$(date -Iseconds)"
}
EOF

    # Remove from queue
    rm -f "$job_file"

    echo "$job_id"
}

# Process all jobs in queue
process_all() {
    local max_parallel="${1:-3}"

    echo -e "${PINK}=== PROCESSING BATCH QUEUE ===${RESET}"
    echo

    local pending=$(ls -1 "$QUEUE_DIR"/*.json 2>/dev/null | wc -l)
    echo "Pending jobs: $pending"
    echo "Max parallel: $max_parallel"
    echo "Nodes: ${LLM_NODES[*]}"
    echo

    if [ "$pending" -eq 0 ]; then
        echo "No jobs to process"
        return
    fi

    local processed=0
    local running=0
    local pids=()
    local node_idx=0

    for job_file in "$QUEUE_DIR"/*.json; do
        [ -f "$job_file" ] || continue

        # Wait if at max parallel
        while [ $running -ge $max_parallel ]; do
            wait -n
            ((running--))
        done

        # Pick node round-robin
        local node="${LLM_NODES[$node_idx]}"
        node_idx=$(( (node_idx + 1) % ${#LLM_NODES[@]} ))

        # Process in background
        (
            local job_id=$(process_job "$job_file" "$node")
            echo -e "  ${GREEN}✓${RESET} $job_id ($node)"
        ) &

        ((running++))
        ((processed++))
    done

    # Wait for remaining
    wait

    echo
    echo -e "${GREEN}Processed $processed jobs${RESET}"
}

# Show queue status
status() {
    echo -e "${PINK}=== BATCH QUEUE STATUS ===${RESET}"
    echo

    local pending=$(ls -1 "$QUEUE_DIR"/*.json 2>/dev/null | wc -l)
    local completed=$(ls -1 "$RESULTS_DIR"/*.json 2>/dev/null | wc -l)

    echo "  Pending: $pending"
    echo "  Completed: $completed"
    echo

    if [ "$pending" -gt 0 ]; then
        echo "Pending jobs:"
        for f in "$QUEUE_DIR"/*.json; do
            [ -f "$f" ] || continue
            local id=$(jq -r '.id' "$f")
            local prompt=$(jq -r '.prompt[:50]' "$f")
            echo "  $id: $prompt..."
        done
    fi
}

# Get results
results() {
    local format="${1:-summary}"

    case "$format" in
        summary)
            echo -e "${PINK}=== BATCH RESULTS ===${RESET}"
            echo
            for f in "$RESULTS_DIR"/*.json; do
                [ -f "$f" ] || continue
                local id=$(jq -r '.id' "$f")
                local tokens=$(jq -r '.tokens' "$f")
                local response=$(jq -r '.response[:60]' "$f")
                echo "  $id ($tokens tok): $response..."
            done
            ;;
        json)
            for f in "$RESULTS_DIR"/*.json; do
                [ -f "$f" ] || continue
                cat "$f"
                echo
            done
            ;;
        csv)
            echo "id,tokens,response"
            for f in "$RESULTS_DIR"/*.json; do
                [ -f "$f" ] || continue
                jq -r '[.id, .tokens, .response] | @csv' "$f"
            done
            ;;
    esac
}

# Clear queue and results
clear_all() {
    rm -f "$QUEUE_DIR"/*.json "$RESULTS_DIR"/*.json 2>/dev/null
    echo -e "${GREEN}Cleared queue and results${RESET}"
}

# Help
help() {
    echo -e "${PINK}BlackRoad Batch Processor${RESET}"
    echo
    echo "Process large LLM jobs across the cluster"
    echo
    echo "Commands:"
    echo "  init                Initialize directories"
    echo "  add <prompt>        Add single job"
    echo "  add-file <file>     Add jobs from file (one per line)"
    echo "  process [n]         Process queue (n parallel, default 3)"
    echo "  status              Show queue status"
    echo "  results [format]    Show results (summary/json/csv)"
    echo "  clear               Clear queue and results"
    echo
    echo "Examples:"
    echo "  $0 add 'Summarize quantum computing'"
    echo "  $0 add-file prompts.txt"
    echo "  $0 process 4"
    echo "  $0 results csv > output.csv"
}

# Ensure initialized
[ -d "$QUEUE_DIR" ] || init >/dev/null

case "${1:-help}" in
    init)
        init
        ;;
    add)
        shift
        job_id=$(add_job "$@")
        echo -e "${GREEN}Added job: $job_id${RESET}"
        ;;
    add-file)
        add_from_file "$2" "$3"
        ;;
    process)
        process_all "$2"
        ;;
    status)
        status
        ;;
    results)
        results "$2"
        ;;
    clear)
        clear_all
        ;;
    *)
        help
        ;;
esac
