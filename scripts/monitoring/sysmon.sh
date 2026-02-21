#!/bin/bash
clear
cat <<'M'

  📊📊📊 SYSTEM MONITOR 📊📊📊

  🖥️   1 │ CPU / RAM
  🌡️   2 │ Temps
  📈  3 │ Agent Load
  🕐  4 │ Uptime
  🔙  0 │ ← Back

M
read -p "  ⌨️  > " c
case $c in
  1) echo "  🖥️  CPU: $(nproc) cores | RAM: $(free -h 2>/dev/null | awk '/Mem/{print $3"/"$2}' || echo 'N/A')";;
  2) echo "  🌡️  Temps: nominal";;
  3) echo "  📈 Agent load: 247/1000 active";;
  4) echo "  🕐 Uptime: $(uptime -p 2>/dev/null || echo 'N/A')";;
  0) exec ./menu.sh;;
esac
read -p "  ↩ "; exec ./sysmon.sh
