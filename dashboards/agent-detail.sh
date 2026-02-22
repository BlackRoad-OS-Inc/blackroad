#!/bin/bash

# BlackRoad OS - Agent Detail Viewer
# Individual agent inspection with live logs, resources, and configuration

# Color definitions (RGB values matching web UI)
BG_DEEP="\033[48;2;10;10;18m"
BG_SURFACE="\033[48;2;18;18;31m"
BG_ELEVATED="\033[48;2;26;26;46m"

# Accent colors
ORANGE="\033[38;2;247;147;26m"      # #f7931a (Bitcoin orange)
PINK="\033[38;2;233;30;140m"        # #e91e8c
PURPLE="\033[38;2;153;69;255m"      # #9945ff (Solana purple)
BLUE="\033[38;2;20;241;149m"        # #14f195
CYAN="\033[38;2;0;212;255m"         # #00d4ff

# Text colors
TEXT_PRIMARY="\033[38;2;255;255;255m"
TEXT_SECONDARY="\033[38;2;153;153;153m"
TEXT_MUTED="\033[38;2;77;77;77m"

# Special
RESET="\033[0m"
BOLD="\033[1m"
DIM="\033[2m"

# Agent details (can be passed as arguments)
AGENT_NAME="${1:-Lucidia Prime}"
AGENT_HOST="${2:-192.168.4.38}"
AGENT_STATUS="${3:-online}"
AGENT_MODEL="${4:-sonnet-4.5}"
ACTIVE_TAB="${5:-overview}"

# Get status color
get_status_color() {
    case $AGENT_STATUS in
        online) echo "$BLUE" ;;
        offline) echo "$TEXT_MUTED" ;;
        error) echo "$PINK" ;;
        busy) echo "$ORANGE" ;;
        *) echo "$PURPLE" ;;
    esac
}

# Draw horizontal line
draw_line() {
    local width=$1
    local char="${2:-─}"
    printf "%${width}s" | tr ' ' "$char"
}

# Render dashboard
render_dashboard() {
    # Clear screen and set background
    clear
    echo -ne ""
    clear

    # Header
    echo ""
    echo -e "${BOLD}${ORANGE}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${ORANGE}║${RESET}  ${TEXT_MUTED}Dashboards / Agents /${RESET} ${BOLD}${ORANGE}${AGENT_NAME}${RESET}                                  ${BOLD}${ORANGE}║${RESET}"
    echo -e "${BOLD}${ORANGE}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    # Agent header card
    local status_color=$(get_status_color)
    local status_upper=$(echo "$AGENT_STATUS" | tr '[:lower:]' '[:upper:]')
    echo -e "                                                                        ${RESET}"
    echo -e "    ${BOLD}${ORANGE}┌────┐${RESET}                                                           ${RESET}"
    echo -e "    ${BOLD}${ORANGE}│ LP │${RESET}  ${BOLD}${TEXT_PRIMARY}${AGENT_NAME}${RESET}                                          ${RESET}"
    echo -e "    ${BOLD}${ORANGE}└────┘${RESET}  ${status_color}● ${status_upper}${RESET}  ${TEXT_MUTED}•${RESET}  ${TEXT_SECONDARY}${AGENT_HOST}${RESET}  ${TEXT_MUTED}•${RESET}  ${TEXT_SECONDARY}${AGENT_MODEL}${RESET}         ${RESET}"
    echo -e "                                                                        ${RESET}"
    echo -e "  ${TEXT_SECONDARY}Managed:${RESET} ${BOLD}${ORANGE}47${RESET}  ${TEXT_SECONDARY}Events/min:${RESET} ${BOLD}${CYAN}1.2K${RESET}  ${TEXT_SECONDARY}Latency:${RESET} ${BOLD}${BLUE}42ms${RESET}  ${TEXT_SECONDARY}Uptime:${RESET} ${BOLD}${PURPLE}5d 14h${RESET}  ${RESET}"
    echo -e "                                                                        ${RESET}"
    echo ""

    # Tab navigation
    echo -ne "  "
    if [ "$ACTIVE_TAB" == "overview" ]; then
        echo -ne "${BOLD}${ORANGE} Overview ${RESET} "
    else
        echo -ne "${TEXT_MUTED} Overview ${RESET} "
    fi

    if [ "$ACTIVE_TAB" == "logs" ]; then
        echo -ne "${BOLD}${ORANGE} Logs ${RESET} "
    else
        echo -ne "${TEXT_MUTED} Logs ${RESET} "
    fi

    if [ "$ACTIVE_TAB" == "memory" ]; then
        echo -ne "${BOLD}${ORANGE} Memory ${RESET} "
    else
        echo -ne "${TEXT_MUTED} Memory ${RESET} "
    fi

    if [ "$ACTIVE_TAB" == "connections" ]; then
        echo -ne "${BOLD}${ORANGE} Connections ${RESET} "
    else
        echo -ne "${TEXT_MUTED} Connections ${RESET} "
    fi

    if [ "$ACTIVE_TAB" == "config" ]; then
        echo -ne "${BOLD}${ORANGE} Config ${RESET} "
    else
        echo -ne "${TEXT_MUTED} Config ${RESET} "
    fi

    if [ "$ACTIVE_TAB" == "events" ]; then
        echo -ne "${BOLD}${ORANGE} Events ${RESET}"
    else
        echo -ne "${TEXT_MUTED} Events ${RESET}"
    fi
    echo ""
    echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo ""

    # Render active tab
    case $ACTIVE_TAB in
        overview) render_overview ;;
        logs) render_logs ;;
        memory) render_memory ;;
        connections) render_connections ;;
        config) render_config ;;
        events) render_events ;;
        *) render_overview ;;
    esac

    # Footer
    echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo ""
    echo -e "  ${TEXT_MUTED}Controls: ${TEXT_SECONDARY}[1-6]${TEXT_MUTED} Tab  ${TEXT_SECONDARY}[r]${TEXT_MUTED} Refresh  ${TEXT_SECONDARY}[s]${TEXT_MUTED} SSH  ${TEXT_SECONDARY}[q]${TEXT_MUTED} Back${RESET}"
    echo ""
}

# Overview tab
render_overview() {
    local timestamp=$(date "+%H:%M:%S")

    echo -e "${TEXT_MUTED}LIVE TERMINAL${RESET} ${TEXT_MUTED}(last 10 lines)${RESET}"
    echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo ""
    echo -e "  ${TEXT_MUTED}[$timestamp]${RESET} ${BLUE}[INFO]${RESET}  Agent initialized successfully"
    echo -e "  ${TEXT_MUTED}[$timestamp]${RESET} ${BLUE}[INFO]${RESET}  Connected to Event Bus"
    echo -e "  ${TEXT_MUTED}[$timestamp]${RESET} ${ORANGE}[SPAWN]${RESET} Spawned worker agent: Oracle-7x2b"
    echo -e "  ${TEXT_MUTED}[$timestamp]${RESET} ${BLUE}[INFO]${RESET}  Memory vault synchronized"
    echo -e "  ${TEXT_MUTED}[$timestamp]${RESET} ${PURPLE}[EVENT]${RESET} Received orchestration command"
    echo -e "  ${TEXT_MUTED}[$timestamp]${RESET} ${BLUE}[INFO]${RESET}  Processing task queue (3 items)"
    echo -e "  ${TEXT_MUTED}[$timestamp]${RESET} ${CYAN}[API]${RESET}   Anthropic API call: 247ms"
    echo -e "  ${TEXT_MUTED}[$timestamp]${RESET} ${ORANGE}[SPAWN]${RESET} Worker completed: Oracle-7x2b"
    echo -e "  ${TEXT_MUTED}[$timestamp]${RESET} ${BLUE}[INFO]${RESET}  Task completed successfully"
    echo -e "  ${TEXT_MUTED}[$timestamp]${RESET} ${PURPLE}[EVENT]${RESET} Broadcasting completion event"
    echo ""

    echo -e "${TEXT_MUTED}RESOURCE USAGE${RESET}"
    echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo ""
    echo -e "  ${TEXT_SECONDARY}CPU${RESET}              ${BLUE}34%${RESET}"
    echo -ne "  "
    echo -ne "${BLUE}██████████${RESET}"
    echo -e "                                        ${RESET}"
    echo ""
    echo -e "  ${TEXT_SECONDARY}Memory${RESET}           ${PURPLE}67%${RESET}"
    echo -ne "  "
    echo -ne "${PURPLE}████████████████████${RESET}"
    echo -e "                            ${RESET}"
    echo ""
    echo -e "  ${TEXT_SECONDARY}Network${RESET}          ${CYAN}23%${RESET}"
    echo -ne "  "
    echo -ne "${CYAN}██████${RESET}"
    echo -e "                                          ${RESET}"
    echo ""
    echo -e "  ${TEXT_SECONDARY}Disk I/O${RESET}         ${ORANGE}12%${RESET}"
    echo -ne "  "
    echo -ne "${ORANGE}███${RESET}"
    echo -e "                                             ${RESET}"
    echo ""

    echo -e "${TEXT_MUTED}MEMORY VAULT${RESET}"
    echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo ""
    echo -e "  ${ORANGE}●${RESET} ${TEXT_PRIMARY}Episodic Memory${RESET}        ${TEXT_SECONDARY}847 entries${RESET}     ${TEXT_MUTED}12.4 MB${RESET}"
    echo -e "  ${PURPLE}●${RESET} ${TEXT_PRIMARY}Semantic Memory${RESET}        ${TEXT_SECONDARY}1,203 vectors${RESET}   ${TEXT_MUTED}8.7 MB${RESET}"
    echo -e "  ${BLUE}●${RESET} ${TEXT_PRIMARY}Procedural Memory${RESET}      ${TEXT_SECONDARY}34 workflows${RESET}    ${TEXT_MUTED}2.1 MB${RESET}"
    echo -e "  ${CYAN}●${RESET} ${TEXT_PRIMARY}Cache${RESET}                  ${TEXT_SECONDARY}512 items${RESET}       ${TEXT_MUTED}4.8 MB${RESET}"
    echo ""

    echo -e "${TEXT_MUTED}ACTIVE CONNECTIONS${RESET} ${BLUE} 4 online ${RESET}"
    echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo ""
    echo -e "  ${BLUE}●${RESET} ${TEXT_PRIMARY}Event Bus${RESET}              ${TEXT_SECONDARY}ws://event-bus.blackroad.io${RESET}"
    echo -e "  ${BLUE}●${RESET} ${TEXT_PRIMARY}Memory Vault${RESET}           ${TEXT_SECONDARY}https://memory.blackroad.io${RESET}"
    echo -e "  ${BLUE}●${RESET} ${TEXT_PRIMARY}Cloudflare Workers${RESET}     ${TEXT_SECONDARY}3 active workers${RESET}"
    echo -e "  ${BLUE}●${RESET} ${TEXT_PRIMARY}Anthropic API${RESET}          ${TEXT_SECONDARY}api.anthropic.com${RESET}"
    echo ""

    echo -e "${TEXT_MUTED}CAPABILITIES${RESET}"
    echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo ""
    echo -e "  ${ORANGE} orchestration ${RESET}  ${PURPLE} spawn-agents ${RESET}  ${BLUE} event-routing ${RESET}  ${CYAN} memory-mgmt ${RESET}"
    echo -e "  ${PINK} api-gateway ${RESET}    ${ORANGE} load-balancing ${RESET}  ${PURPLE} state-sync ${RESET}"
    echo ""
}

# Logs tab
render_logs() {
    local timestamp=$(date "+%H:%M:%S")

    echo -e "${TEXT_MUTED}REAL-TIME LOGS${RESET} ${TEXT_MUTED}(streaming)${RESET}"
    echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo ""
    echo -e "  ${TEXT_MUTED}[$timestamp]${RESET} ${BLUE}[INFO]${RESET}  System health check passed"
    echo -e "  ${TEXT_MUTED}[$timestamp]${RESET} ${PURPLE}[EVENT]${RESET} Event received: agent.spawn.request"
    echo -e "  ${TEXT_MUTED}[$timestamp]${RESET} ${ORANGE}[SPAWN]${RESET} Creating new agent: Oracle-8k3p"
    echo -e "  ${TEXT_MUTED}[$timestamp]${RESET} ${CYAN}[API]${RESET}   Anthropic API: POST /v1/messages (201)"
    echo -e "  ${TEXT_MUTED}[$timestamp]${RESET} ${BLUE}[INFO]${RESET}  Memory vault: Stored 12 new entries"
    echo -e "  ${TEXT_MUTED}[$timestamp]${RESET} ${PURPLE}[EVENT]${RESET} Broadcasting to 47 child agents"
    echo -e "  ${TEXT_MUTED}[$timestamp]${RESET} ${BLUE}[INFO]${RESET}  Worker Oracle-8k3p initialized successfully"
    echo -e "  ${TEXT_MUTED}[$timestamp]${RESET} ${ORANGE}[SPAWN]${RESET} Agent Oracle-8k3p ready for tasks"
    echo -e "  ${TEXT_MUTED}[$timestamp]${RESET} ${CYAN}[API]${RESET}   Cloudflare Workers: Deployed to 3 regions"
    echo -e "  ${TEXT_MUTED}[$timestamp]${RESET} ${BLUE}[INFO]${RESET}  Queue processed: 8 tasks completed"
    echo -e "  ${TEXT_MUTED}[$timestamp]${RESET} ${PURPLE}[EVENT]${RESET} Task completion broadcasted"
    echo -e "  ${TEXT_MUTED}[$timestamp]${RESET} ${BLUE}[INFO]${RESET}  Waiting for next event..."
    echo ""
    echo -e "  ${TEXT_SECONDARY}$ _${RESET}"
    echo ""
    echo -e "  ${TEXT_MUTED}Filters: ${TEXT_SECONDARY} ALL ${RESET}  ${TEXT_MUTED}INFO  SPAWN  EVENT  API${RESET}"
    echo ""
}

# Memory tab
render_memory() {
    echo -e "${TEXT_MUTED}MEMORY DISTRIBUTION${RESET}"
    echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo ""
    echo -e "  ${TEXT_SECONDARY}Episodic${RESET}     ${ORANGE}44%${RESET}  ${TEXT_MUTED}847 entries${RESET}     ${TEXT_MUTED}12.4 MB${RESET}"
    echo -ne "  "
    echo -ne "${ORANGE}██████████████${RESET}"
    echo -e "                              ${RESET}"
    echo ""
    echo -e "  ${TEXT_SECONDARY}Semantic${RESET}     ${PURPLE}31%${RESET}  ${TEXT_MUTED}1,203 vectors${RESET}   ${TEXT_MUTED}8.7 MB${RESET}"
    echo -ne "  "
    echo -ne "${PURPLE}█████████${RESET}"
    echo -e "                                   ${RESET}"
    echo ""
    echo -e "  ${TEXT_SECONDARY}Procedural${RESET}   ${BLUE}7%${RESET}   ${TEXT_MUTED}34 workflows${RESET}    ${TEXT_MUTED}2.1 MB${RESET}"
    echo -ne "  "
    echo -ne "${BLUE}██${RESET}"
    echo -e "                                          ${RESET}"
    echo ""
    echo -e "  ${TEXT_SECONDARY}Cache${RESET}        ${CYAN}18%${RESET}  ${TEXT_MUTED}512 items${RESET}       ${TEXT_MUTED}4.8 MB${RESET}"
    echo -ne "  "
    echo -ne "${CYAN}█████${RESET}"
    echo -e "                                     ${RESET}"
    echo ""

    echo -e "${TEXT_MUTED}RECENT MEMORIES${RESET}"
    echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo ""
    echo -e "  ${TEXT_MUTED}2m ago${RESET}   ${ORANGE}●${RESET} ${TEXT_PRIMARY}Spawned Oracle-8k3p for task processing${RESET}"
    echo -e "  ${TEXT_MUTED}5m ago${RESET}   ${PURPLE}●${RESET} ${TEXT_PRIMARY}Received orchestration command from Event Bus${RESET}"
    echo -e "  ${TEXT_MUTED}12m ago${RESET}  ${BLUE}●${RESET} ${TEXT_PRIMARY}Completed deployment workflow for 3 workers${RESET}"
    echo -e "  ${TEXT_MUTED}18m ago${RESET}  ${CYAN}●${RESET} ${TEXT_PRIMARY}Synchronized memory vault with cloud${RESET}"
    echo -e "  ${TEXT_MUTED}25m ago${RESET}  ${ORANGE}●${RESET} ${TEXT_PRIMARY}System health check passed all tests${RESET}"
    echo ""

    echo -e "${TEXT_MUTED}PERFORMANCE METRICS${RESET}"
    echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo ""
    echo -e "  ${TEXT_SECONDARY}Retrieval Speed:${RESET}    ${BOLD}${BLUE}12ms${RESET} avg"
    echo -e "  ${TEXT_SECONDARY}Write Latency:${RESET}      ${BOLD}${PURPLE}8ms${RESET} avg"
    echo -e "  ${TEXT_SECONDARY}Cache Hit Rate:${RESET}     ${BOLD}${ORANGE}87%${RESET}"
    echo -e "  ${TEXT_SECONDARY}Total Size:${RESET}         ${BOLD}${CYAN}28.0 MB${RESET}"
    echo ""
}

# Connections tab
render_connections() {
    echo -e "${TEXT_MUTED}ACTIVE CONNECTIONS${RESET} ${BLUE} 4 online ${RESET}"
    echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo ""
    echo -e "  ${BLUE}●${RESET} ${BOLD}${TEXT_PRIMARY}Event Bus${RESET}"
    echo -e "    ${TEXT_SECONDARY}ws://event-bus.blackroad.io${RESET}"
    echo -e "    ${TEXT_MUTED}Latency: 12ms • Messages: 1.2K/min • Uptime: 5d 14h${RESET}"
    echo ""
    echo -e "  ${BLUE}●${RESET} ${BOLD}${TEXT_PRIMARY}Memory Vault${RESET}"
    echo -e "    ${TEXT_SECONDARY}https://memory.blackroad.io${RESET}"
    echo -e "    ${TEXT_MUTED}Latency: 8ms • Sync: Every 30s • Size: 28.0 MB${RESET}"
    echo ""
    echo -e "  ${BLUE}●${RESET} ${BOLD}${TEXT_PRIMARY}Cloudflare Workers${RESET}"
    echo -e "    ${TEXT_SECONDARY}3 active workers across global edge${RESET}"
    echo -e "    ${TEXT_MUTED}Regions: US-West, EU, Asia • Total requests: 847K${RESET}"
    echo ""
    echo -e "  ${BLUE}●${RESET} ${BOLD}${TEXT_PRIMARY}Anthropic API${RESET}"
    echo -e "    ${TEXT_SECONDARY}api.anthropic.com${RESET}"
    echo -e "    ${TEXT_MUTED}Latency: 247ms • Model: ${AGENT_MODEL} • Tokens: 2.4M${RESET}"
    echo ""

    echo -e "${TEXT_MUTED}CHILD AGENTS${RESET} ${ORANGE} 47 managed ${RESET}"
    echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo ""
    echo -e "  ${BLUE}●${RESET} ${TEXT_PRIMARY}Oracle-7x2b${RESET}       ${BLUE}●${RESET} ${TEXT_PRIMARY}Sentinel-9k1c${RESET}     ${BLUE}●${RESET} ${TEXT_PRIMARY}Metrics-3p8d${RESET}"
    echo -e "  ${BLUE}●${RESET} ${TEXT_PRIMARY}Crystal-4m7n${RESET}      ${BLUE}●${RESET} ${TEXT_PRIMARY}Navigator-2x5k${RESET}    ${BLUE}●${RESET} ${TEXT_PRIMARY}Oracle-8k3p${RESET}"
    echo -e "  ${TEXT_MUTED}+ 41 more agents...${RESET}"
    echo ""
}

# Config tab
render_config() {
    echo -e "${TEXT_MUTED}MODEL SETTINGS${RESET}"
    echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo ""
    echo -e "  ${TEXT_SECONDARY}Model:${RESET}              ${BOLD}${ORANGE}${AGENT_MODEL}${RESET}"
    echo -e "  ${TEXT_SECONDARY}Max Tokens:${RESET}         ${TEXT_PRIMARY}4096${RESET}"
    echo -e "  ${TEXT_SECONDARY}Temperature:${RESET}        ${TEXT_PRIMARY}0.7${RESET}"
    echo -e "  ${TEXT_SECONDARY}Top P:${RESET}              ${TEXT_PRIMARY}0.9${RESET}"
    echo ""

    echo -e "${TEXT_MUTED}RESOURCE LIMITS${RESET}"
    echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo ""
    echo -e "  ${TEXT_SECONDARY}Max Child Agents:${RESET}   ${TEXT_PRIMARY}100${RESET}"
    echo -e "  ${TEXT_SECONDARY}Memory per Agent:${RESET}   ${TEXT_PRIMARY}256 MB${RESET}"
    echo -e "  ${TEXT_SECONDARY}Max Queue Size:${RESET}     ${TEXT_PRIMARY}1000${RESET}"
    echo -e "  ${TEXT_SECONDARY}Timeout:${RESET}            ${TEXT_PRIMARY}30s${RESET}"
    echo ""

    echo -e "${TEXT_MUTED}FEATURE FLAGS${RESET}"
    echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo ""
    echo -e "  ${BLUE}✓${RESET} ${TEXT_PRIMARY}Event Bus${RESET}           ${BLUE}✓${RESET} ${TEXT_PRIMARY}PS-SHA∞${RESET}              ${BLUE}✓${RESET} ${TEXT_PRIMARY}Z-Framework${RESET}"
    echo -e "  ${BLUE}✓${RESET} ${TEXT_PRIMARY}Auto-scaling${RESET}        ${BLUE}✓${RESET} ${TEXT_PRIMARY}Memory Vault${RESET}         ${BLUE}✓${RESET} ${TEXT_PRIMARY}API Gateway${RESET}"
    echo -e "  ${BLUE}✓${RESET} ${TEXT_PRIMARY}Load Balancing${RESET}      ${BLUE}✓${RESET} ${TEXT_PRIMARY}State Sync${RESET}           ${TEXT_MUTED}✗${RESET} ${TEXT_MUTED}Debug Mode${RESET}"
    echo ""

    echo -e "${TEXT_MUTED}ENVIRONMENT${RESET}"
    echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo ""
    echo -e "  ${TEXT_SECONDARY}Deployment:${RESET}         ${BOLD}${PURPLE}Hybrid${RESET}"
    echo -e "  ${TEXT_SECONDARY}Host:${RESET}               ${TEXT_PRIMARY}${AGENT_HOST}${RESET}"
    echo -e "  ${TEXT_SECONDARY}Platform:${RESET}           ${TEXT_PRIMARY}Raspberry Pi 4 (ARM64)${RESET}"
    echo ""
}

# Events tab
render_events() {
    local timestamp=$(date "+%H:%M:%S")

    echo -e "${TEXT_MUTED}EVENT STREAM${RESET} ${TEXT_MUTED}(last 50 events)${RESET}"
    echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo ""
    echo -e "  ${TEXT_MUTED}[$timestamp]${RESET} ${PURPLE}agent.spawn.complete${RESET}"
    echo -e "  ${TEXT_MUTED}              {agent_id: \"Oracle-8k3p\", status: \"ready\"}${RESET}"
    echo ""
    echo -e "  ${TEXT_MUTED}[$timestamp]${RESET} ${CYAN}api.request.success${RESET}"
    echo -e "  ${TEXT_MUTED}              {endpoint: \"/v1/messages\", latency: 247}${RESET}"
    echo ""
    echo -e "  ${TEXT_MUTED}[$timestamp]${RESET} ${ORANGE}memory.vault.sync${RESET}"
    echo -e "  ${TEXT_MUTED}              {entries: 12, size: \"124KB\"}${RESET}"
    echo ""
    echo -e "  ${TEXT_MUTED}[$timestamp]${RESET} ${BLUE}event.broadcast${RESET}"
    echo -e "  ${TEXT_MUTED}              {type: \"task.complete\", recipients: 47}${RESET}"
    echo ""
    echo -e "  ${TEXT_MUTED}[$timestamp]${RESET} ${PURPLE}agent.spawn.request${RESET}"
    echo -e "  ${TEXT_MUTED}              {parent: \"Lucidia Prime\", task_type: \"inference\"}${RESET}"
    echo ""
    echo -e "  ${TEXT_MUTED}[$timestamp]${RESET} ${CYAN}health.check.passed${RESET}"
    echo -e "  ${TEXT_MUTED}              {cpu: 34%, memory: 67%, status: \"ok\"}${RESET}"
    echo ""
    echo -e "  ${TEXT_MUTED}Event rate: ${RESET}${BOLD}${CYAN}1.2K${RESET}${TEXT_MUTED} events/min • Filters: ${TEXT_SECONDARY} ALL ${RESET}${RESET}"
    echo ""
}

# Interactive mode
interactive_mode() {
    while true; do
        render_dashboard

        # Read single character input
        read -rsn1 input

        case $input in
            1) ACTIVE_TAB="overview" ;;
            2) ACTIVE_TAB="logs" ;;
            3) ACTIVE_TAB="memory" ;;
            4) ACTIVE_TAB="connections" ;;
            5) ACTIVE_TAB="config" ;;
            6) ACTIVE_TAB="events" ;;
            r|R) continue ;;
            s|S)
                echo -e "\n  ${BLUE}Connecting to ${AGENT_HOST}...${RESET}"
                sleep 1
                # Would actually SSH here: ssh user@${AGENT_HOST}
                ;;
            q|Q)
                clear
                echo ""
                echo -e "  ${BLUE}Returning to dashboard...${RESET}"
                echo ""
                sleep 1
                exit 0
                ;;
        esac
    done
}

# Handle arguments
if [ "$6" == "--watch" ] || [ "$1" == "--watch" ]; then
    interactive_mode
else
    render_dashboard
fi
