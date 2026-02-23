#!/bin/bash
clear
cat <<'MENU'

  💿💿💿 BACKUP 💿💿💿

  📦 1  Backup BlackRoad Config
  📦 2  Backup Pi Home Dirs
  📦 3  Backup Notes & Journals
  📦 4  Backup SSH Keys
  📦 5  Backup to DigitalOcean
  🔄 6  Rsync to Shellfish
  📋 7  Backup Log
  ♻️  8  Restore from Backup
  🔙 0  ← Main Menu

MENU
BACKUP_DIR="$HOME/.blackroad/backups"
mkdir -p "$BACKUP_DIR"
read -p "  ⌨️  > " c
case $c in
  1) tar czf "$BACKUP_DIR/blackroad-config-$(date +%Y%m%d).tar.gz" "$HOME/.blackroad/" 2>/dev/null && echo "  ✅ Config backed up" || echo "  ❌ Failed"; read -p "  ↩ ";;
  2) for h in "alice:192.168.4.49" "aria:192.168.4.64" "octavia:192.168.4.74" "lucidia:192.168.4.38"; do
       name="${h%%:*}"; ip="${h##*:}"
       echo "  📦 Backing up $name..."
       rsync -az --timeout=5 "pi@$ip:~/" "$BACKUP_DIR/$name/" 2>/dev/null && echo "  ✅ $name" || echo "  ⚠️  $name offline"
     done; read -p "  ↩ ";;
  3) tar czf "$BACKUP_DIR/notes-$(date +%Y%m%d).tar.gz" "$HOME/.blackroad/notes/" 2>/dev/null && echo "  ✅ Notes backed up" || echo "  ❌ Failed"; read -p "  ↩ ";;
  4) tar czf "$BACKUP_DIR/ssh-keys-$(date +%Y%m%d).tar.gz" "$HOME/.ssh/" 2>/dev/null && echo "  ✅ SSH keys backed up (keep secure!)" || echo "  ❌ Failed"; read -p "  ↩ ";;
  5) echo "  📦 Syncing to shellfish..."; rsync -az "$BACKUP_DIR/" root@174.138.44.45:/root/backups/blackroad/ 2>/dev/null && echo "  ✅ Uploaded to DO" || echo "  ⚠️  Shellfish offline"; read -p "  ↩ ";;
  6) read -p "  🔄 Local dir: " src; rsync -avz "$src" root@174.138.44.45:/root/sync/ 2>/dev/null && echo "  ✅ Synced" || echo "  ❌ Failed"; read -p "  ↩ ";;
  7) ls -lht "$BACKUP_DIR/" 2>/dev/null; read -p "  ↩ ";;
  8) echo "  ♻️  Backups available:"; ls "$BACKUP_DIR/"*.tar.gz 2>/dev/null || echo "  (none)"; read -p "  File to restore: " f; tar xzf "$f" -C / 2>/dev/null && echo "  ✅ Restored" || echo "  ❌ Failed"; read -p "  ↩ ";;
  0) exec ./menu.sh;;
  *) echo "  ❌"; sleep 1;;
esac
exec ./backup.sh
