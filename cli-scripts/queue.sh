#!/bin/bash

tput civis
trap 'tput cnorm; exit' INT

TYPES=("task.process" "data.sync" "query.route" "auth.check" "mem.write" "pattern.scan")
AGENTS=("LUCIDIA" "ALICE" "OCTAVIA" "PRISM" "ECHO" "CIPHER")
COLORS=("1;31" "1;36" "1;32" "1;33" "1;35" "1;34")

while true; do
  clear
  echo ""
  echo -e "  \033[1;35m┌──────────────────────────────────────────────────────────────────────────────┐\033[0m"
  echo -e "  \033[1;35m│\033[0m  \033[1;37mBLACKROAD OS · MESSAGE QUEUE\033[0m                              $(date +%H:%M:%S)   \033[1;35m│\033[0m"
  echo -e "  \033[1;35m├──────────────────────────────────────────────────────────────────────────────┤\033[0m"
  echo -e "  \033[1;35m│\033[0m  \033[2mID        TYPE            FROM        TO          AGE     STATUS\033[0m       \033[1;35m│\033[0m"
  echo -e "  \033[1;35m├──────────────────────────────────────────────────────────────────────────────┤\033[0m"
  
  for _ in {1..10}; do
    id=$(printf '%04x' $RANDOM)
    type=${TYPES[$((RANDOM % 6))]}
    from=$((RANDOM % 6))
    to=$((RANDOM % 6))
    while [ $to -eq $from ]; do to=$((RANDOM % 6)); done
    age=$((RANDOM % 500))
    
    status_n=$((RANDOM % 3))
    case $status_n in
      0) status="\033[1;32mPROCESSING\033[0m" ;;
      1) status="\033[1;33mPENDING\033[0m   " ;;
      2) status="\033[2mDONE\033[0m      " ;;
    esac
    
    echo -e "  \033[1;35m│\033[0m  \033[2m#$id\033[0m    $type    \033[${COLORS[$from]}m${AGENTS[$from]:0:7}\033[0m     \033[${COLORS[$to]}m${AGENTS[$to]:0:7}\033[0m     ${age}ms   $status   \033[1;35m│\033[0m"
  done
  
  echo -e "  \033[1;35m├──────────────────────────────────────────────────────────────────────────────┤\033[0m"
  echo -e "  \033[1;35m│\033[0m  \033[2mTotal: $((RANDOM % 50 + 100))   Processing: $((RANDOM % 20 + 10))   Pending: $((RANDOM % 30))   Rate: $((RANDOM % 100 + 50))/s\033[0m      \033[1;35m│\033[0m"
  echo -e "  \033[1;35m└──────────────────────────────────────────────────────────────────────────────┘\033[0m"
  
  read -t 0.5 -n 1 key && [ "$key" = "q" ] && break
done
tput cnorm
