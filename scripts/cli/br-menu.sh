#!/usr/bin/env bash
set -euo pipefail

while true; do
  clear
  echo "BlackRoad CLI Menu"
  echo "=================="
  echo "1) status"
  echo "2) colors (all)"
  echo "3) agents"
  echo "4) lucidia state"
  echo "5) ping agents"
  echo "6) registry list"
  echo "7) help"
  echo "0) exit"
  echo

  read -rp "Select: " choice

  case "$choice" in
    1) br status ;;
    2) br colors all ;;
    3) br agents ;;
    4) br lucidia state ;;
    5) br ping agents ;;
    6) br registry list ;;
    7) br help ;;
    0) exit 0 ;;
    *) echo "invalid choice" ;;
  esac

  echo
  read -rp "Press Enter to continue..." _
done
