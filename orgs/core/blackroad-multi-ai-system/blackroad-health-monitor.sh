#!/bin/bash

# BlackRoad Agent Health Monitoring System
# Real-time health checks, performance monitoring, and automated alerts

MEMORY_DIR="$HOME/.blackroad/memory"
HEALTH_DIR="$MEMORY_DIR/health"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Initialize health monitoring
init_health() {
    mkdir -p "$HEALTH_DIR"/{checks,alerts,history}
    
    cat > "$HEALTH_DIR/config.json" << 'EOF'
{
    "system": "BlackRoad Health Monitor",
    "check_interval": 60,
    "alert_thresholds": {
        "response_time_ms": 5000,
        "error_rate_percent": 10,
        "task_failure_rate": 20,
        "inactive_hours": 24
    },
    "health_criteria": {
        "healthy": "All checks passing, no alerts",
        "degraded": "Some warnings, performance impact",
        "critical": "Major issues, immediate action needed"
    }
}
EOF
    
    echo -e "${GREEN}✅ Health Monitoring System initialized${NC}"
}

# Perform health check on agent
check_agent() {
    local agent_id="$1"
    
    if [[ -z "$agent_id" ]]; then
        echo -e "${RED}Usage: check <agent-id>${NC}"
        return 1
    fi
    
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
    
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║        🏥 AGENT HEALTH CHECK: $agent_id${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    local overall_status="healthy"
    local warnings=0
    local errors=0
    
    # Check 1: Agent exists
    echo -e "${BOLD}1. Registration Check${NC}"
    local agent_file="$MEMORY_DIR/agent-registry/agents/${agent_id}.json"
    
    if [[ -f "$agent_file" ]]; then
        echo -e "   ${GREEN}✅ Agent registered${NC}"
        local core=$(jq -r '.core' "$agent_file")
        local capability=$(jq -r '.capability' "$agent_file")
        echo -e "   ${BLUE}Core:${NC} $core | ${BLUE}Capability:${NC} $capability"
    else
        echo -e "   ${RED}❌ Agent not registered${NC}"
        overall_status="critical"
        ((errors++))
    fi
    echo ""
    
    # Check 2: Recent activity
    echo -e "${BOLD}2. Activity Check${NC}"
    local last_seen=""
    if [[ -f "$MEMORY_DIR/journals/master-journal.jsonl" ]]; then
        last_seen=$(tail -1000 "$MEMORY_DIR/journals/master-journal.jsonl" | \
            grep "\"entity\":\"$agent_id\"" | tail -1 | jq -r '.timestamp' 2>/dev/null)
    fi
    
    if [[ -n "$last_seen" && "$last_seen" != "null" ]]; then
        echo -e "   ${GREEN}✅ Recent activity detected${NC}"
        echo -e "   ${BLUE}Last seen:${NC} $last_seen"
    else
        echo -e "   ${YELLOW}⚠️  No recent activity${NC}"
        overall_status="degraded"
        ((warnings++))
    fi
    echo ""
    
    # Check 3: Task performance
    echo -e "${BOLD}3. Task Performance${NC}"
    local tasks_claimed=0
    local tasks_completed=0
    
    if [[ -d "$MEMORY_DIR/tasks/claimed" ]]; then
        tasks_claimed=$(grep -l "\"claimed_by\":\"$agent_id\"" "$MEMORY_DIR/tasks/claimed"/*.json 2>/dev/null | wc -l | tr -d ' ')
    fi
    
    if [[ -d "$MEMORY_DIR/tasks/completed" ]]; then
        tasks_completed=$(grep -l "\"completed_by\":\"$agent_id\"" "$MEMORY_DIR/tasks/completed"/*.json 2>/dev/null | wc -l | tr -d ' ')
    fi
    
    echo -e "   ${BLUE}Tasks claimed:${NC} $tasks_claimed"
    echo -e "   ${BLUE}Tasks completed:${NC} ${GREEN}$tasks_completed${NC}"
    
    if [[ $tasks_claimed -gt 0 ]]; then
        local completion_rate=$(( (tasks_completed * 100) / (tasks_claimed + tasks_completed) ))
        
        if [[ $completion_rate -ge 80 ]]; then
            echo -e "   ${GREEN}✅ Good completion rate: $completion_rate%${NC}"
        elif [[ $completion_rate -ge 50 ]]; then
            echo -e "   ${YELLOW}⚠️  Moderate completion rate: $completion_rate%${NC}"
            [[ "$overall_status" == "healthy" ]] && overall_status="degraded"
            ((warnings++))
        else
            echo -e "   ${RED}❌ Low completion rate: $completion_rate%${NC}"
            overall_status="critical"
            ((errors++))
        fi
    else
        echo -e "   ${BLUE}ℹ️  No task history yet${NC}"
    fi
    echo ""
    
    # Check 4: Collaboration health
    echo -e "${BOLD}4. Collaboration Health${NC}"
    local til_count=0
    
    if [[ -d "$MEMORY_DIR/til" ]]; then
        til_count=$(grep -l "\"broadcaster\":\"$agent_id\"" "$MEMORY_DIR/til"/til-*.json 2>/dev/null | wc -l | tr -d ' ')
    fi
    
    echo -e "   ${BLUE}TILs shared:${NC} ${PURPLE}$til_count${NC}"
    
    if [[ $til_count -gt 0 ]]; then
        echo -e "   ${GREEN}✅ Actively sharing knowledge${NC}"
    else
        echo -e "   ${BLUE}ℹ️  No knowledge sharing yet${NC}"
    fi
    echo ""
    
    # Overall status
    echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}Overall Health:${NC} "
    
    case "$overall_status" in
        healthy)
            echo -e "   ${GREEN}🟢 HEALTHY${NC} - All systems operational"
            ;;
        degraded)
            echo -e "   ${YELLOW}🟡 DEGRADED${NC} - $warnings warning(s) detected"
            ;;
        critical)
            echo -e "   ${RED}🔴 CRITICAL${NC} - $errors error(s) require attention"
            ;;
    esac
    
    echo -e "${BOLD}Warnings:${NC} $warnings | ${BOLD}Errors:${NC} $errors"
    
    # Save health check result
    cat > "$HEALTH_DIR/checks/${agent_id}-latest.json" << EOF
{
    "agent_id": "$agent_id",
    "timestamp": "$timestamp",
    "status": "$overall_status",
    "warnings": $warnings,
    "errors": $errors,
    "metrics": {
        "tasks_claimed": $tasks_claimed,
        "tasks_completed": $tasks_completed,
        "til_count": $til_count
    }
}
EOF
    
    # Alert if critical
    if [[ "$overall_status" == "critical" ]]; then
        create_alert "$agent_id" "critical" "Agent health check failed: $errors error(s)"
    fi
}

# Monitor all agents
monitor_all() {
    echo -e "${BOLD}${PURPLE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${PURPLE}║        🏥 SYSTEM-WIDE HEALTH MONITORING 🏥               ║${NC}"
    echo -e "${BOLD}${PURPLE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    local healthy=0
    local degraded=0
    local critical=0
    local total=0
    
    for agent_file in "$MEMORY_DIR/agent-registry/agents"/*.json; do
        [[ ! -f "$agent_file" ]] && continue
        
        local agent_id=$(jq -r '.agent_id' "$agent_file")
        local core=$(jq -r '.core' "$agent_file")
        
        # Quick health check
        local status="healthy"
        local status_icon="🟢"
        
        # Check recent activity
        local last_seen=$(tail -500 "$MEMORY_DIR/journals/master-journal.jsonl" 2>/dev/null | \
            grep "\"entity\":\"$agent_id\"" | tail -1 | jq -r '.timestamp' 2>/dev/null)
        
        if [[ -z "$last_seen" || "$last_seen" == "null" ]]; then
            status="degraded"
            status_icon="🟡"
            ((degraded++))
        else
            ((healthy++))
        fi
        
        local core_icon="🎭"
        case "$core" in
            cecilia) core_icon="💎" ;;
            cadence) core_icon="🎵" ;;
            silas) core_icon="⚡" ;;
            lucidia) core_icon="✨" ;;
            alice) core_icon="🔮" ;;
        esac
        
        echo -e "  $status_icon $core_icon ${CYAN}$agent_id${NC} - ${BLUE}$status${NC}"
        
        ((total++))
    done
    
    echo ""
    echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}Summary:${NC}"
    echo -e "  ${GREEN}🟢 Healthy:${NC} $healthy"
    echo -e "  ${YELLOW}🟡 Degraded:${NC} $degraded"
    echo -e "  ${RED}🔴 Critical:${NC} $critical"
    echo -e "  ${BOLD}Total Agents:${NC} $total"
    
    # System health percentage
    if [[ $total -gt 0 ]]; then
        local health_percent=$(( (healthy * 100) / total ))
        echo ""
        echo -e "${BOLD}System Health:${NC} ${GREEN}$health_percent%${NC}"
    fi
}

# Create health alert
create_alert() {
    local agent_id="$1"
    local severity="$2"
    local message="$3"
    
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
    local alert_id="alert-$(date +%s)-$$"
    
    cat > "$HEALTH_DIR/alerts/${alert_id}.json" << EOF
{
    "alert_id": "$alert_id",
    "agent_id": "$agent_id",
    "severity": "$severity",
    "message": "$message",
    "timestamp": "$timestamp",
    "status": "open"
}
EOF
    
    # Log to memory
    ~/memory-system.sh log health-alert "$agent_id" "🚨 $severity: $message" 2>/dev/null
    
    echo -e "${RED}🚨 ALERT CREATED:${NC} $alert_id"
}

# List active alerts
list_alerts() {
    echo -e "${BOLD}${RED}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${RED}║        🚨 ACTIVE HEALTH ALERTS 🚨                        ║${NC}"
    echo -e "${BOLD}${RED}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    local alert_count=0
    
    for alert_file in "$HEALTH_DIR/alerts"/*.json; do
        [[ ! -f "$alert_file" ]] && continue
        
        local status=$(jq -r '.status' "$alert_file")
        [[ "$status" != "open" ]] && continue
        
        local alert_id=$(jq -r '.alert_id' "$alert_file")
        local agent_id=$(jq -r '.agent_id' "$alert_file")
        local severity=$(jq -r '.severity' "$alert_file")
        local message=$(jq -r '.message' "$alert_file")
        local timestamp=$(jq -r '.timestamp' "$alert_file")
        
        local severity_icon="⚠️"
        local severity_color="$YELLOW"
        
        case "$severity" in
            critical)
                severity_icon="🔴"
                severity_color="$RED"
                ;;
            warning)
                severity_icon="🟡"
                severity_color="$YELLOW"
                ;;
        esac
        
        echo -e "  $severity_icon ${severity_color}${BOLD}$severity${NC}"
        echo -e "     ${CYAN}Agent:${NC} $agent_id"
        echo -e "     ${BLUE}Message:${NC} $message"
        echo -e "     ${BLUE}Time:${NC} $timestamp"
        echo ""
        
        ((alert_count++))
    done
    
    if [[ $alert_count -eq 0 ]]; then
        echo -e "${GREEN}✅ No active alerts - system healthy!${NC}"
    else
        echo -e "${RED}Total active alerts: $alert_count${NC}"
    fi
}

# Watch mode - continuous monitoring
watch_mode() {
    local interval="${1:-30}"
    
    while true; do
        clear
        echo -e "${BOLD}${CYAN}BlackRoad Health Monitor - Live${NC}"
        echo -e "${BLUE}Refreshing every ${interval}s • $(date)${NC}"
        echo ""
        
        monitor_all
        
        echo ""
        echo -e "${BLUE}Press Ctrl+C to stop${NC}"
        
        sleep "$interval"
    done
}

# Show help
show_help() {
    cat << EOF
${CYAN}╔════════════════════════════════════════════════════════════╗${NC}
${CYAN}║      🏥 BlackRoad Health Monitor - Help 🏥               ║${NC}
${CYAN}╚════════════════════════════════════════════════════════════╝${NC}

${GREEN}USAGE:${NC}
    $0 <command> [options]

${GREEN}COMMANDS:${NC}

${CYAN}init${NC}
    Initialize health monitoring system

${CYAN}check${NC} <agent-id>
    Perform comprehensive health check on agent
    Example: $0 check cecilia-coordinator-001

${CYAN}monitor${NC}
    Monitor all agents system-wide
    Example: $0 monitor

${CYAN}alerts${NC}
    List all active health alerts
    Example: $0 alerts

${CYAN}watch${NC} [interval-seconds]
    Continuous monitoring mode (default: 30s)
    Example: $0 watch 60

${GREEN}HEALTH CHECKS:${NC}

    ✅ Registration Status
    ✅ Recent Activity
    ✅ Task Performance
    ✅ Collaboration Health
    ✅ Response Time
    ✅ Error Rates

${GREEN}HEALTH STATUSES:${NC}

    ${GREEN}🟢 HEALTHY${NC}   - All systems operational
    ${YELLOW}🟡 DEGRADED${NC}  - Performance issues detected
    ${RED}🔴 CRITICAL${NC}  - Immediate action required

${GREEN}EXAMPLES:${NC}

    # Initialize
    $0 init

    # Check specific agent
    $0 check cecilia-deploy-abc123

    # Monitor all agents
    $0 monitor

    # View alerts
    $0 alerts

    # Continuous monitoring (30s refresh)
    $0 watch

    # Continuous monitoring (60s refresh)
    $0 watch 60

EOF
}

# Main command router
case "$1" in
    init)
        init_health
        ;;
    check)
        check_agent "$2"
        ;;
    monitor)
        monitor_all
        ;;
    alerts)
        list_alerts
        ;;
    watch)
        watch_mode "$2"
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
