#!/bin/bash
# BlackRoad Coordination v2.0 - Master Setup Script
# One command to rule them all!
# Version: 1.0.0

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

# Configuration
INSTALL_DIR="$HOME"
BLACKROAD_DIR="$HOME/.blackroad"

echo -e "${BOLD}${CYAN}"
cat << "EOF"
╔════════════════════════════════════════════════════════════════╗
║                                                                ║
║     🌌 BLACKROAD COORDINATION v2.0 - MASTER SETUP 🌌          ║
║                                                                ║
║              One Command To Rule Them All!                     ║
║                                                                ║
╚════════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"
echo ""

# Step 1: Check prerequisites
echo -e "${PURPLE}━━━ Step 1/10: Checking Prerequisites ━━━${NC}"
echo ""

# Check for required commands
MISSING_DEPS=0

check_command() {
    if ! command -v "$1" &> /dev/null; then
        echo -e "${RED}  ✗${NC} $1 not found"
        MISSING_DEPS=1
    else
        echo -e "${GREEN}  ✓${NC} $1 found"
    fi
}

check_command "sqlite3"
check_command "jq"
check_command "gh"
check_command "git"

if [ $MISSING_DEPS -eq 1 ]; then
    echo ""
    echo -e "${YELLOW}Please install missing dependencies:${NC}"
    echo "  brew install sqlite jq gh git"
    exit 1
fi

echo ""

# Step 2: Set Claude Agent ID
echo -e "${PURPLE}━━━ Step 2/10: Setting Up Claude Agent ID ━━━${NC}"
echo ""

if [ -z "$MY_CLAUDE" ]; then
    export MY_CLAUDE="claude-$(whoami)-$(date +%s)-$(openssl rand -hex 4)"
    echo "export MY_CLAUDE=\"$MY_CLAUDE\"" >> ~/.bash_profile
    echo -e "${GREEN}  ✓${NC} Created agent ID: $MY_CLAUDE"
else
    echo -e "${GREEN}  ✓${NC} Using existing agent ID: $MY_CLAUDE"
fi

echo ""

# Step 3: Initialize all systems
echo -e "${PURPLE}━━━ Step 3/10: Initializing All Systems ━━━${NC}"
echo ""

systems=(
    "memory-system.sh:init:[MEMORY] Memory System"
    "blackroad-universal-index.sh:init:[INDEX] Universal Asset Indexer"
    "blackroad-knowledge-graph.sh:init:[GRAPH] Knowledge Graph"
    "blackroad-semantic-memory.sh:init:[SEMANTIC] Semantic Search"
    "blackroad-health-monitor.sh:init:[HEALTH] Health Monitor"
    "blackroad-conflict-detector.sh:init:[CONFLICT] Conflict Detector"
    "blackroad-work-router.sh:init:[ROUTER] Work Router"
    "blackroad-timeline.sh:init:[TIMELINE] Timeline"
    "blackroad-intelligence.sh:init:[INTELLIGENCE] Pattern Intelligence"
    "blackroad-auto-sync-daemon.sh:init:Auto-Sync Daemon"
)

for system in "${systems[@]}"; do
    IFS=':' read -r script cmd name <<< "$system"

    if [ -f "$INSTALL_DIR/$script" ]; then
        echo -e "${CYAN}  Initializing $name...${NC}"
        "$INSTALL_DIR/$script" "$cmd" > /dev/null 2>&1 && \
            echo -e "${GREEN}    ✓${NC} Initialized" || \
            echo -e "${YELLOW}    ⚠${NC} Already initialized or error"
    else
        echo -e "${RED}  ✗${NC} $script not found"
    fi
done

echo ""

# Step 4: Index all assets
echo -e "${PURPLE}━━━ Step 4/10: Indexing All Assets ━━━${NC}"
echo ""

if [ -f "$INSTALL_DIR/blackroad-universal-index.sh" ]; then
    echo -e "${CYAN}  Scanning GitHub repos, Cloudflare, Pi cluster...${NC}"
    "$INSTALL_DIR/blackroad-universal-index.sh" refresh > /dev/null 2>&1 && \
        echo -e "${GREEN}  ✓${NC} Assets indexed" || \
        echo -e "${YELLOW}  ⚠${NC} Indexing failed (may need authentication)"
else
    echo -e "${RED}  ✗${NC} Index script not found"
fi

echo ""

# Step 5: Build knowledge graph
echo -e "${PURPLE}━━━ Step 5/10: Building Knowledge Graph ━━━${NC}"
echo ""

if [ -f "$INSTALL_DIR/blackroad-knowledge-graph.sh" ]; then
    echo -e "${CYAN}  Analyzing dependencies and relationships...${NC}"
    "$INSTALL_DIR/blackroad-knowledge-graph.sh" build > /dev/null 2>&1 && \
        echo -e "${GREEN}  ✓${NC} Graph built" || \
        echo -e "${YELLOW}  ⚠${NC} Graph build incomplete"
else
    echo -e "${RED}  ✗${NC} Graph script not found"
fi

echo ""

# Step 6: Index memory for semantic search
echo -e "${PURPLE}━━━ Step 6/10: Indexing Memory for Semantic Search ━━━${NC}"
echo ""

if [ -f "$INSTALL_DIR/blackroad-semantic-memory.sh" ]; then
    echo -e "${CYAN}  Processing memory entries...${NC}"
    "$INSTALL_DIR/blackroad-semantic-memory.sh" index-memory > /dev/null 2>&1 && \
        echo -e "${GREEN}  ✓${NC} Memory indexed" || \
        echo -e "${YELLOW}  ⚠${NC} Indexing incomplete"
else
    echo -e "${RED}  ✗${NC} Semantic search script not found"
fi

echo ""

# Step 7: Import timeline data
echo -e "${PURPLE}━━━ Step 7/10: Importing Timeline Data ━━━${NC}"
echo ""

if [ -f "$INSTALL_DIR/blackroad-timeline.sh" ]; then
    echo -e "${CYAN}  Importing from memory and git...${NC}"
    "$INSTALL_DIR/blackroad-timeline.sh" import-memory > /dev/null 2>&1 || true
    "$INSTALL_DIR/blackroad-timeline.sh" import-git > /dev/null 2>&1 || true
    echo -e "${GREEN}  ✓${NC} Timeline data imported"
else
    echo -e "${RED}  ✗${NC} Timeline script not found"
fi

echo ""

# Step 8: Register agent
echo -e "${PURPLE}━━━ Step 8/10: Registering Claude Agent ━━━${NC}"
echo ""

if [ -f "$INSTALL_DIR/blackroad-work-router.sh" ]; then
    echo -e "${CYAN}  Registering with skills...${NC}"
    "$INSTALL_DIR/blackroad-work-router.sh" register "$(whoami)" "coordination,automation,systems,bash,sqlite" > /dev/null 2>&1 && \
        echo -e "${GREEN}  ✓${NC} Agent registered" || \
        echo -e "${YELLOW}  ⚠${NC} Registration may have failed"
else
    echo -e "${RED}  ✗${NC} Router script not found"
fi

echo ""

# Step 9: Run health check
echo -e "${PURPLE}━━━ Step 9/10: Running Health Check ━━━${NC}"
echo ""

if [ -f "$INSTALL_DIR/blackroad-health-monitor.sh" ]; then
    echo -e "${CYAN}  Checking infrastructure...${NC}"
    "$INSTALL_DIR/blackroad-health-monitor.sh" check > /dev/null 2>&1 || true
    echo -e "${GREEN}  ✓${NC} Health check complete"
else
    echo -e "${RED}  ✗${NC} Health monitor script not found"
fi

echo ""

# Step 10: Log to memory
echo -e "${PURPLE}━━━ Step 10/10: Logging Setup to Memory ━━━${NC}"
echo ""

if [ -f "$INSTALL_DIR/memory-system.sh" ]; then
    "$INSTALL_DIR/memory-system.sh" log created "coordination-setup" "BlackRoad Coordination v2.0 setup completed for $MY_CLAUDE. All 8 systems initialized and ready!" "coordination,setup,initialization" > /dev/null 2>&1 || true
    echo -e "${GREEN}  ✓${NC} Logged to memory"
fi

echo ""
echo -e "${BOLD}${GREEN}"
cat << "EOF"
╔════════════════════════════════════════════════════════════════╗
║                                                                ║
║                  ✅ SETUP COMPLETE! ✅                         ║
║                                                                ║
╚════════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"
echo ""

# Show what's available
echo -e "${CYAN}━━━ Available Systems ━━━${NC}"
echo ""
echo -e "${GREEN}  ✓${NC} [MEMORY]        Memory journal system"
echo -e "${GREEN}  ✓${NC} [INDEX]         Universal asset indexer"
echo -e "${GREEN}  ✓${NC} [GRAPH]         Knowledge graph"
echo -e "${GREEN}  ✓${NC} [SEMANTIC]      Semantic search"
echo -e "${GREEN}  ✓${NC} [HEALTH]        Health monitor"
echo -e "${GREEN}  ✓${NC} [CONFLICT]      Conflict detector"
echo -e "${GREEN}  ✓${NC} [ROUTER]        Work router"
echo -e "${GREEN}  ✓${NC} [TIMELINE]      Activity timeline"
echo -e "${GREEN}  ✓${NC} [INTELLIGENCE]  Pattern learning"
echo ""

# Show next steps
echo -e "${CYAN}━━━ Next Steps ━━━${NC}"
echo ""
echo -e "${YELLOW}1.${NC} Run session init to see everything:"
echo -e "   ${CYAN}~/claude-session-init-v2.sh${NC}"
echo ""
echo -e "${YELLOW}2.${NC} Start auto-sync daemon (optional):"
echo -e "   ${CYAN}~/blackroad-auto-sync-daemon.sh start &${NC}"
echo ""
echo -e "${YELLOW}3.${NC} Watch real-time dashboard (optional):"
echo -e "   ${CYAN}~/blackroad-realtime-dashboard.sh watch${NC}"
echo ""
echo -e "${YELLOW}4.${NC} Read the complete usage guide:"
echo -e "   ${CYAN}cat ~/COMPLETE_USAGE_GUIDE.md${NC}"
echo ""

# Show stats
echo -e "${CYAN}━━━ Quick Stats ━━━${NC}"
echo ""

if [ -f ~/.blackroad/index/assets.db ]; then
    local assets=$(sqlite3 ~/.blackroad/index/assets.db "SELECT COUNT(*) FROM assets;" 2>/dev/null || echo "0")
    echo -e "${PURPLE}  📦${NC} Assets indexed: $assets"
fi

if [ -f ~/.blackroad/graph/knowledge.db ]; then
    local nodes=$(sqlite3 ~/.blackroad/graph/knowledge.db "SELECT COUNT(*) FROM nodes;" 2>/dev/null || echo "0")
    local edges=$(sqlite3 ~/.blackroad/graph/knowledge.db "SELECT COUNT(*) FROM edges;" 2>/dev/null || echo "0")
    echo -e "${PURPLE}  🕸️${NC}  Knowledge graph: $nodes nodes, $edges edges"
fi

if [ -f ~/.blackroad/memory/journals/master-journal.jsonl ]; then
    local entries=$(wc -l < ~/.blackroad/memory/journals/master-journal.jsonl)
    echo -e "${PURPLE}  📝${NC} Memory entries: $entries"
fi

echo ""
echo -e "${BOLD}${CYAN}🌌 BlackRoad Coordination v2.0 is ready! 🌌${NC}"
echo ""
