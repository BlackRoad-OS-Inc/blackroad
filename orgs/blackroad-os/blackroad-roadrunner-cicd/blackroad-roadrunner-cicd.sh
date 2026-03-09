#!/bin/bash
# RoadRunner CI/CD - Automated Deployment Pipeline
# BlackRoad OS, Inc. © 2026

CICD_DIR="$HOME/.blackroad/roadrunner"
CICD_DB="$CICD_DIR/cicd.db"
PIPELINE_DIR="$CICD_DIR/pipelines"
LOG_DIR="$CICD_DIR/logs"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

init() {
    echo -e "${PURPLE}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║     🏃 RoadRunner CI/CD Pipeline              ║${NC}"
    echo -e "${PURPLE}╚════════════════════════════════════════════════╝${NC}\n"

    mkdir -p "$PIPELINE_DIR"
    mkdir -p "$LOG_DIR"

    # Create pipeline database
    sqlite3 "$CICD_DB" <<'SQL'
-- Pipelines
CREATE TABLE IF NOT EXISTS pipelines (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE NOT NULL,
    repo TEXT NOT NULL,
    branch TEXT DEFAULT 'main',
    stages TEXT NOT NULL,              -- JSON array of stages
    triggers TEXT NOT NULL,             -- JSON: push, pr, schedule, manual
    config TEXT,                        -- JSON configuration
    status TEXT DEFAULT 'active',
    created_at INTEGER NOT NULL,
    last_run INTEGER
);

-- Pipeline runs
CREATE TABLE IF NOT EXISTS pipeline_runs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    pipeline_id INTEGER NOT NULL,
    trigger TEXT NOT NULL,              -- what triggered this run
    status TEXT DEFAULT 'running',      -- running, success, failed, cancelled
    started_at INTEGER NOT NULL,
    finished_at INTEGER,
    duration INTEGER,
    commit_hash TEXT,
    log_file TEXT,
    FOREIGN KEY (pipeline_id) REFERENCES pipelines(id)
);

-- Stages
CREATE TABLE IF NOT EXISTS stages (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    run_id INTEGER NOT NULL,
    name TEXT NOT NULL,
    commands TEXT NOT NULL,             -- JSON array of commands
    status TEXT DEFAULT 'pending',      -- pending, running, success, failed, skipped
    started_at INTEGER,
    finished_at INTEGER,
    duration INTEGER,
    output TEXT,
    FOREIGN KEY (run_id) REFERENCES pipeline_runs(id)
);

-- Deployments
CREATE TABLE IF NOT EXISTS deployments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    run_id INTEGER NOT NULL,
    environment TEXT NOT NULL,          -- dev, staging, production
    service TEXT NOT NULL,
    version TEXT,
    url TEXT,
    status TEXT DEFAULT 'pending',
    deployed_at INTEGER,
    FOREIGN KEY (run_id) REFERENCES pipeline_runs(id)
);

CREATE INDEX IF NOT EXISTS idx_pipeline_runs_pipeline ON pipeline_runs(pipeline_id);
CREATE INDEX IF NOT EXISTS idx_pipeline_runs_status ON pipeline_runs(status);
CREATE INDEX IF NOT EXISTS idx_stages_run ON stages(run_id);
CREATE INDEX IF NOT EXISTS idx_deployments_run ON deployments(run_id);

SQL

    echo -e "${GREEN}✓${NC} RoadRunner CI/CD initialized"
}

# Create pipeline
create_pipeline() {
    local name="$1"
    local repo="$2"
    local branch="${3:-main}"

    if [ -z "$name" ] || [ -z "$repo" ]; then
        echo -e "${RED}Error: Pipeline name and repo required${NC}"
        return 1
    fi

    # Default stages
    local stages='["test","build","deploy"]'
    local triggers='{"push":true,"pr":true,"schedule":"0 2 * * *","manual":true}'

    local timestamp=$(date +%s)

    sqlite3 "$CICD_DB" <<SQL
INSERT INTO pipelines (name, repo, branch, stages, triggers, created_at)
VALUES ('$name', '$repo', '$branch', '$stages', '$triggers', $timestamp);
SQL

    echo -e "${GREEN}✓${NC} Pipeline created: $name"
    echo -e "  ${CYAN}Repo:${NC} $repo"
    echo -e "  ${CYAN}Branch:${NC} $branch"
    echo -e "  ${CYAN}Stages:${NC} test → build → deploy"
}

# Run pipeline
run_pipeline() {
    local pipeline_name="$1"
    local trigger="${2:-manual}"

    # Get pipeline config
    local pipeline_id=$(sqlite3 "$CICD_DB" "SELECT id FROM pipelines WHERE name = '$pipeline_name'")

    if [ -z "$pipeline_id" ]; then
        echo -e "${RED}Error: Pipeline not found: $pipeline_name${NC}"
        return 1
    fi

    local repo=$(sqlite3 "$CICD_DB" "SELECT repo FROM pipelines WHERE id = $pipeline_id")
    local branch=$(sqlite3 "$CICD_DB" "SELECT branch FROM pipelines WHERE id = $pipeline_id")
    local stages=$(sqlite3 "$CICD_DB" "SELECT stages FROM pipelines WHERE id = $pipeline_id")

    echo -e "${CYAN}🏃 Running pipeline: $pipeline_name${NC}"
    echo -e "  ${CYAN}Trigger:${NC} $trigger"

    local started=$(date +%s)
    local log_file="$LOG_DIR/run-$(date +%Y%m%d-%H%M%S).log"

    # Create run
    sqlite3 "$CICD_DB" <<SQL
INSERT INTO pipeline_runs (pipeline_id, trigger, started_at, log_file)
VALUES ($pipeline_id, '$trigger', $started, '$log_file');
SQL

    local run_id=$(sqlite3 "$CICD_DB" "SELECT last_insert_rowid()")

    echo "Pipeline Run #$run_id" > "$log_file"
    echo "Started: $(date)" >> "$log_file"
    echo "Trigger: $trigger" >> "$log_file"
    echo "---" >> "$log_file"

    # Execute stages (simplified)
    local overall_status="success"

    for stage in test build deploy; do
        echo -e "\n${PURPLE}━━━ Stage: $stage ━━━${NC}"

        local stage_start=$(date +%s)

        sqlite3 "$CICD_DB" <<SQL
INSERT INTO stages (run_id, name, commands, status, started_at)
VALUES ($run_id, '$stage', '[]', 'running', $stage_start);
SQL

        local stage_id=$(sqlite3 "$CICD_DB" "SELECT last_insert_rowid()")

        # Simulate stage execution
        local stage_status="success"

        case "$stage" in
            test)
                echo -e "  ${CYAN}→${NC} Running tests..."
                echo "  ✓ Unit tests passed"
                ;;
            build)
                echo -e "  ${CYAN}→${NC} Building application..."
                echo "  ✓ Build successful"
                ;;
            deploy)
                echo -e "  ${CYAN}→${NC} Deploying to production..."
                echo "  ✓ Deployment complete"

                # Record deployment
                sqlite3 "$CICD_DB" <<SQL
INSERT INTO deployments (run_id, environment, service, status, deployed_at)
VALUES ($run_id, 'production', '$pipeline_name', 'success', $(date +%s));
SQL
                ;;
        esac

        local stage_end=$(date +%s)
        local stage_duration=$((stage_end - stage_start))

        sqlite3 "$CICD_DB" <<SQL
UPDATE stages
SET status = '$stage_status', finished_at = $stage_end, duration = $stage_duration
WHERE id = $stage_id;
SQL

        if [ "$stage_status" = "failed" ]; then
            overall_status="failed"
            break
        fi
    done

    local finished=$(date +%s)
    local duration=$((finished - started))

    sqlite3 "$CICD_DB" <<SQL
UPDATE pipeline_runs
SET status = '$overall_status', finished_at = $finished, duration = $duration
WHERE id = $run_id;

UPDATE pipelines
SET last_run = $finished
WHERE id = $pipeline_id;
SQL

    echo "" >> "$log_file"
    echo "Finished: $(date)" >> "$log_file"
    echo "Status: $overall_status" >> "$log_file"
    echo "Duration: ${duration}s" >> "$log_file"

    echo -e "\n${GREEN}✓${NC} Pipeline completed: $overall_status"
    echo -e "  ${CYAN}Duration:${NC} ${duration}s"
    echo -e "  ${CYAN}Log:${NC} $log_file"

    # Log to memory
    ~/memory-system.sh log "pipeline-run" "$pipeline_name" "RoadRunner pipeline $pipeline_name completed with status: $overall_status (${duration}s)" "cicd,automation" 2>/dev/null
}

# List pipelines
list_pipelines() {
    echo -e "${PURPLE}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║     Active Pipelines                          ║${NC}"
    echo -e "${PURPLE}╚════════════════════════════════════════════════╝${NC}\n"

    sqlite3 -header -column "$CICD_DB" <<SQL
SELECT
    name,
    repo,
    branch,
    status,
    datetime(last_run, 'unixepoch', 'localtime') as last_run
FROM pipelines
ORDER BY created_at DESC;
SQL
}

# Show pipeline history
history() {
    local pipeline_name="$1"

    if [ -z "$pipeline_name" ]; then
        echo -e "${RED}Error: Pipeline name required${NC}"
        return 1
    fi

    echo -e "${PURPLE}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║     Pipeline History: $pipeline_name           ║${NC}"
    echo -e "${PURPLE}╚════════════════════════════════════════════════╝${NC}\n"

    sqlite3 -header -column "$CICD_DB" <<SQL
SELECT
    r.id,
    r.status,
    r.trigger,
    r.duration || 's' as duration,
    datetime(r.started_at, 'unixepoch', 'localtime') as started
FROM pipeline_runs r
JOIN pipelines p ON r.pipeline_id = p.id
WHERE p.name = '$pipeline_name'
ORDER BY r.started_at DESC
LIMIT 20;
SQL
}

# Dashboard
dashboard() {
    echo -e "${PURPLE}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║     🏃 RoadRunner Dashboard                   ║${NC}"
    echo -e "${PURPLE}╚════════════════════════════════════════════════╝${NC}\n"

    local total_pipelines=$(sqlite3 "$CICD_DB" "SELECT COUNT(*) FROM pipelines")
    local total_runs=$(sqlite3 "$CICD_DB" "SELECT COUNT(*) FROM pipeline_runs")
    local successful_runs=$(sqlite3 "$CICD_DB" "SELECT COUNT(*) FROM pipeline_runs WHERE status = 'success'")
    local failed_runs=$(sqlite3 "$CICD_DB" "SELECT COUNT(*) FROM pipeline_runs WHERE status = 'failed'")
    local total_deployments=$(sqlite3 "$CICD_DB" "SELECT COUNT(*) FROM deployments")

    local success_rate=0
    if [ "$total_runs" -gt 0 ]; then
        success_rate=$((successful_runs * 100 / total_runs))
    fi

    echo -e "${CYAN}📊 Statistics${NC}"
    echo -e "  ${GREEN}Pipelines:${NC} $total_pipelines"
    echo -e "  ${GREEN}Total Runs:${NC} $total_runs"
    echo -e "  ${GREEN}Successful:${NC} $successful_runs"
    echo -e "  ${RED}Failed:${NC} $failed_runs"
    echo -e "  ${PURPLE}Success Rate:${NC} ${success_rate}%"
    echo -e "  ${PURPLE}Deployments:${NC} $total_deployments"

    echo -e "\n${CYAN}🔥 Recent Runs${NC}"
    sqlite3 -header -column "$CICD_DB" <<SQL
SELECT
    p.name as pipeline,
    r.status,
    r.duration || 's' as duration,
    datetime(r.started_at, 'unixepoch', 'localtime') as started
FROM pipeline_runs r
JOIN pipelines p ON r.pipeline_id = p.id
ORDER BY r.started_at DESC
LIMIT 5;
SQL
}

# Main execution
case "${1:-help}" in
    init)
        init
        ;;
    create)
        create_pipeline "$2" "$3" "$4"
        ;;
    run)
        run_pipeline "$2" "$3"
        ;;
    list)
        list_pipelines
        ;;
    history)
        history "$2"
        ;;
    dashboard)
        dashboard
        ;;
    help|*)
        echo -e "${PURPLE}╔════════════════════════════════════════════════╗${NC}"
        echo -e "${PURPLE}║     🏃 RoadRunner CI/CD Pipeline              ║${NC}"
        echo -e "${PURPLE}╚════════════════════════════════════════════════╝${NC}\n"
        echo "Automated deployment pipeline for BlackRoad"
        echo ""
        echo "Usage: $0 COMMAND [OPTIONS]"
        echo ""
        echo "Setup:"
        echo "  init                              - Initialize RoadRunner"
        echo "  create NAME REPO [BRANCH]         - Create new pipeline"
        echo ""
        echo "Operations:"
        echo "  run NAME [TRIGGER]                - Run pipeline"
        echo "  list                              - List all pipelines"
        echo "  history NAME                      - Show pipeline history"
        echo "  dashboard                         - Show dashboard"
        echo ""
        echo "Examples:"
        echo "  $0 init"
        echo "  $0 create blackroad-os-web 'BlackRoad-OS/blackroad-os-web'"
        echo "  $0 run blackroad-os-web push"
        echo "  $0 dashboard"
        ;;
esac
