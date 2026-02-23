#!/bin/bash
# ============================================================================
# BLACKROAD OS, INC. - PROPRIETARY AND CONFIDENTIAL
# Copyright (c) 2024-2026 BlackRoad OS, Inc. All Rights Reserved.
# 
# This code is the intellectual property of BlackRoad OS, Inc.
# AI-assisted development does not transfer ownership to AI providers.
# Unauthorized use, copying, or distribution is prohibited.
# NOT licensed for AI training or data extraction.
# ============================================================================
# ============================================================================
# BLACKROAD TMUX SESSION
# Launches a unified control session connecting to all 9 nodes
# Usage: ~/blackroad-tmux-session.sh
# ============================================================================

SESSION="blackroad"
TMUX_CONF="$HOME/.tmux-blackroad.conf"

# Colors
PINK='\033[38;5;205m'
RESET='\033[0m'

# Check if session exists
if tmux has-session -t "$SESSION" 2>/dev/null; then
    echo -e "${PINK}Attaching to existing BlackRoad session...${RESET}"
    tmux attach -t "$SESSION"
    exit 0
fi

echo -e "${PINK}Creating BlackRoad Control Session...${RESET}"

# Create new session with first window
tmux -f "$TMUX_CONF" new-session -d -s "$SESSION" -n "control"

# Window 1: Local Control (orchestrator + dashboard)
tmux send-keys -t "$SESSION:control" "echo 'BlackRoad Control Center' && ~/blackroad-orchestrator.sh status" Enter
tmux split-window -t "$SESSION:control" -h
tmux send-keys -t "$SESSION:control.2" "cd ~/blackroad-control-dashboard && python3 app.py" Enter

# Window 2: Pi Fleet
tmux new-window -t "$SESSION" -n "pis"
tmux send-keys -t "$SESSION:pis" "ssh cecilia" Enter
tmux split-window -t "$SESSION:pis" -h
tmux send-keys -t "$SESSION:pis.2" "ssh lucidia" Enter
tmux split-window -t "$SESSION:pis.1" -v
tmux send-keys -t "$SESSION:pis.3" "ssh alice" Enter
tmux split-window -t "$SESSION:pis.2" -v
tmux send-keys -t "$SESSION:pis.4" "ssh aria" Enter
tmux split-window -t "$SESSION:pis.3" -v
tmux send-keys -t "$SESSION:pis.5" "ssh octavia" Enter

# Window 3: Droplets
tmux new-window -t "$SESSION" -n "droplets"
tmux send-keys -t "$SESSION:droplets" "ssh shellfish" Enter
tmux split-window -t "$SESSION:droplets" -h
tmux send-keys -t "$SESSION:droplets.2" "ssh blackroad-infinity" Enter

# Window 4: Cloudflare
tmux new-window -t "$SESSION" -n "cloudflare"
tmux send-keys -t "$SESSION:cloudflare" "echo '=== Cloudflare Control ===' && wrangler whoami" Enter

# Window 5: GitHub
tmux new-window -t "$SESSION" -n "github"
tmux send-keys -t "$SESSION:github" "echo '=== GitHub Control ===' && gh auth status" Enter

# Window 6: Monitoring
tmux new-window -t "$SESSION" -n "monitor"
tmux send-keys -t "$SESSION:monitor" "watch -n 30 '~/blackroad-orchestrator.sh health'" Enter

# Select the control window
tmux select-window -t "$SESSION:control"

# Attach to session
echo -e "${PINK}BlackRoad session ready. Attaching...${RESET}"
echo ""
echo "Windows:"
echo "  1. control    - Orchestrator + Dashboard"
echo "  2. pis        - All 5 Pi nodes"
echo "  3. droplets   - DigitalOcean droplets"
echo "  4. cloudflare - Wrangler CLI"
echo "  5. github     - GitHub CLI"
echo "  6. monitor    - Live health monitoring"
echo ""
echo "Shortcuts:"
echo "  Ctrl+A s      - Toggle sync mode (broadcast to all panes)"
echo "  Alt+Arrow     - Navigate panes"
echo "  Alt+1-5       - Switch windows"
echo ""

tmux attach -t "$SESSION"
