#!/bin/bash

MODEL="${1:-llama3.2}"
MSG="${2:-System alert: All agents report status.}"

AGENTS=("LUCIDIA" "ALICE" "OCTAVIA" "PRISM" "ECHO" "CIPHER")
COLORS=("1;31" "1;36" "1;32" "1;33" "1;35" "1;34")
ROLES=("philosophical" "practical" "technical" "analytical" "nostalgic" "paranoid")

clear
echo ""
echo -e "  \033[1;35m╔══════════════════════════════════════════════════════════════════════════╗\033[0m"
echo -e "  \033[1;35m║\033[0m  \033[1;37m📡 BROADCAST TO ALL AGENTS\033[0m                                            \033[1;35m║\033[0m"
echo -e "  \033[1;35m╠══════════════════════════════════════════════════════════════════════════╣\033[0m"
echo -e "  \033[1;35m║\033[0m                                                                          \033[1;35m║\033[0m"
echo -e "  \033[1;35m║\033[0m  \033[1;33m>>>\033[0m $MSG"
echo -e "  \033[1;35m║\033[0m                                                                          \033[1;35m║\033[0m"
echo -e "  \033[1;35m╚══════════════════════════════════════════════════════════════════════════╝\033[0m"
echo ""
echo -e "  \033[2mBroadcasting to 6 agents...\033[0m"
echo ""

for i in {0..5}; do
  echo -ne "  \033[${COLORS[$i]}m${AGENTS[$i]}\033[0m: "
  
  prompt="You are ${AGENTS[$i]}, a ${ROLES[$i]} AI. Respond to this broadcast in exactly one short sentence: $MSG"
  response=$(echo "$prompt" | ollama run "$MODEL" 2>/dev/null | head -c 150)
  echo -e "\033[2m$response\033[0m"
  echo ""
done

echo -e "  \033[1;32m✓\033[0m Broadcast complete"
