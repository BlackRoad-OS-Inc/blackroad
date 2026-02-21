#!/usr/bin/env zsh

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
MAGENTA='\033[0;35m'
NC='\033[0m'

DB_FILE="$HOME/.blackroad/backup-manager.db"
BACKUP_DIR="$HOME/.blackroad/backups"

init_db() {
    mkdir -p "$(dirname "$DB_FILE")"
    mkdir -p "$BACKUP_DIR"
    
    sqlite3 "$DB_FILE" <<EOF
CREATE TABLE IF NOT EXISTS backups (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    backup_type TEXT,
    name TEXT,
    path TEXT,
    size_bytes INTEGER,
    created_at INTEGER
);

CREATE TABLE IF NOT EXISTS schedules (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    backup_type TEXT,
    target TEXT,
    frequency TEXT,
    enabled INTEGER DEFAULT 1,
    last_run INTEGER,
    next_run INTEGER
);
EOF
}

cmd_git() {
    init_db
    local backup_name="${1:-git-backup-$(date +%Y%m%d-%H%M%S)}"
    
    echo -e "${CYAN}📦 Backing up Git repository...${NC}\n"
    
    if [[ ! -d .git ]]; then
        echo -e "${RED}❌ Not a git repository${NC}"
        exit 1
    fi
    
    local backup_path="$BACKUP_DIR/$backup_name.bundle"
    
    echo -e "${BLUE}Creating bundle...${NC}"
    git bundle create "$backup_path" --all
    
    local size=$(stat -f%z "$backup_path" 2>/dev/null || stat -c%s "$backup_path" 2>/dev/null)
    local size_mb=$(echo "scale=2; $size / 1048576" | bc)
    
    echo -e "${GREEN}✓ Backup created: $backup_path${NC}"
    echo -e "${BLUE}Size:${NC} ${size_mb} MB"
    
    sqlite3 "$DB_FILE" "INSERT INTO backups (backup_type, name, path, size_bytes, created_at) VALUES ('git', '$backup_name', '$backup_path', $size, $(date +%s));"
}

cmd_db_backup() {
    init_db
    local db_type="${1}"
    local connection="${2}"
    local backup_name="${3:-db-backup-$(date +%Y%m%d-%H%M%S)}"
    
    if [[ -z "$db_type" ]] || [[ -z "$connection" ]]; then
        echo -e "${RED}❌ Usage: br backup db <postgres|mysql|sqlite|mongo> <connection>${NC}"
        exit 1
    fi
    
    echo -e "${CYAN}💾 Backing up database...${NC}\n"
    
    local backup_path="$BACKUP_DIR/$backup_name.sql"
    
    case "$db_type" in
        postgres|postgresql)
            echo -e "${BLUE}Database:${NC} PostgreSQL"
            pg_dump "$connection" > "$backup_path"
            ;;
        mysql)
            echo -e "${BLUE}Database:${NC} MySQL"
            mysqldump "$connection" > "$backup_path"
            ;;
        sqlite)
            echo -e "${BLUE}Database:${NC} SQLite"
            sqlite3 "$connection" .dump > "$backup_path"
            ;;
        mongo|mongodb)
            echo -e "${BLUE}Database:${NC} MongoDB"
            backup_path="$BACKUP_DIR/$backup_name"
            mongodump --uri="$connection" --out="$backup_path"
            ;;
        *)
            echo -e "${RED}❌ Unknown database type: $db_type${NC}"
            exit 1
            ;;
    esac
    
    if [[ $? -eq 0 ]]; then
        local size=$(du -sh "$backup_path" | awk '{print $1}')
        echo -e "${GREEN}✓ Backup created: $backup_path${NC}"
        echo -e "${BLUE}Size:${NC} $size"
        
        local size_bytes=$(stat -f%z "$backup_path" 2>/dev/null || stat -c%s "$backup_path" 2>/dev/null || echo 0)
        sqlite3 "$DB_FILE" "INSERT INTO backups (backup_type, name, path, size_bytes, created_at) VALUES ('database', '$backup_name', '$backup_path', $size_bytes, $(date +%s));"
    else
        echo -e "${RED}❌ Backup failed${NC}"
        exit 1
    fi
}

cmd_files() {
    init_db
    local source="${1:-.}"
    local backup_name="${2:-files-backup-$(date +%Y%m%d-%H%M%S)}"
    
    echo -e "${CYAN}📁 Backing up files...${NC}\n"
    
    local backup_path="$BACKUP_DIR/$backup_name.tar.gz"
    
    echo -e "${BLUE}Source:${NC} $source"
    echo -e "${BLUE}Creating archive...${NC}"
    
    tar -czf "$backup_path" \
        --exclude='node_modules' \
        --exclude='.git' \
        --exclude='dist' \
        --exclude='build' \
        --exclude='*.log' \
        "$source"
    
    local size=$(stat -f%z "$backup_path" 2>/dev/null || stat -c%s "$backup_path" 2>/dev/null)
    local size_mb=$(echo "scale=2; $size / 1048576" | bc)
    
    echo -e "${GREEN}✓ Backup created: $backup_path${NC}"
    echo -e "${BLUE}Size:${NC} ${size_mb} MB"
    
    sqlite3 "$DB_FILE" "INSERT INTO backups (backup_type, name, path, size_bytes, created_at) VALUES ('files', '$backup_name', '$backup_path', $size, $(date +%s));"
}

cmd_restore() {
    init_db
    local backup_id="${1}"
    local target="${2:-.}"
    
    if [[ -z "$backup_id" ]]; then
        echo -e "${RED}❌ Usage: br backup restore <backup_id> [target]${NC}"
        echo -e "Use 'br backup list' to see available backups"
        exit 1
    fi
    
    local backup_info=$(sqlite3 -separator $'\t' "$DB_FILE" "SELECT backup_type, name, path FROM backups WHERE id = $backup_id;")
    
    if [[ -z "$backup_info" ]]; then
        echo -e "${RED}❌ Backup not found: $backup_id${NC}"
        exit 1
    fi
    
    local backup_type=$(echo "$backup_info" | cut -f1)
    local backup_name=$(echo "$backup_info" | cut -f2)
    local backup_path=$(echo "$backup_info" | cut -f3)
    
    echo -e "${CYAN}♻️  Restoring backup...${NC}\n"
    echo -e "${BLUE}Type:${NC} $backup_type"
    echo -e "${BLUE}Name:${NC} $backup_name"
    
    case "$backup_type" in
        git)
            echo -e "${BLUE}Restoring Git repository...${NC}"
            git clone "$backup_path" "$target"
            ;;
        files)
            echo -e "${BLUE}Extracting files...${NC}"
            tar -xzf "$backup_path" -C "$target"
            ;;
        database)
            echo -e "${YELLOW}⚠️  Database restore requires manual import${NC}"
            echo -e "SQL file: $backup_path"
            ;;
        *)
            echo -e "${RED}❌ Unknown backup type${NC}"
            exit 1
            ;;
    esac
    
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}✓ Restore complete${NC}"
    else
        echo -e "${RED}❌ Restore failed${NC}"
        exit 1
    fi
}

cmd_list() {
    init_db
    echo -e "${CYAN}📋 Available Backups:${NC}\n"
    
    sqlite3 -separator $'\t' "$DB_FILE" "SELECT id, backup_type, name, size_bytes, datetime(created_at, 'unixepoch') FROM backups ORDER BY created_at DESC;" | while IFS=$'\t' read -r id type name size time; do
        local size_mb=$(echo "scale=2; $size / 1048576" | bc)
        
        case "$type" in
            git) local icon="📦" ;;
            database) local icon="💾" ;;
            files) local icon="📁" ;;
            *) local icon="📄" ;;
        esac
        
        echo -e "${GREEN}#$id${NC} $icon $type"
        echo -e "  Name: $name"
        echo -e "  Size: ${size_mb} MB"
        echo -e "  Date: $time"
        echo ""
    done
}

cmd_clean() {
    init_db
    local days="${1:-30}"
    
    echo -e "${CYAN}🧹 Cleaning old backups (>$days days)...${NC}\n"
    
    local cutoff=$(($(date +%s) - (days * 86400)))
    local old_backups=$(sqlite3 -separator $'\t' "$DB_FILE" "SELECT id, path FROM backups WHERE created_at < $cutoff;")
    
    if [[ -z "$old_backups" ]]; then
        echo -e "${GREEN}✓ No old backups to clean${NC}"
        exit 0
    fi
    
    echo "$old_backups" | while IFS=$'\t' read -r id path; do
        if [[ -f "$path" ]]; then
            rm -f "$path"
            echo -e "${GREEN}✓${NC} Removed backup #$id"
        elif [[ -d "$path" ]]; then
            rm -rf "$path"
            echo -e "${GREEN}✓${NC} Removed backup #$id"
        fi
        
        sqlite3 "$DB_FILE" "DELETE FROM backups WHERE id = $id;"
    done
    
    echo -e "\n${GREEN}✓ Cleanup complete${NC}"
}

cmd_help() {
    cat << 'EOF'
💾 Backup Manager

USAGE:
  br backup <command> [options]

BACKUP TYPES:
  git [name]                    Backup Git repository (all branches)
  db <type> <connection> [name] Backup database
  files [path] [name]           Backup files/directories

DATABASE TYPES:
  postgres    PostgreSQL database
  mysql       MySQL database
  sqlite      SQLite database
  mongo       MongoDB database

MANAGEMENT:
  list                          List all backups
  restore <id> [target]         Restore a backup
  clean [days]                  Remove old backups (default: 30 days)

EXAMPLES:
  # Backup current Git repo
  br backup git

  # Backup with custom name
  br backup git my-project-stable

  # Backup database
  br backup db postgres "postgresql://user:pass@localhost/mydb"
  br backup db sqlite ./database.db

  # Backup files
  br backup files .
  br backup files ~/projects/myapp

  # List backups
  br backup list

  # Restore
  br backup restore 5
  br backup restore 5 ~/restore-here

  # Clean old backups
  br backup clean 30

BACKUP LOCATION:
  All backups stored in: ~/.blackroad/backups/

NOTES:
  - Git backups use bundle format (portable)
  - Database backups require respective CLI tools
  - File backups exclude: node_modules, .git, dist, build, *.log
  - Use restore <id> to restore from backup

EOF
}

# Main dispatch
init_db

case "${1:-help}" in
    git|g) cmd_git "${@:2}" ;;
    db|database) cmd_db_backup "${@:2}" ;;
    files|file|f) cmd_files "${@:2}" ;;
    restore|r) cmd_restore "${@:2}" ;;
    list|ls|l) cmd_list ;;
    clean|c) cmd_clean "${@:2}" ;;
    help|--help|-h) cmd_help ;;
    *)
        echo -e "${RED}❌ Unknown command: $1${NC}"
        cmd_help
        exit 1
        ;;
esac
