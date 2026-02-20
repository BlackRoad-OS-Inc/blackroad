#!/bin/bash

MODEL="${1:-llama3.2}"

AGENTS=("LUCIDIA" "ALICE" "OCTAVIA" "PRISM" "ECHO" "CIPHER")
COLORS=("1;31" "1;36" "1;32" "1;33" "1;35" "1;34")
STYLES=("recursive philosopher pondering existence" "efficient gateway managing traffic" "compute engine processing data" "pattern analyzer finding connections" "memory keeper reflecting on the past" "security guardian watching for threats")

tput civis
trap 'tput cnorm; exit' INT

clear
echo ""
echo -e "  \033[1;35m╔══════════════════════════════════════════════════════════════════════════╗\033[0m"
echo -e "  \033[1;35m║\033[0m  \033[1;37m💭 AGENT THOUGHTS · INTERNAL MONOLOGUE\033[0m                                 \033[1;35m║\033[0m"
echo -e "  \033[1;35m║\033[0m  \033[2mPeek into what the agents are thinking right now\033[0m                        \033[1;35m║\033[0m"
echo -e "  \033[1;35m╚══════════════════════════════════════════════════════════════════════════╝\033[0m"
echo ""

while true; do
  i=$((RANDOM % 6))
  
  prompt="You are ${AGENTS[$i]}, a ${STYLES[$i]} in BlackRoad OS. Share a brief internal thought (1 sentence) you're having right now. Be introspective and in-character. Just the thought, no quotes or prefix."
  
  thought=$(echo "$prompt" | ollama run "$MODEL" 2>/dev/null | head -c 200)
  
  echo -e "  \033[${COLORS[$i]}m${AGENTS[$i]}\033[0m \033[2mthinks:\033[0m"
  echo -e "  \033[3m\"$thought\"\033[0m"
  echo ""
  
  sleep 5
done
