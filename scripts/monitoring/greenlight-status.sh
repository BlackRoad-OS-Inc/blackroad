#!/bin/bash
# GreenLight Deployment Status Dashboard
# Real-time view of all deployment activity across all Claude instances

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

MEMORY_DIR="$HOME/.blackroad/memory"
JOURNAL_FILE="$MEMORY_DIR/journals/master-journal.jsonl"

# Show recent deployments
show_recent_deployments() {
    local limit="${1:-20}"

    echo -e "${BOLD}${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${CYAN}║         🚀 GREENLIGHT DEPLOYMENT DASHBOARD                    ║${NC}"
    echo -e "${BOLD}${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    if [ ! -f "$JOURNAL_FILE" ]; then
        echo -e "${RED}No memory journal found${NC}"
        return 1
    fi

    # Recent deployments
    echo -e "${BOLD}${PURPLE}Recent Deployments:${NC}"
    echo ""

    tail -n "$limit" "$JOURNAL_FILE" | \
        jq -r 'select(.action == "deployed" or .action == "triggered" or .action | test("workflow_")) |
               "  " + .timestamp + " " + .details' | \
        while read -r line; do
            # Color code by emoji
            if echo "$line" | grep -q "✅"; then
                echo -e "${GREEN}$line${NC}"
            elif echo "$line" | grep -q "❌"; then
                echo -e "${RED}$line${NC}"
            elif echo "$line" | grep -q "⚡"; then
                echo -e "${CYAN}$line${NC}"
            elif echo "$line" | grep -q "🚀"; then
                echo -e "${PURPLE}$line${NC}"
            else
                echo "$line"
            fi
        done

    echo ""
}

# Show active workflows
show_active_workflows() {
    echo -e "${BOLD}${YELLOW}Active Workflows:${NC}"
    echo ""

    if [ ! -f "$JOURNAL_FILE" ]; then
        echo -e "${RED}No memory journal found${NC}"
        return 1
    fi

    # Find workflows that were triggered but not yet completed
    local triggered=$(cat "$JOURNAL_FILE" | jq -r 'select(.action == "triggered") | .entity' | sort -u)
    local completed=$(cat "$JOURNAL_FILE" | jq -r 'select(.action | test("workflow_(passed|failed)")) | .entity' | sort -u)

    # Active = triggered but not completed
    local active=$(comm -23 <(echo "$triggered" | sort) <(echo "$completed" | sort))

    if [ -z "$active" ]; then
        echo -e "  ${GREEN}No active workflows${NC}"
    else
        echo "$active" | while read -r workflow; do
            # Get latest status
            local latest=$(cat "$JOURNAL_FILE" | jq -r --arg w "$workflow" 'select(.entity == $w) | .details' | tail -1)
            echo -e "  ${CYAN}⚡ $workflow${NC}"
            echo -e "    $latest"
        done
    fi

    echo ""
}

# Show deployment statistics
show_stats() {
    echo -e "${BOLD}${BLUE}Deployment Statistics (Last 24h):${NC}"
    echo ""

    if [ ! -f "$JOURNAL_FILE" ]; then
        echo -e "${RED}No memory journal found${NC}"
        return 1
    fi

    # Count by action type
    local total_triggered=$(cat "$JOURNAL_FILE" | jq -r 'select(.action == "triggered")' | wc -l)
    local total_passed=$(cat "$JOURNAL_FILE" | jq -r 'select(.action == "workflow_passed")' | wc -l)
    local total_failed=$(cat "$JOURNAL_FILE" | jq -r 'select(.action == "workflow_failed")' | wc -l)
    local total_deployed=$(cat "$JOURNAL_FILE" | jq -r 'select(.action == "deployed")' | wc -l)

    echo -e "  Workflows Triggered: ${CYAN}$total_triggered${NC}"
    echo -e "  Workflows Passed:    ${GREEN}$total_passed${NC}"
    echo -e "  Workflows Failed:    ${RED}$total_failed${NC}"
    echo -e "  Workers Deployed:    ${PURPLE}$total_deployed${NC}"

    # Calculate success rate
    if [ "$total_triggered" -gt 0 ]; then
        local success_rate=$((total_passed * 100 / (total_passed + total_failed)))
        echo ""
        echo -e "  Success Rate:        ${GREEN}${success_rate}%${NC}"
    fi

    echo ""
}

# Show worker status
show_workers() {
    echo -e "${BOLD}${PURPLE}Deployed Workers:${NC}"
    echo ""

    if [ ! -f "$JOURNAL_FILE" ]; then
        echo -e "${RED}No memory journal found${NC}"
        return 1
    fi

    # Get unique workers and their latest deployment
    cat "$JOURNAL_FILE" | \
        jq -r 'select(.action == "deployed" and (.details | contains("Worker deployed"))) |
               .entity + "|" + .timestamp + "|" + .details' | \
        awk -F'|' '{workers[$1] = $2 "|" $3} END {for (w in workers) print w "|" workers[w]}' | \
        sort | \
        while IFS='|' read -r worker timestamp details; do
            echo -e "  ${PURPLE}⚙️ $worker${NC}"
            echo -e "    Last deployed: $timestamp"
            echo -e "    $details"
            echo ""
        done
}

# Watch mode (live updates)
watch_mode() {
    local interval="${1:-5}"

    while true; do
        clear
        show_recent_deployments 15
        show_active_workflows
        show_stats
        echo -e "${CYAN}Refreshing every ${interval}s... (Ctrl+C to exit)${NC}"
        sleep "$interval"
    done
}

# Show help
show_help() {
    cat <<'EOF'
GreenLight Deployment Status Dashboard

USAGE:
    greenlight-status.sh [command] [options]

COMMANDS:
    recent [n]        Show n recent deployments (default: 20)
    active            Show active workflows
    stats             Show deployment statistics
    workers           Show deployed workers
    watch [interval]  Live dashboard (updates every interval seconds, default: 5)
    help              Show this help

EXAMPLES:
    # Show recent deployments
    greenlight-status.sh recent 50

    # Show active workflows
    greenlight-status.sh active

    # Live dashboard
    greenlight-status.sh watch 3

    # Full status
    greenlight-status.sh

EOF
}

# Main
main() {
    local command="${1:-all}"
    shift || true

    case "$command" in
        recent)
            show_recent_deployments "${1:-20}"
            ;;
        active)
            show_active_workflows
            ;;
        stats)
            show_stats
            ;;
        workers)
            show_workers
            ;;
        watch)
            watch_mode "${1:-5}"
            ;;
        all)
            show_recent_deployments 15
            show_active_workflows
            show_stats
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            echo -e "${RED}Unknown command: $command${NC}"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# Run main
main "$@"
