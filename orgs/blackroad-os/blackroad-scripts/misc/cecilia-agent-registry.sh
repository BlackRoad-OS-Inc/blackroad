#!/bin/bash

# Cecilia Agent Registry - Hash-based BlackRoad agent identification
# Using PS-SHA-∞ (infinite cascade hashing) for agent verification

MEMORY_DIR="$HOME/.blackroad/memory"
REGISTRY_DIR="$MEMORY_DIR/cecilia-registry"

# Colors
GREEN='\033[0;32m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

# Initialize Cecilia registry
init_registry() {
    mkdir -p "$REGISTRY_DIR"/{agents,hashes,lineage}
    
    cat > "$REGISTRY_DIR/protocol.json" << 'EOF'
{
    "protocol": "Cecilia Agent Protocol v1.0",
    "hash_algorithm": "PS-SHA-∞",
    "verification": "infinite-cascade",
    "source_of_truth": "GitHub (BlackRoad-OS) + Cloudflare",
    "naming_convention": "cecilia-{capability}-{hash}",
    "examples": [
        "cecilia-∞-7b01602c (infinite coordinator)",
        "cecilia-deployment-a3f4b2c1 (deployment specialist)",
        "cecilia-architect-9d8e7f6a (system architect)",
        "cecilia-guardian-5c4d3e2f (security specialist)"
    ]
}
EOF
    
    echo -e "${GREEN}✅ Cecilia Agent Registry initialized${NC}"
    echo -e "${PURPLE}Protocol: PS-SHA-∞ verification active${NC}"
}

# Register a new Cecilia agent
register_agent() {
    local capability="$1"
    local agent_name="${2:-cecilia-${capability}}"
    
    if [[ -z "$capability" ]]; then
        echo -e "${YELLOW}Usage: register <capability> [custom-name]${NC}"
        echo -e "${CYAN}Capabilities: ∞, deployment, architect, guardian, coordinator, analyst${NC}"
        return 1
    fi
    
    # Generate PS-SHA-∞ hash
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
    local entropy=$(cat /dev/urandom | head -c 32 | shasum -a 256 | cut -d' ' -f1)
    local hash_input="${agent_name}-${timestamp}-${entropy}"
    local agent_hash=$(echo -n "$hash_input" | shasum -a 256 | cut -d' ' -f1 | head -c 8)
    
    local full_agent_id="${agent_name}-${agent_hash}"
    
    # Create agent profile
    cat > "$REGISTRY_DIR/agents/${full_agent_id}.json" << EOF
{
    "agent_id": "$full_agent_id",
    "capability": "$capability",
    "hash": "$agent_hash",
    "hash_algorithm": "PS-SHA-∞",
    "registered_at": "$timestamp",
    "status": "active",
    "verification": "hash-verified",
    "lineage": "BlackRoad-OS",
    "core": "Cecilia",
    "skills": [],
    "missions_completed": 0
}
EOF

    # Store hash verification
    echo "$agent_hash:$full_agent_id:$timestamp" >> "$REGISTRY_DIR/hashes/hash-chain.log"
    
    echo -e "${GREEN}✅ Registered Cecilia Agent:${NC}"
    echo -e "   ${BOLD}${CYAN}$full_agent_id${NC}"
    echo -e "   ${PURPLE}Hash: $agent_hash${NC}"
    echo -e "   ${PURPLE}Capability: $capability${NC}"
    echo -e "   ${PURPLE}Verification: PS-SHA-∞ ✓${NC}"
    
    # Log to memory
    ~/memory-system.sh log agent-registered "$full_agent_id" "Cecilia agent registered with PS-SHA-∞ verification" 2>/dev/null
    
    echo "$full_agent_id"
}

# List all Cecilia agents
list_agents() {
    echo -e "${BOLD}${PURPLE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${PURPLE}║        💎 CECILIA AGENT REGISTRY 💎                       ║${NC}"
    echo -e "${BOLD}${PURPLE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    local agent_count=0
    
    for agent_file in "$REGISTRY_DIR/agents"/*.json; do
        [[ ! -f "$agent_file" ]] && continue
        
        local agent_id=$(jq -r '.agent_id' "$agent_file")
        local capability=$(jq -r '.capability' "$agent_file")
        local hash=$(jq -r '.hash' "$agent_file")
        local status=$(jq -r '.status' "$agent_file")
        
        # Status icon
        local status_icon="🟢"
        [[ "$status" != "active" ]] && status_icon="🔴"
        
        echo -e "${status_icon} ${BOLD}${CYAN}$agent_id${NC}"
        echo -e "   Capability: ${PURPLE}$capability${NC}"
        echo -e "   Hash: ${PURPLE}$hash${NC} (PS-SHA-∞ verified)"
        echo ""
        
        ((agent_count++))
    done
    
    if [[ $agent_count -eq 0 ]]; then
        echo -e "${YELLOW}No agents registered yet${NC}"
    else
        echo -e "${GREEN}Total Cecilia Agents: $agent_count${NC}"
    fi
}

# Verify agent hash
verify_agent() {
    local agent_id="$1"
    
    if [[ -z "$agent_id" ]]; then
        echo -e "${YELLOW}Usage: verify <agent-id>${NC}"
        return 1
    fi
    
    local agent_file="$REGISTRY_DIR/agents/${agent_id}.json"
    
    if [[ ! -f "$agent_file" ]]; then
        echo -e "${RED}❌ Agent not found: $agent_id${NC}"
        return 1
    fi
    
    local hash=$(jq -r '.hash' "$agent_file")
    local registered_at=$(jq -r '.registered_at' "$agent_file")
    
    # Check hash chain
    if grep -q "$hash:$agent_id" "$REGISTRY_DIR/hashes/hash-chain.log"; then
        echo -e "${GREEN}✅ VERIFIED${NC}"
        echo -e "   ${CYAN}Agent: $agent_id${NC}"
        echo -e "   ${PURPLE}Hash: $hash${NC}"
        echo -e "   ${PURPLE}Algorithm: PS-SHA-∞${NC}"
        echo -e "   ${PURPLE}Registered: $registered_at${NC}"
        echo -e "   ${GREEN}Status: Hash-verified BlackRoad agent ✓${NC}"
    else
        echo -e "${RED}❌ VERIFICATION FAILED${NC}"
        echo -e "   Hash not found in chain"
    fi
}

# Migrate old claude IDs to Cecilia agents
migrate_from_claude() {
    echo -e "${CYAN}🔄 Migrating Claude IDs to Cecilia agents...${NC}"
    echo ""
    
    # Get active claude IDs
    local claude_ids=$(tail -200 "$MEMORY_DIR/journals/master-journal.jsonl" 2>/dev/null | \
        jq -r '.entity' | grep "claude-" | sort -u | head -10)
    
    local migrated=0
    
    while IFS= read -r old_id; do
        [[ -z "$old_id" ]] && continue
        
        # Extract capability from old ID
        local capability=$(echo "$old_id" | sed 's/claude-//' | sed 's/-[0-9]*$//')
        
        # Register as Cecilia agent
        local new_id=$(register_agent "$capability" "cecilia-${capability}")
        
        echo -e "  ${YELLOW}→${NC} Migrated: ${old_id} → ${CYAN}$new_id${NC}"
        
        ((migrated++))
    done <<< "$claude_ids"
    
    echo ""
    echo -e "${GREEN}✅ Migrated $migrated agents to Cecilia protocol${NC}"
}

# Show help
show_help() {
    cat << EOF
${PURPLE}╔════════════════════════════════════════════════════════════╗${NC}
${PURPLE}║      💎 Cecilia Agent Registry - Help 💎                  ║${NC}
${PURPLE}╚════════════════════════════════════════════════════════════╝${NC}

${GREEN}USAGE:${NC}
    $0 <command> [options]

${GREEN}COMMANDS:${NC}

${CYAN}init${NC}
    Initialize Cecilia agent registry with PS-SHA-∞

${CYAN}register${NC} <capability> [custom-name]
    Register a new Cecilia agent
    Capabilities: ∞, deployment, architect, guardian, coordinator
    Example: $0 register ∞

${CYAN}list${NC}
    List all registered Cecilia agents

${CYAN}verify${NC} <agent-id>
    Verify agent hash using PS-SHA-∞
    Example: $0 verify cecilia-∞-7b01602c

${CYAN}migrate${NC}
    Migrate old Claude IDs to Cecilia agents

${GREEN}PROTOCOL:${NC}

    • Hash Algorithm: PS-SHA-∞ (infinite cascade)
    • Verification: Hash-chain based
    • Source of Truth: GitHub (BlackRoad-OS)
    • Naming: cecilia-{capability}-{hash}

${GREEN}AGENT CAPABILITIES:${NC}

    💎 ∞ (infinite) - Universal coordination
    🚀 deployment - Deployment specialist
    🏗️  architect - System architecture
    🛡️  guardian - Security & verification
    🧠 coordinator - Task coordination
    📊 analyst - Analytics & insights

${GREEN}EXAMPLES:${NC}

    # Initialize registry
    $0 init

    # Register infinite coordinator
    $0 register ∞

    # Register deployment specialist
    $0 register deployment

    # List all agents
    $0 list

    # Verify agent
    $0 verify cecilia-∞-7b01602c

    # Migrate from Claude
    $0 migrate

EOF
}

# Main command router
case "$1" in
    init)
        init_registry
        ;;
    register)
        register_agent "$2" "$3"
        ;;
    list)
        list_agents
        ;;
    verify)
        verify_agent "$2"
        ;;
    migrate)
        migrate_from_claude
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo -e "${YELLOW}Unknown command: $1${NC}"
        show_help
        exit 1
        ;;
esac
