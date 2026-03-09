#!/bin/bash

# 🤖 Pi AI Community Bot Setup

set -e

AMBER='\033[38;5;214m'
PINK='\033[38;5;198m'
BLUE='\033[38;5;33m'
GREEN='\033[0;32m'
RESET='\033[0m'

echo -e "${AMBER}🤖 Pi AI Community Bot Setup${RESET}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""

# Check Python
if ! command -v python3 &> /dev/null; then
    echo -e "❌ Python 3 not found. Install with: brew install python3"
    exit 1
fi

echo -e "${GREEN}✅ Python 3 found${RESET}"

# Create virtual environment
echo -e "${PINK}Creating virtual environment...${RESET}"
python3 -m venv venv
source venv/bin/activate

# Install dependencies
echo -e "${PINK}Installing dependencies...${RESET}"
pip install --upgrade pip
pip install -r requirements.txt

echo -e "${GREEN}✅ Dependencies installed${RESET}"
echo ""

# Setup environment file
if [ ! -f .env ]; then
    echo -e "${PINK}Creating .env file...${RESET}"
    cat > .env << 'EOF'
# Discord Bot Token
# Get yours at: https://discord.com/developers/applications
DISCORD_BOT_TOKEN=your_token_here
EOF

    echo -e "${GREEN}✅ Created .env file${RESET}"
    echo ""
    echo -e "${AMBER}⚠️  IMPORTANT: Edit .env and add your Discord bot token${RESET}"
    echo ""
else
    echo -e "${BLUE}ℹ️  .env file already exists${RESET}"
fi

# Instructions
echo -e "${AMBER}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${GREEN}✅ Setup complete!${RESET}"
echo ""
echo -e "${PINK}Next steps:${RESET}"
echo ""
echo "1. Create a Discord bot:"
echo "   https://discord.com/developers/applications"
echo ""
echo "2. Get your bot token and add it to .env:"
echo "   DISCORD_BOT_TOKEN=your_actual_token_here"
echo ""
echo "3. Invite bot to your server:"
echo "   https://discord.com/api/oauth2/authorize?client_id=YOUR_CLIENT_ID&permissions=8&scope=bot"
echo ""
echo "4. Run the bot:"
echo "   ./run.sh"
echo ""
echo -e "${BLUE}🖤🛣️ Pi AI Community Bot${RESET}"
