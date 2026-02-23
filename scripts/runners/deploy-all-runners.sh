#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# BlackRoad — Deploy self-hosted runners to ALL Pi/DO nodes
# Gets GitHub Actions cost to $0
# ═══════════════════════════════════════════════════════════════
set -euo pipefail

GREEN='\033[0;32m'; RED='\033[0;31m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; BOLD='\033[1m'; NC='\033[0m'

NODES=("cecilia" "aria" "octavia" "alice" "gematria")
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${CYAN}║  BlackRoad Pi Runner Fleet Deployment    ║${NC}"
echo -e "${BOLD}${CYAN}║  GitHub Actions Cost: \$0                 ║${NC}"
echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════╝${NC}"
echo ""

FAILED=()
SUCCESS=()

for NODE in "${NODES[@]}"; do
    echo -e "${YELLOW}▶ Setting up ${NODE}...${NC}"
    if bash "${SCRIPT_DIR}/setup-pi-runner.sh" "$NODE" 2>&1 | tail -3; then
        SUCCESS+=("$NODE")
        echo -e "${GREEN}  ✓ ${NODE} done${NC}"
    else
        FAILED+=("$NODE")
        echo -e "${RED}  ✗ ${NODE} failed (skipping)${NC}"
    fi
    echo ""
done

echo -e "${BOLD}Results:${NC}"
echo -e "  ${GREEN}Success: ${SUCCESS[*]:-none}${NC}"
echo -e "  ${RED}Failed:  ${FAILED[*]:-none}${NC}"
echo ""
echo -e "${CYAN}All registered runners are free (self-hosted).${NC}"
echo -e "${CYAN}GitHub Actions minutes: \$0/month${NC}"
