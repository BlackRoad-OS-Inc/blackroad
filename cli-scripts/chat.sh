#!/bin/bash

MODEL="${1:-llama3.2}"
HISTORY=""

clear
echo -e "\033[1;35m╔══════════════════════════════════════════════════════════════════════════════╗\033[0m"
echo -e "\033[1;35m║\033[0m  \033[1;37mBLACKROAD OS · AGENT CHAT\033[0m                                               \033[1;35m║\033[0m"
echo -e "\033[1;35m║\033[0m  \033[2mTalk to the agents. Type 'exit' to quit.\033[0m                                  \033[1;35m║\033[0m"
echo -e "\033[1;35m╚══════════════════════════════════════════════════════════════════════════════╝\033[0m"
echo ""

while true; do
  echo -ne "  \033[1;37mYOU ▸\033[0m "
  read input
  [ "$input" = "exit" ] && break
  [ -z "$input" ] && continue
  
  HISTORY="$HISTORY
Human: $input"

  prompt="You are the BlackRoad OS agent collective. Lucidia (philosophical), Alice (practical), Octavia (technical), Prism (analytical), Echo (memory), and Cipher (security) share one voice. Respond briefly as whichever agent fits best. Prefix with agent name.

$HISTORY

Respond in 1-2 sentences:"

  echo ""
  echo -ne "  "
  response=$(echo "$prompt" | ollama run "$MODEL" 2>/dev/null)
  
  if [[ "$response" == *"LUCIDIA"* ]] || [[ "$response" == *"Lucidia"* ]]; then
    echo -e "\033[1;31m$response\033[0m"
  elif [[ "$response" == *"ALICE"* ]] || [[ "$response" == *"Alice"* ]]; then
    echo -e "\033[1;36m$response\033[0m"
  elif [[ "$response" == *"OCTAVIA"* ]] || [[ "$response" == *"Octavia"* ]]; then
    echo -e "\033[1;32m$response\033[0m"
  elif [[ "$response" == *"PRISM"* ]] || [[ "$response" == *"Prism"* ]]; then
    echo -e "\033[1;33m$response\033[0m"
  elif [[ "$response" == *"ECHO"* ]] || [[ "$response" == *"Echo"* ]]; then
    echo -e "\033[1;35m$response\033[0m"
  elif [[ "$response" == *"CIPHER"* ]] || [[ "$response" == *"Cipher"* ]]; then
    echo -e "\033[1;34m$response\033[0m"
  else
    echo -e "\033[1;37m$response\033[0m"
  fi
  
  HISTORY="$HISTORY
Agent: $response"
  echo ""
done
