#!/bin/zsh
# BR Backup - Git, file, and database backup manager

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
BACKUP_DIR="$HOME/.blackroad/backups"
DB_FILE="$HOME/.blackroad/backup.db"

init_db() {
  mkdir -p "$BACKUP_DIR"
  sqlite3 "$DB_FILE" "CREATE TABLE IF NOT EXISTS backups (id INTEGER PRIMARY KEY, name TEXT, type TEXT, path TEXT, size_bytes INTEGER, created_at TEXT DEFAULT (datetime('now')));"
}

show_help() {
  echo "${CYAN}BR Backup${NC}"
  echo "  br backup git [name]    - Backup current git repo"
  echo "  br backup db [path]     - Backup SQLite database"
  echo "  br backup dir [path]    - Backup directory"
  echo "  br backup list          - List all backups"
  echo "  br backup restore [id]  - Restore a backup"
}

cmd_git() {
  init_db
  local name="${2:-$(basename $(pwd))}"
  local ts=$(date +%Y%m%d_%H%M%S)
  local out="$BACKUP_DIR/${name}_git_${ts}.tar.gz"
  echo "${CYAN}Backing up git repo...${NC}"
  git bundle create "$out.bundle" --all 2>/dev/null && {
    local sz=$(stat -f%z "$out.bundle" 2>/dev/null || stat -c%s "$out.bundle" 2>/dev/null || echo 0)
    sqlite3 "$DB_FILE" "INSERT INTO backups (name, type, path, size_bytes) VALUES ('$name', 'git', '$out.bundle', $sz);"
    echo "${GREEN}✓ Saved: $out.bundle ($(( sz / 1024 ))KB)${NC}"
  } || echo "${RED}✗ Backup failed${NC}"
}

cmd_db() {
  init_db
  local src="${2:-$DB_FILE}"
  local name=$(basename "$src" .db)
  local ts=$(date +%Y%m%d_%H%M%S)
  local out="$BACKUP_DIR/${name}_db_${ts}.sqlite3"
  cp "$src" "$out" && {
    local sz=$(stat -f%z "$out" 2>/dev/null || stat -c%s "$out" 2>/dev/null || echo 0)
    sqlite3 "$DB_FILE" "INSERT INTO backups (name, type, path, size_bytes) VALUES ('$name', 'db', '$out', $sz);"
    echo "${GREEN}✓ Saved: $out${NC}"
  } || echo "${RED}✗ Backup failed${NC}"
}

cmd_dir() {
  init_db
  local src="${2:-$(pwd)}"
  local name=$(basename "$src")
  local ts=$(date +%Y%m%d_%H%M%S)
  local out="$BACKUP_DIR/${name}_${ts}.tar.gz"
  tar -czf "$out" -C "$(dirname $src)" "$(basename $src)" && {
    local sz=$(stat -f%z "$out" 2>/dev/null || stat -c%s "$out" 2>/dev/null || echo 0)
    sqlite3 "$DB_FILE" "INSERT INTO backups (name, type, path, size_bytes) VALUES ('$name', 'dir', '$out', $sz);"
    echo "${GREEN}✓ Saved: $out ($(( sz / 1024 ))KB)${NC}"
  } || echo "${RED}✗ Backup failed${NC}"
}

cmd_list() {
  init_db
  echo "${CYAN}Backups:${NC}"
  sqlite3 -column -header "$DB_FILE" "SELECT id, name, type, substr(path,-40), size_bytes, created_at FROM backups ORDER BY created_at DESC LIMIT 20;"
}

case "$1" in
  git)      cmd_git "$@" ;;
  db)       cmd_db "$@" ;;
  dir)      cmd_dir "$@" ;;
  list)     cmd_list ;;
  help|--help) show_help ;;
  *)        show_help ;;
esac
