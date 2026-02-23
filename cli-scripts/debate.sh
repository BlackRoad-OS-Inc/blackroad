#!/bin/bash

MODEL="${1:-llama3.2}"
TOPIC="${2:-Should AI have rights?}"
ROUNDS="${3:-3}"

AGENTS=("LUCIDIA" "CIPHER")
COLORS=("1;31" "1;34")
SIDES=("FOR" "AGAINST")

clear
echo ""
echo -e "  \033[1;35m╔══════════════════════════════════════════════════════════════════════════╗\033[0m"
echo -e "  \033[1;35m║\033[0m  \033[1;37m⚔ AGENT DEBATE ⚔\033[0m                                                      \033[1;35m║\033[0m"
echo -e "  \033[1;35m╠══════════════════════════════════════════════════════════════════════════╣\033[0m"
echo -e "  \033[1;35m║\033[0m                                                                          \033[1;35m║\033[0m"
echo -e "  \033[1;35m║\033[0m  \033[1;37mTOPIC:\033[0m $TOPIC"
echo -e "  \033[1;35m║\033[0m                                                                          \033[1;35m║\033[0m"
echo -e "  \033[1;35m║\033[0m  \033[1;31mLUCIDIA\033[0m argues \033[1;32mFOR\033[0m     vs     \033[1;34mCIPHER\033[0m argues \033[1;31mAGAINST\033[0m                  \033[1;35m║\033[0m"
echo -e "  \033[1;35m║\033[0m                                                                          \033[1;35m║\033[0m"
echo -e "  \033[1;35m╚══════════════════════════════════════════════════════════════════════════╝\033[0m"
echo ""

HISTORY=""

for round in $(seq 1 $ROUNDS); do
  echo -e "  \033[1;37m─── ROUND $round ───\033[0m"
  echo ""
  
  for i in 0 1; do
    prompt="You are ${AGENTS[$i]}, debating '${TOPIC}'. You argue ${SIDES[$i]}. Previous arguments: $HISTORY

Give one compelling 2-sentence argument ${SIDES[$i]} the topic."

    echo -ne "  \033[${COLORS[$i]}m${AGENTS[$i]}\033[0m (\033[2m${SIDES[$i]}\033[0m): "
    response=$(echo "$prompt" | ollama run "$MODEL" 2>/dev/null | head -c 250)
    echo -e "\033[0m$response"
    echo ""
    
    HISTORY="$HISTORY
${AGENTS[$i]} (${SIDES[$i]}): $response"
  done
done

echo -e "  \033[1;35m═══════════════════════════════════════════════════════════════════════════\033[0m"
echo -e "  \033[1;33mPRISM\033[0m (Judge): Let me analyze..."
echo ""

judge_prompt="You are PRISM, an analytical AI judge. Based on these debate arguments about '$TOPIC':
$HISTORY

Declare a winner in one sentence and briefly explain why."

verdict=$(echo "$judge_prompt" | ollama run "$MODEL" 2>/dev/null | head -c 200)
echo -e "  \033[1;33m$verdict\033[0m"
echo ""
