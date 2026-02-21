#!/bin/bash

W=$(tput cols)
H=$(tput lines)
x=$((W/2))
y=$((H/2))
dx=1
dy=1
text="BLACKROAD"

tput civis
trap 'tput cnorm; clear; exit' INT

colors=("1;31" "1;32" "1;33" "1;34" "1;35" "1;36")
c=0

while true; do
  tput cup $y $x
  echo -ne "\033[${colors[$c]}m$text\033[0m"
  
  sleep 0.1
  
  tput cup $y $x
  echo -ne "         "
  
  x=$((x + dx))
  y=$((y + dy))
  
  if [ $x -le 0 ] || [ $x -ge $((W - 10)) ]; then
    dx=$((-dx))
    c=$(((c + 1) % 6))
  fi
  
  if [ $y -le 0 ] || [ $y -ge $((H - 1)) ]; then
    dy=$((-dy))
    c=$(((c + 1) % 6))
  fi
done
