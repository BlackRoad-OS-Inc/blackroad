#!/bin/zsh
#===============================================================================
# Context Radar Watcher - Actual file monitoring process
# This is the long-running process that fswatch events
#===============================================================================

RADAR_HOME="/Users/alexa/blackroad/tools/context-radar"
RADAR_DB="${RADAR_HOME}/data/radar.db"
WATCH_DIR="/Users/alexa/blackroad"
LOG_FILE="${RADAR_HOME}/data/radar.log"

# Track recently accessed files
typeset -a RECENT_FILES
MAX_RECENT=10
TIME_WINDOW=300

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

add_to_recent() {
    local filepath=$1
    local timestamp=$(date +%s)
    
    RECENT_FILES=("${filepath}:${timestamp}" "${RECENT_FILES[@]}")
    
    local new_recent=()
    local count=0
    for entry in "${RECENT_FILES[@]}"; do
        local file="${entry%%:*}"
        local time="${entry##*:}"
        if (( timestamp - time < TIME_WINDOW && count < MAX_RECENT )); then
            new_recent+=("$entry")
            ((count++))
        fi
    done
    RECENT_FILES=("${new_recent[@]}")
}

log_file_access() {
    local filepath=$1
    local access_type=$2
    local timestamp=$(date +%s)
    
    sqlite3 "$RADAR_DB" \
        "INSERT INTO file_access (filepath, access_time, access_type, context) 
         VALUES ('$filepath', $timestamp, '$access_type', '');" 2>/dev/null
}

update_file_relationship() {
    local file_a=$1
    local file_b=$2
    local timestamp=$(date +%s)
    
    if [[ "$file_a" > "$file_b" ]]; then
        local temp=$file_a
        file_a=$file_b
        file_b=$temp
    fi
    
    sqlite3 "$RADAR_DB" <<EOF 2>/dev/null
INSERT INTO file_relationships (file_a, file_b, relationship_type, strength, last_updated, access_count)
VALUES ('$file_a', '$file_b', 'co-accessed', 1.0, $timestamp, 1)
ON CONFLICT(file_a, file_b, relationship_type) DO UPDATE SET
    access_count = access_count + 1,
    strength = MIN(10.0, strength + 0.1),
    last_updated = $timestamp;
EOF
}

process_file_event() {
    local filepath=$1
    local event_type=$2
    
    # Ignore noise
    if [[ "$filepath" =~ "/\." ]] || \
       [[ "$filepath" =~ "\.git/" ]] || \
       [[ "$filepath" =~ "\.log$" ]] || \
       [[ "$filepath" =~ "\.tmp$" ]] || \
       [[ "$filepath" =~ "node_modules/" ]] || \
       [[ "$filepath" =~ "__pycache__/" ]] || \
       [[ "$filepath" =~ "\.pyc$" ]] || \
       [[ "$filepath" =~ "\.db$" ]] || \
       [[ "$filepath" =~ "\.db-journal$" ]] || \
       [[ "$filepath" =~ "\.pid$" ]]; then
        return
    fi
    
    log_file_access "$filepath" "$event_type"
    
    # Build relationships
    for entry in "${RECENT_FILES[@]}"; do
        local recent_file="${entry%%:*}"
        if [[ "$recent_file" != "$filepath" ]]; then
            update_file_relationship "$filepath" "$recent_file"
        fi
    done
    
    add_to_recent "$filepath"
    log "📝 ${filepath##*/} ($event_type)"
}

# Main watch loop
log "🎯 Watcher started"

fswatch -0 -r \
    --event Created \
    --event Updated \
    --event Renamed \
    "$WATCH_DIR" | while IFS= read -r -d $'\0' filepath; do
    
    # Determine event type
    local event_type="modified"
    if [[ ! -f "$filepath" ]]; then
        event_type="deleted"
    elif [[ -f "$filepath" ]]; then
        local birth=$(stat -f %B "$filepath" 2>/dev/null || echo "0")
        local now=$(date +%s)
        if (( now - birth < 2 )); then
            event_type="created"
        fi
    fi
    
    process_file_event "$filepath" "$event_type"
done
