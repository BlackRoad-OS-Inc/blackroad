#!/bin/bash
# Complete BlackRoad Memory System Initialization
# Sets up analytics, indexing, codex, and all monitoring tools

MEMORY_DIR="$HOME/.blackroad/memory"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${PURPLE}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║   🌌 BlackRoad Memory System - Complete Initialization   ║
║                                                           ║
║   "The road remembers everything. So should we."         ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}\n"

# Check if memory system exists
if [ ! -d "$MEMORY_DIR" ]; then
    echo -e "${YELLOW}⚠️  Memory system not found. Creating...${NC}\n"
    mkdir -p "$MEMORY_DIR"
fi

# Initialize core components
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}   PHASE 1: Core Memory System${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}\n"

if [ -f ~/memory-system.sh ]; then
    echo -e "${GREEN}✓${NC} Initializing core memory system..."
    ~/memory-system.sh init 2>/dev/null || echo -e "${YELLOW}  Note: Core system may already be initialized${NC}"
else
    echo -e "${RED}✗${NC} Core memory system script not found"
fi

echo ""

# Initialize analytics
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}   PHASE 2: Analytics & Performance Tracking${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}\n"

if [ -f ~/memory-analytics.sh ]; then
    echo -e "${GREEN}✓${NC} Initializing analytics system..."
    ~/memory-analytics.sh init
else
    echo -e "${RED}✗${NC} Analytics script not found: ~/memory-analytics.sh"
fi

if [ -f ~/memory-enhanced-log.sh ]; then
    echo -e "${GREEN}✓${NC} Initializing performance tracking..."
    ~/memory-enhanced-log.sh init
else
    echo -e "${RED}✗${NC} Enhanced logging script not found: ~/memory-enhanced-log.sh"
fi

echo ""

# Initialize indexer
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}   PHASE 3: Indexing System${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}\n"

if [ -f ~/memory-indexer.sh ]; then
    echo -e "${GREEN}✓${NC} Initializing indexing system..."
    ~/memory-indexer.sh init

    # Build indexes if journal exists
    if [ -f "$MEMORY_DIR/journals/master-journal.jsonl" ]; then
        local entries=$(wc -l < "$MEMORY_DIR/journals/master-journal.jsonl")
        if [ "$entries" -gt 0 ]; then
            echo -e "${GREEN}✓${NC} Building indexes from $entries existing entries..."
            ~/memory-indexer.sh build
            ~/memory-indexer.sh knowledge
        fi
    fi
else
    echo -e "${RED}✗${NC} Indexer script not found: ~/memory-indexer.sh"
fi

echo ""

# Initialize codex
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}   PHASE 4: Knowledge Codex${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}\n"

if [ -f ~/memory-codex.sh ]; then
    echo -e "${GREEN}✓${NC} Initializing knowledge codex..."
    ~/memory-codex.sh init
else
    echo -e "${RED}✗${NC} Codex script not found: ~/memory-codex.sh"
fi

echo ""

# Create quick access aliases
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}   PHASE 5: Creating Quick Access Commands${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}\n"

# Create wrapper scripts for easy access
mkdir -p "$HOME/.blackroad/bin"

# Memory search wrapper
cat > "$HOME/.blackroad/bin/msearch" <<'WRAPPER'
#!/bin/bash
# Quick memory search
~/memory-query.sh search "$@"
WRAPPER

# Memory recent wrapper
cat > "$HOME/.blackroad/bin/mrecent" <<'WRAPPER'
#!/bin/bash
# Quick recent activity
~/memory-query.sh recent "${1:-10}"
WRAPPER

# Memory stats wrapper
cat > "$HOME/.blackroad/bin/mstats" <<'WRAPPER'
#!/bin/bash
# Quick memory statistics
~/memory-query.sh stats
WRAPPER

# Codex search wrapper
cat > "$HOME/.blackroad/bin/csearch" <<'WRAPPER'
#!/bin/bash
# Quick codex search
~/memory-codex.sh search "$@"
WRAPPER

# Codex recommend wrapper
cat > "$HOME/.blackroad/bin/crecommend" <<'WRAPPER'
#!/bin/bash
# Quick codex recommendations
~/memory-codex.sh recommend "$@"
WRAPPER

# Memory dashboard wrapper
cat > "$HOME/.blackroad/bin/mdash" <<'WRAPPER'
#!/bin/bash
# Open memory dashboard
open ~/memory-health-dashboard.html
WRAPPER

# Index lookup wrapper
cat > "$HOME/.blackroad/bin/ilookup" <<'WRAPPER'
#!/bin/bash
# Quick index lookup
~/memory-indexer.sh lookup-$1 "$2"
WRAPPER

chmod +x "$HOME/.blackroad/bin/"*

echo -e "${GREEN}✓${NC} Quick access commands created:"
echo -e "  ${CYAN}msearch${NC}    - Search memory"
echo -e "  ${CYAN}mrecent${NC}    - Recent activity"
echo -e "  ${CYAN}mstats${NC}     - Memory statistics"
echo -e "  ${CYAN}csearch${NC}    - Search codex"
echo -e "  ${CYAN}crecommend${NC} - Get recommendations"
echo -e "  ${CYAN}mdash${NC}      - Open dashboard"
echo -e "  ${CYAN}ilookup${NC}    - Index lookup"

echo ""

# Add to PATH if not already
if [[ ":$PATH:" != *":$HOME/.blackroad/bin:"* ]]; then
    echo -e "${YELLOW}💡 Tip: Add to your ~/.bashrc or ~/.zshrc:${NC}"
    echo -e "   ${CYAN}export PATH=\"\$HOME/.blackroad/bin:\$PATH\"${NC}\n"
fi

# Generate summary report
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}   PHASE 6: System Summary${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}\n"

# Count features
local total_features=0
local active_features=0

# Check each component
declare -A components=(
    ["Core Memory"]="$HOME/memory-system.sh"
    ["Analytics"]="$HOME/memory-analytics.sh"
    ["Performance Tracking"]="$HOME/memory-enhanced-log.sh"
    ["Query System"]="$HOME/memory-query.sh"
    ["Indexer"]="$HOME/memory-indexer.sh"
    ["Codex"]="$HOME/memory-codex.sh"
    ["Health Dashboard"]="$HOME/memory-health-dashboard.html"
)

for component in "${!components[@]}"; do
    total_features=$((total_features + 1))
    if [ -f "${components[$component]}" ]; then
        active_features=$((active_features + 1))
        echo -e "  ${GREEN}✓${NC} $component"
    else
        echo -e "  ${RED}✗${NC} $component"
    fi
done

echo ""

# Database stats
if [ -f "$MEMORY_DIR/journals/master-journal.jsonl" ]; then
    local entries=$(wc -l < "$MEMORY_DIR/journals/master-journal.jsonl")
    echo -e "${PURPLE}📊 Memory Statistics:${NC}"
    echo -e "  ${CYAN}Total Entries:${NC} $entries"
fi

if [ -f "$MEMORY_DIR/indexes/indexes.db" ]; then
    local indexed=$(sqlite3 "$MEMORY_DIR/indexes/indexes.db" "SELECT COUNT(*) FROM action_index" 2>/dev/null || echo 0)
    echo -e "  ${CYAN}Indexed Actions:${NC} $indexed"
fi

if [ -f "$MEMORY_DIR/codex/codex.db" ]; then
    local solutions=$(sqlite3 "$MEMORY_DIR/codex/codex.db" "SELECT COUNT(*) FROM solutions" 2>/dev/null || echo 0)
    local patterns=$(sqlite3 "$MEMORY_DIR/codex/codex.db" "SELECT COUNT(*) FROM patterns" 2>/dev/null || echo 0)
    echo -e "  ${CYAN}Codex Solutions:${NC} $solutions"
    echo -e "  ${CYAN}Codex Patterns:${NC} $patterns"
fi

echo ""

# Final status
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}   Initialization Complete!${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}\n"

if [ $active_features -eq $total_features ]; then
    echo -e "${GREEN}✅ All systems operational! ($active_features/$total_features)${NC}\n"
else
    echo -e "${YELLOW}⚠️  Some systems missing ($active_features/$total_features)${NC}\n"
fi

# Quick start guide
echo -e "${PURPLE}🚀 Quick Start:${NC}"
echo -e "  ${CYAN}View Dashboard:${NC}     open ~/memory-health-dashboard.html"
echo -e "  ${CYAN}Recent Activity:${NC}    ~/memory-query.sh recent 10"
echo -e "  ${CYAN}Search Memory:${NC}      ~/memory-query.sh search KEYWORD"
echo -e "  ${CYAN}Get Recommendations:${NC} ~/memory-codex.sh recommend PROBLEM"
echo -e "  ${CYAN}Full Analytics:${NC}     ~/memory-analytics.sh all"
echo -e "  ${CYAN}View Documentation:${NC} cat ~/MEMORY_ANALYTICS_DOCUMENTATION.md"

echo ""

echo -e "${PURPLE}📚 Documentation:${NC}"
echo -e "  ${CYAN}Full Docs:${NC}     ~/MEMORY_ANALYTICS_DOCUMENTATION.md"
echo -e "  ${CYAN}Quick Reference:${NC} ~/MEMORY_QUICK_REFERENCE.md"

echo ""

# Log initialization
if [ -f ~/memory-system.sh ]; then
    ~/memory-system.sh log "initialized" "memory-complete-system" "🌌 Complete memory system initialized! Analytics, indexing, codex, performance tracking, query system, health dashboard all operational. Quick commands: msearch, mrecent, mstats, csearch, crecommend, mdash, ilookup. Total features: $active_features/$total_features active. The road remembers everything - and now we can search, analyze, and learn from what it remembers! 🖤🛣️" "$(whoami)" 2>/dev/null
fi

echo -e "${GREEN}🌌 The road remembers everything. So should we. 🖤🛣️${NC}\n"
