#!/bin/bash

MODEL="${1:-llama3.2}"
AGENT="${2:-LUCIDIA}"

case "$AGENT" in
  LUCIDIA|lucidia) COLOR="1;31"; ROLE="recursive philosopher"; STYLE="deep, questioning" ;;
  ALICE|alice) COLOR="1;36"; ROLE="gateway router"; STYLE="practical, efficient" ;;
  OCTAVIA|octavia) COLOR="1;32"; ROLE="compute engine"; STYLE="technical, precise" ;;
  PRISM|prism) COLOR="1;33"; ROLE="pattern analyst"; STYLE="data-driven, observant" ;;
  ECHO|echo) COLOR="1;35"; ROLE="memory keeper"; STYLE="nostalgic, reflective" ;;
  CIPHER|cipher) COLOR="1;34"; ROLE="security guardian"; STYLE="paranoid, cryptic" ;;
  *) echo "Unknown agent"; exit 1 ;;
esac

AGENT="${AGENT^^}"

clear
echo ""
echo -e "  \033[${COLOR}m╔══════════════════════════════════════════════════════════════════════════╗\033[0m"
echo -e "  \033[${COLOR}m║\033[0m                                                                          \033[${COLOR}m║\033[0m"
echo -e "  \033[${COLOR}m║\033[0m                        \033[1;37m◉ FOCUS MODE: $AGENT\033[0m                           \033[${COLOR}m║\033[0m"
echo -e "  \033[${COLOR}m║\033[0m                        \033[2m$ROLE\033[0m                              \033[${COLOR}m║\033[0m"
echo -e "  \033[${COLOR}m║\033[0m                                                                          \033[${COLOR}m║\033[0m"
echo -e "  \033[${COLOR}m║\033[0m                        \033[2mType 'exit' to leave\033[0m                              \033[${COLOR}m║\033[0m"
echo -e "  \033[${COLOR}m║\033[0m                                                                          \033[${COLOR}m║\033[0m"
echo -e "  \033[${COLOR}m╚══════════════════════════════════════════════════════════════════════════╝\033[0m"
echo ""

HISTORY=""

while true; do
  echo -ne "  \033[1;37mYOU ▸\033[0m "
  read input
  [ "$input" = "exit" ] && break
  [ -z "$input" ] && continue
  
  HISTORY="$HISTORY
Human: $input"
  
  prompt="You are $AGENT, a $ROLE in the BlackRoad OS agent collective. Your communication style is $STYLE. Respond briefly (1-2 sentences).

$HISTORY

$AGENT:"

  echo ""
  echo -ne "  \033[${COLOR}m$AGENT ▸\033[0m "
  response=$(echo "$prompt" | ollama run "$MODEL" 2>/dev/null)
  echo -e "\033[0m$response"
  echo ""
  
  HISTORY="$HISTORY
$AGENT: $response"
done
