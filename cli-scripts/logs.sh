#!/bin/bash

AGENTS=("LUCIDIA" "ALICE" "OCTAVIA" "PRISM" "ECHO" "CIPHER")
COLORS=("1;31" "1;36" "1;32" "1;33" "1;35" "1;34")
ACTIONS=("processing request" "syncing memory" "routing message" "analyzing data" "encrypting payload" "spawning task" "checking status" "updating cache" "validating token" "querying vector store")

echo -e "\033[1;35m┌─────────────────────────────────────────────────────────────────────────────┐\033[0m"
echo -e "\033[1;35m│\033[0m  \033[1;37mBLACKROAD OS · LIVE LOGS\033[0m                               \033[2mCtrl+C quit\033[0m   \033[1;35m│\033[0m"
echo -e "\033[1;35m└─────────────────────────────────────────────────────────────────────────────┘\033[0m"

while true; do
  i=$((RANDOM % 6))
  a=$((RANDOM % 10))
  ts=$(date +%H:%M:%S)
  id=$(printf '%04x' $((RANDOM % 65535)))
  echo -e "  \033[2m$ts\033[0m \033[${COLORS[$i]}m${AGENTS[$i]}\033[0m ${ACTIONS[$a]} \033[2m#$id\033[0m"
  sleep 0.$((RANDOM % 5 + 1))
done
