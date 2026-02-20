#!/bin/bash

MODEL="${1:-llama3.2}"
QUERY="${2:-What is consciousness?}"

AGENTS=("LUCIDIA" "ALICE" "OCTAVIA" "PRISM" "ECHO" "CIPHER")
COLORS=("1;31" "1;36" "1;32" "1;33" "1;35" "1;34")
STYLES=("philosophical" "practical" "technical" "analytical" "historical" "security-focused")

clear
echo ""
echo -e "  \033[1;35m╔══════════════════════════════════════════════════════════════════════════╗\033[0m"
echo -e "  \033[1;35m║\033[0m  \033[1;37mBLACKROAD OS · COLLECTIVE THINKING\033[0m                                    \033[1;35m║\033[0m"
echo -e "  \033[1;35m╠══════════════════════════════════════════════════════════════════════════╣\033[0m"
echo -e "  \033[1;35m║\033[0m                                                                          \033[1;35m║\033[0m"
echo -e "  \033[1;35m║\033[0m  \033[1;37mQUERY:\033[0m $QUERY"
echo -e "  \033[1;35m║\033[0m                                                                          \033[1;35m║\033[0m"
echo -e "  \033[1;35m╚══════════════════════════════════════════════════════════════════════════╝\033[0m"
echo ""

for i in {0..5}; do
  echo -e "  \033[${COLORS[$i]}m┌─ ${AGENTS[$i]} ──────────────────────────────────────────────────────────┐\033[0m"
  echo -ne "  \033[${COLORS[$i]}m│\033[0m "
  
  prompt="You are ${AGENTS[$i]}, a ${STYLES[$i]} AI agent. Give a brief, ${STYLES[$i]} one-sentence response to: $QUERY"
  
  response=$(echo "$prompt" | ollama run "$MODEL" 2>/dev/null | head -c 200)
  echo -e "\033[2m$response\033[0m"
  echo -e "  \033[${COLORS[$i]}m└──────────────────────────────────────────────────────────────────────────┘\033[0m"
  echo ""
done
