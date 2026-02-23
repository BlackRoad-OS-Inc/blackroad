#!/bin/bash
clear
cat <<'MENU'

  ⏰⏰⏰ CRON JOBS ⏰⏰⏰

  📋 1  List Crontab
  ✏️  2  Edit Crontab
  ➕ 3  Add Quick Job
  🗑️  4  Remove All (confirm)
  📊 5  Cron Log
  🔧 6  Systemd Timers
  📖 7  Cron Cheatsheet
  🔙 0  ← Main Menu

MENU
read -p "  ⌨️  > " c
case $c in
  1) crontab -l 2>/dev/null || echo "  (no crontab)"; read -p "  ↩ ";;
  2) crontab -e;;
  3) read -p "  ➕ Schedule (e.g. */5 * * * *): " sched; read -p "  Command: " cmd; (crontab -l 2>/dev/null; echo "$sched $cmd") | crontab - && echo "  ✅ Added" || echo "  ❌ Failed"; read -p "  ↩ ";;
  4) read -p "  🗑️  Remove ALL cron jobs? (yes/no): " yn; [ "$yn" = "yes" ] && crontab -r && echo "  ✅ Cleared" || echo "  Cancelled"; read -p "  ↩ ";;
  5) grep CRON /var/log/syslog 2>/dev/null | tail -20 || journalctl -u cron --no-pager -n 20 2>/dev/null || echo "  ⚠️  No cron log"; read -p "  ↩ ";;
  6) systemctl list-timers --all 2>/dev/null; read -p "  ↩ ";;
  7) cat <<'CHEAT'
  ⏰ Cron Cheatsheet:
  ─────────────────────
  * * * * *  = every minute
  */5 * * * * = every 5 min
  0 * * * *  = every hour
  0 0 * * *  = daily midnight
  0 0 * * 0  = weekly Sunday
  0 0 1 * *  = monthly 1st
  @reboot    = on boot
CHEAT
     read -p "  ↩ ";;
  0) exec ./menu.sh;;
  *) echo "  ❌"; sleep 1;;
esac
exec ./cron.sh
