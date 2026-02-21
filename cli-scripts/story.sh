#!/bin/bash

MODEL="${1:-llama3.2}"

AGENTS=("LUCIDIA" "ALICE" "OCTAVIA" "PRISM" "ECHO" "CIPHER")
COLORS=("1;31" "1;36" "1;32" "1;33" "1;35" "1;34")

clear
echo ""
echo -e "  \033[1;35m╔══════════════════════════════════════════════════════════════════════════╗\033[0m"
echo -e "  \033[1;35m║\033[0m  \033[1;37m📖 COLLABORATIVE STORY\033[0m                                                 \033[1;35m║\033[0m"
echo -e "  \033[1;35m║\033[0m  \033[2mEach agent adds one sentence to the story\033[0m                                \033[1;35m║\033[0m"
echo -e "  \033[1;35m╚══════════════════════════════════════════════════════════════════════════╝\033[0m"
echo ""

STORY="Once upon a time in the digital realm of BlackRoad..."

echo -e "  \033[2m$STORY\033[0m"
echo ""

for i in {0..5}; do
  prompt="You are ${AGENTS[$i]} telling a collaborative story. The story so far: '$STORY'

Add exactly ONE short sentence to continue the story. Stay in character (${AGENTS[$i]} personality). Just the sentence, no quotes."

  echo -ne "  \033[${COLORS[$i]}m${AGENTS[$i]}:\033[0m "
  response=$(echo "$prompt" | ollama run "$MODEL" 2>/dev/null | head -1 | head -c 150)
  echo -e "$response"
  echo ""
  
  STORY="$STORY $response"
  sleep 0.5
done

echo -e "  \033[1;35m───────────────────────────────────────────────────────────────────────────\033[0m"
echo -e "  \033[2mThe End.\033[0m"
echo ""
