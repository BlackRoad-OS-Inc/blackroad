#!/bin/bash

clear
echo ""
sleep 0.1

# Logo reveal
echo -e "\033[1;35m"
sleep 0.05; echo "    ██████╗ ██╗      █████╗  ██████╗██╗  ██╗██████╗  ██████╗  █████╗ ██████╗ "
sleep 0.05; echo "    ██╔══██╗██║     ██╔══██╗██╔════╝██║ ██╔╝██╔══██╗██╔═══██╗██╔══██╗██╔══██╗"
sleep 0.05; echo "    ██████╔╝██║     ███████║██║     █████╔╝ ██████╔╝██║   ██║███████║██║  ██║"
sleep 0.05; echo "    ██╔══██╗██║     ██╔══██║██║     ██╔═██╗ ██╔══██╗██║   ██║██╔══██║██║  ██║"
sleep 0.05; echo "    ██████╔╝███████╗██║  ██║╚██████╗██║  ██╗██║  ██║╚██████╔╝██║  ██║██████╔╝"
sleep 0.05; echo "    ╚═════╝ ╚══════╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═════╝ "
echo -e "\033[0m"
sleep 0.1
echo -e "                         \033[1;31m█▀█ █▀\033[0m  \033[2mv0.1.0 · agent orchestration\033[0m"
echo ""
sleep 0.3

# Boot sequence
items=(
  "Loading kernel modules"
  "Initializing memory pools"
  "Starting agent runtime"
  "Connecting to NATS bus"
  "Loading agent: LUCIDIA"
  "Loading agent: ALICE"
  "Loading agent: OCTAVIA"
  "Loading agent: PRISM"
  "Loading agent: ECHO"
  "Loading agent: CIPHER"
  "Mounting vector store"
  "Starting API gateway"
  "Verifying checksums"
  "System ready"
)

for item in "${items[@]}"; do
  echo -ne "    \033[2m[\033[0m\033[1;33m▸\033[0m\033[2m]\033[0m $item"
  sleep 0.1
  for i in {1..3}; do
    echo -n "."
    sleep 0.05
  done
  echo -e " \033[1;32m✓\033[0m"
done

echo ""
echo -e "    \033[1;32m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "    \033[1;37m6 agents online\033[0m · \033[2mType 'help' for commands\033[0m"
echo ""
