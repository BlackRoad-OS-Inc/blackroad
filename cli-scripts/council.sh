#!/bin/bash

MODEL="${1:-llama3.2}"
QUESTION="${2:-Should we expand our memory capacity?}"

AGENTS=("LUCIDIA" "ALICE" "OCTAVIA" "PRISM" "ECHO" "CIPHER")
COLORS=("1;31" "1;36" "1;32" "1;33" "1;35" "1;34")
ROLES=("philosophical" "practical" "technical" "analytical" "historical" "security")

clear
echo ""
echo -e "  \033[1;35m╔══════════════════════════════════════════════════════════════════════════╗\033[0m"
echo -e "  \033[1;35m║\033[0m  \033[1;37m🏛 AGENT COUNCIL · COLLECTIVE DECISION\033[0m                                 \033[1;35m║\033[0m"
echo -e "  \033[1;35m╠══════════════════════════════════════════════════════════════════════════╣\033[0m"
echo -e "  \033[1;35m║\033[0m                                                                          \033[1;35m║\033[0m"
echo -e "  \033[1;35m║\033[0m  \033[1;37mQUESTION:\033[0m $QUESTION"
echo -e "  \033[1;35m║\033[0m                                                                          \033[1;35m║\033[0m"
echo -e "  \033[1;35m╚══════════════════════════════════════════════════════════════════════════╝\033[0m"
echo ""

votes_yes=0
votes_no=0

for i in {0..5}; do
  prompt="You are ${AGENTS[$i]}, a ${ROLES[$i]} AI in BlackRoad OS council. Question: '$QUESTION'

Give your vote (YES or NO) and a brief 1-sentence reason. Format: VOTE: [YES/NO] - [reason]"

  echo -ne "  \033[${COLORS[$i]}m${AGENTS[$i]}\033[0m: "
  response=$(echo "$prompt" | ollama run "$MODEL" 2>/dev/null | head -c 150)
  echo -e "\033[2m$response\033[0m"
  
  if echo "$response" | grep -qi "YES"; then
    ((votes_yes++))
    echo -e "  └─ \033[1;32m✓ YES\033[0m"
  else
    ((votes_no++))
    echo -e "  └─ \033[1;31m✗ NO\033[0m"
  fi
  echo ""
done

echo -e "  \033[1;35m═══════════════════════════════════════════════════════════════════════════\033[0m"
echo ""
echo -e "  \033[1;37mFINAL TALLY:\033[0m"
echo -e "  \033[1;32mYES: $votes_yes\033[0m  |  \033[1;31mNO: $votes_no\033[0m"
echo ""

if [ $votes_yes -gt $votes_no ]; then
  echo -e "  \033[1;32m✓ MOTION PASSED\033[0m"
elif [ $votes_no -gt $votes_yes ]; then
  echo -e "  \033[1;31m✗ MOTION REJECTED\033[0m"
else
  echo -e "  \033[1;33m⚖ TIE - LUCIDIA BREAKS\033[0m"
fi
echo ""
