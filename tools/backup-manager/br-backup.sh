#!/usr/bin/env zsh

# Colors
AMBER='[38;5;214m'; PINK='[38;5;205m'; VIOLET='[38;5;135m'; BBLUE='[38;5;69m'
GREEN='[0;32m'; RED='[0;31m'; BOLD='[1m'; DIM='[2m'; NC='[0m'
CYAN="$AMBER"; YELLOW="$PINK"; BLUE="$BBLUE"; MAGENTA="$VIOLET"; PURPLE="$VIOLET"
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
    echo -e "  ${AMBER}${BOLD}◆ BR BACKUP${NC}  backup manager\n"
    echo -e "  ${BOLD}create${NC}"
    echo -e "  ${AMBER}br backup git [name]${NC}                    git bundle"
    echo -e "  ${AMBER}br backup db <type> <conn> [name]${NC}       database"
    echo -e "  ${AMBER}br backup files [path] [name]${NC}           files/dirs\n"
    echo -e "  ${BOLD}database types:${NC}  postgres · mysql · sqlite · mongo\n"
    echo -e "  ${BOLD}manage${NC}"
    echo -e "  ${AMBER}br backup list${NC}                          list all"
    echo -e "  ${AMBER}br backup restore <id> [target]${NC}         restore"
    echo -e "  ${AMBER}br backup clean [days]${NC}                  remove old (30d)\n"
    echo -e "  ${DIM}stored in ~/.blackroad/backups/${NC}"
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
