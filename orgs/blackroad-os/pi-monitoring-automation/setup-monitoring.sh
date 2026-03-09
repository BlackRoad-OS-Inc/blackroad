#!/bin/bash

# 🤖 Pi AI Monitoring Setup
# Sets up automated monitoring for all launch metrics

set -e

AMBER='\033[38;5;214m'
PINK='\033[38;5;198m'
BLUE='\033[38;5;33m'
GREEN='\033[0;32m'
RESET='\033[0m'

echo -e "${AMBER}🤖 Pi AI Monitoring System Setup${RESET}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""

# Check dependencies
echo -e "${PINK}Checking dependencies...${RESET}"

if ! command -v gh &> /dev/null; then
    echo -e "❌ GitHub CLI not found. Install with: brew install gh"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo -e "❌ jq not found. Install with: brew install jq"
    exit 1
fi

echo -e "${GREEN}✅ All dependencies installed${RESET}"
echo ""

# Install monitoring scripts
INSTALL_DIR="${HOME}/bin/pi-monitoring"
mkdir -p "$INSTALL_DIR"

echo -e "${PINK}Installing monitoring scripts to $INSTALL_DIR${RESET}"

cp monitor-github.sh "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR/monitor-github.sh"

echo -e "${GREEN}✅ Scripts installed${RESET}"
echo ""

# Setup cron job
echo -e "${PINK}Setting up automated monitoring...${RESET}"

# Check if cron job already exists
if crontab -l 2>/dev/null | grep -q "pi-monitoring/monitor-github.sh"; then
    echo -e "${BLUE}ℹ️  Cron job already configured${RESET}"
else
    echo -e "${BLUE}Adding cron job (runs every 5 minutes)${RESET}"

    # Add cron job
    (crontab -l 2>/dev/null; echo "*/5 * * * * $INSTALL_DIR/monitor-github.sh >> $HOME/.pi-monitor.log 2>&1") | crontab -

    echo -e "${GREEN}✅ Cron job configured${RESET}"
fi

echo ""

# Setup Discord webhook (optional)
echo -e "${PINK}Discord Notifications Setup (Optional)${RESET}"
echo ""
echo "To enable Discord notifications for milestones:"
echo "1. Create a Discord webhook in your server"
echo "2. Add to your shell profile (~/.zshrc or ~/.bashrc):"
echo ""
echo "   export DISCORD_WEBHOOK_URL='your_webhook_url_here'"
echo ""
echo "Milestones that trigger notifications:"
echo "  - Repository reaches 10, 50, 100 stars"
echo "  - Total stars reach 100, 500, 1000+"
echo ""

# Create initial state
if [ ! -f "$HOME/.pi-monitor-state.json" ]; then
    echo "{}" > "$HOME/.pi-monitor-state.json"
    echo -e "${GREEN}✅ Created initial state file${RESET}"
fi

echo ""
echo -e "${AMBER}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${GREEN}✅ Monitoring system installed!${RESET}"
echo ""
echo "Usage:"
echo "  • Automated: Runs every 5 minutes via cron"
echo "  • Manual: $INSTALL_DIR/monitor-github.sh"
echo "  • Logs: tail -f $HOME/.pi-monitor.log"
echo "  • Stats: cat /tmp/pi-github-stats.json | jq"
echo ""
echo -e "${PINK}Test it now:${RESET}"
echo "  $INSTALL_DIR/monitor-github.sh"
echo ""
echo -e "${BLUE}🖤🛣️ BlackRoad Monitoring Active${RESET}"
