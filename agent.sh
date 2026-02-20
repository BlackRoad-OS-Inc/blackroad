#!/bin/bash

show_agent() {
  local name=$1
  local color=$2
  local role=$3
  local status=$4
  
  echo ""
  echo -e "  \033[${color}m╔════════════════════════════════════════╗\033[0m"
  echo -e "  \033[${color}m║\033[0m                                        \033[${color}m║\033[0m"
  echo -e "  \033[${color}m║\033[0m      \033[1;37m█████\033[0m   \033[1;37m$name\033[0m                  \033[${color}m║\033[0m"
  echo -e "  \033[${color}m║\033[0m      \033[1;37m█   █\033[0m   \033[2m$role\033[0m        \033[${color}m║\033[0m"
  echo -e "  \033[${color}m║\033[0m      \033[1;37m█████\033[0m                            \033[${color}m║\033[0m"
  echo -e "  \033[${color}m║\033[0m       \033[1;37m█ █\033[0m    Status: \033[1;32m$status\033[0m            \033[${color}m║\033[0m"
  echo -e "  \033[${color}m║\033[0m      \033[1;37m██ ██\033[0m   Tasks:  \033[1;36m$((RANDOM % 20))\033[0m               \033[${color}m║\033[0m"
  echo -e "  \033[${color}m║\033[0m                Memory: \033[1;36m$((RANDOM % 500))MB\033[0m           \033[${color}m║\033[0m"
  echo -e "  \033[${color}m║\033[0m                Uptime: \033[1;36m${5}h\033[0m              \033[${color}m║\033[0m"
  echo -e "  \033[${color}m║\033[0m                                        \033[${color}m║\033[0m"
  echo -e "  \033[${color}m╚════════════════════════════════════════╝\033[0m"
}

clear
echo -e "\n  \033[1;37mBLACKROAD OS · AGENT ROSTER\033[0m\n"

show_agent "LUCIDIA " "1;31" "Chief Intelligence  " "ONLINE" "127"
show_agent "ALICE   " "1;36" "Gateway Agent       " "ONLINE" "127"
show_agent "OCTAVIA " "1;32" "Compute Worker      " "ONLINE" "89"
show_agent "PRISM   " "1;33" "Analytics Engine    " "ONLINE" "64"
show_agent "ECHO    " "1;35" "Memory Systems      " "ONLINE" "127"
show_agent "CIPHER  " "1;34" "Security Agent      " "ONLINE" "127"
