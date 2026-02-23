#!/bin/bash

AGENTS=("LUCIDIA" "ALICE" "OCTAVIA" "PRISM" "ECHO" "CIPHER")
COLORS=("1;31" "1;36" "1;32" "1;33" "1;35" "1;34")
MOODS=("contemplative" "focused" "busy" "curious" "nostalgic" "vigilant")
EMOJIS=("🤔" "⚡" "🔥" "🔍" "💭" "👁")

echo ""
echo -e "  \033[1;35m┌──────────────────────────────────────────────────────────────────────────┐\033[0m"
echo -e "  \033[1;35m│\033[0m  \033[1;37mBLACKROAD OS · AGENT MOOD TRACKER\033[0m                         $(date +%H:%M)   \033[1;35m│\033[0m"
echo -e "  \033[1;35m├──────────────────────────────────────────────────────────────────────────┤\033[0m"
echo -e "  \033[1;35m│\033[0m                                                                          \033[1;35m│\033[0m"

for i in {0..5}; do
  energy=$((RANDOM % 100))
  bar=""
  for ((j=0; j<energy/10; j++)); do bar+="█"; done
  for ((j=energy/10; j<10; j++)); do bar+="░"; done
  
  echo -e "  \033[1;35m│\033[0m  ${EMOJIS[$i]} \033[${COLORS[$i]}m${AGENTS[$i]}\033[0m"
  echo -e "  \033[1;35m│\033[0m     Mood: \033[1;37m${MOODS[$i]}\033[0m"
  echo -e "  \033[1;35m│\033[0m     Energy: [$bar] $energy%"
  echo -e "  \033[1;35m│\033[0m                                                                          \033[1;35m│\033[0m"
done

echo -e "  \033[1;35m└──────────────────────────────────────────────────────────────────────────┘\033[0m"
