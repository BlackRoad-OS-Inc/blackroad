#!/bin/bash

tput civis
trap 'tput cnorm; exit' INT

clear

# Fade in logo
sleep 0.5

echo ""
echo ""
echo ""
echo ""
echo ""
sleep 0.1
echo -e "                    \033[2m██████\033[0m"
sleep 0.1
echo -e "                    \033[2m██   ██\033[0m"
sleep 0.1
echo -e "                    \033[2m██████\033[0m"
sleep 0.1
echo -e "                    \033[2m██   ██\033[0m"
sleep 0.1
echo -e "                    \033[2m██████\033[0m"

sleep 0.5
clear

echo ""
echo ""
echo ""
echo ""
echo ""
echo -e "             \033[1;35m██████  ██       █████   ██████ ██   ██\033[0m"
sleep 0.1
echo -e "             \033[1;35m██   ██ ██      ██   ██ ██      ██  ██\033[0m"
sleep 0.1
echo -e "             \033[1;35m██████  ██      ███████ ██      █████\033[0m"
sleep 0.1
echo -e "             \033[1;35m██   ██ ██      ██   ██ ██      ██  ██\033[0m"
sleep 0.1
echo -e "             \033[1;35m██████  ███████ ██   ██  ██████ ██   ██\033[0m"

sleep 0.3

echo ""
echo -e "             \033[1;35m██████   ██████   █████  ██████\033[0m"
sleep 0.1
echo -e "             \033[1;35m██   ██ ██    ██ ██   ██ ██   ██\033[0m"
sleep 0.1
echo -e "             \033[1;35m██████  ██    ██ ███████ ██   ██\033[0m"
sleep 0.1
echo -e "             \033[1;35m██   ██ ██    ██ ██   ██ ██   ██\033[0m"
sleep 0.1
echo -e "             \033[1;35m██   ██  ██████  ██   ██ ██████\033[0m"

sleep 0.5

echo ""
echo ""
echo -e "                       \033[2m◆ OPERATING SYSTEM ◆\033[0m"

sleep 1

echo ""
echo ""
echo -e "          \033[1;31m●\033[0m \033[2mLUCIDIA\033[0m   \033[1;36m●\033[0m \033[2mALICE\033[0m   \033[1;32m●\033[0m \033[2mOCTAVIA\033[0m   \033[1;33m●\033[0m \033[2mPRISM\033[0m   \033[1;35m●\033[0m \033[2mECHO\033[0m   \033[1;34m●\033[0m \033[2mCIPHER\033[0m"

sleep 1.5

echo ""
echo ""
echo -e "                         \033[1;32m[ SYSTEM READY ]\033[0m"
echo ""

sleep 1
tput cnorm
