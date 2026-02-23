#!/bin/bash
# BlackRoad Data Pipeline
# ETL and data processing across the cluster
# Agent: Icarus (b3e01bd9)

PINK='\033[38;5;205m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
RESET='\033[0m'

PIPELINE_DIR="$HOME/.blackroad/pipelines"
PIPELINE_DB="$PIPELINE_DIR/pipelines.db"
ALL_NODES=("lucidia" "cecilia" "octavia" "aria" "alice")

# Initialize
init() {
    mkdir -p "$PIPELINE_DIR"/{stages,data,temp}

    sqlite3 "$PIPELINE_DB" << 'SQL'
CREATE TABLE IF NOT EXISTS pipelines (
    id TEXT PRIMARY KEY,
    name TEXT,
    description TEXT,
    stages TEXT,
    schedule TEXT,
    status TEXT DEFAULT 'created',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    last_run DATETIME
);

CREATE TABLE IF NOT EXISTS runs (
    id TEXT PRIMARY KEY,
    pipeline_id TEXT,
    status TEXT DEFAULT 'running',
    started_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    completed_at DATETIME,
    records_in INTEGER DEFAULT 0,
    records_out INTEGER DEFAULT 0,
    errors INTEGER DEFAULT 0,
    logs TEXT,
    FOREIGN KEY (pipeline_id) REFERENCES pipelines(id)
);

CREATE TABLE IF NOT EXISTS stages (
    id TEXT PRIMARY KEY,
    name TEXT,
    type TEXT,
    config TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_pipeline ON runs(pipeline_id);
SQL

    echo -e "${GREEN}Data pipeline system initialized${RESET}"
}

# Create pipeline
create() {
    local name="$1"
    local description="${2:-}"

    local pipeline_id="pipe_$(date +%s)_$(openssl rand -hex 4)"

    sqlite3 "$PIPELINE_DB" "
        INSERT INTO pipelines (id, name, description, stages)
        VALUES ('$pipeline_id', '$name', '$description', '[]')
    "

    echo -e "${GREEN}Pipeline created: $pipeline_id${RESET}"
    echo "  Name: $name"
}

# Add stage to pipeline
add_stage() {
    local pipeline_id="$1"
    local stage_type="$2"
    local config="$3"

    local stage_id="stage_$(openssl rand -hex 8)"

    # Get current stages
    local stages=$(sqlite3 "$PIPELINE_DB" "SELECT stages FROM pipelines WHERE id = '$pipeline_id'")

    # Add new stage
    local new_stages=$(echo "$stages" | jq --arg id "$stage_id" --arg type "$stage_type" --arg cfg "$config" \
        '. + [{"id": $id, "type": $type, "config": ($cfg | fromjson)}]')

    sqlite3 "$PIPELINE_DB" "
        UPDATE pipelines SET stages = '$(echo "$new_stages" | sed "s/'/''/g")' WHERE id = '$pipeline_id'
    "

    echo -e "${GREEN}Added stage: $stage_type${RESET}"
}

# Available stage types
stage_types() {
    echo -e "${PINK}=== AVAILABLE STAGE TYPES ===${RESET}"
    echo
    echo "Sources:"
    echo "  file          Read from file/directory"
    echo "  http          Fetch from HTTP endpoint"
    echo "  database      Query database"
    echo "  stream        Read from event stream"
    echo
    echo "Transforms:"
    echo "  filter        Filter records by condition"
    echo "  map           Transform each record"
    echo "  aggregate     Group and aggregate"
    echo "  join          Join with another source"
    echo "  llm           Process with LLM"
    echo "  embed         Generate embeddings"
    echo
    echo "Sinks:"
    echo "  file          Write to file"
    echo "  database      Write to database"
    echo "  http          POST to endpoint"
    echo "  stream        Emit to event stream"
}

# Execute file source stage
exec_file_source() {
    local config="$1"
    local path=$(echo "$config" | jq -r '.path')
    local format=$(echo "$config" | jq -r '.format // "lines"')

    case "$format" in
        lines)
            cat "$path"
            ;;
        json)
            cat "$path" | jq -c '.[]'
            ;;
        csv)
            tail -n +2 "$path" | while IFS=, read -r line; do
                echo "$line"
            done
            ;;
    esac
}

# Execute filter stage
exec_filter() {
    local config="$1"
    local condition=$(echo "$config" | jq -r '.condition')
    local field=$(echo "$config" | jq -r '.field // "."')

    while IFS= read -r record; do
        if echo "$record" | jq -e "$field $condition" >/dev/null 2>&1; then
            echo "$record"
        fi
    done
}

# Execute map stage
exec_map() {
    local config="$1"
    local transform=$(echo "$config" | jq -r '.transform')

    while IFS= read -r record; do
        echo "$record" | jq -c "$transform"
    done
}

# Execute aggregate stage
exec_aggregate() {
    local config="$1"
    local group_by=$(echo "$config" | jq -r '.group_by // "."')
    local operation=$(echo "$config" | jq -r '.operation // "count"')

    # Collect all records
    local records=""
    while IFS= read -r record; do
        records="$records$record\n"
    done

    echo -e "$records" | jq -s "group_by($group_by) | map({key: .[0]$group_by, $operation: length})"
}

# Execute LLM stage
exec_llm() {
    local config="$1"
    local node=$(echo "$config" | jq -r '.node // "cecilia"')
    local model=$(echo "$config" | jq -r '.model // "llama3.2:1b"')
    local prompt_template=$(echo "$config" | jq -r '.prompt')
    local field=$(echo "$config" | jq -r '.input_field // "."')
    local output_field=$(echo "$config" | jq -r '.output_field // "llm_output"')

    while IFS= read -r record; do
        local input=$(echo "$record" | jq -r "$field")
        local prompt=$(echo "$prompt_template" | sed "s/{{INPUT}}/$input/g")

        local response=$(ssh -o ConnectTimeout=30 "$node" "
            curl -s http://localhost:11434/api/generate -d '{\"model\":\"$model\",\"prompt\":\"$prompt\",\"stream\":false}'
        " | jq -r '.response // ""')

        echo "$record" | jq -c --arg out "$response" ". + {\"$output_field\": \$out}"
    done
}

# Execute embedding stage
exec_embed() {
    local config="$1"
    local node=$(echo "$config" | jq -r '.node // "cecilia"')
    local model=$(echo "$config" | jq -r '.model // "nomic-embed-text"')
    local field=$(echo "$config" | jq -r '.input_field // "."')

    while IFS= read -r record; do
        local text=$(echo "$record" | jq -r "$field")

        local embedding=$(ssh -o ConnectTimeout=30 "$node" "
            curl -s http://localhost:11434/api/embeddings -d '{\"model\":\"$model\",\"prompt\":\"$text\"}'
        " | jq -c '.embedding // []')

        echo "$record" | jq -c --argjson emb "$embedding" '. + {"embedding": $emb}'
    done
}

# Execute file sink
exec_file_sink() {
    local config="$1"
    local path=$(echo "$config" | jq -r '.path')
    local format=$(echo "$config" | jq -r '.format // "jsonl"')

    case "$format" in
        jsonl)
            while IFS= read -r record; do
                echo "$record" >> "$path"
            done
            ;;
        json)
            local records=""
            while IFS= read -r record; do
                records="$records$record\n"
            done
            echo -e "$records" | jq -s '.' > "$path"
            ;;
    esac
}

# Execute a stage
execute_stage() {
    local stage_type="$1"
    local config="$2"

    case "$stage_type" in
        file)
            exec_file_source "$config"
            ;;
        filter)
            exec_filter "$config"
            ;;
        map)
            exec_map "$config"
            ;;
        aggregate)
            exec_aggregate "$config"
            ;;
        llm)
            exec_llm "$config"
            ;;
        embed)
            exec_embed "$config"
            ;;
        file_sink)
            exec_file_sink "$config"
            ;;
        *)
            cat  # Pass through for unknown types
            ;;
    esac
}

# Run pipeline
run() {
    local pipeline_id="$1"

    local pipeline=$(sqlite3 "$PIPELINE_DB" "SELECT name, stages FROM pipelines WHERE id = '$pipeline_id'")
    local name=$(echo "$pipeline" | cut -d'|' -f1)
    local stages=$(echo "$pipeline" | cut -d'|' -f2)

    echo -e "${PINK}╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${PINK}║           📊 RUNNING PIPELINE: $name${RESET}"
    echo -e "${PINK}╚══════════════════════════════════════════════════════════════╝${RESET}"
    echo

    local run_id="run_$(date +%s)_$(openssl rand -hex 4)"
    sqlite3 "$PIPELINE_DB" "
        INSERT INTO runs (id, pipeline_id) VALUES ('$run_id', '$pipeline_id')
    "

    local records_in=0
    local records_out=0
    local errors=0

    # Build pipeline command
    local cmd=""
    local stage_count=$(echo "$stages" | jq 'length')

    for i in $(seq 0 $((stage_count - 1))); do
        local stage=$(echo "$stages" | jq -c ".[$i]")
        local stage_type=$(echo "$stage" | jq -r '.type')
        local stage_config=$(echo "$stage" | jq -c '.config')

        echo -e "${BLUE}Stage $((i+1)): $stage_type${RESET}"

        if [ -z "$cmd" ]; then
            cmd="execute_stage '$stage_type' '$stage_config'"
        else
            cmd="$cmd | execute_stage '$stage_type' '$stage_config'"
        fi
    done

    # Execute pipeline
    local temp_out="$PIPELINE_DIR/temp/${run_id}.out"
    local temp_err="$PIPELINE_DIR/temp/${run_id}.err"

    eval "$cmd" > "$temp_out" 2> "$temp_err"

    records_out=$(wc -l < "$temp_out" | tr -d ' ')
    errors=$(wc -l < "$temp_err" | tr -d ' ')

    # Update run status
    sqlite3 "$PIPELINE_DB" "
        UPDATE runs SET
            status = 'completed',
            completed_at = datetime('now'),
            records_out = $records_out,
            errors = $errors
        WHERE id = '$run_id'
    "

    sqlite3 "$PIPELINE_DB" "
        UPDATE pipelines SET last_run = datetime('now') WHERE id = '$pipeline_id'
    "

    echo
    echo -e "${GREEN}Pipeline completed${RESET}"
    echo "  Run ID: $run_id"
    echo "  Records out: $records_out"
    echo "  Errors: $errors"
}

# List pipelines
list() {
    echo -e "${PINK}=== PIPELINES ===${RESET}"
    echo

    sqlite3 "$PIPELINE_DB" "
        SELECT p.id, p.name, p.status, json_array_length(p.stages), p.last_run,
               (SELECT COUNT(*) FROM runs r WHERE r.pipeline_id = p.id)
        FROM pipelines p ORDER BY p.created_at DESC
    " | while IFS='|' read -r id name status stages last_run runs; do
        local status_color=$YELLOW
        [ "$status" = "active" ] && status_color=$GREEN

        printf "  %-20s ${status_color}%-10s${RESET} %d stages, %d runs\n" "$id" "[$status]" "$stages" "$runs"
        echo "    $name (last: ${last_run:-never})"
    done
}

# Show pipeline details
show() {
    local pipeline_id="$1"

    local pipeline=$(sqlite3 "$PIPELINE_DB" "SELECT * FROM pipelines WHERE id = '$pipeline_id'")

    if [ -z "$pipeline" ]; then
        echo -e "${RED}Pipeline not found${RESET}"
        return 1
    fi

    echo -e "${PINK}=== PIPELINE DETAILS ===${RESET}"
    echo

    sqlite3 "$PIPELINE_DB" -line "SELECT id, name, description, status, last_run FROM pipelines WHERE id = '$pipeline_id'"

    echo
    echo "Stages:"
    sqlite3 "$PIPELINE_DB" "SELECT stages FROM pipelines WHERE id = '$pipeline_id'" | jq -c '.[]' | while IFS= read -r stage; do
        local type=$(echo "$stage" | jq -r '.type')
        local config=$(echo "$stage" | jq -c '.config')
        echo "  - $type: $config"
    done

    echo
    echo "Recent runs:"
    sqlite3 "$PIPELINE_DB" "
        SELECT id, status, records_out, errors, started_at
        FROM runs WHERE pipeline_id = '$pipeline_id'
        ORDER BY started_at DESC LIMIT 5
    " | while IFS='|' read -r run_id status records errors started; do
        echo "  $run_id: $status ($records records, $errors errors) @ $started"
    done
}

# Quick pipeline builder
quick() {
    local name="$1"
    local source="$2"
    local transform="$3"
    local sink="$4"

    echo -e "${PINK}=== QUICK PIPELINE BUILDER ===${RESET}"
    echo

    # Create pipeline
    local pipeline_id="pipe_$(date +%s)"
    sqlite3 "$PIPELINE_DB" "
        INSERT INTO pipelines (id, name, stages) VALUES ('$pipeline_id', '$name', '[]')
    "

    # Add source
    add_stage "$pipeline_id" "file" "{\"path\":\"$source\",\"format\":\"lines\"}"

    # Add transform if specified
    if [ -n "$transform" ]; then
        add_stage "$pipeline_id" "map" "{\"transform\":\"$transform\"}"
    fi

    # Add sink
    add_stage "$pipeline_id" "file_sink" "{\"path\":\"$sink\",\"format\":\"jsonl\"}"

    echo
    echo -e "${GREEN}Quick pipeline created: $pipeline_id${RESET}"
    run "$pipeline_id"
}

# Delete pipeline
delete() {
    local pipeline_id="$1"

    sqlite3 "$PIPELINE_DB" "
        DELETE FROM runs WHERE pipeline_id = '$pipeline_id';
        DELETE FROM pipelines WHERE id = '$pipeline_id';
    "

    echo -e "${GREEN}Deleted pipeline: $pipeline_id${RESET}"
}

# Stats
stats() {
    echo -e "${PINK}=== PIPELINE STATISTICS ===${RESET}"
    echo

    echo "Overall:"
    local total_pipelines=$(sqlite3 "$PIPELINE_DB" "SELECT COUNT(*) FROM pipelines")
    local total_runs=$(sqlite3 "$PIPELINE_DB" "SELECT COUNT(*) FROM runs")
    local total_records=$(sqlite3 "$PIPELINE_DB" "SELECT SUM(records_out) FROM runs")
    echo "  Pipelines: $total_pipelines"
    echo "  Total runs: $total_runs"
    echo "  Total records processed: ${total_records:-0}"

    echo
    echo "Recent runs:"
    sqlite3 "$PIPELINE_DB" "
        SELECT p.name, r.status, r.records_out, r.started_at
        FROM runs r JOIN pipelines p ON r.pipeline_id = p.id
        ORDER BY r.started_at DESC LIMIT 10
    " | while IFS='|' read -r name status records started; do
        local status_icon="✓"
        [ "$status" = "failed" ] && status_icon="✗"
        echo "  $status_icon $name: $records records @ $started"
    done
}

# Help
help() {
    echo -e "${PINK}BlackRoad Data Pipeline${RESET}"
    echo
    echo "ETL and data processing for the cluster"
    echo
    echo "Commands:"
    echo "  create <name>                   Create pipeline"
    echo "  add-stage <pipe> <type> <cfg>   Add processing stage"
    echo "  stage-types                     List available stages"
    echo "  run <pipeline>                  Execute pipeline"
    echo "  list                            List pipelines"
    echo "  show <pipeline>                 Pipeline details"
    echo "  quick <name> <src> <tr> <sink>  Quick pipeline builder"
    echo "  delete <pipeline>               Delete pipeline"
    echo "  stats                           Pipeline statistics"
    echo
    echo "Examples:"
    echo "  $0 create 'process-logs'"
    echo "  $0 add-stage pipe_123 file '{\"path\":\"/var/log/app.log\"}'"
    echo "  $0 add-stage pipe_123 filter '{\"condition\":\"> 0\",\"field\":\".level\"}'"
    echo "  $0 run pipe_123"
}

# Ensure initialized
[ -f "$PIPELINE_DB" ] || init >/dev/null

case "${1:-help}" in
    init)
        init
        ;;
    create|new)
        create "$2" "$3"
        ;;
    add-stage|stage)
        add_stage "$2" "$3" "$4"
        ;;
    stage-types|types)
        stage_types
        ;;
    run|execute)
        run "$2"
        ;;
    list|ls)
        list
        ;;
    show|info)
        show "$2"
        ;;
    quick)
        quick "$2" "$3" "$4" "$5"
        ;;
    delete|rm)
        delete "$2"
        ;;
    stats)
        stats
        ;;
    *)
        help
        ;;
esac
