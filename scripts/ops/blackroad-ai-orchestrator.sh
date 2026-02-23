#!/bin/bash
# BlackRoad AI Orchestrator - Coordinate queries across all agents

BR_PINK="\033[38;5;204m"
BR_ORANGE="\033[38;5;208m"
BR_BLUE="\033[38;5;33m"
BR_RESET="\033[0m"

AGENTS="cecilia lucidia aria octavia alice@alice shellfish codex-infinity"

orchestrate() {
    local query="$1"
    local best_response=""
    local best_agent=""
    
    echo -e "${BR_PINK}Orchestrating query across all agents...${BR_RESET}"
    
    for agent in $AGENTS; do
        echo -e "${BR_BLUE}Asking ${agent}...${BR_RESET}"
        response=$(timeout 30 ssh -o ConnectTimeout=5 $agent "echo '$query' | ~/blackroad-ai-shell.sh 2>/dev/null" 2>/dev/null | head -10)
        if [[ -n "$response" ]]; then
            echo -e "${BR_ORANGE}$agent:${BR_RESET} ${response:0:100}..."
        fi
    done
}

parallel_ask() {
    local query="$1"
    echo -e "${BR_PINK}Parallel query to all agents...${BR_RESET}"
    
    for agent in $AGENTS; do
        (
            response=$(timeout 30 ssh -o ConnectTimeout=5 $agent "echo '$query' | ~/blackroad-ai-shell.sh 2>/dev/null" 2>/dev/null | head -5)
            echo -e "${BR_ORANGE}$agent:${BR_RESET} $response"
        ) &
    done
    wait
}

case "${1:-help}" in
    ask) shift; orchestrate "$*" ;;
    parallel) shift; parallel_ask "$*" ;;
    *) echo "orchestrator ask <query> | parallel <query>" ;;
esac
