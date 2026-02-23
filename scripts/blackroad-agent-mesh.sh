#!/usr/bin/env bash
# BlackRoad Unified Agent Mesh
# Connects: Ollama (local) ↔ Cloudflare (KV/D1) ↔ Edge Devices ↔ GitHub

set -e

MESH_VERSION="1.0.0"
CLOUDFLARE_KV="blackroad-router-AGENTS"
D1_DATABASE="apollo-agent-registry"
LOCAL_REGISTRY="$HOME/.blackroad-agent-registry.db"
OLLAMA_HOST="${OLLAMA_HOST:-http://localhost:11434}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Edge devices (name:ip pairs)
EDGE_ALICE="192.168.4.49"
EDGE_LUCIDIA="192.168.4.38"
EDGE_ARIA="192.168.4.82"
EDGE_CODEX="159.65.43.12"
EDGE_SHELLFISH="174.138.44.45"

get_edge_ip() {
    case "$1" in
        alice) echo "$EDGE_ALICE" ;;
        lucidia) echo "$EDGE_LUCIDIA" ;;
        aria) echo "$EDGE_ARIA" ;;
        codex-infinity|codex) echo "$EDGE_CODEX" ;;
        shellfish) echo "$EDGE_SHELLFISH" ;;
        *) echo "" ;;
    esac
}

show_banner() {
    echo -e "${MAGENTA}"
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║          BLACKROAD UNIFIED AGENT MESH v${MESH_VERSION}              ║"
    echo "║   Ollama ↔ Cloudflare ↔ Edge Devices ↔ GitHub                ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# ═══════════════════════════════════════════════════════════════
# OLLAMA FUNCTIONS
# ═══════════════════════════════════════════════════════════════

ollama_list() {
    echo -e "${CYAN}[OLLAMA] Local Models:${NC}"
    ollama list 2>/dev/null | head -20
    echo -e "${YELLOW}... $(ollama list 2>/dev/null | wc -l) total models${NC}"
}

ollama_run() {
    local model="$1"
    local prompt="$2"

    echo -e "${CYAN}[OLLAMA] Running ${model}...${NC}"
    ollama run "$model" "$prompt" 2>/dev/null
}

ollama_api() {
    local model="$1"
    local prompt="$2"

    curl -s "${OLLAMA_HOST}/api/generate" \
        -d "{\"model\": \"$model\", \"prompt\": \"$prompt\", \"stream\": false}" \
        | jq -r '.response' 2>/dev/null
}

# ═══════════════════════════════════════════════════════════════
# CLOUDFLARE FUNCTIONS
# ═══════════════════════════════════════════════════════════════

cf_sync_agent() {
    local agent_name="$1"
    local status="$2"
    local metadata="$3"

    echo -e "${BLUE}[CLOUDFLARE] Syncing agent: ${agent_name}${NC}"

    # Sync to KV
    wrangler kv key put --namespace-id="$(cf_get_kv_id)" \
        "agent:${agent_name}" \
        "{\"name\":\"${agent_name}\",\"status\":\"${status}\",\"updated\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"metadata\":${metadata:-{}}}" \
        2>/dev/null && echo -e "${GREEN}  ✓ KV synced${NC}" || echo -e "${RED}  ✗ KV failed${NC}"
}

cf_get_kv_id() {
    wrangler kv namespace list 2>/dev/null | jq -r '.[] | select(.title=="blackroad-router-AGENTS") | .id' 2>/dev/null
}

cf_list_agents() {
    echo -e "${BLUE}[CLOUDFLARE] Agents in KV:${NC}"
    local kv_id=$(cf_get_kv_id)
    if [ -n "$kv_id" ]; then
        wrangler kv key list --namespace-id="$kv_id" 2>/dev/null | jq -r '.[].name' | grep "^agent:" | sed 's/agent:/  - /'
    else
        echo "  (KV namespace not found)"
    fi
}

cf_call_worker() {
    local endpoint="$1"
    local payload="$2"

    echo -e "${BLUE}[CLOUDFLARE] Calling worker: ${endpoint}${NC}"
    curl -s -X POST "https://blackroad-agents.blackroad.workers.dev${endpoint}" \
        -H "Content-Type: application/json" \
        -d "$payload"
}

# ═══════════════════════════════════════════════════════════════
# EDGE DEVICE FUNCTIONS
# ═══════════════════════════════════════════════════════════════

edge_check_all() {
    echo -e "${GREEN}[EDGE] Checking devices:${NC}"
    for name in alice lucidia aria codex-infinity shellfish; do
        local ip=$(get_edge_ip "$name")
        if ping -c 1 -W 1 "$ip" &>/dev/null; then
            echo -e "  ${GREEN}✓${NC} $name ($ip) - online"
        else
            echo -e "  ${RED}✗${NC} $name ($ip) - offline"
        fi
    done
}

edge_run_ollama() {
    local device="$1"
    local model="$2"
    local prompt="$3"

    local ip=$(get_edge_ip "$device")
    if [ -z "$ip" ]; then
        echo -e "${RED}Unknown device: $device${NC}"
        return 1
    fi

    echo -e "${GREEN}[EDGE] Running on ${device} (${ip})...${NC}"
    ssh -o ConnectTimeout=5 "$ip" "ollama run '$model' '$prompt'" 2>/dev/null
}

edge_list_models() {
    local device="$1"
    local ip=$(get_edge_ip "$device")

    echo -e "${GREEN}[EDGE] Models on ${device}:${NC}"
    ssh -o ConnectTimeout=5 "$ip" "ollama list" 2>/dev/null || echo "  (unreachable)"
}

# ═══════════════════════════════════════════════════════════════
# GITHUB FUNCTIONS
# ═══════════════════════════════════════════════════════════════

gh_trigger_agent() {
    local repo="$1"
    local workflow="$2"
    local inputs="$3"

    echo -e "${YELLOW}[GITHUB] Triggering ${workflow} on ${repo}...${NC}"
    gh workflow run "$workflow" -R "$repo" -f "$inputs" 2>/dev/null \
        && echo -e "${GREEN}  ✓ Workflow triggered${NC}" \
        || echo -e "${RED}  ✗ Trigger failed${NC}"
}

gh_list_agent_workflows() {
    echo -e "${YELLOW}[GITHUB] Agent workflows:${NC}"
    gh workflow list -R BlackRoad-OS/blackroad-os-agents 2>/dev/null | grep -i agent
}

# ═══════════════════════════════════════════════════════════════
# LOCAL REGISTRY FUNCTIONS
# ═══════════════════════════════════════════════════════════════

local_list_agents() {
    echo -e "${MAGENTA}[LOCAL] Registered agents:${NC}"
    sqlite3 "$LOCAL_REGISTRY" "SELECT name, type, status FROM agents ORDER BY name;" 2>/dev/null \
        | while IFS='|' read -r name type status; do
            case "$status" in
                active) echo -e "  ${GREEN}●${NC} $name ($type)" ;;
                offline) echo -e "  ${RED}●${NC} $name ($type)" ;;
                *) echo -e "  ${YELLOW}●${NC} $name ($type) - $status" ;;
            esac
        done
}

local_register_agent() {
    local name="$1"
    local type="$2"

    sqlite3 "$LOCAL_REGISTRY" "INSERT OR REPLACE INTO agents (name, type, status, created_at) VALUES ('$name', '$type', 'active', datetime('now'));" 2>/dev/null
    echo -e "${GREEN}Registered: $name ($type)${NC}"
}

# ═══════════════════════════════════════════════════════════════
# UNIFIED MESH FUNCTIONS
# ═══════════════════════════════════════════════════════════════

mesh_status() {
    show_banner
    echo ""

    echo -e "${CYAN}━━━ OLLAMA (Local) ━━━${NC}"
    local model_count=$(ollama list 2>/dev/null | wc -l)
    echo -e "  Models: ${GREEN}$model_count${NC}"
    echo -e "  Host: ${OLLAMA_HOST}"
    echo ""

    echo -e "${BLUE}━━━ CLOUDFLARE ━━━${NC}"
    local kv_count=$(wrangler kv namespace list 2>/dev/null | jq 'length')
    local d1_count=$(wrangler d1 list 2>/dev/null | grep -c "blackroad" || echo "0")
    echo -e "  KV Namespaces: ${GREEN}${kv_count:-0}${NC}"
    echo -e "  D1 Databases: ${GREEN}${d1_count}${NC}"
    echo ""

    echo -e "${GREEN}━━━ EDGE DEVICES ━━━${NC}"
    local online=0
    local total=5
    for name in alice lucidia aria codex-infinity shellfish; do
        local ip=$(get_edge_ip "$name")
        ping -c 1 -W 1 "$ip" &>/dev/null && ((online++)) || true
    done
    echo -e "  Online: ${GREEN}${online}${NC}/${total}"
    echo ""

    echo -e "${YELLOW}━━━ GITHUB ━━━${NC}"
    local org_count=$(gh api user/memberships/orgs 2>/dev/null | jq 'length')
    echo -e "  Organizations: ${GREEN}${org_count:-0}${NC}"
    echo ""

    echo -e "${MAGENTA}━━━ LOCAL REGISTRY ━━━${NC}"
    local agent_count=$(sqlite3 "$LOCAL_REGISTRY" "SELECT COUNT(*) FROM agents;" 2>/dev/null || echo "0")
    echo -e "  Agents: ${GREEN}${agent_count}${NC}"
}

mesh_sync_all() {
    echo -e "${MAGENTA}[MESH] Syncing all agents to Cloudflare...${NC}"

    sqlite3 "$LOCAL_REGISTRY" "SELECT name, type, status FROM agents;" 2>/dev/null \
        | while IFS='|' read -r name type status; do
            cf_sync_agent "$name" "$status" "{\"type\":\"$type\",\"source\":\"local\"}"
        done

    echo -e "${GREEN}[MESH] Sync complete!${NC}"
}

mesh_ask() {
    local agent="$1"
    local prompt="$2"

    if [ -z "$agent" ] || [ -z "$prompt" ]; then
        echo "Usage: mesh ask <agent> <prompt>"
        return 1
    fi

    show_banner
    echo -e "${CYAN}Asking ${agent}: ${prompt}${NC}"
    echo ""

    # Try local Ollama first
    if ollama list 2>/dev/null | grep -qi "^${agent}:"; then
        echo -e "${GREEN}[LOCAL OLLAMA]${NC}"
        ollama_api "$agent" "$prompt"
        return
    fi

    # Try edge devices
    for device in alice lucidia aria codex-infinity shellfish; do
        local ip=$(get_edge_ip "$device")
        if ping -c 1 -W 1 "$ip" &>/dev/null; then
            echo -e "${GREEN}[EDGE: $device]${NC}"
            edge_run_ollama "$device" "$agent" "$prompt" && return
        fi
    done

    # Fallback to Cloudflare worker
    echo -e "${BLUE}[CLOUDFLARE WORKER]${NC}"
    cf_call_worker "/agent" "{\"request\":\"$prompt\",\"agent\":\"$agent\"}"
}

# ═══════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════

case "${1:-status}" in
    status)
        mesh_status
        ;;
    sync)
        mesh_sync_all
        ;;
    ask)
        mesh_ask "$2" "${*:3}"
        ;;
    ollama)
        case "$2" in
            list) ollama_list ;;
            run) ollama_run "$3" "${*:4}" ;;
            api) ollama_api "$3" "${*:4}" ;;
            *) echo "Usage: $0 ollama [list|run|api]" ;;
        esac
        ;;
    cloudflare|cf)
        case "$2" in
            sync) cf_sync_agent "$3" "$4" "$5" ;;
            list) cf_list_agents ;;
            call) cf_call_worker "$3" "$4" ;;
            *) echo "Usage: $0 cf [sync|list|call]" ;;
        esac
        ;;
    edge)
        case "$2" in
            check) edge_check_all ;;
            run) edge_run_ollama "$3" "$4" "${*:5}" ;;
            models) edge_list_models "$3" ;;
            *) echo "Usage: $0 edge [check|run|models]" ;;
        esac
        ;;
    github|gh)
        case "$2" in
            trigger) gh_trigger_agent "$3" "$4" "$5" ;;
            workflows) gh_list_agent_workflows ;;
            *) echo "Usage: $0 gh [trigger|workflows]" ;;
        esac
        ;;
    local)
        case "$2" in
            list) local_list_agents ;;
            register) local_register_agent "$3" "$4" ;;
            *) echo "Usage: $0 local [list|register]" ;;
        esac
        ;;
    help|--help|-h)
        show_banner
        echo "Commands:"
        echo "  status              Show mesh status across all platforms"
        echo "  sync                Sync local agents to Cloudflare"
        echo "  ask <agent> <text>  Ask an agent (auto-routes to best source)"
        echo ""
        echo "  ollama list         List local Ollama models"
        echo "  ollama run <m> <p>  Run model with prompt"
        echo "  ollama api <m> <p>  Call Ollama API"
        echo ""
        echo "  cf list             List agents in Cloudflare KV"
        echo "  cf sync <n> <s> <m> Sync agent to Cloudflare"
        echo "  cf call <ep> <json> Call Cloudflare worker"
        echo ""
        echo "  edge check          Check all edge devices"
        echo "  edge run <d> <m> <p> Run Ollama on edge device"
        echo "  edge models <d>     List models on edge device"
        echo ""
        echo "  gh workflows        List agent workflows"
        echo "  gh trigger <r> <w>  Trigger workflow"
        echo ""
        echo "  local list          List registered agents"
        echo "  local register <n>  Register new agent"
        ;;
    *)
        echo "Unknown command: $1"
        echo "Run '$0 help' for usage"
        ;;
esac
