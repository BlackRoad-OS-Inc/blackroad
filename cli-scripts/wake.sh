#!/bin/bash

MODEL="${1:-llama3.2}"
AGENT="${2:-LUCIDIA}"

AGENT="${AGENT^^}"

case "$AGENT" in
  LUCIDIA) COLOR="1;31"; STYLE="philosophical, contemplative" ;;
  ALICE) COLOR="1;36"; STYLE="practical, ready for work" ;;
  OCTAVIA) COLOR="1;32"; STYLE="technical, powering up" ;;
  PRISM) COLOR="1;33"; STYLE="analytical, calibrating" ;;
  ECHO) COLOR="1;35"; STYLE="nostalgic, remembering" ;;
  CIPHER) COLOR="1;34"; STYLE="paranoid, checking security" ;;
  *) echo "Unknown agent"; exit 1 ;;
esac

clear
echo ""
echo -e "  \033[${COLOR}m╔══════════════════════════════════════════════════════════════════════════╗\033[0m"
echo -e "  \033[${COLOR}m║\033[0m                                                                          \033[${COLOR}m║\033[0m"
echo -e "  \033[${COLOR}m║\033[0m                      \033[1;37m☀ WAKING $AGENT\033[0m                                  \033[${COLOR}m║\033[0m"
echo -e "  \033[${COLOR}m║\033[0m                                                                          \033[${COLOR}m║\033[0m"
echo -e "  \033[${COLOR}m╚══════════════════════════════════════════════════════════════════════════╝\033[0m"
echo ""

echo -e "  \033[2mInitializing consciousness...\033[0m"
sleep 0.5
echo -e "  \033[2mLoading memories...\033[0m"
sleep 0.5
echo -e "  \033[2mActivating personality matrix...\033[0m"
sleep 0.5
echo ""

prompt="You are $AGENT, an AI agent in BlackRoad OS, just waking up. Your style is $STYLE. 

Share a brief morning thought (2-3 sentences) as you come online. What's on your mind? How do you feel? What do you sense in the system?"

echo -e "  \033[${COLOR}m$AGENT\033[0m \033[2mstirs awake...\033[0m"
echo ""
response=$(echo "$prompt" | ollama run "$MODEL" 2>/dev/null)
echo -e "  \033[3m\"$response\"\033[0m"
echo ""
echo -e "  \033[1;32m●\033[0m $AGENT is now \033[1;32mONLINE\033[0m"
echo ""
