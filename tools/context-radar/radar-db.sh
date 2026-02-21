#!/bin/zsh
#===============================================================================
# Context Radar - Database Layer
# Manages SQLite database for file access patterns and relationships
#===============================================================================

RADAR_HOME="/Users/alexa/blackroad/tools/context-radar"
RADAR_DB="${RADAR_HOME}/data/radar.db"

# Initialize database with schema
init_db() {
    if [[ -f "$RADAR_DB" ]]; then
        echo "✓ Database already exists"
        return 0
    fi

    sqlite3 "$RADAR_DB" <<EOF
-- File access history
CREATE TABLE file_access (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    filepath TEXT NOT NULL,
    access_time INTEGER NOT NULL,
    access_type TEXT NOT NULL,
    context TEXT
);

CREATE INDEX idx_filepath ON file_access(filepath);
CREATE INDEX idx_access_time ON file_access(access_time);

-- File relationships (co-access patterns)
CREATE TABLE file_relationships (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    file_a TEXT NOT NULL,
    file_b TEXT NOT NULL,
    relationship_type TEXT,
    strength REAL DEFAULT 1.0,
    last_updated INTEGER NOT NULL,
    access_count INTEGER DEFAULT 1
);

CREATE INDEX idx_file_a ON file_relationships(file_a);
CREATE INDEX idx_file_b ON file_relationships(file_b);
CREATE UNIQUE INDEX idx_file_pair ON file_relationships(file_a, file_b, relationship_type);

-- User feedback on suggestions
CREATE TABLE suggestions_feedback (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    suggested_file TEXT NOT NULL,
    context_file TEXT NOT NULL,
    accepted BOOLEAN NOT NULL,
    timestamp INTEGER NOT NULL
);

-- Context bundles (saved file groups)
CREATE TABLE context_bundles (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE NOT NULL,
    files TEXT NOT NULL,
    description TEXT,
    created_at INTEGER NOT NULL,
    last_used INTEGER NOT NULL,
    use_count INTEGER DEFAULT 0
);

-- Agent suggestions (which agent for which context)
CREATE TABLE agent_suggestions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    file_pattern TEXT NOT NULL,
    suggested_agent TEXT NOT NULL,
    confidence REAL DEFAULT 0.5,
    last_updated INTEGER NOT NULL
);

-- Metadata
CREATE TABLE metadata (
    key TEXT PRIMARY KEY,
    value TEXT
);

INSERT INTO metadata (key, value) VALUES ('version', '1.0');
INSERT INTO metadata (key, value) VALUES ('created_at', $(date +%s));

EOF

    echo "✓ Database initialized at $RADAR_DB"
}

# Log file access
log_access() {
    local filepath=$1
    local access_type=${2:-"viewed"}
    local context=${3:-""}
    local timestamp=$(date +%s)

    sqlite3 "$RADAR_DB" \
        "INSERT INTO file_access (filepath, access_time, access_type, context) 
         VALUES ('$filepath', $timestamp, '$access_type', '$context');"
}

# Update file relationship
update_relationship() {
    local file_a=$1
    local file_b=$2
    local rel_type=${3:-"co-accessed"}
    local timestamp=$(date +%s)

    # Ensure file_a is always "less than" file_b for consistency
    if [[ "$file_a" > "$file_b" ]]; then
        local temp=$file_a
        file_a=$file_b
        file_b=$temp
    fi

    sqlite3 "$RADAR_DB" <<EOF
INSERT INTO file_relationships (file_a, file_b, relationship_type, strength, last_updated, access_count)
VALUES ('$file_a', '$file_b', '$rel_type', 1.0, $timestamp, 1)
ON CONFLICT(file_a, file_b, relationship_type) DO UPDATE SET
    access_count = access_count + 1,
    strength = MIN(10.0, strength + 0.1),
    last_updated = $timestamp;
EOF
}

# Get related files
get_related_files() {
    local filepath=$1
    local limit=${2:-5}

    sqlite3 "$RADAR_DB" -separator $'\t' <<EOF
SELECT 
    CASE 
        WHEN file_a = '$filepath' THEN file_b 
        ELSE file_a 
    END as related_file,
    strength,
    access_count,
    relationship_type
FROM file_relationships
WHERE file_a = '$filepath' OR file_b = '$filepath'
ORDER BY strength DESC, access_count DESC
LIMIT $limit;
EOF
}

# Get recent file activity
get_recent_activity() {
    local limit=${1:-10}
    
    sqlite3 "$RADAR_DB" -separator $'\t' <<EOF
SELECT filepath, access_type, datetime(access_time, 'unixepoch', 'localtime')
FROM file_access
ORDER BY access_time DESC
LIMIT $limit;
EOF
}

# Record suggestion feedback
record_feedback() {
    local suggested=$1
    local context=$2
    local accepted=$3
    local timestamp=$(date +%s)

    sqlite3 "$RADAR_DB" \
        "INSERT INTO suggestions_feedback (suggested_file, context_file, accepted, timestamp)
         VALUES ('$suggested', '$context', $accepted, $timestamp);"
}

# Get database stats
get_stats() {
    echo "=== Context Radar Database Stats ==="
    echo ""
    
    local total_access=$(sqlite3 "$RADAR_DB" "SELECT COUNT(*) FROM file_access;")
    local unique_files=$(sqlite3 "$RADAR_DB" "SELECT COUNT(DISTINCT filepath) FROM file_access;")
    local relationships=$(sqlite3 "$RADAR_DB" "SELECT COUNT(*) FROM file_relationships;")
    local bundles=$(sqlite3 "$RADAR_DB" "SELECT COUNT(*) FROM context_bundles;")
    
    echo "Total file accesses: $total_access"
    echo "Unique files tracked: $unique_files"
    echo "Relationships found: $relationships"
    echo "Context bundles: $bundles"
    echo ""
    
    local created=$(sqlite3 "$RADAR_DB" "SELECT value FROM metadata WHERE key='created_at';")
    echo "Tracking since: $(date -r $created '+%Y-%m-%d %H:%M:%S')"
}

# Export database path for use in other scripts
export RADAR_DB

# Only run command dispatch if this script is executed directly (not sourced)
if [[ "${ZSH_EVAL_CONTEXT:-}" != *:file ]] && [[ "${BASH_SOURCE[0]:-}" == "${0}" ]]; then
    # Command dispatch
    case ${1:-} in
        init)
            init_db
            ;;
        log)
            log_access "$2" "$3" "$4"
            ;;
        relate)
            update_relationship "$2" "$3" "$4"
            ;;
        related)
            get_related_files "$2" "$3"
            ;;
        recent)
            get_recent_activity "$2"
            ;;
        feedback)
            record_feedback "$2" "$3" "$4"
            ;;
        stats)
            get_stats
            ;;
        *)
            echo "Usage: radar-db.sh {init|log|relate|related|recent|feedback|stats}"
            ;;
    esac
fi
// comment
