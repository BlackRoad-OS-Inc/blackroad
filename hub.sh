#!/bin/bash
#===============================================================================
# BlackRoad OS Hub — Launcher
# Delegates to the full hub in blackroad-operator/cli-scripts/hub.sh
#===============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REAL_HUB="${SCRIPT_DIR}/blackroad-operator/cli-scripts/hub.sh"

if [[ -f "$REAL_HUB" ]]; then
  exec bash "$REAL_HUB" "$@"
fi

# Fallback: simple arrow-key menu if operator hub not found
echo -e "\033[1;33m⚠  Real hub not found at: ${REAL_HUB}\033[0m"
echo -e "\033[2mFalling back to basic menu...\033[0m"
sleep 1

selected=0
options=("DASHBOARD" "AGENTS" "CHAT" "LOGS" "NETWORK" "MEMORY" "TASKS" "EVENTS" "METRICS" "OFFICE" "EXIT")
commands=("./dash.sh" "./agent.sh" "./chat.sh" "./logs.sh" "./net.sh" "./mem.sh" "./tasks.sh" "./events.sh" "./spark.sh" "./office.sh" "exit")

draw() {
  clear
  echo ""
  echo -e "  \033[1;35m██████╗ ██╗      █████╗  ██████╗██╗  ██╗██████╗  ██████╗  █████╗ ██████╗\033[0m"
  echo -e "  \033[1;35m██╔══██╗██║     ██╔══██╗██╔════╝██║ ██╔╝██╔══██╗██╔═══██╗██╔══██╗██╔══██╗\033[0m"
  echo -e "  \033[1;35m██████╔╝██║     ███████║██║     █████╔╝ ██████╔╝██║   ██║███████║██║  ██║\033[0m"
  echo -e "  \033[1;35m██╔══██╗██║     ██╔══██║██║     ██╔═██╗ ██╔══██╗██║   ██║██╔══██║██║  ██║\033[0m"
  echo -e "  \033[1;35m██████╔╝███████╗██║  ██║╚██████╗██║  ██╗██║  ██║╚██████╔╝██║  ██║██████╔╝\033[0m"
  echo -e "  \033[1;35m╚═════╝ ╚══════╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═════╝\033[0m"
  echo ""
  echo -e "  \033[2m────────────────────────────────────────────────────────────────────────\033[0m"
  echo ""
  
  for i in "${!options[@]}"; do
    if [ $i -eq $selected ]; then
      echo -e "       \033[1;35m▸\033[0m \033[1;37m${options[$i]}\033[0m"
    else
      echo -e "         \033[2m${options[$i]}\033[0m"
    fi
  done
  
  echo ""
  echo -e "  \033[2m────────────────────────────────────────────────────────────────────────\033[0m"
  echo -e "  \033[2m↑↓ navigate  ⏎ select                         6 agents online\033[0m"
}

while true; do
  draw
  read -rsn1 key
  case "$key" in
    A) ((selected > 0)) && ((selected--)) ;;
    B) ((selected < ${#options[@]}-1)) && ((selected++)) ;;
    "") 
      if [ "${options[$selected]}" = "EXIT" ]; then
        clear
        exit 0
      fi
      ${commands[$selected]}
      ;;
  esac
done
