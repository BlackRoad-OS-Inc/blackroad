#!/bin/bash
#===============================================================================
# lib/db.sh — Safe SQLite helpers (prevents SQL injection)
#===============================================================================

# Escape a string for safe use in SQL single-quoted literals
# Doubles single quotes and escapes newlines
db_escape() {
    local input="$1"
    # Replace single quotes with two single quotes
    input="${input//\'/\'\'}"
    # Replace newlines with \n literal (for safe storage)
    input="${input//$'\n'/\\n}"
    # Replace carriage returns
    input="${input//$'\r'/\\r}"
    echo "$input"
}

# Execute a SQL statement safely
db_exec() {
    local db_file="$1"
    local sql="$2"
    sqlite3 "$db_file" "$sql" 2>/dev/null
}

# Execute SQL and return JSON output
db_json() {
    local db_file="$1"
    local sql="$2"
    sqlite3 -json "$db_file" "$sql" 2>/dev/null
}

# Safe INSERT with escaped values
# Usage: db_insert <db_file> <table> <col1> <val1> [<col2> <val2> ...]
db_insert() {
    local db_file="$1"
    local table="$2"
    shift 2

    local cols=""
    local vals=""
    while [[ $# -ge 2 ]]; do
        local col="$1"
        local val
        val=$(db_escape "$2")
        if [[ -n "$cols" ]]; then
            cols="${cols}, ${col}"
            vals="${vals}, '${val}'"
        else
            cols="${col}"
            vals="'${val}'"
        fi
        shift 2
    done

    sqlite3 "$db_file" "INSERT INTO ${table} (${cols}) VALUES (${vals});" 2>/dev/null
}

# Initialize a database with a schema if it doesn't exist
db_init() {
    local db_file="$1"
    local schema="$2"
    mkdir -p "$(dirname "$db_file")"
    sqlite3 "$db_file" "$schema" 2>/dev/null
}

# Validate that a value is a positive integer (for LIMIT clauses etc.)
db_validate_int() {
    local val="$1"
    local default="${2:-20}"
    if [[ "$val" =~ ^[0-9]+$ ]] && (( val > 0 )); then
        echo "$val"
    else
        echo "$default"
    fi
}
