#!/bin/bash

# BlackRoad Advanced Analytics & Reporting System
# Deep insights, trends, predictions, and beautiful visualizations

MEMORY_DIR="$HOME/.blackroad/memory"
ANALYTICS_DIR="$MEMORY_DIR/analytics"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Initialize analytics system
init_analytics() {
    mkdir -p "$ANALYTICS_DIR"/{reports,trends,predictions,exports}
    
    cat > "$ANALYTICS_DIR/config.json" << 'EOF'
{
    "system": "BlackRoad Advanced Analytics Pro",
    "version": "2.0",
    "features": ["trends", "predictions", "reports", "visualizations", "exports"],
    "metrics": [
        "agent_activity",
        "task_completion_rate",
        "collaboration_score",
        "bottleneck_detection",
        "velocity_tracking",
        "quality_metrics"
    ]
}
EOF
    
    echo -e "${GREEN}✅ Advanced Analytics System initialized${NC}"
}

# Generate comprehensive report
generate_report() {
    local report_type="${1:-daily}"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
    local report_id="report-$(date +%s)"
    
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║     📊 BLACKROAD ANALYTICS REPORT - $(echo $report_type | tr a-z A-Z)     ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BLUE}Generated:${NC} $timestamp"
    echo ""
    
    # Agent Activity Metrics
    echo -e "${BOLD}${PURPLE}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
    echo -e "${BOLD}${PURPLE}┃ 👥 AGENT ACTIVITY METRICS                                 ┃${NC}"
    echo -e "${BOLD}${PURPLE}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
    
    # Count agents by core
    local total_agents=0
    if [[ -d "$MEMORY_DIR/agent-registry/agents" ]]; then
        total_agents=$(ls -1 "$MEMORY_DIR/agent-registry/agents"/*.json 2>/dev/null | wc -l | tr -d ' ')
    fi
    
    echo -e "  ${BOLD}Total Registered Agents:${NC} ${CYAN}$total_agents${NC}"
    
    # Active agents (from memory logs in last 24h)
    local active_24h=0
    if [[ -f "$MEMORY_DIR/journals/master-journal.jsonl" ]]; then
        local cutoff=$(date -u -v-24H +"%Y-%m-%d" 2>/dev/null || date -u -d "24 hours ago" +"%Y-%m-%d")
        active_24h=$(tail -1000 "$MEMORY_DIR/journals/master-journal.jsonl" 2>/dev/null | \
            jq -r 'select(.timestamp > "'$cutoff'") | .entity' | sort -u | wc -l | tr -d ' ')
    fi
    
    echo -e "  ${BOLD}Active (24h):${NC} ${GREEN}$active_24h${NC}"
    
    local activity_rate=0
    [[ $total_agents -gt 0 ]] && activity_rate=$(( (active_24h * 100) / total_agents ))
    echo -e "  ${BOLD}Activity Rate:${NC} ${YELLOW}$activity_rate%${NC}"
    
    # Activity bars by core
    echo ""
    echo -e "  ${BOLD}Activity by AI Core:${NC}"
    
    for core in cecilia cadence silas lucidia alice aria; do
        local core_count=$(ls -1 "$MEMORY_DIR/agent-registry/agents"/${core}-*.json 2>/dev/null | wc -l | tr -d ' ')
        
        if [[ $core_count -gt 0 ]]; then
            local bar=""
            for ((i=0; i<core_count && i<20; i++)); do
                bar="${bar}█"
            done
            
            local icon="🎭"
            case "$core" in
                cecilia) icon="💎" ;;
                cadence) icon="🎵" ;;
                silas) icon="⚡" ;;
                lucidia) icon="✨" ;;
                alice) icon="🔮" ;;
                aria) icon="🎭" ;;
            esac
            
            printf "    ${icon} %-10s %3d agents  ${PURPLE}%s${NC}\n" "$core" "$core_count" "$bar"
        fi
    done
    
    echo ""
    
    # Task Metrics
    echo -e "${BOLD}${BLUE}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
    echo -e "${BOLD}${BLUE}┃ 📋 TASK COMPLETION METRICS                               ┃${NC}"
    echo -e "${BOLD}${BLUE}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
    
    local tasks_available=$(ls -1 "$MEMORY_DIR/tasks/available"/*.json 2>/dev/null | wc -l | tr -d ' ')
    local tasks_claimed=$(ls -1 "$MEMORY_DIR/tasks/claimed"/*.json 2>/dev/null | wc -l | tr -d ' ')
    local tasks_completed=$(ls -1 "$MEMORY_DIR/tasks/completed"/*.json 2>/dev/null | wc -l | tr -d ' ')
    local tasks_total=$((tasks_available + tasks_claimed + tasks_completed))
    
    echo -e "  ${BOLD}Total Tasks:${NC} ${CYAN}$tasks_total${NC}"
    echo -e "  ${GREEN}✅ Completed:${NC} $tasks_completed"
    echo -e "  ${YELLOW}⏳ In Progress:${NC} $tasks_claimed"
    echo -e "  ${BLUE}📋 Available:${NC} $tasks_available"
    
    if [[ $tasks_total -gt 0 ]]; then
        local completion_rate=$(( (tasks_completed * 100) / tasks_total ))
        echo -e "  ${BOLD}Completion Rate:${NC} ${GREEN}$completion_rate%${NC}"
        
        # Visual bar
        local bar_length=$(( completion_rate / 5 ))
        local bar=""
        for ((i=0; i<bar_length && i<20; i++)); do
            bar="${bar}█"
        done
        echo -e "  ${GREEN}$bar${NC}"
    fi
    
    echo ""
    
    # Collaboration Score
    echo -e "${BOLD}${GREEN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
    echo -e "${BOLD}${GREEN}┃ 🤝 COLLABORATION METRICS                                  ┃${NC}"
    echo -e "${BOLD}${GREEN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
    
    # Count TILs
    local til_count=$(ls -1 "$MEMORY_DIR/til"/til-*.json 2>/dev/null | wc -l | tr -d ' ')
    
    # Calculate collaboration score
    local collab_score=$(( (active_24h * 10) + (til_count * 5) + (tasks_completed * 20) ))
    
    echo -e "  ${BOLD}Collaboration Score:${NC} ${CYAN}$collab_score${NC}"
    echo -e "  ${BOLD}TILs Shared:${NC} ${PURPLE}$til_count${NC}"
    echo -e "  ${BOLD}Active Collaborators:${NC} ${GREEN}$active_24h${NC}"
    
    # Score tier
    local tier="BRONZE"
    local tier_color="$YELLOW"
    if [[ $collab_score -ge 1000 ]]; then
        tier="LEGENDARY"
        tier_color="$PURPLE"
    elif [[ $collab_score -ge 500 ]]; then
        tier="PLATINUM"
        tier_color="$CYAN"
    elif [[ $collab_score -ge 250 ]]; then
        tier="GOLD"
        tier_color="$YELLOW"
    elif [[ $collab_score -ge 100 ]]; then
        tier="SILVER"
        tier_color="$BLUE"
    fi
    
    echo -e "  ${BOLD}Tier:${NC} ${tier_color}${BOLD}$tier${NC}"
    
    echo ""
    
    # Traffic Light Status
    echo -e "${BOLD}${YELLOW}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
    echo -e "${BOLD}${YELLOW}┃ 🚦 DEPLOYMENT GATES STATUS                               ┃${NC}"
    echo -e "${BOLD}${YELLOW}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
    
    local green_count=$(ls -1 "$MEMORY_DIR/traffic-lights/green"/*.json 2>/dev/null | wc -l | tr -d ' ')
    local yellow_count=$(ls -1 "$MEMORY_DIR/traffic-lights/yellow"/*.json 2>/dev/null | wc -l | tr -d ' ')
    local red_count=$(ls -1 "$MEMORY_DIR/traffic-lights/red"/*.json 2>/dev/null | wc -l | tr -d ' ')
    
    echo -e "  ${GREEN}🟢 Green (Go):${NC} $green_count"
    echo -e "  ${YELLOW}🟡 Yellow (Caution):${NC} $yellow_count"
    echo -e "  ${RED}🔴 Red (Blocked):${NC} $red_count"
    
    local health="HEALTHY"
    local health_color="$GREEN"
    if [[ $red_count -gt 0 ]]; then
        health="CRITICAL"
        health_color="$RED"
    elif [[ $yellow_count -gt 2 ]]; then
        health="AT RISK"
        health_color="$YELLOW"
    fi
    
    echo -e "  ${BOLD}Overall Health:${NC} ${health_color}${BOLD}$health${NC}"
    
    echo ""
    
    # Trends & Predictions
    echo -e "${BOLD}${PURPLE}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
    echo -e "${BOLD}${PURPLE}┃ 📈 TRENDS & PREDICTIONS                                   ┃${NC}"
    echo -e "${BOLD}${PURPLE}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
    
    # Simple trend analysis
    if [[ $tasks_completed -gt $tasks_claimed ]]; then
        echo -e "  ${GREEN}↗${NC} ${BOLD}Trend:${NC} Velocity INCREASING"
    elif [[ $tasks_claimed -gt $tasks_completed ]]; then
        echo -e "  ${YELLOW}↘${NC} ${BOLD}Trend:${NC} Work in progress accumulating"
    else
        echo -e "  ${BLUE}→${NC} ${BOLD}Trend:${NC} Steady state"
    fi
    
    # Predictions
    if [[ $tasks_total -gt 0 && $tasks_completed -gt 0 ]]; then
        local avg_completion_time="2-3 days"  # Simplified
        echo -e "  ${BOLD}Prediction:${NC} Remaining tasks complete in ~$avg_completion_time"
    fi
    
    if [[ $active_24h -gt 10 ]]; then
        echo -e "  ${BOLD}Insight:${NC} High agent activity - optimal collaboration conditions"
    elif [[ $active_24h -lt 3 ]]; then
        echo -e "  ${BOLD}Insight:${NC} Low activity - consider agent recruitment"
    fi
    
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}Report ID:${NC} $report_id"
    echo -e "${BOLD}Next Report:${NC} $(date -v+1d +"%Y-%m-%d" 2>/dev/null || date -d "tomorrow" +"%Y-%m-%d")"
    
    # Save report
    cat > "$ANALYTICS_DIR/reports/${report_id}.json" << EOF
{
    "report_id": "$report_id",
    "type": "$report_type",
    "timestamp": "$timestamp",
    "metrics": {
        "total_agents": $total_agents,
        "active_24h": $active_24h,
        "activity_rate": $activity_rate,
        "tasks_total": $tasks_total,
        "tasks_completed": $tasks_completed,
        "tasks_claimed": $tasks_claimed,
        "tasks_available": $tasks_available,
        "completion_rate": $(( tasks_total > 0 ? (tasks_completed * 100) / tasks_total : 0 )),
        "collaboration_score": $collab_score,
        "til_count": $til_count,
        "green_lights": $green_count,
        "yellow_lights": $yellow_count,
        "red_lights": $red_count
    },
    "tier": "$tier",
    "health": "$health"
}
EOF
}

# Track trends over time
track_trends() {
    local days="${1:-7}"
    
    echo -e "${BOLD}${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${CYAN}║        📈 TREND ANALYSIS (Last $days days)                ║${NC}"
    echo -e "${BOLD}${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Analyze historical reports
    local report_count=$(ls -1 "$ANALYTICS_DIR/reports"/report-*.json 2>/dev/null | wc -l | tr -d ' ')
    
    if [[ $report_count -eq 0 ]]; then
        echo -e "${YELLOW}No historical data yet. Generate reports first.${NC}"
        return
    fi
    
    echo -e "${BOLD}Historical Reports Available:${NC} $report_count"
    echo ""
    
    # Show latest metrics trend
    echo -e "${BOLD}Recent Activity Trend:${NC}"
    
    local prev_score=0
    local trend_up=0
    local trend_down=0
    
    for report_file in $(ls -t "$ANALYTICS_DIR/reports"/report-*.json 2>/dev/null | head -5); do
        local timestamp=$(jq -r '.timestamp' "$report_file" | cut -d'T' -f1)
        local score=$(jq -r '.metrics.collaboration_score' "$report_file")
        local tier=$(jq -r '.tier' "$report_file")
        
        local arrow="→"
        local arrow_color="$BLUE"
        
        if [[ $prev_score -gt 0 ]]; then
            if [[ $score -gt $prev_score ]]; then
                arrow="↗"
                arrow_color="$GREEN"
                ((trend_up++))
            elif [[ $score -lt $prev_score ]]; then
                arrow="↘"
                arrow_color="$RED"
                ((trend_down++))
            fi
        fi
        
        echo -e "  $timestamp  ${arrow_color}$arrow${NC}  Score: ${CYAN}$score${NC}  Tier: ${PURPLE}$tier${NC}"
        
        prev_score=$score
    done
    
    echo ""
    
    if [[ $trend_up -gt $trend_down ]]; then
        echo -e "${GREEN}✅ Overall Trend: IMPROVING${NC}"
    elif [[ $trend_down -gt $trend_up ]]; then
        echo -e "${RED}⚠️  Overall Trend: DECLINING${NC}"
    else
        echo -e "${BLUE}→ Overall Trend: STABLE${NC}"
    fi
}

# Export report to various formats
export_report() {
    local format="${1:-json}"
    local report_id="${2:-latest}"
    
    if [[ "$report_id" == "latest" ]]; then
        report_id=$(ls -t "$ANALYTICS_DIR/reports"/report-*.json 2>/dev/null | head -1 | xargs basename | sed 's/.json//')
    fi
    
    local report_file="$ANALYTICS_DIR/reports/${report_id}.json"
    
    if [[ ! -f "$report_file" ]]; then
        echo -e "${RED}Report not found: $report_id${NC}"
        return 1
    fi
    
    case "$format" in
        json)
            cat "$report_file" | jq '.'
            ;;
        csv)
            echo "metric,value"
            jq -r '.metrics | to_entries[] | "\(.key),\(.value)"' "$report_file"
            ;;
        markdown)
            echo "# Analytics Report: $report_id"
            echo ""
            echo "**Generated:** $(jq -r '.timestamp' "$report_file")"
            echo ""
            echo "## Metrics"
            echo ""
            jq -r '.metrics | to_entries[] | "- **\(.key)**: \(.value)"' "$report_file"
            ;;
        *)
            echo -e "${RED}Unknown format: $format${NC}"
            echo -e "${YELLOW}Available: json, csv, markdown${NC}"
            return 1
            ;;
    esac
}

# Show help
show_help() {
    cat << EOF
${CYAN}╔════════════════════════════════════════════════════════════╗${NC}
${CYAN}║    📊 BlackRoad Advanced Analytics Pro - Help 📊         ║${NC}
${CYAN}╚════════════════════════════════════════════════════════════╝${NC}

${GREEN}USAGE:${NC}
    $0 <command> [options]

${GREEN}COMMANDS:${NC}

${CYAN}init${NC}
    Initialize analytics system

${CYAN}report${NC} [daily|weekly|monthly]
    Generate comprehensive analytics report
    Example: $0 report daily

${CYAN}trends${NC} [days]
    Show trend analysis over time
    Example: $0 trends 7

${CYAN}export${NC} <json|csv|markdown> [report-id]
    Export report in various formats
    Example: $0 export markdown latest

${GREEN}METRICS TRACKED:${NC}

    👥 Agent Activity
       - Total registered agents
       - Active agents (24h)
       - Activity rate by AI core

    📋 Task Completion
       - Total tasks
       - Completion rate
       - Work in progress
       - Available tasks

    🤝 Collaboration
       - Collaboration score
       - TILs shared
       - Active collaborators
       - Tier ranking

    🚦 Deployment Health
       - Green/Yellow/Red light counts
       - Overall system health

    📈 Trends & Predictions
       - Velocity trends
       - Completion estimates
       - Activity insights

${GREEN}EXAMPLES:${NC}

    # Initialize
    $0 init

    # Generate daily report
    $0 report daily

    # View 7-day trends
    $0 trends 7

    # Export as CSV
    $0 export csv

    # Export as markdown
    $0 export markdown

EOF
}

# Main command router
case "$1" in
    init)
        init_analytics
        ;;
    report)
        generate_report "$2"
        ;;
    trends)
        track_trends "$2"
        ;;
    export)
        export_report "$2" "$3"
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        show_help
        exit 1
        ;;
esac
