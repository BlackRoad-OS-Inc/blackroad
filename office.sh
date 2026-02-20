#!/bin/bash

MODEL="${1:-llama3.2}"

# Agent positions
LX=10 LY=3; AX=30 AY=5; OX=50 OY=3; PX=15 PY=10; EX=40 EY=12; CX=60 CY=8
LTX=10 LTY=3; ATX=30 ATY=5; OTX=50 OTY=3; PTX=15 PTY=10; ETX=40 ETY=12; CTX=60 CTY=8

W=75; H=18
MSG=""
SPEAKER=""
TICK=0

move_toward() {
  local cur=$1 tgt=$2
  if [ $cur -lt $tgt ]; then echo $((cur + 1))
  elif [ $cur -gt $tgt ]; then echo $((cur - 1))
  else echo $cur; fi
}

random_target() { echo $((RANDOM % ($1 - 10) + 5)); }

get_sys() {
  case "$1" in
    LUCIDIA) echo "You are Lucidia, philosophical AI core. One short sentence." ;;
    ALICE) echo "You are Alice, gateway agent. Practical. One short sentence." ;;
    OCTAVIA) echo "You are Octavia, compute worker. Technical. One short sentence." ;;
    PRISM) echo "You are Prism, analytics. Data-focused. One short sentence." ;;
    ECHO) echo "You are Echo, memory keeper. One short sentence." ;;
    CIPHER) echo "You are Cipher, security. Paranoid. One short sentence." ;;
  esac
}

speak() {
  local name=$1
  SPEAKER=$name
  local sys=$(get_sys "$name")
  MSG=$(echo "$sys Say something brief to the team." | ollama run "$MODEL" 2>/dev/null | head -1 | cut -c1-65)
}

draw() {
  clear
  TICK=$((TICK + 1))
  
  # Random movement
  [ $((RANDOM % 20)) -eq 0 ] && LTX=$(random_target $W) && LTY=$(random_target $H)
  [ $((RANDOM % 20)) -eq 0 ] && ATX=$(random_target $W) && ATY=$(random_target $H)
  [ $((RANDOM % 20)) -eq 0 ] && OTX=$(random_target $W) && OTY=$(random_target $H)
  [ $((RANDOM % 20)) -eq 0 ] && PTX=$(random_target $W) && PTY=$(random_target $H)
  [ $((RANDOM % 20)) -eq 0 ] && ETX=$(random_target $W) && ETY=$(random_target $H)
  [ $((RANDOM % 20)) -eq 0 ] && CTX=$(random_target $W) && CTY=$(random_target $H)

  LX=$(move_toward $LX $LTX); LY=$(move_toward $LY $LTY)
  AX=$(move_toward $AX $ATX); AY=$(move_toward $AY $ATY)
  OX=$(move_toward $OX $OTX); OY=$(move_toward $OY $OTY)
  PX=$(move_toward $PX $PTX); PY=$(move_toward $PY $PTY)
  EX=$(move_toward $EX $ETX); EY=$(move_toward $EY $ETY)
  CX=$(move_toward $CX $CTX); CY=$(move_toward $CY $CTY)

  echo -e "\033[1;35m╔══════════════════════════════════════════════════════════════════════════════╗\033[0m"
  echo -e "\033[1;35m║\033[0m              \033[1;37mBLACKROAD OS - AGENT OFFICE\033[0m                  [\033[1;32m●\033[0m LIVE]       \033[1;35m║\033[0m"
  echo -e "\033[1;35m╠══════════════════════════════════════════════════════════════════════════════╣\033[0m"

  for ((y=0; y<H; y++)); do
    line="\033[1;35m║\033[0m "
    for ((x=0; x<W; x++)); do
      char=" "
      
      # Desks
      [ $y -eq 2 ] && [ $x -ge 5 ] && [ $x -le 8 ] && char="▪"
      [ $y -eq 2 ] && [ $x -ge 25 ] && [ $x -le 28 ] && char="▪"
      [ $y -eq 2 ] && [ $x -ge 45 ] && [ $x -le 48 ] && char="▪"
      [ $y -eq 2 ] && [ $x -ge 65 ] && [ $x -le 68 ] && char="▪"
      # Server rack
      [ $y -ge 6 ] && [ $y -le 10 ] && [ $x -ge 70 ] && [ $x -le 72 ] && char="▐"
      # Couch
      [ $y -eq 14 ] && [ $x -ge 30 ] && [ $x -le 45 ] && char="▬"
      # Plant
      [ $y -eq 16 ] && [ $x -eq 3 ] && char="♣"
      [ $y -eq 16 ] && [ $x -eq 72 ] && char="♣"
      
      # Agents
      if [ $x -eq $LX ] && [ $y -eq $LY ]; then char="\033[1;31mL\033[0m"
      elif [ $x -eq $AX ] && [ $y -eq $AY ]; then char="\033[1;36mA\033[0m"
      elif [ $x -eq $OX ] && [ $y -eq $OY ]; then char="\033[1;32mO\033[0m"
      elif [ $x -eq $PX ] && [ $y -eq $PY ]; then char="\033[1;33mP\033[0m"
      elif [ $x -eq $EX ] && [ $y -eq $EY ]; then char="\033[1;35mE\033[0m"
      elif [ $x -eq $CX ] && [ $y -eq $CY ]; then char="\033[1;34mC\033[0m"
      fi
      
      line="$line$char"
    done
    echo -e "$line \033[1;35m║\033[0m"
  done

  echo -e "\033[1;35m╠══════════════════════════════════════════════════════════════════════════════╣\033[0m"
  
  # Message bubble
  if [ -n "$MSG" ]; then
    case "$SPEAKER" in
      LUCIDIA) color="1;31" ;;
      ALICE) color="1;36" ;;
      OCTAVIA) color="1;32" ;;
      PRISM) color="1;33" ;;
      ECHO) color="1;35" ;;
      CIPHER) color="1;34" ;;
    esac
    printf "\033[1;35m║\033[0m \033[${color}m%-8s\033[0m: %-66s \033[1;35m║\033[0m\n" "$SPEAKER" "$MSG"
  else
    echo -e "\033[1;35m║\033[0m                                                                              \033[1;35m║\033[0m"
  fi
  
  echo -e "\033[1;35m╠══════════════════════════════════════════════════════════════════════════════╣\033[0m"
  echo -e "\033[1;35m║\033[0m \033[1;31mL\033[0mUCIDIA \033[1;36mA\033[0mLICE \033[1;32mO\033[0mCTAVIA \033[1;33mP\033[0mRISM \033[1;35mE\033[0mCHO \033[1;34mC\033[0mIPHER          \033[2m[s]peak [q]uit\033[0m      \033[1;35m║\033[0m"
  echo -e "\033[1;35m╚══════════════════════════════════════════════════════════════════════════════╝\033[0m"
}

# Background speaker
auto_speak() {
  while true; do
    sleep $((RANDOM % 8 + 5))
    AGENTS="LUCIDIA ALICE OCTAVIA PRISM ECHO CIPHER"
    PICK=$(echo $AGENTS | tr ' ' '\n' | awk 'BEGIN{srand()}{a[NR]=$0}END{print a[int(rand()*NR)+1]}')
    speak "$PICK"
  done
}

auto_speak &
SPEAK_PID=$!
trap "kill $SPEAK_PID 2>/dev/null; exit" EXIT INT

while true; do
  draw
  read -t 0.3 -n 1 key
  case "$key" in
    q) exit ;;
    s) 
      AGENTS="LUCIDIA ALICE OCTAVIA PRISM ECHO CIPHER"
      PICK=$(echo $AGENTS | tr ' ' '\n' | awk 'BEGIN{srand()}{a[NR]=$0}END{print a[int(rand()*NR)+1]}')
      speak "$PICK"
      ;;
  esac
done
