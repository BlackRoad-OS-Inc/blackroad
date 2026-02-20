#!/bin/bash

tput civis
trap 'tput cnorm; exit' INT

echo ""
echo -e "  \033[1;35m╔══════════════════════════════════════════════════════════════════════════╗\033[0m"
echo -e "  \033[1;35m║\033[0m  \033[1;37mBLACKROAD OS · DEMO MODE\033[0m                                               \033[1;35m║\033[0m"
echo -e "  \033[1;35m║\033[0m  \033[2mShowcasing system capabilities\033[0m                                          \033[1;35m║\033[0m"
echo -e "  \033[1;35m╚══════════════════════════════════════════════════════════════════════════╝\033[0m"
echo ""
sleep 1

echo -e "  \033[1;33m▸ Running intro sequence...\033[0m"
sleep 0.5
./intro.sh
sleep 1

echo -e "  \033[1;33m▸ Boot sequence...\033[0m"
sleep 0.5
./boot.sh
sleep 1

echo -e "  \033[1;33m▸ Health check...\033[0m"
sleep 0.5
./health.sh
sleep 2

echo -e "  \033[1;33m▸ Agent roster...\033[0m"
sleep 0.5
./agent.sh
sleep 2

echo -e "  \033[1;33m▸ Network topology...\033[0m"
sleep 0.5
./net.sh
sleep 2

echo -e "  \033[1;33m▸ Memory banks...\033[0m"
sleep 0.5
./mem.sh
sleep 2

echo -e "  \033[1;33m▸ Metrics...\033[0m"
sleep 0.5
./spark.sh
sleep 2

echo -e "  \033[1;33m▸ Timeline...\033[0m"
sleep 0.5
./timeline.sh
sleep 2

echo ""
echo -e "  \033[1;32m✓ Demo complete\033[0m"
echo -e "  \033[2mRun ./hub.sh for interactive mode\033[0m"
echo ""

tput cnorm
