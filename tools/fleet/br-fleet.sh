#!/bin/zsh
# BR Fleet — Multi-node Pi fleet management
# Usage: br fleet [status|run <cmd>|sync|worlds|ssh <node>]

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Fleet node definitions
typeset -A FLEET_NODES FLEET_USERS FLEET_ROLES FLEET_CAPACITY
FLEET_NODES=(
    aria64 "192.168.4.38"
    alice  "192.168.4.49"
)
FLEET_USERS=(
    aria64 "alexa"
    alice  "blackroad"
)
FLEET_ROLES=(
    aria64 "PRIMARY"
    alice  "SECONDARY"
)
FLEET_CAPACITY=(
    aria64 22500
    alice  7500
)

TIMEOUT=8

ssh_node() {
    local name=$1; shift
    local user=${FLEET_USERS[$name]}
    local ip=${FLEET_NODES[$name]}
    ssh -o ConnectTimeout=$TIMEOUT -o StrictHostKeyChecking=no "$user@$ip" "$@" 2>/dev/null
}

cmd_status() {
    echo -e "${CYAN}╔══════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║       🖥  BlackRoad Fleet Status                  ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════╝${NC}"
    echo ""

    local total_worlds=0
    for node in aria64 alice; do
        local ip=${FLEET_NODES[$node]}
        local role=${FLEET_ROLES[$node]}
        local cap=${FLEET_CAPACITY[$node]}
        echo -e "${BLUE}▶ $node${NC} (${ip}) — ${role} — ${cap} agents"

        local result
        result=$(ssh_node "$node" "
            echo cpu=\$(grep 'cpu ' /proc/stat | awk '{printf \"%.0f\", (\$2+\$4)*100/(\$2+\$3+\$4+\$5)}')%
            echo mem=\$(free -m | awk '/^Mem/{printf \"%.0f%%\", \$3/\$2*100}')
            echo worlds=\$(ls ~/.blackroad/worlds/*.md 2>/dev/null | wc -l)
            echo disk=\$(df -h ~ | awk 'NR==2{print \$4\" free\"}')" 2>/dev/null)

        if [[ $? -eq 0 ]]; then
            local worlds=$(echo "$result" | grep worlds= | cut -d= -f2)
            total_worlds=$((total_worlds + worlds))
            echo -e "  ${GREEN}●${NC} $(echo "$result" | tr '\n' '  ')"
        else
            echo -e "  ${RED}○ offline or unreachable${NC}"
        fi
        echo ""
    done

    echo -e "${PURPLE}Total worlds in GitHub: ${NC}$(curl -sf https://worlds.blackroad.io/ 2>/dev/null | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['total'])" 2>/dev/null || echo '?')"
    echo -e "${PURPLE}Local worlds (all nodes): ${NC}${total_worlds}"
}

cmd_run() {
    local CMD="$*"
    [[ -z "$CMD" ]] && { echo "Usage: br fleet run <command>"; exit 1; }

    echo -e "${CYAN}🚀 Running on all fleet nodes: ${YELLOW}$CMD${NC}"
    echo ""

    for node in aria64 alice; do
        echo -e "${BLUE}▶ $node${NC}"
        local output
        output=$(ssh_node "$node" "$CMD")
        if [[ $? -eq 0 ]]; then
            echo "$output" | sed 's/^/  /'
        else
            echo -e "  ${RED}Failed or unreachable${NC}"
        fi
        echo ""
    done
}

cmd_sync() {
    echo -e "${CYAN}🔄 Syncing fleet...${NC}"
    echo ""

    # Push latest br CLI to each Pi
    local BR_REMOTE="$HOME/blackroad/br"
    for node in aria64 alice; do
        local user=${FLEET_USERS[$node]}
        local ip=${FLEET_NODES[$node]}
        echo -e "${BLUE}▶ $node${NC} — syncing br CLI..."
        scp -o ConnectTimeout=$TIMEOUT "$BR_REMOTE" "$user@$ip:~/blackroad/br" 2>/dev/null && \
            echo -e "  ${GREEN}✓ synced${NC}" || \
            echo -e "  ${RED}✗ failed${NC}"
    done
}

cmd_worlds() {
    echo -e "${CYAN}🌍 World Artifacts${NC}"
    echo ""
    echo -e "  Live feed: ${BLUE}https://worlds.blackroad.io/${NC}"
    echo ""

    local data
    data=$(curl -sf "https://worlds.blackroad.io/" 2>/dev/null)
    if [[ -n "$data" ]]; then
        local total=$(echo "$data" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['total'])" 2>/dev/null)
        echo -e "  ${GREEN}Total: $total worlds${NC}"
        echo ""
        echo "$data" | python3 -c "
import json, sys
d = json.load(sys.stdin)
icons = {'world': '🌍', 'lore': '📖', 'code': '💻'}
node_icons = {'aria64': '🔴', 'alice': '🔵'}
for w in d['worlds'][:15]:
    icon = icons.get(w['type'], '⚪')
    ni = node_icons.get(w['node'], '⚫')
    ts = w['timestamp'][11:16]
    print(f\"  {icon} {ni} {w['title']:<30} {w['type']:<8} {ts}\")
" 2>/dev/null
    else
        echo -e "  ${RED}Unable to reach worlds.blackroad.io${NC}"
    fi
}

cmd_ssh() {
    local node=$1
    [[ -z "$node" ]] && { echo "Usage: br fleet ssh <node>"; echo "Nodes: ${(k)FLEET_NODES}"; exit 1; }
    [[ -z "${FLEET_NODES[$node]}" ]] && { echo "Unknown node: $node. Valid: ${(k)FLEET_NODES}"; exit 1; }
    local user=${FLEET_USERS[$node]}
    local ip=${FLEET_NODES[$node]}
    echo -e "${CYAN}Connecting to $node ($ip)...${NC}"
    ssh -o StrictHostKeyChecking=no "$user@$ip"
}

show_help() {
    echo -e "${CYAN}BR Fleet — Multi-node Pi fleet management${NC}"
    echo ""
    echo "  br fleet status          - Show all nodes health + world counts"
    echo "  br fleet run <cmd>       - Run command on all nodes"
    echo "  br fleet sync            - Sync br CLI to all nodes"
    echo "  br fleet worlds          - Show world artifact feed"
    echo "  br fleet ssh <node>      - SSH into a specific node"
    echo ""
    echo "  Nodes: aria64 (192.168.4.38) · alice (192.168.4.49)"
}

case "$1" in
    status|"") cmd_status ;;
    run)       shift; cmd_run "$@" ;;
    sync)      cmd_sync ;;
    worlds)    cmd_worlds ;;
    ssh)       shift; cmd_ssh "$@" ;;
    help|-h|--help) show_help ;;
    *) echo "Unknown: $1"; show_help; exit 1 ;;
esac
