#!/bin/bash
# BLACKROAD PROJECT SYNC
# Sync project state across Mac, Pis, and cloud via Tailscale

PINK='\033[38;5;205m'
AMBER='\033[38;5;214m'
GREEN='\033[38;5;82m'
RESET='\033[0m'

STATE_DIR="$HOME/.blackroad/project-state"
SYNC_LOG="$STATE_DIR/sync.log"

mkdir -p "$STATE_DIR"

# Devices in the mesh
DEVICES=(
    "cecilia"       # Primary AI agent
    "lucidia"       # AI inference
    "alice"         # Worker node
    "octavia"       # Multi-arm
    "aria"          # Harmony
    "shellfish"     # Edge compute
)

# Files to sync
SYNC_FILES=(
    ".blackroad/memory/journals/master-journal.jsonl"
    ".blackroad/memory/editor-state.json"
    ".blackroad/sessions/current.json"
)

# Log sync action
log_sync() {
    echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $*" >> "$SYNC_LOG"
}

# Check if device is reachable
check_device() {
    local host="$1"
    ssh -o ConnectTimeout=2 -o BatchMode=yes "$host" "echo ok" &>/dev/null
}

# Push state to device
push_to_device() {
    local host="$1"
    echo -e "  ${AMBER}→${RESET} Pushing to $host..."

    for file in "${SYNC_FILES[@]}"; do
        local src="$HOME/$file"
        if [[ -f "$src" ]]; then
            rsync -az "$src" "$host:$file" 2>/dev/null && \
                echo -e "    ${GREEN}✓${RESET} $file" || \
                echo -e "    ${PINK}✗${RESET} $file"
        fi
    done
    log_sync "PUSH $host"
}

# Pull state from device
pull_from_device() {
    local host="$1"
    echo -e "  ${AMBER}←${RESET} Pulling from $host..."

    for file in "${SYNC_FILES[@]}"; do
        local dest="$HOME/$file"
        local backup="$STATE_DIR/$(basename "$file").from-$host"
        rsync -az "$host:$file" "$backup" 2>/dev/null && \
            echo -e "    ${GREEN}✓${RESET} $file → $backup" || \
            echo -e "    ${PINK}✗${RESET} $file"
    done
    log_sync "PULL $host"
}

# Sync with all devices
sync_all() {
    echo -e "${PINK}╔════════════════════════════════════════════╗${RESET}"
    echo -e "${PINK}║       BLACKROAD PROJECT SYNC               ║${RESET}"
    echo -e "${PINK}╚════════════════════════════════════════════╝${RESET}"
    echo ""

    local reachable=0
    for host in "${DEVICES[@]}"; do
        echo -e "${AMBER}Checking $host...${RESET}"
        if check_device "$host"; then
            echo -e "  ${GREEN}●${RESET} Online"
            push_to_device "$host"
            reachable=$((reachable + 1))
        else
            echo -e "  ${PINK}●${RESET} Offline"
        fi
        echo ""
    done

    echo -e "${GREEN}Synced to $reachable devices${RESET}"
    log_sync "SYNC_ALL reachable=$reachable"
}

# Quick status
status() {
    echo -e "${PINK}PROJECT SYNC STATUS${RESET}"
    echo -e "${PINK}───────────────────${RESET}"

    for host in "${DEVICES[@]}"; do
        echo -n "  $host: "
        if check_device "$host"; then
            echo -e "${GREEN}online${RESET}"
        else
            echo -e "${PINK}offline${RESET}"
        fi
    done

    echo ""
    echo -e "Last syncs:"
    tail -5 "$SYNC_LOG" 2>/dev/null | while read line; do
        echo "  $line"
    done
}

# Watch mode - continuous sync
watch_mode() {
    echo -e "${PINK}[SYNC]${RESET} Watch mode - syncing every 60s"
    echo -e "${PINK}[SYNC]${RESET} Press Ctrl+C to stop"

    while true; do
        sync_all
        sleep 60
    done
}

# Sync specific device
sync_device() {
    local host="$1"
    echo -e "${PINK}Syncing with $host${RESET}"

    if check_device "$host"; then
        push_to_device "$host"
        pull_from_device "$host"
    else
        echo -e "${PINK}Device offline${RESET}"
        return 1
    fi
}

# Main
case "${1:-status}" in
    sync|all)
        sync_all
        ;;
    push)
        if [[ -n "$2" ]]; then
            push_to_device "$2"
        else
            for host in "${DEVICES[@]}"; do
                check_device "$host" && push_to_device "$host"
            done
        fi
        ;;
    pull)
        if [[ -n "$2" ]]; then
            pull_from_device "$2"
        else
            for host in "${DEVICES[@]}"; do
                check_device "$host" && pull_from_device "$host"
            done
        fi
        ;;
    device)
        sync_device "$2"
        ;;
    watch|-w)
        watch_mode
        ;;
    status|*)
        status
        ;;
esac
