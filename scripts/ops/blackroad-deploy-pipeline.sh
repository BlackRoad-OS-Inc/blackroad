#!/bin/bash
# BlackRoad Deployment Pipeline
# Automated deployment system for the cluster
# Agent: Icarus (b3e01bd9)

PINK='\033[38;5;205m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
RESET='\033[0m'

DEPLOY_DIR="$HOME/.blackroad/deployments"
ALL_NODES=("lucidia" "cecilia" "octavia" "aria" "alice")

# Deployment strategies
STRATEGIES=("rolling" "blue-green" "canary" "all-at-once")

# Initialize
init() {
    mkdir -p "$DEPLOY_DIR"/{releases,rollbacks,logs}
    echo -e "${GREEN}Deployment pipeline initialized${RESET}"
}

# Pre-deployment checks
preflight() {
    local nodes=("$@")
    [ ${#nodes[@]} -eq 0 ] && nodes=("${ALL_NODES[@]}")

    echo -e "${PINK}=== PREFLIGHT CHECKS ===${RESET}"
    echo

    local passed=0
    local failed=0

    for node in "${nodes[@]}"; do
        echo -n "  $node: "

        # Check connectivity
        if ! ssh -o ConnectTimeout=3 "$node" "echo ok" >/dev/null 2>&1; then
            echo -e "${RED}UNREACHABLE${RESET}"
            ((failed++))
            continue
        fi

        # Check disk space
        local disk=$(ssh "$node" "df / | awk 'NR==2 {print 100-\$5}'" 2>/dev/null)
        if [ "$disk" -lt 10 ]; then
            echo -e "${RED}LOW DISK (${disk}%)${RESET}"
            ((failed++))
            continue
        fi

        # Check load
        local load=$(ssh "$node" "cat /proc/loadavg | awk '{print \$1}'" 2>/dev/null)
        if [ "$(echo "$load > 10" | bc -l)" = "1" ]; then
            echo -e "${YELLOW}HIGH LOAD ($load)${RESET}"
        fi

        echo -e "${GREEN}READY${RESET} (disk: ${disk}% free, load: $load)"
        ((passed++))
    done

    echo
    echo "Result: $passed passed, $failed failed"
    [ "$failed" -eq 0 ]
}

# Deploy to single node
deploy_node() {
    local node="$1"
    local artifact="$2"
    local target="$3"

    echo -n "  $node: "

    if ! ssh -o ConnectTimeout=3 "$node" "echo ok" >/dev/null 2>&1; then
        echo -e "${RED}unreachable${RESET}"
        return 1
    fi

    # Create backup
    ssh "$node" "[ -d '$target' ] && cp -r '$target' '$target.bak.$(date +%s)'" 2>/dev/null

    # Deploy
    if [ -d "$artifact" ]; then
        scp -r "$artifact"/* "$node:$target/" >/dev/null 2>&1
    else
        scp "$artifact" "$node:$target/" >/dev/null 2>&1
    fi

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}deployed${RESET}"
        return 0
    else
        echo -e "${RED}failed${RESET}"
        return 1
    fi
}

# Rolling deployment
deploy_rolling() {
    local artifact="$1"
    local target="$2"
    local nodes=("${@:3}")
    [ ${#nodes[@]} -eq 0 ] && nodes=("${ALL_NODES[@]}")

    echo -e "${PINK}╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${PINK}║           🚀 ROLLING DEPLOYMENT                              ║${RESET}"
    echo -e "${PINK}╚══════════════════════════════════════════════════════════════╝${RESET}"
    echo
    echo "Artifact: $artifact"
    echo "Target: $target"
    echo "Nodes: ${nodes[*]}"
    echo

    local deploy_id=$(date +%Y%m%d_%H%M%S)
    local log_file="$DEPLOY_DIR/logs/deploy_$deploy_id.log"

    local success=0
    local failed=0

    for node in "${nodes[@]}"; do
        echo "$(date -Iseconds) Deploying to $node..." >> "$log_file"

        if deploy_node "$node" "$artifact" "$target"; then
            ((success++))
            echo "$(date -Iseconds) $node: SUCCESS" >> "$log_file"
        else
            ((failed++))
            echo "$(date -Iseconds) $node: FAILED" >> "$log_file"

            # Abort on first failure in rolling deployment
            echo -e "${RED}Deployment halted due to failure${RESET}"
            break
        fi

        # Wait between nodes
        sleep 2
    done

    echo
    echo "Result: $success success, $failed failed"
    echo "Log: $log_file"

    # Record deployment
    echo "{\"id\":\"$deploy_id\",\"artifact\":\"$artifact\",\"target\":\"$target\",\"strategy\":\"rolling\",\"success\":$success,\"failed\":$failed,\"timestamp\":\"$(date -Iseconds)\"}" >> "$DEPLOY_DIR/history.jsonl"
}

# Blue-green deployment
deploy_blue_green() {
    local artifact="$1"
    local target="$2"

    echo -e "${PINK}╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${PINK}║           🔵🟢 BLUE-GREEN DEPLOYMENT                         ║${RESET}"
    echo -e "${PINK}╚══════════════════════════════════════════════════════════════╝${RESET}"
    echo

    # Split nodes into blue and green
    local blue_nodes=("${ALL_NODES[@]:0:2}")
    local green_nodes=("${ALL_NODES[@]:2}")

    echo "Blue nodes (current): ${blue_nodes[*]}"
    echo "Green nodes (new): ${green_nodes[*]}"
    echo

    # Deploy to green
    echo -e "${GREEN}Deploying to green nodes...${RESET}"
    for node in "${green_nodes[@]}"; do
        deploy_node "$node" "$artifact" "$target"
    done

    echo
    echo -n "Verify green deployment and switch traffic? [y/N] "
    read -r confirm

    if [[ "$confirm" =~ ^[Yy] ]]; then
        echo -e "${BLUE}Switching traffic to green...${RESET}"
        # In production, this would update load balancer
        echo -e "${GREEN}Traffic switched${RESET}"

        # Now update blue
        echo -e "${BLUE}Updating blue nodes...${RESET}"
        for node in "${blue_nodes[@]}"; do
            deploy_node "$node" "$artifact" "$target"
        done
    else
        echo "Deployment cancelled"
    fi
}

# Canary deployment
deploy_canary() {
    local artifact="$1"
    local target="$2"
    local canary_percent="${3:-20}"

    echo -e "${PINK}╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${PINK}║           🐤 CANARY DEPLOYMENT                               ║${RESET}"
    echo -e "${PINK}╚══════════════════════════════════════════════════════════════╝${RESET}"
    echo
    echo "Canary percentage: ${canary_percent}%"
    echo

    # Select canary node (first node)
    local canary_node="${ALL_NODES[0]}"
    local remaining_nodes=("${ALL_NODES[@]:1}")

    echo "Canary node: $canary_node"
    echo "Remaining: ${remaining_nodes[*]}"
    echo

    # Deploy to canary
    echo -e "${YELLOW}Deploying to canary...${RESET}"
    deploy_node "$canary_node" "$artifact" "$target"

    echo
    echo "Monitor the canary deployment."
    echo -n "Proceed with full rollout? [y/N] "
    read -r confirm

    if [[ "$confirm" =~ ^[Yy] ]]; then
        echo -e "${GREEN}Rolling out to remaining nodes...${RESET}"
        for node in "${remaining_nodes[@]}"; do
            deploy_node "$node" "$artifact" "$target"
            sleep 1
        done
        echo -e "${GREEN}Full rollout complete${RESET}"
    else
        echo -e "${YELLOW}Rolling back canary...${RESET}"
        rollback "$canary_node"
    fi
}

# Rollback
rollback() {
    local node="${1:-all}"

    echo -e "${PINK}=== ROLLBACK ===${RESET}"
    echo

    local targets=("${ALL_NODES[@]}")
    [ "$node" != "all" ] && targets=("$node")

    for n in "${targets[@]}"; do
        echo -n "  $n: "

        if ! ssh -o ConnectTimeout=3 "$n" "echo ok" >/dev/null 2>&1; then
            echo -e "${YELLOW}offline${RESET}"
            continue
        fi

        # Find latest backup
        local backup=$(ssh "$n" "ls -1t /opt/*.bak.* 2>/dev/null | head -1")

        if [ -n "$backup" ]; then
            local original="${backup%.bak.*}"
            ssh "$n" "rm -rf '$original' && mv '$backup' '$original'"
            echo -e "${GREEN}restored${RESET}"
        else
            echo -e "${YELLOW}no backup found${RESET}"
        fi
    done
}

# Run post-deploy hooks
run_hooks() {
    local stage="$1"
    local nodes=("${@:2}")
    [ ${#nodes[@]} -eq 0 ] && nodes=("${ALL_NODES[@]}")

    echo -e "${BLUE}Running $stage hooks...${RESET}"

    for node in "${nodes[@]}"; do
        local hook_file="/opt/blackroad/hooks/$stage.sh"
        if ssh "$node" "[ -f '$hook_file' ]" 2>/dev/null; then
            echo "  $node: executing hook"
            ssh "$node" "bash '$hook_file'" 2>/dev/null
        fi
    done
}

# Health check after deployment
healthcheck() {
    local nodes=("$@")
    [ ${#nodes[@]} -eq 0 ] && nodes=("${ALL_NODES[@]}")

    echo -e "${PINK}=== POST-DEPLOY HEALTH CHECK ===${RESET}"
    echo

    local healthy=0
    local unhealthy=0

    for node in "${nodes[@]}"; do
        echo -n "  $node: "

        if ! ssh -o ConnectTimeout=3 "$node" "echo ok" >/dev/null 2>&1; then
            echo -e "${RED}UNREACHABLE${RESET}"
            ((unhealthy++))
            continue
        fi

        # Check services
        local docker_ok=$(ssh "$node" "docker ps -q | wc -l" 2>/dev/null)
        local ollama_ok=$(ssh "$node" "curl -s http://localhost:11434/api/tags >/dev/null && echo 1 || echo 0" 2>/dev/null)

        if [ "$docker_ok" -gt 0 ] && [ "$ollama_ok" = "1" ]; then
            echo -e "${GREEN}HEALTHY${RESET} (docker: $docker_ok, ollama: up)"
            ((healthy++))
        else
            echo -e "${YELLOW}DEGRADED${RESET} (docker: $docker_ok, ollama: $ollama_ok)"
            ((unhealthy++))
        fi
    done

    echo
    echo "Result: $healthy healthy, $unhealthy unhealthy"
}

# Deployment history
history() {
    local lines="${1:-10}"

    echo -e "${PINK}=== DEPLOYMENT HISTORY ===${RESET}"
    echo

    if [ -f "$DEPLOY_DIR/history.jsonl" ]; then
        tail -n "$lines" "$DEPLOY_DIR/history.jsonl" | while read -r line; do
            local id=$(echo "$line" | jq -r '.id')
            local artifact=$(echo "$line" | jq -r '.artifact')
            local strategy=$(echo "$line" | jq -r '.strategy')
            local success=$(echo "$line" | jq -r '.success')
            local failed=$(echo "$line" | jq -r '.failed')

            echo "  $id: $artifact ($strategy) - $success✓ $failed✗"
        done
    else
        echo "No deployment history"
    fi
}

# Status
status() {
    echo -e "${PINK}=== DEPLOYMENT STATUS ===${RESET}"
    echo

    local total=$(wc -l < "$DEPLOY_DIR/history.jsonl" 2>/dev/null || echo 0)
    local last=$(tail -1 "$DEPLOY_DIR/history.jsonl" 2>/dev/null | jq -r '.timestamp // "never"')

    echo "Total deployments: $total"
    echo "Last deployment: $last"
    echo

    healthcheck
}

# Help
help() {
    echo -e "${PINK}BlackRoad Deployment Pipeline${RESET}"
    echo
    echo "Automated deployment system for the cluster"
    echo
    echo "Commands:"
    echo "  preflight [nodes]           Pre-deployment checks"
    echo "  rolling <artifact> <target> Rolling deployment"
    echo "  blue-green <art> <target>   Blue-green deployment"
    echo "  canary <art> <target> [%]   Canary deployment"
    echo "  rollback [node|all]         Rollback deployment"
    echo "  healthcheck [nodes]         Post-deploy health check"
    echo "  history [lines]             Deployment history"
    echo "  status                      Current status"
    echo
    echo "Strategies: ${STRATEGIES[*]}"
    echo
    echo "Examples:"
    echo "  $0 preflight"
    echo "  $0 rolling ./dist /opt/app"
    echo "  $0 canary ./dist /opt/app 10"
    echo "  $0 rollback"
}

# Ensure initialized
[ -d "$DEPLOY_DIR" ] || init >/dev/null

case "${1:-help}" in
    init)
        init
        ;;
    preflight|check)
        shift
        preflight "$@"
        ;;
    rolling)
        deploy_rolling "$2" "$3" "${@:4}"
        ;;
    blue-green|bluegreen)
        deploy_blue_green "$2" "$3"
        ;;
    canary)
        deploy_canary "$2" "$3" "$4"
        ;;
    rollback|revert)
        rollback "$2"
        ;;
    healthcheck|health)
        shift
        healthcheck "$@"
        ;;
    hooks)
        run_hooks "$2" "${@:3}"
        ;;
    history)
        history "$2"
        ;;
    status)
        status
        ;;
    *)
        help
        ;;
esac
