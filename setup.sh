#!/bin/bash
# BlackRoad Codex Setup Script

set -e

COLOR_GREEN='\033[0;32m'
COLOR_CYAN='\033[0;36m'
COLOR_YELLOW='\033[1;33m'
COLOR_RESET='\033[0m'

echo -e "${COLOR_CYAN}"
cat << 'BANNER'
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║      📜 BLACKROAD CODEX SETUP 📜                            ║
║                                                              ║
║      A Masterpiece of Alexandria & Amunra & Rohonc          ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
BANNER
echo -e "${COLOR_RESET}"

# Set Codex path
CODEX_PATH="${CODEX_PATH:-$HOME/blackroad-codex}"

echo -e "${COLOR_YELLOW}Setting up BlackRoad Codex at: $CODEX_PATH${COLOR_RESET}"
echo ""

# Create directory structure
echo "Creating directory structure..."
mkdir -p "$CODEX_PATH"
mkdir -p "$CODEX_PATH/index"
mkdir -p "$CODEX_PATH/cache"
mkdir -p "$CODEX_PATH/logs"

# Initialize database
echo "Initializing database..."
python3 blackroad-codex-scanner.py --init-db

# Make scripts executable
echo "Making scripts executable..."
chmod +x *.sh
chmod +x *.py

echo ""
echo -e "${COLOR_GREEN}✅ BlackRoad Codex setup complete!${COLOR_RESET}"
echo ""
echo "Next steps:"
echo "  1. Index your first repository:"
echo "     python3 blackroad-codex-scanner.py --repo /path/to/repo"
echo ""
echo "  2. Search the Codex:"
echo "     python3 blackroad-codex-search.py 'your query'"
echo ""
echo "  3. View the dashboard:"
echo "     python3 blackroad-codex-scraping-dashboard.py"
echo ""
echo "  4. Index the entire BlackRoad ecosystem:"
echo "     ./blackroad-codex-index-all.sh"
echo ""
echo -e "${COLOR_CYAN}The Codex remembers everything. So should we.${COLOR_RESET}"
echo ""
