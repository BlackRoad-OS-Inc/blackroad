#!/usr/bin/env zsh

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

DB_FILE="$HOME/.blackroad/db-client.db"

init_db() {
    mkdir -p "$(dirname "$DB_FILE")"
    sqlite3 "$DB_FILE" <<EOF
CREATE TABLE IF NOT EXISTS connections (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE,
    type TEXT,
    host TEXT,
    port INTEGER,
    database_name TEXT,
    username TEXT,
    password TEXT,
    created_at INTEGER,
    last_used INTEGER
);

CREATE TABLE IF NOT EXISTS queries (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    connection_name TEXT,
    query TEXT,
    executed_at INTEGER,
    success INTEGER
);
EOF
}

cmd_add() {
    init_db
    local name="$1"
    local type="$2"
    local connection="$3"
    
    if [[ -z "$name" || -z "$type" || -z "$connection" ]]; then
        echo -e "${RED}❌ Usage: br db add <name> <type> <connection>${NC}"
        echo "Types: postgres, mysql, sqlite, mongodb"
        echo "Example: br db add mydb postgres localhost:5432/myapp:user:pass"
        exit 1
    fi
    
    local host port dbname user pass
    case "$type" in
        postgres|mysql|mongodb)
            # Parse: host:port/database:user:pass
            host=$(echo "$connection" | cut -d':' -f1)
            port=$(echo "$connection" | cut -d':' -f2 | cut -d'/' -f1)
            dbname=$(echo "$connection" | cut -d'/' -f2 | cut -d':' -f1)
            user=$(echo "$connection" | cut -d':' -f3)
            pass=$(echo "$connection" | cut -d':' -f4-)
            ;;
        sqlite)
            host="$connection"
            port=0
            dbname=""
            user=""
            pass=""
            ;;
    esac
    
    sqlite3 "$DB_FILE" "INSERT OR REPLACE INTO connections (name, type, host, port, database_name, username, password, created_at) VALUES ('$name', '$type', '$host', $port, '$dbname', '$user', '$pass', $(date +%s));"
    
    echo -e "${GREEN}✓ Connection '$name' saved${NC}"
}

cmd_list() {
    init_db
    echo -e "${CYAN}📊 Saved Connections:${NC}\n"
    
    sqlite3 -separator $'\t' "$DB_FILE" "SELECT name, type, host, database_name FROM connections ORDER BY last_used DESC;" | while IFS=$'\t' read -r name type host dbname; do
        echo -e "${BLUE}▸${NC} $name"
        echo "  Type: $type"
        echo "  Host: $host"
        [[ -n "$dbname" ]] && echo "  Database: $dbname"
        echo ""
    done
}

cmd_connect() {
    init_db
    local name="$1"
    
    if [[ -z "$name" ]]; then
        echo -e "${RED}❌ Specify connection name${NC}"
        exit 1
    fi
    
    local result=$(sqlite3 -separator '|' "$DB_FILE" "SELECT type, host, port, database_name, username, password FROM connections WHERE name='$name';")
    
    if [[ -z "$result" ]]; then
        echo -e "${RED}❌ Connection '$name' not found${NC}"
        exit 1
    fi
    
    IFS='|' read -r type host port dbname user pass <<< "$result"
    
    sqlite3 "$DB_FILE" "UPDATE connections SET last_used=$(date +%s) WHERE name='$name';"
    
    echo -e "${CYAN}🔌 Connecting to $name ($type)...${NC}\n"
    
    case "$type" in
        postgres)
            if ! command -v psql &> /dev/null; then
                echo -e "${RED}❌ psql not found${NC}"
                exit 1
            fi
            PGPASSWORD="$pass" psql -h "$host" -p "$port" -U "$user" -d "$dbname"
            ;;
        mysql)
            if ! command -v mysql &> /dev/null; then
                echo -e "${RED}❌ mysql not found${NC}"
                exit 1
            fi
            mysql -h "$host" -P "$port" -u "$user" -p"$pass" "$dbname"
            ;;
        sqlite)
            if ! command -v sqlite3 &> /dev/null; then
                echo -e "${RED}❌ sqlite3 not found${NC}"
                exit 1
            fi
            sqlite3 "$host"
            ;;
        mongodb)
            if ! command -v mongosh &> /dev/null && ! command -v mongo &> /dev/null; then
                echo -e "${RED}❌ mongosh/mongo not found${NC}"
                exit 1
            fi
            local mongo_cmd=$(command -v mongosh || command -v mongo)
            $mongo_cmd "mongodb://${user}:${pass}@${host}:${port}/${dbname}"
            ;;
    esac
}

cmd_query() {
    init_db
    local name="$1"
    local query="$2"
    
    if [[ -z "$name" || -z "$query" ]]; then
        echo -e "${RED}❌ Usage: br db query <connection> <query>${NC}"
        exit 1
    fi
    
    local result=$(sqlite3 -separator '|' "$DB_FILE" "SELECT type, host, port, database_name, username, password FROM connections WHERE name='$name';")
    
    if [[ -z "$result" ]]; then
        echo -e "${RED}❌ Connection '$name' not found${NC}"
        exit 1
    fi
    
    IFS='|' read -r type host port dbname user pass <<< "$result"
    
    echo -e "${CYAN}⚡ Executing query on $name...${NC}\n"
    
    local success=1
    case "$type" in
        postgres)
            PGPASSWORD="$pass" psql -h "$host" -p "$port" -U "$user" -d "$dbname" -c "$query" || success=0
            ;;
        mysql)
            mysql -h "$host" -P "$port" -u "$user" -p"$pass" "$dbname" -e "$query" || success=0
            ;;
        sqlite)
            sqlite3 "$host" "$query" || success=0
            ;;
    esac
    
    sqlite3 "$DB_FILE" "INSERT INTO queries (connection_name, query, executed_at, success) VALUES ('$name', '$(echo "$query" | sed "s/'/''/g")', $(date +%s), $success);"
}

cmd_tables() {
    init_db
    local name="$1"
    
    if [[ -z "$name" ]]; then
        echo -e "${RED}❌ Specify connection name${NC}"
        exit 1
    fi
    
    local result=$(sqlite3 -separator '|' "$DB_FILE" "SELECT type, host, port, database_name, username, password FROM connections WHERE name='$name';")
    
    if [[ -z "$result" ]]; then
        echo -e "${RED}❌ Connection '$name' not found${NC}"
        exit 1
    fi
    
    IFS='|' read -r type host port dbname user pass <<< "$result"
    
    echo -e "${CYAN}📋 Tables in $name:${NC}\n"
    
    case "$type" in
        postgres)
            PGPASSWORD="$pass" psql -h "$host" -p "$port" -U "$user" -d "$dbname" -c "\dt"
            ;;
        mysql)
            mysql -h "$host" -P "$port" -u "$user" -p"$pass" "$dbname" -e "SHOW TABLES;"
            ;;
        sqlite)
            sqlite3 "$host" ".tables"
            ;;
        mongodb)
            local mongo_cmd=$(command -v mongosh || command -v mongo)
            $mongo_cmd --quiet "mongodb://${user}:${pass}@${host}:${port}/${dbname}" --eval "db.getCollectionNames().forEach(function(c){print(c)})"
            ;;
    esac
}

cmd_history() {
    init_db
    local name="${1:-all}"
    
    echo -e "${CYAN}📜 Query History:${NC}\n"
    
    local where=""
    [[ "$name" != "all" ]] && where="WHERE connection_name='$name'"
    
    sqlite3 -separator $'\t' "$DB_FILE" "SELECT connection_name, query, datetime(executed_at, 'unixepoch'), success FROM queries $where ORDER BY executed_at DESC LIMIT 20;" | while IFS=$'\t' read -r conn query time success; do
        if [[ "$success" == "1" ]]; then
            echo -e "${GREEN}✓${NC} $conn - $time"
        else
            echo -e "${RED}✗${NC} $conn - $time"
        fi
        echo "  $query"
        echo ""
    done
}

cmd_remove() {
    init_db
    local name="$1"
    
    if [[ -z "$name" ]]; then
        echo -e "${RED}❌ Specify connection name${NC}"
        exit 1
    fi
    
    sqlite3 "$DB_FILE" "DELETE FROM connections WHERE name='$name';"
    echo -e "${GREEN}✓ Connection '$name' removed${NC}"
}

cmd_help() {
    cat << 'EOF'
💾 Database Client

USAGE:
  br db <command> [options]

CONNECTION MANAGEMENT:
  add <name> <type> <conn>  Add connection
  list                      List all connections
  connect <name>            Connect interactively
  remove <name>             Remove connection

QUERY COMMANDS:
  query <name> <sql>        Execute query
  tables <name>             List tables/collections
  history [name]            Show query history

TYPES:
  postgres   PostgreSQL database
  mysql      MySQL/MariaDB database
  sqlite     SQLite file
  mongodb    MongoDB database

CONNECTION FORMATS:
  postgres/mysql: host:port/database:user:pass
  mongodb:        host:port/database:user:pass
  sqlite:         /path/to/file.db

EXAMPLES:
  br db add prod postgres localhost:5432/myapp:admin:secret
  br db add local sqlite ./dev.db
  br db list
  br db connect prod
  br db query prod "SELECT * FROM users LIMIT 10"
  br db tables prod
  br db history

EOF
}

# Main dispatch
init_db

case "${1:-help}" in
    add) cmd_add "${@:2}" ;;
    list|ls) cmd_list ;;
    connect|conn) cmd_connect "${@:2}" ;;
    query|exec) cmd_query "${@:2}" ;;
    tables) cmd_tables "${@:2}" ;;
    history|hist) cmd_history "${@:2}" ;;
    remove|rm) cmd_remove "${@:2}" ;;
    help|--help|-h) cmd_help ;;
    *)
        echo -e "${RED}❌ Unknown command: $1${NC}"
        cmd_help
        exit 1
        ;;
esac
