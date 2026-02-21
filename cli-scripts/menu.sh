#!/bin/bash

SEL=0
ITEMS=("◆ AGENTS" "◆ CHAT" "◆ LOGS" "◆ SERVICES" "◆ SETTINGS" "◆ EXIT")

draw() {
  clear
  echo ""
  echo -e "    \033[1;35m╔═══════════════════════════════════╗\033[0m"
  echo -e "    \033[1;35m║\033[0m    \033[1;37mB L A C K R O A D   O S\033[0m        \033[1;35m║\033[0m"
  echo -e "    \033[1;35m╠═══════════════════════════════════╣\033[0m"
  
  for i in "${!ITEMS[@]}"; do
    if [ $i -eq $SEL ]; then
      echo -e "    \033[1;35m║\033[0m  \033[1;36m▸ ${ITEMS[$i]}\033[0m                      \033[1;35m║\033[0m"
    else
      echo -e "    \033[1;35m║\033[0m    \033[2m${ITEMS[$i]}\033[0m                      \033[1;35m║\033[0m"
    fi
  done
  
  echo -e "    \033[1;35m╠═══════════════════════════════════╣\033[0m"
  echo -e "    \033[1;35m║\033[0m  \033[2m↑↓ navigate  ⏎ select\033[0m          \033[1;35m║\033[0m"
  echo -e "    \033[1;35m╚═══════════════════════════════════╝\033[0m"
}

while true; do
  draw
  read -rsn1 key
  case "$key" in
    A) ((SEL > 0)) && ((SEL--)) ;;
    B) ((SEL < ${#ITEMS[@]} - 1)) && ((SEL++)) ;;
    "") 
      [ $SEL -eq 5 ] && exit
      echo -e "\n    \033[1;32m▸ Selected: ${ITEMS[$SEL]}\033[0m"
      sleep 1
      ;;
  esac
done
