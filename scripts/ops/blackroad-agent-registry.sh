#!/bin/bash
# BlackRoad Agent Registry CLI
# Manage and query all BlackRoad agents (hardware + AI)

set -e

# Source SHA-2048 identity bridge
source ~/roadchain-identity.sh 2>/dev/null || true

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Database
REGISTRY_DB="${HOME}/.blackroad-agent-registry.db"

# Initialize database
init_db() {
    sqlite3 "$REGISTRY_DB" <<EOF
CREATE TABLE IF NOT EXISTS agents (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE NOT NULL,
    type TEXT NOT NULL,  -- hardware, ai, human
    platform TEXT,       -- raspberry_pi, claude, grok, etc.
    ip_local TEXT,
    ip_wireguard TEXT,
    role TEXT,
    status TEXT DEFAULT 'active',
    sha2048_fingerprint TEXT,
    sha2048_short TEXT,
    provider TEXT DEFAULT '',
    last_seen DATETIME,
    metadata TEXT,       -- JSON for extra data
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS agent_services (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    agent_id INTEGER,
    service_name TEXT,
    port INTEGER,
    status TEXT DEFAULT 'running',
    FOREIGN KEY (agent_id) REFERENCES agents(id)
);

CREATE TABLE IF NOT EXISTS agent_capabilities (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    agent_id INTEGER,
    capability TEXT,
    FOREIGN KEY (agent_id) REFERENCES agents(id)
);
EOF
    echo -e "${GREEN}Database initialized at ${REGISTRY_DB}${NC}"
}

# Register an agent
register() {
    local name="$1"
    local type="$2"
    local platform="${3:-unknown}"
    local ip="${4:-}"
    local role="${5:-general}"

    if [[ -z "$name" || -z "$type" ]]; then
        echo -e "${RED}Usage: $0 register <name> <type> [platform] [ip] [role]${NC}"
        echo "Types: hardware, ai, human"
        return 1
    fi

    # Compute SHA-2048 identity
    local sha2048="" sha2048_short="" provider_val=""
    if type sha2048_compute &>/dev/null; then
        sha2048=$(sha2048_compute "${name}-${type}-${platform}")
        sha2048_short="${sha2048:0:16}"
    fi
    provider_val="${platform:-unknown}"

    sqlite3 "$REGISTRY_DB" "INSERT OR REPLACE INTO agents (name, type, platform, ip_local, role, sha2048_fingerprint, sha2048_short, provider, last_seen, updated_at)
        VALUES ('$name', '$type', '$platform', '$ip', '$role', '$sha2048', '$sha2048_short', '$provider_val', datetime('now'), datetime('now'));"

    echo -e "${GREEN}Registered agent: ${WHITE}$name${NC}"
    echo -e "  Type:     $type"
    echo -e "  Platform: $platform"
    echo -e "  IP:       $ip"
    echo -e "  Role:     $role"
    echo -e "  SHA-2048: ${sha2048_short:-computing...} (2048-bit)"
}

# List all agents
list_agents() {
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║           🖤🛣️ BLACKROAD AGENT REGISTRY 🖤🛣️              ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo

    echo -e "${WHITE}=== HARDWARE AGENTS ===${NC}"
    sqlite3 -column -header "$REGISTRY_DB" "SELECT name, platform, ip_local, role, status FROM agents WHERE type='hardware' ORDER BY name;"
    echo

    echo -e "${WHITE}=== AI AGENTS ===${NC}"
    sqlite3 -column -header "$REGISTRY_DB" "SELECT name, platform, role, sha2048_short as identity, status FROM agents WHERE type='ai' ORDER BY name;"
    echo

    echo -e "${WHITE}=== HUMAN AGENTS ===${NC}"
    sqlite3 -column -header "$REGISTRY_DB" "SELECT name, role, status FROM agents WHERE type='human' ORDER BY name;"
}

# Show agent details
show() {
    local name="$1"
    if [[ -z "$name" ]]; then
        echo -e "${RED}Usage: $0 show <agent-name>${NC}"
        return 1
    fi

    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║           AGENT: ${WHITE}${name}${CYAN}${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"

    sqlite3 -line "$REGISTRY_DB" "SELECT * FROM agents WHERE name='$name';"
}

# Ping hardware agents
ping_all() {
    echo -e "${CYAN}Pinging all hardware agents...${NC}"
    echo

    local agents=$(sqlite3 "$REGISTRY_DB" "SELECT name, ip_local FROM agents WHERE type='hardware' AND ip_local IS NOT NULL AND ip_local != '';")

    while IFS='|' read -r name ip; do
        if [[ -n "$ip" ]]; then
            echo -n -e "  ${WHITE}$name${NC} ($ip): "
            if ping -c 1 -W 1 "$ip" &>/dev/null; then
                echo -e "${GREEN}ONLINE${NC}"
                sqlite3 "$REGISTRY_DB" "UPDATE agents SET status='active', last_seen=datetime('now') WHERE name='$name';"
            else
                echo -e "${RED}OFFLINE${NC}"
                sqlite3 "$REGISTRY_DB" "UPDATE agents SET status='offline' WHERE name='$name';"
            fi
        fi
    done <<< "$agents"
}

# SSH into agent
connect() {
    local name="$1"
    if [[ -z "$name" ]]; then
        echo -e "${RED}Usage: $0 connect <agent-name>${NC}"
        return 1
    fi

    local ip=$(sqlite3 "$REGISTRY_DB" "SELECT ip_local FROM agents WHERE name='$name' AND type='hardware';")

    if [[ -n "$ip" ]]; then
        echo -e "${GREEN}Connecting to ${WHITE}$name${GREEN} at ${ip}...${NC}"
        # Use hostname-based user (alice@alice, cecilia@cecilia, etc.)
        local user=$(sqlite3 "$REGISTRY_DB" "SELECT LOWER(name) FROM agents WHERE name='$name';")
        ssh "${user}@${ip}"
    else
        echo -e "${RED}Agent not found or not a hardware agent: $name${NC}"
        return 1
    fi
}

# Show statistics
stats() {
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║           📊 AGENT REGISTRY STATISTICS 📊                 ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo

    local total=$(sqlite3 "$REGISTRY_DB" "SELECT COUNT(*) FROM agents;")
    local hardware=$(sqlite3 "$REGISTRY_DB" "SELECT COUNT(*) FROM agents WHERE type='hardware';")
    local ai=$(sqlite3 "$REGISTRY_DB" "SELECT COUNT(*) FROM agents WHERE type='ai';")
    local human=$(sqlite3 "$REGISTRY_DB" "SELECT COUNT(*) FROM agents WHERE type='human';")
    local active=$(sqlite3 "$REGISTRY_DB" "SELECT COUNT(*) FROM agents WHERE status='active';")

    echo -e "${WHITE}Total Agents:${NC}    $total"
    echo -e "${WHITE}Hardware:${NC}        $hardware"
    echo -e "${WHITE}AI:${NC}              $ai"
    echo -e "${WHITE}Human:${NC}           $human"
    echo -e "${GREEN}Active:${NC}          $active"
}

# Seed initial data
seed() {
    echo -e "${CYAN}Seeding BlackRoad agent registry...${NC}"

    # Human
    register "Alexandria" "human" "human_in_the_loop" "" "founder_ceo"

    # AI Agents
    register "Cecilia" "ai" "claude" "" "primary_ai_partner"
    register "Cadence" "ai" "chatgpt" "" "creative_ai"
    register "Silas" "ai" "grok" "" "analyst_ai"
    register "Gematria" "ai" "gemini" "" "research_ai"

    # Hardware Agents
    register "Alice" "hardware" "raspberry_pi_5" "192.168.4.49" "gateway"
    register "Aria" "hardware" "raspberry_pi_5" "192.168.4.64" "api_services"
    register "Octavia" "hardware" "raspberry_pi_5" "192.168.4.74" "ai_inference"
    register "Olympia" "hardware" "raspberry_pi_5" "" "ai_inference_secondary"
    register "Lucidia" "hardware" "raspberry_pi_4b" "192.168.4.38" "legacy_services"
    register "Anastasia" "hardware" "raspberry_pi_400" "" "development"
    register "Shellfish" "hardware" "digitalocean" "174.138.44.45" "cloud_infrastructure"

    echo
    echo -e "${GREEN}Registry seeded with 11 agents!${NC}"
}

# Export to JSON
export_json() {
    echo -e "${CYAN}Exporting registry to JSON...${NC}"
    sqlite3 -json "$REGISTRY_DB" "SELECT * FROM agents;" > "${HOME}/blackroad-agents.json"
    echo -e "${GREEN}Exported to ~/blackroad-agents.json${NC}"
}

# Help
show_help() {
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║        🖤🛣️ BLACKROAD AGENT REGISTRY CLI 🖤🛣️            ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${WHITE}Usage:${NC} $0 <command> [args]"
    echo
    echo -e "${WHITE}Commands:${NC}"
    echo -e "  ${GREEN}init${NC}                    Initialize the database"
    echo -e "  ${GREEN}seed${NC}                    Seed with BlackRoad agents"
    echo -e "  ${GREEN}register${NC} <n> <t> [p] [i] [r]  Register new agent"
    echo -e "  ${GREEN}list${NC}                    List all agents"
    echo -e "  ${GREEN}show${NC} <name>             Show agent details"
    echo -e "  ${GREEN}ping${NC}                    Ping all hardware agents"
    echo -e "  ${GREEN}connect${NC} <name>          SSH into hardware agent"
    echo -e "  ${GREEN}stats${NC}                   Show statistics"
    echo -e "  ${GREEN}export${NC}                  Export to JSON"
    echo -e "  ${GREEN}help${NC}                    Show this help"
    echo
    echo -e "${WHITE}Agent Types:${NC} hardware, ai, human"
    echo
    echo -e "${WHITE}Examples:${NC}"
    echo -e "  $0 init && $0 seed    # First time setup"
    echo -e "  $0 list               # Show all agents"
    echo -e "  $0 connect alice      # SSH to Alice"
    echo -e "  $0 ping               # Check which agents are online"
}

# Show identity for an agent
show_identity() {
    local name="$1"
    if [[ -z "$name" ]]; then
        echo -e "${RED}Usage: $0 identity <agent-name>${NC}"
        return 1
    fi

    local sha2048=$(sqlite3 "$REGISTRY_DB" "SELECT sha2048_fingerprint FROM agents WHERE name='$name';")
    local sha2048_short=$(sqlite3 "$REGISTRY_DB" "SELECT sha2048_short FROM agents WHERE name='$name';")
    local provider=$(sqlite3 "$REGISTRY_DB" "SELECT provider FROM agents WHERE name='$name';")

    if [[ -z "$sha2048" ]]; then
        echo -e "${YELLOW}No SHA-2048 identity for $name. Computing...${NC}"
        if type sha2048_compute &>/dev/null; then
            sha2048=$(sha2048_compute "${name}")
            sha2048_short="${sha2048:0:16}"
            sqlite3 "$REGISTRY_DB" "UPDATE agents SET sha2048_fingerprint='$sha2048', sha2048_short='$sha2048_short' WHERE name='$name';"
            echo -e "${GREEN}SHA-2048 computed and stored.${NC}"
        fi
    fi

    if type identity_banner &>/dev/null && [[ -n "$sha2048" ]]; then
        identity_banner "$name" "$sha2048" "${provider:-sovereign}"
    else
        echo -e "${WHITE}Agent:${NC}    $name"
        echo -e "${CYAN}SHA-2048:${NC} $sha2048_short"
        echo -e "${CYAN}Provider:${NC} ${provider:-unknown}"
    fi
}

# Main
case "${1:-help}" in
    init) init_db ;;
    seed) seed ;;
    register) register "$2" "$3" "$4" "$5" "$6" ;;
    list) list_agents ;;
    show) show "$2" ;;
    identity) show_identity "$2" ;;
    ping) ping_all ;;
    connect) connect "$2" ;;
    stats) stats ;;
    export) export_json ;;
    help|*) show_help ;;
esac
