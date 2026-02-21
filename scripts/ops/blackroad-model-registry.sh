#!/bin/bash
# BlackRoad Model Registry
# Centralized registry for all LLM models across the cluster
# Agent: Icarus (b3e01bd9)

PINK='\033[38;5;205m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RESET='\033[0m'

REGISTRY_DIR="$HOME/.blackroad/model-registry"
REGISTRY_FILE="$REGISTRY_DIR/registry.json"
CACHE_FILE="$REGISTRY_DIR/cache.json"

LLM_NODES=("lucidia" "cecilia" "octavia" "aria")

# Initialize
init() {
    mkdir -p "$REGISTRY_DIR"
    [ -f "$REGISTRY_FILE" ] || echo '{"models":[],"nodes":{},"updated":""}' > "$REGISTRY_FILE"
    echo -e "${GREEN}Model registry initialized${RESET}"
}

# Scan all nodes for models
scan() {
    echo -e "${PINK}=== SCANNING CLUSTER FOR MODELS ===${RESET}"
    echo

    local all_models='{"models":[],"nodes":{},"updated":"'"$(date -Iseconds)"'"}'

    for node in "${LLM_NODES[@]}"; do
        echo -n "  Scanning $node... "

        if ! ssh -o ConnectTimeout=3 "$node" "echo ok" >/dev/null 2>&1; then
            echo -e "${YELLOW}offline${RESET}"
            continue
        fi

        local models=$(ssh -o ConnectTimeout=10 "$node" \
            "curl -s http://localhost:11434/api/tags" 2>/dev/null)

        if [ -z "$models" ] || [ "$models" = "null" ]; then
            echo -e "${YELLOW}no ollama${RESET}"
            continue
        fi

        local model_list=$(echo "$models" | jq -r '.models[]?.name // empty')
        local count=$(echo "$model_list" | grep -c .)

        echo -e "${GREEN}$count models${RESET}"

        # Add to registry
        all_models=$(echo "$all_models" | jq --arg node "$node" --argjson models "$models" \
            '.nodes[$node] = $models.models')

        # Merge into global list
        for model in $model_list; do
            all_models=$(echo "$all_models" | jq --arg model "$model" --arg node "$node" \
                'if .models | map(select(.name == $model)) | length == 0
                 then .models += [{"name": $model, "nodes": [$node]}]
                 else .models = [.models[] | if .name == $model then .nodes += [$node] else . end]
                 end')
        done
    done

    echo "$all_models" > "$REGISTRY_FILE"

    echo
    local total=$(echo "$all_models" | jq '.models | length')
    echo -e "${GREEN}Registry updated: $total unique models${RESET}"
}

# List all models
list() {
    local filter="${1:-all}"

    echo -e "${PINK}=== MODEL REGISTRY ===${RESET}"
    echo

    case "$filter" in
        all)
            jq -r '.models[] | "\(.name)\t\(.nodes | join(", "))"' "$REGISTRY_FILE" 2>/dev/null | \
                while IFS=$'\t' read -r name nodes; do
                    local node_count=$(echo "$nodes" | tr ',' '\n' | wc -w)
                    echo "  $name"
                    echo -e "    ${BLUE}Nodes: $nodes ($node_count)${RESET}"
                done
            ;;
        llama*)
            jq -r '.models[] | select(.name | contains("llama")) | .name' "$REGISTRY_FILE"
            ;;
        code*)
            jq -r '.models[] | select(.name | contains("code")) | .name' "$REGISTRY_FILE"
            ;;
        tiny*)
            jq -r '.models[] | select(.name | contains("tiny")) | .name' "$REGISTRY_FILE"
            ;;
    esac

    echo
    local total=$(jq '.models | length' "$REGISTRY_FILE" 2>/dev/null || echo 0)
    local updated=$(jq -r '.updated' "$REGISTRY_FILE" 2>/dev/null)
    echo "Total: $total models (updated: $updated)"
}

# Get model details
info() {
    local model="$1"

    echo -e "${PINK}=== MODEL INFO: $model ===${RESET}"
    echo

    # Find in registry
    local found=$(jq -r --arg m "$model" '.models[] | select(.name == $m)' "$REGISTRY_FILE" 2>/dev/null)

    if [ -z "$found" ]; then
        echo -e "${YELLOW}Model not in registry. Scanning...${RESET}"
        scan >/dev/null
        found=$(jq -r --arg m "$model" '.models[] | select(.name == $m)' "$REGISTRY_FILE" 2>/dev/null)
    fi

    if [ -z "$found" ]; then
        echo -e "${RED}Model not found: $model${RESET}"
        return 1
    fi

    local nodes=$(echo "$found" | jq -r '.nodes | join(", ")')
    echo "Name: $model"
    echo "Available on: $nodes"
    echo

    # Get detailed info from first available node
    local first_node=$(echo "$found" | jq -r '.nodes[0]')
    echo "Details from $first_node:"

    local details=$(ssh -o ConnectTimeout=10 "$first_node" \
        "curl -s http://localhost:11434/api/show -d '{\"name\":\"$model\"}'" 2>/dev/null)

    if [ -n "$details" ]; then
        echo "  Parameters: $(echo "$details" | jq -r '.details.parameter_size // "unknown"')"
        echo "  Quantization: $(echo "$details" | jq -r '.details.quantization_level // "unknown"')"
        echo "  Family: $(echo "$details" | jq -r '.details.family // "unknown"')"
        echo "  Format: $(echo "$details" | jq -r '.details.format // "unknown"')"

        local size=$(echo "$details" | jq -r '.size // 0')
        local size_mb=$((size / 1024 / 1024))
        echo "  Size: ${size_mb}MB"
    fi
}

# Find best node for a model
find() {
    local model="$1"

    local found=$(jq -r --arg m "$model" '.models[] | select(.name == $m)' "$REGISTRY_FILE" 2>/dev/null)

    if [ -z "$found" ]; then
        echo ""
        return 1
    fi

    local nodes=$(echo "$found" | jq -r '.nodes[]')
    local best_node=""
    local best_load=999

    for node in $nodes; do
        local load=$(ssh -o ConnectTimeout=2 "$node" "cat /proc/loadavg | awk '{print \$1}'" 2>/dev/null || echo 999)

        if [ "$(echo "$load < $best_load" | bc -l)" = "1" ]; then
            best_load=$load
            best_node=$node
        fi
    done

    echo "$best_node"
}

# Deploy model to node
deploy() {
    local model="$1"
    local node="$2"

    echo -e "${PINK}=== DEPLOY MODEL ===${RESET}"
    echo "Model: $model"
    echo "Node: $node"
    echo

    if ! ssh -o ConnectTimeout=3 "$node" "echo ok" >/dev/null 2>&1; then
        echo -e "${RED}Node offline: $node${RESET}"
        return 1
    fi

    echo "Pulling model..."
    ssh "$node" "ollama pull $model" 2>&1 | while read -r line; do
        echo "  $line"
    done

    echo
    echo -e "${GREEN}Model deployed!${RESET}"

    # Update registry
    scan >/dev/null
}

# Remove model from node
remove() {
    local model="$1"
    local node="$2"

    echo -e "${PINK}=== REMOVE MODEL ===${RESET}"
    echo "Model: $model"
    echo "Node: $node"
    echo

    ssh "$node" "ollama rm $model" 2>&1

    echo -e "${GREEN}Model removed${RESET}"
    scan >/dev/null
}

# Replicate model to all nodes
replicate() {
    local model="$1"

    echo -e "${PINK}=== REPLICATE MODEL: $model ===${RESET}"
    echo

    for node in "${LLM_NODES[@]}"; do
        echo -n "  $node: "

        if ! ssh -o ConnectTimeout=3 "$node" "echo ok" >/dev/null 2>&1; then
            echo -e "${YELLOW}offline${RESET}"
            continue
        fi

        # Check if already exists
        local exists=$(ssh "$node" "ollama list 2>/dev/null | grep -c '^$model'" 2>/dev/null)

        if [ "$exists" -gt 0 ]; then
            echo -e "${GREEN}exists${RESET}"
        else
            echo -n "pulling... "
            ssh "$node" "ollama pull $model >/dev/null 2>&1"
            echo -e "${GREEN}done${RESET}"
        fi
    done

    scan >/dev/null
}

# Model comparison (benchmark same prompt across models)
compare() {
    local prompt="${1:-Hello, how are you?}"

    echo -e "${PINK}=== MODEL COMPARISON ===${RESET}"
    echo "Prompt: $prompt"
    echo

    printf "%-25s %-12s %-10s %-8s\n" "MODEL" "NODE" "LATENCY" "TOKENS"
    echo "────────────────────────────────────────────────────────────"

    for model in $(jq -r '.models[].name' "$REGISTRY_FILE" 2>/dev/null | head -10); do
        local node=$(find "$model")
        [ -z "$node" ] && continue

        local start=$(date +%s%N)
        local response=$(ssh -o ConnectTimeout=30 "$node" \
            "curl -s http://localhost:11434/api/generate -d '{\"model\":\"$model\",\"prompt\":\"$prompt\",\"stream\":false}'" 2>/dev/null)
        local end=$(date +%s%N)

        local latency=$(( (end - start) / 1000000 ))
        local tokens=$(echo "$response" | jq -r '.eval_count // 0')

        printf "%-25s %-12s %-10s %-8s\n" "$model" "$node" "${latency}ms" "$tokens"
    done
}

# Status overview
status() {
    echo -e "${PINK}=== MODEL REGISTRY STATUS ===${RESET}"
    echo

    local total=$(jq '.models | length' "$REGISTRY_FILE" 2>/dev/null || echo 0)
    local nodes=$(jq '.nodes | keys | length' "$REGISTRY_FILE" 2>/dev/null || echo 0)
    local updated=$(jq -r '.updated // "never"' "$REGISTRY_FILE" 2>/dev/null)

    echo "Total unique models: $total"
    echo "Active nodes: $nodes"
    echo "Last updated: $updated"
    echo

    echo "Models per node:"
    jq -r '.nodes | to_entries[] | "  \(.key): \(.value | length) models"' "$REGISTRY_FILE" 2>/dev/null

    echo
    echo "Most replicated models:"
    jq -r '.models | sort_by(.nodes | length) | reverse | .[0:5][] | "  \(.name): \(.nodes | length) nodes"' "$REGISTRY_FILE" 2>/dev/null
}

# Export registry
export_registry() {
    local format="${1:-json}"

    case "$format" in
        json)
            cat "$REGISTRY_FILE"
            ;;
        csv)
            echo "model,nodes,node_count"
            jq -r '.models[] | "\(.name),\"\(.nodes | join(";"))\",\(.nodes | length)"' "$REGISTRY_FILE"
            ;;
        markdown)
            echo "# BlackRoad Model Registry"
            echo
            echo "| Model | Nodes | Count |"
            echo "|-------|-------|-------|"
            jq -r '.models[] | "| \(.name) | \(.nodes | join(", ")) | \(.nodes | length) |"' "$REGISTRY_FILE"
            ;;
    esac
}

# Help
help() {
    echo -e "${PINK}BlackRoad Model Registry${RESET}"
    echo
    echo "Centralized registry for all LLM models"
    echo
    echo "Commands:"
    echo "  scan                Scan cluster for models"
    echo "  list [filter]       List models (all/llama/code/tiny)"
    echo "  info <model>        Get model details"
    echo "  find <model>        Find best node for model"
    echo "  deploy <m> <node>   Deploy model to node"
    echo "  remove <m> <node>   Remove model from node"
    echo "  replicate <model>   Replicate to all nodes"
    echo "  compare [prompt]    Compare model performance"
    echo "  status              Registry status"
    echo "  export [format]     Export (json/csv/markdown)"
    echo
    echo "Examples:"
    echo "  $0 scan"
    echo "  $0 list llama"
    echo "  $0 deploy llama3.2:1b cecilia"
    echo "  $0 replicate tinyllama"
}

# Ensure initialized
[ -d "$REGISTRY_DIR" ] || init >/dev/null

case "${1:-help}" in
    init)
        init
        ;;
    scan|refresh)
        scan
        ;;
    list|ls)
        list "$2"
        ;;
    info|show)
        info "$2"
        ;;
    find)
        find "$2"
        ;;
    deploy|pull)
        deploy "$2" "$3"
        ;;
    remove|rm)
        remove "$2" "$3"
        ;;
    replicate|sync)
        replicate "$2"
        ;;
    compare|benchmark)
        shift
        compare "$*"
        ;;
    status)
        status
        ;;
    export)
        export_registry "$2"
        ;;
    *)
        help
        ;;
esac
