#!/bin/bash

W=$(tput cols)
H=$(tput lines)
declare -a drops
for ((i=0; i<W; i++)); do drops[$i]=$((RANDOM % H)); done

clear
tput civis
trap 'tput cnorm; exit' INT

while true; do
  for ((i=0; i<W; i++)); do
    y=${drops[$i]}
    x=$i
    char=$(printf '%x' $((RANDOM % 16)))
    
    tput cup $y $x
    echo -ne "\033[1;32m$char\033[0m"
    
    tput cup $((y - 1)) $x
    echo -ne "\033[0;32m$char\033[0m"
    
    tput cup $((y - 3)) $x
    echo -ne "\033[2;32m \033[0m"
    
    drops[$i]=$(( (y + 1) % H ))
    [ $((RANDOM % 20)) -eq 0 ] && drops[$i]=0
  done
  sleep 0.05
done
