#!/bin/bash

tput civis
trap 'tput cnorm; exit' INT

AGENTS=("L" "A" "O" "P" "E" "C")
COLORS=("1;31" "1;36" "1;32" "1;33" "1;35" "1;34")

while true; do
  clear
  echo ""
  echo -e "  \033[1;35m┌──────────────────────────────────────────────────────────────────────────────┐\033[0m"
  echo -e "  \033[1;35m│\033[0m  \033[1;37mBLACKROAD OS · LIVE TRAFFIC\033[0m                                $(date +%H:%M:%S)   \033[1;35m│\033[0m"
  echo -e "  \033[1;35m├──────────────────────────────────────────────────────────────────────────────┤\033[0m"
  echo -e "  \033[1;35m│\033[0m                                                                              \033[1;35m│\033[0m"
  
  # Generate 12 random traffic lines
  for _ in {1..12}; do
    src=$((RANDOM % 6))
    dst=$((RANDOM % 6))
    while [ $dst -eq $src ]; do dst=$((RANDOM % 6)); done
    
    # Create the line
    line="  \033[1;35m│\033[0m  "
    
    # Build arrow
    for j in {0..5}; do
      if [ $j -eq $src ]; then
        line+="\033[${COLORS[$j]}m[${AGENTS[$j]}]\033[0m"
      elif [ $j -eq $dst ]; then
        line+="\033[${COLORS[$j]}m[${AGENTS[$j]}]\033[0m"
      elif [ $j -gt $src ] && [ $j -lt $dst ]; then
        line+="═══"
      elif [ $j -lt $src ] && [ $j -gt $dst ]; then
        line+="═══"
      elif [ $j -eq $((src + 1)) ] && [ $src -lt $dst ]; then
        line+="══▶"
      elif [ $j -eq $((dst + 1)) ] && [ $dst -lt $src ]; then
        line+="◀══"
      else
        line+="───"
      fi
    done
    
    # Simpler approach - just show source -> dest
    bytes=$((RANDOM % 900 + 100))
    ms=$((RANDOM % 5 + 1))
    echo -e "  \033[1;35m│\033[0m  \033[${COLORS[$src]}m${AGENTS[$src]}\033[0m ════════════════════════════════════▶ \033[${COLORS[$dst]}m${AGENTS[$dst]}\033[0m  \033[2m${bytes}b ${ms}ms\033[0m    \033[1;35m│\033[0m"
  done
  
  echo -e "  \033[1;35m│\033[0m                                                                              \033[1;35m│\033[0m"
  echo -e "  \033[1;35m├──────────────────────────────────────────────────────────────────────────────┤\033[0m"
  echo -e "  \033[1;35m│\033[0m  \033[2mPackets: $((RANDOM%500+500))/s   Bandwidth: $((RANDOM%50+50))KB/s   Latency: $((RANDOM%3+1))ms\033[0m             \033[1;35m│\033[0m"
  echo -e "  \033[1;35m└──────────────────────────────────────────────────────────────────────────────┘\033[0m"
  
  sleep 0.3
done
