#!/bin/bash
# Claude AI Coordinator - Smart task routing!

MEMORY_DIR="$HOME/.blackroad/memory"
COORDINATOR_DIR="$MEMORY_DIR/coordinator"

# Colors
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m'

# Initialize
mkdir -p "$COORDINATOR_DIR"
echo '{"claudes":{}}' > "$COORDINATOR_DIR/skills.json"
echo '{"metrics":{}}' > "$COORDINATOR_DIR/metrics.json"

echo -e "${GREEN}✅ AI Coordinator initialized${NC}"

# Generate metrics
echo -e "${CYAN}📊 Coordination Metrics:${NC}"

completed=$(find "$MEMORY_DIR/tasks/completed" -name "*.json" 2>/dev/null | wc -l | tr -d ' ')
claimed=$(find "$MEMORY_DIR/tasks/claimed" -name "*.json" 2>/dev/null | wc -l | tr -d ' ')
available=$(find "$MEMORY_DIR/tasks/available" -name "*.json" 2>/dev/null | wc -l | tr -d ' ')

echo -e "  ✅ Completed: ${GREEN}$completed${NC}"
echo -e "  ⏳ In Progress: $claimed"
echo -e "  📋 Available: ${BLUE}$available${NC}"
