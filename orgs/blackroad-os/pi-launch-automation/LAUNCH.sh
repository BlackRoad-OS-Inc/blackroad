#!/bin/bash

# 🚀🚀🚀 PI AI MASTER LAUNCHER 🚀🚀🚀
# ONE COMMAND TO LAUNCH THE REVOLUTION

set -e

AMBER='\033[38;5;214m'
PINK='\033[38;5;198m'
BLUE='\033[38;5;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
VIOLET='\033[38;5;93m'
RESET='\033[0m'

clear

# Epic ASCII art
cat << 'EOF'
[38;5;214m
    ███████╗██╗      █████╗ ██╗   ██╗███╗   ██╗ ██████╗██╗  ██╗
    ██╔════╝██║     ██╔══██╗██║   ██║████╗  ██║██╔════╝██║  ██║
    █████╗  ██║     ███████║██║   ██║██╔██╗ ██║██║     ███████║
    ██╔══╝  ██║     ██╔══██║██║   ██║██║╚██╗██║██║     ██╔══██║
    ███████╗███████╗██║  ██║╚██████╔╝██║ ╚████║╚██████╗██║  ██║
    ╚══════╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝╚═╝  ╚═╝
[0m
[38;5;198m
          🥧  PI AI REVOLUTION  🥧
[0m
[38;5;33m
    Same Energy • 1% Cost • 100% Sovereignty
[0m
[38;5;93m
              🖤🛣️ BlackRoad 🖤🛣️
[0m

EOF

echo -e "${AMBER}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${PINK}                   MASTER LAUNCH CONTROL                    ${RESET}"
echo -e "${AMBER}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""

echo -e "${VIOLET}What do you want to do?${RESET}"
echo ""
echo -e "${BLUE}1)${RESET} 🚀 Execute Full Launch Sequence (Automated multi-platform)"
echo -e "${BLUE}2)${RESET} 📧 Generate Press Emails (All media outlets)"
echo -e "${BLUE}3)${RESET} 🎮 Open Mission Control (Command center dashboard)"
echo -e "${BLUE}4)${RESET} 📊 Open Launch Dashboard (Real-time metrics)"
echo -e "${BLUE}5)${RESET} 🌐 Open All Live Sites (Calculator, Registry, Hub)"
echo -e "${BLUE}6)${RESET} 📋 View Launch Manual (Complete documentation)"
echo -e "${BLUE}7)${RESET} 🐦 Copy Twitter Thread (Ready to post)"
echo -e "${BLUE}8)${RESET} 👽 Copy Reddit Post (Ready to post)"
echo -e "${BLUE}9)${RESET} 📈 Show System Status (All repositories)"
echo -e "${BLUE}0)${RESET} ❌ Exit"
echo ""

read -p "$(echo -e ${PINK}Choose action [0-9]:${RESET} )" choice

case $choice in
    1)
        echo -e "${GREEN}🚀 Launching full sequence...${RESET}"
        chmod +x launch-sequencer.sh
        ./launch-sequencer.sh
        ;;
    2)
        echo -e "${GREEN}📧 Generating press emails...${RESET}"
        chmod +x send-press-emails.sh
        ./send-press-emails.sh
        ;;
    3)
        echo -e "${GREEN}🎮 Opening Mission Control...${RESET}"
        open https://blackroad-os.github.io/pi-mission-control/
        ;;
    4)
        echo -e "${GREEN}📊 Opening Launch Dashboard...${RESET}"
        open https://blackroad-os.github.io/pi-launch-dashboard/
        ;;
    5)
        echo -e "${GREEN}🌐 Opening all live sites...${RESET}"
        open https://blackroad-os.github.io/pi-mission-control/
        sleep 1
        open https://blackroad-os.github.io/pi-cost-calculator
        sleep 1
        open https://blackroad-os.github.io/pi-ai-registry
        sleep 1
        open https://blackroad-os.github.io/pi-ai-hub
        sleep 1
        open https://blackroad-os.github.io/pi-launch-dashboard/
        ;;
    6)
        echo -e "${GREEN}📋 Opening launch manual...${RESET}"
        if [ -f /tmp/PI-AI-LAUNCH-COMPLETE.md ]; then
            cat /tmp/PI-AI-LAUNCH-COMPLETE.md
        else
            echo -e "${RED}Launch manual not found at /tmp/PI-AI-LAUNCH-COMPLETE.md${RESET}"
        fi
        ;;
    7)
        echo -e "${GREEN}🐦 Twitter thread copied to clipboard!${RESET}"
        if [ -f /tmp/twitter-announcement.md ]; then
            cat /tmp/twitter-announcement.md | pbcopy
            echo -e "${BLUE}Thread ready to paste into Twitter${RESET}"
            cat /tmp/twitter-announcement.md
        else
            echo -e "${RED}Twitter thread not found${RESET}"
        fi
        ;;
    8)
        echo -e "${GREEN}👽 Reddit post copied to clipboard!${RESET}"
        if [ -f /tmp/reddit-post.md ]; then
            cat /tmp/reddit-post.md | pbcopy
            echo -e "${BLUE}Post ready to paste into Reddit${RESET}"
            cat /tmp/reddit-post.md
        else
            echo -e "${RED}Reddit post not found${RESET}"
        fi
        ;;
    9)
        echo -e "${GREEN}📈 Fetching system status...${RESET}"
        echo ""
        echo -e "${AMBER}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
        echo -e "${PINK}PI AI ECOSYSTEM STATUS${RESET}"
        echo -e "${AMBER}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
        echo ""

        REPOS=(
            "BlackRoad-OS/pi-mission-control"
            "BlackRoad-OS/pi-cost-calculator"
            "BlackRoad-OS/pi-ai-starter-kit"
            "BlackRoad-OS/pi-ai-registry"
            "BlackRoad-OS/pi-ai-hub"
            "BlackRoad-OS/pi-launch-dashboard"
            "BlackRoad-OS/pi-monitoring-automation"
            "BlackRoad-OS/pi-community-bot"
        )

        for repo in "${REPOS[@]}"; do
            repo_name=$(basename "$repo")
            echo -e "${BLUE}📦 $repo_name${RESET}"

            if command -v gh &> /dev/null; then
                stats=$(gh api repos/$repo 2>/dev/null || echo "{}")
                stars=$(echo "$stats" | jq -r '.stargazers_count // "?"')
                forks=$(echo "$stats" | jq -r '.forks_count // "?"')

                echo "   ⭐ Stars: $stars"
                echo "   🔱 Forks: $forks"
                echo "   🔗 https://github.com/$repo"
            else
                echo "   🔗 https://github.com/$repo"
            fi
            echo ""
        done

        echo -e "${AMBER}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
        echo -e "${GREEN}Live Sites:${RESET}"
        echo "  🎮 Mission Control: https://blackroad-os.github.io/pi-mission-control/"
        echo "  💰 Calculator: https://blackroad-os.github.io/pi-cost-calculator"
        echo "  🌍 Registry: https://blackroad-os.github.io/pi-ai-registry"
        echo "  🥧 Hub: https://blackroad-os.github.io/pi-ai-hub"
        echo "  🚀 Dashboard: https://blackroad-os.github.io/pi-launch-dashboard/"
        echo ""
        ;;
    0)
        echo -e "${BLUE}👋 May the revolution be with you!${RESET}"
        exit 0
        ;;
    *)
        echo -e "${RED}Invalid choice${RESET}"
        exit 1
        ;;
esac

echo ""
echo -e "${AMBER}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${GREEN}✅ Action complete!${RESET}"
echo ""
echo -e "${PINK}🥧🍎 Pi + Apple = Revolution 🥧🍎${RESET}"
echo -e "${BLUE}🖤🛣️ Same Energy • 1% Cost • 100% Sovereignty 🖤🛣️${RESET}"
echo ""
