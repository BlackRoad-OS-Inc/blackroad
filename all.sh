#!/bin/bash

echo ""
echo -e "  \033[1;35m╔══════════════════════════════════════════════════════════════════════════╗\033[0m"
echo -e "  \033[1;35m║\033[0m  \033[1;37mBLACKROAD OS · ALL SCRIPTS\033[0m                                             \033[1;35m║\033[0m"
echo -e "  \033[1;35m╚══════════════════════════════════════════════════════════════════════════╝\033[0m"
echo ""

count=0
for f in *.sh; do
  if [ -x "$f" ]; then
    echo -e "  \033[1;36m./$f\033[0m"
    ((count++))
  fi
done

echo ""
echo -e "  \033[1;37m$count\033[0m \033[2mexecutable scripts\033[0m"
echo ""
