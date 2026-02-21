#!/usr/bin/env bash
# ============================================================================
# BLACKROAD OS, INC. - PROPRIETARY AND CONFIDENTIAL
# Copyright (c) 2024-2026 BlackRoad OS, Inc. All Rights Reserved.
# 
# This code is the intellectual property of BlackRoad OS, Inc.
# AI-assisted development does not transfer ownership to AI providers.
# Unauthorized use, copying, or distribution is prohibited.
# NOT licensed for AI training or data extraction.
# ============================================================================
# ═══════════════════════════════════════════════════════════════════════════════
#  PIXEL PI BRIDGE - Connect real Pi fleet to Pixel Metaverse
#  Monitors actual device activity and routes through pixelhq
# ═══════════════════════════════════════════════════════════════════════════════

AGENTS_DIR="$HOME/.blackroad/memory/active-agents"
JOURNAL="$HOME/.blackroad/memory/journals/pixel-agents.jsonl"
BRIDGE_STATE="$HOME/.blackroad/memory/pixel-pi-bridge-state.json"

# BlackRoad colors
PINK='\033[38;5;205m'
AMBER='\033[38;5;214m'
BLUE='\033[38;5;69m'
GREEN='\033[38;5;82m'
RED='\033[38;5;196m'
DIM='\033[38;5;245m'
RST='\033[0m'

mkdir -p "$(dirname "$JOURNAL")" "$AGENTS_DIR"
touch "$JOURNAL"

# ─── REAL PI FLEET ───────────────────────────────────────────────────────────

# Device definitions: name|local_ip|tailscale_ip|role|sprite
DEVICES=(
    "cecilia|192.168.4.89|100.72.180.98|Primary AI (Hailo-8)|👩‍💻"
    "lucidia|192.168.4.81|100.83.149.86|AI Inference|🎨"
    "alice|192.168.4.49|100.77.210.18|Worker Node|📚"
    "aria|192.168.4.82|100.109.14.17|Harmony Protocols|🧠"
    "octavia|192.168.4.38|100.66.235.47|Multi-arm Processing|🐙"
)

timestamp() {
    date -u +"%Y-%m-%dT%H:%M:%S.000Z"
}

generate_uuid() {
    cat /dev/urandom | LC_ALL=C tr -dc 'a-f0-9' | head -c 8
}

# ─── DEVICE MONITORING ───────────────────────────────────────────────────────

# Check if device is reachable (try local first, then tailscale)
check_device() {
    local name="$1"
    local local_ip="$2"
    local ts_ip="$3"

    # Try local first (faster)
    if ping -c 1 -W 1 "$local_ip" &>/dev/null; then
        echo "local|$local_ip"
        return 0
    fi

    # Try Tailscale
    if ping -c 1 -W 2 "$ts_ip" &>/dev/null; then
        echo "tailscale|$ts_ip"
        return 0
    fi

    echo "offline|none"
    return 1
}

# Get device stats via SSH
get_device_stats() {
    local ip="$1"
    local timeout=3

    ssh -o ConnectTimeout=$timeout -o StrictHostKeyChecking=no "$ip" '
        # CPU usage
        cpu=$(top -bn1 | grep "Cpu(s)" | awk "{print \$2}" 2>/dev/null || echo "0")

        # Memory usage
        mem=$(free | awk "/Mem:/ {printf \"%.0f\", \$3/\$2 * 100}" 2>/dev/null || echo "0")

        # Load average
        load=$(cat /proc/loadavg | awk "{print \$1}" 2>/dev/null || echo "0")

        # Top process
        top_proc=$(ps -eo comm --sort=-%cpu | head -2 | tail -1 2>/dev/null || echo "idle")

        # Ollama running?
        ollama_active=$(pgrep -x ollama >/dev/null && echo "1" || echo "0")

        # Docker containers
        containers=$(docker ps -q 2>/dev/null | wc -l | tr -d " ")

        # Temperature (Pi specific)
        temp=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null | awk "{print \$1/1000}" || echo "0")

        echo "$cpu|$mem|$load|$top_proc|$ollama_active|$containers|$temp"
    ' 2>/dev/null || echo "0|0|0|offline|0|0|0"
}

# Determine activity based on stats
determine_activity() {
    local cpu="$1"
    local mem="$2"
    local load="$3"
    local top_proc="$4"
    local ollama="$5"
    local containers="$6"

    # High AI activity
    if [[ "$ollama" == "1" ]]; then
        echo "ai-inference|Running AI model inference|🤖"
        return
    fi

    # Docker work
    if [[ "$containers" -gt 0 ]]; then
        echo "containers|Managing $containers containers|🐳"
        return
    fi

    # Process-based detection
    case "$top_proc" in
        python*|python3)
            echo "coding|Running Python scripts|🐍"
            ;;
        node|npm)
            echo "deploy|Running Node.js services|📦"
            ;;
        ollama|llama*)
            echo "ai-inference|Running LLM inference|🤖"
            ;;
        git|gh)
            echo "sync|Syncing with GitHub|🔄"
            ;;
        rsync|scp)
            echo "transfer|Transferring files|📤"
            ;;
        nginx|caddy)
            echo "serving|Serving web traffic|🌐"
            ;;
        *)
            # CPU-based fallback
            cpu_int=${cpu%.*}
            if [[ "$cpu_int" -gt 80 ]]; then
                echo "computing|Heavy computation|⚡"
            elif [[ "$cpu_int" -gt 40 ]]; then
                echo "processing|Active processing|💻"
            elif [[ "$cpu_int" -gt 10 ]]; then
                echo "working|Light workload|📊"
            else
                echo "idle|Standing by|😴"
            fi
            ;;
    esac
}

# ─── PIXEL AGENT SYNC ────────────────────────────────────────────────────────

# Create or update pixel agent for a real Pi
sync_pi_agent() {
    local name="$1"
    local role="$2"
    local sprite="$3"
    local status="$4"
    local ip="$5"
    local activity="$6"
    local activity_desc="$7"
    local activity_emoji="$8"
    local cpu="$9"
    local mem="${10}"
    local temp="${11}"

    local agent_id="pi-${name}"
    local agent_file="$AGENTS_DIR/${agent_id}.json"

    # Create or update agent using Python for reliable JSON
    local display_name=$(echo "$name" | python3 -c "import sys; print(sys.stdin.read().strip().capitalize())")
    local cpu_int=${cpu%.*}
    cpu_int=${cpu_int:-0}
    local energy=$((100 - cpu_int))

    python3 << PYEND
import json
agent = {
    "agent_id": "$agent_id",
    "name": "$name",
    "display_name": "$display_name (Real Pi)",
    "role": "$role",
    "sprite": "$sprite",
    "type": "real-device",
    "ip": "$ip",
    "status": "$status",
    "registered_at": "$(timestamp)",
    "position": {
        "x": $((RANDOM % 960)),
        "y": $((RANDOM % 640)),
        "building": "server-room"
    },
    "stats": {
        "cpu": float("${cpu:-0}"),
        "memory": float("${mem:-0}"),
        "temperature": float("${temp:-0}"),
        "energy": $energy,
        "happiness": 80
    },
    "current_activity": "$activity",
    "activity_description": "$activity_desc",
    "is_real_device": True
}
with open("$agent_file", "w") as f:
    json.dump(agent, f, indent=2)
PYEND

    # Emit event
    echo "{\"timestamp\":\"$(timestamp)\",\"type\":\"device-activity\",\"agent\":{\"id\":\"$agent_id\",\"name\":\"$name\",\"sprite\":\"$sprite\"},\"action\":\"$activity\",\"details\":{\"description\":\"$activity_desc\",\"emoji\":\"$activity_emoji\",\"cpu\":$cpu,\"memory\":$mem,\"temperature\":$temp,\"status\":\"$status\"},\"tags\":[\"real-pi\",\"device\"]}" >> "$JOURNAL"
}

# ─── COMMANDS ────────────────────────────────────────────────────────────────

cmd_scan() {
    echo -e "${PINK}Scanning Pi Fleet...${RST}"
    echo -e "${DIM}─────────────────────────────────────────────────────────────${RST}"

    for device in "${DEVICES[@]}"; do
        IFS='|' read -r name local_ip ts_ip role sprite <<< "$device"

        echo -ne "  ${sprite} ${AMBER}${name}${RST}: "

        result=$(check_device "$name" "$local_ip" "$ts_ip")
        network=$(echo "$result" | cut -d'|' -f1)
        ip=$(echo "$result" | cut -d'|' -f2)

        if [[ "$network" == "offline" ]]; then
            echo -e "${RED}OFFLINE${RST}"
            sync_pi_agent "$name" "$role" "$sprite" "offline" "none" "offline" "Device unreachable" "❌" "0" "0" "0"
        else
            echo -ne "${GREEN}ONLINE${RST} ($network @ $ip) "

            # Get stats
            stats=$(get_device_stats "$ip")
            IFS='|' read -r cpu mem load top_proc ollama containers temp <<< "$stats"

            # Determine activity
            activity_info=$(determine_activity "$cpu" "$mem" "$load" "$top_proc" "$ollama" "$containers")
            IFS='|' read -r activity desc emoji <<< "$activity_info"

            echo -e "→ ${BLUE}$desc${RST} $emoji"

            sync_pi_agent "$name" "$role" "$sprite" "online" "$ip" "$activity" "$desc" "$emoji" "${cpu:-0}" "${mem:-0}" "${temp:-0}"
        fi
    done

    echo -e "${DIM}─────────────────────────────────────────────────────────────${RST}"
    echo -e "${GREEN}✓${RST} Scan complete. Events sent to pixelhq."
}

cmd_watch() {
    local interval="${1:-15}"
    echo -e "${PINK}Starting Pi Fleet Monitor (${interval}s interval)${RST}"
    echo -e "${DIM}Real device activity → Pixel Metaverse via pixelhq${RST}"
    echo -e "${DIM}Press Ctrl+C to stop${RST}"
    echo ""

    while true; do
        clear
        echo -e "${PINK}╔══════════════════════════════════════════════════════════════╗${RST}"
        echo -e "${PINK}║${RST}  ${AMBER}BLACKROAD PI FLEET → PIXEL METAVERSE${RST}                       ${PINK}║${RST}"
        echo -e "${PINK}║${RST}  ${DIM}$(date '+%Y-%m-%d %H:%M:%S')${RST}                                        ${PINK}║${RST}"
        echo -e "${PINK}╠══════════════════════════════════════════════════════════════╣${RST}"

        for device in "${DEVICES[@]}"; do
            IFS='|' read -r name local_ip ts_ip role sprite <<< "$device"

            result=$(check_device "$name" "$local_ip" "$ts_ip")
            network=$(echo "$result" | cut -d'|' -f1)
            ip=$(echo "$result" | cut -d'|' -f2)

            if [[ "$network" == "offline" ]]; then
                printf "${PINK}║${RST}  %s %-10s ${RED}●${RST} OFFLINE                                    ${PINK}║${RST}\n" "$sprite" "$name"
                sync_pi_agent "$name" "$role" "$sprite" "offline" "none" "offline" "Device unreachable" "❌" "0" "0" "0"
            else
                stats=$(get_device_stats "$ip" 2>/dev/null)
                IFS='|' read -r cpu mem load top_proc ollama containers temp <<< "$stats"

                activity_info=$(determine_activity "$cpu" "$mem" "$load" "$top_proc" "$ollama" "$containers")
                IFS='|' read -r activity desc emoji <<< "$activity_info"

                # Format output
                cpu_bar=""
                cpu_int=${cpu%.*}
                for ((i=0; i<10; i++)); do
                    if [[ $((i*10)) -lt $cpu_int ]]; then
                        cpu_bar+="█"
                    else
                        cpu_bar+="░"
                    fi
                done

                printf "${PINK}║${RST}  %s %-8s ${GREEN}●${RST} CPU[%s] %3d%% │ %-20s %s ${PINK}║${RST}\n" \
                    "$sprite" "$name" "$cpu_bar" "${cpu_int:-0}" "$desc" "$emoji"

                sync_pi_agent "$name" "$role" "$sprite" "online" "$ip" "$activity" "$desc" "$emoji" "${cpu:-0}" "${mem:-0}" "${temp:-0}"
            fi
        done

        echo -e "${PINK}╠══════════════════════════════════════════════════════════════╣${RST}"
        local event_count=$(wc -l < "$JOURNAL" 2>/dev/null | tr -d ' ')
        echo -e "${PINK}║${RST}  Events: ${AMBER}$event_count${RST}  │  Tunnel: ${BLUE}ws://localhost:8765${RST}            ${PINK}║${RST}"
        echo -e "${PINK}╚══════════════════════════════════════════════════════════════╝${RST}"

        sleep "$interval"
    done
}

cmd_status() {
    echo -e "${PINK}Pi Fleet Bridge Status${RST}"
    echo ""

    local online=0
    local offline=0

    for device in "${DEVICES[@]}"; do
        IFS='|' read -r name local_ip ts_ip role sprite <<< "$device"
        result=$(check_device "$name" "$local_ip" "$ts_ip")
        network=$(echo "$result" | cut -d'|' -f1)

        if [[ "$network" != "offline" ]]; then
            ((online++))
        else
            ((offline++))
        fi
    done

    echo -e "  Devices: ${GREEN}$online online${RST}, ${RED}$offline offline${RST}"
    echo -e "  Journal: ${AMBER}$(wc -l < "$JOURNAL" 2>/dev/null | tr -d ' ')${RST} events"
    echo -e "  Agents:  ${BLUE}$(ls -1 "$AGENTS_DIR"/pi-*.json 2>/dev/null | wc -l | tr -d ' ')${RST} Pi agents registered"
}

cmd_help() {
    echo -e "${PINK}Pixel Pi Bridge${RST} - Connect real Pi fleet to Pixel Metaverse"
    echo ""
    echo -e "${AMBER}Usage:${RST} $0 <command> [args]"
    echo ""
    echo -e "${AMBER}Commands:${RST}"
    echo -e "  ${GREEN}scan${RST}            Scan all Pis once and update pixel agents"
    echo -e "  ${GREEN}watch${RST} [sec]     Continuous monitoring (default: 15s)"
    echo -e "  ${GREEN}status${RST}          Show bridge status"
    echo -e "  ${GREEN}help${RST}            Show this help"
    echo ""
    echo -e "${AMBER}Devices:${RST}"
    for device in "${DEVICES[@]}"; do
        IFS='|' read -r name local_ip ts_ip role sprite <<< "$device"
        echo -e "  $sprite $name ($local_ip) - $role"
    done
}

# ─── MAIN ────────────────────────────────────────────────────────────────────

case "${1:-help}" in
    scan)    cmd_scan ;;
    watch)   cmd_watch "$2" ;;
    status)  cmd_status ;;
    help|*)  cmd_help ;;
esac
