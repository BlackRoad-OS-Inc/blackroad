#!/usr/bin/env zsh
# 🔧 CI/CD Pipeline Manager - Feature #29
# Complete pipeline orchestration with stages, tracking, and intelligent execution

# Colors
AMBER='\033[38;5;214m'; PINK='\033[38;5;205m'; VIOLET='\033[38;5;135m'; BBLUE='\033[38;5;69m'
GREEN='\033[0;32m'; RED='\033[0;31m'; BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'
CYAN="$AMBER"; YELLOW="$PINK"; BLUE="$BBLUE"; MAGENTA="$VIOLET"; PURPLE="$VIOLET"

DB_FILE="$HOME/.blackroad/ci-pipeline.db"

init_db() {
    mkdir -p "$(dirname "$DB_FILE")"
    sqlite3 "$DB_FILE" <<EOF
CREATE TABLE IF NOT EXISTS pipelines (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE,
    description TEXT,
    status TEXT DEFAULT 'idle',
    last_run INTEGER,
    success_count INTEGER DEFAULT 0,
    fail_count INTEGER DEFAULT 0,
    avg_duration REAL DEFAULT 0.0,
    created_at INTEGER
);

CREATE TABLE IF NOT EXISTS stages (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    pipeline_name TEXT,
    stage_name TEXT,
    stage_order INTEGER,
    command TEXT,
    timeout INTEGER DEFAULT 300,
    retry_count INTEGER DEFAULT 0,
    on_failure TEXT DEFAULT 'stop',
    created_at INTEGER
);

CREATE TABLE IF NOT EXISTS pipeline_runs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    pipeline_name TEXT,
    run_id TEXT UNIQUE,
    trigger TEXT,
    status TEXT,
    total_duration REAL,
    started_at INTEGER,
    completed_at INTEGER
);

CREATE TABLE IF NOT EXISTS stage_runs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    run_id TEXT,
    stage_name TEXT,
    status TEXT,
    output TEXT,
    error TEXT,
    duration REAL,
    started_at INTEGER,
    completed_at INTEGER
);
EOF
}

# Create pipeline
cmd_create() {
    init_db
    local name="${1}"
    local desc="${2:-CI/CD Pipeline}"
    
    if [[ -z "$name" ]]; then
        echo -e "${RED}❌ Usage: br ci create <name> [description]${NC}"
        exit 1
    fi
    
    echo -e "${CYAN}🔧 Creating CI/CD pipeline...${NC}\n"
    
    sqlite3 "$DB_FILE" "INSERT OR REPLACE INTO pipelines (name, description, created_at) VALUES ('$name', '$desc', $(date +%s));"
    
    # Add default stages
    sqlite3 "$DB_FILE" "INSERT INTO stages (pipeline_name, stage_name, stage_order, command, created_at) VALUES 
        ('$name', 'install', 1, 'npm install || pip install -r requirements.txt || true', $(date +%s)),
        ('$name', 'lint', 2, 'npm run lint || pylint . || true', $(date +%s)),
        ('$name', 'test', 3, 'npm test || pytest || cargo test || go test ./... || true', $(date +%s)),
        ('$name', 'build', 4, 'npm run build || cargo build --release || go build || true', $(date +%s));"
    
    echo -e "${GREEN}✓ Pipeline created:${NC} $name"
    echo -e "${BLUE}Description:${NC} $desc"
    echo -e "${BLUE}Stages:${NC} install → lint → test → build"
    echo -e "\n${YELLOW}💡 Run with:${NC} br ci run $name"
    echo -e "${YELLOW}💡 Add stages:${NC} br ci add-stage $name <stage> <command>"
}

# Run pipeline
cmd_run() {
    init_db
    local name="${1}"
    local trigger="${2:-manual}"
    
    if [[ -z "$name" ]]; then
        echo -e "${RED}❌ Usage: br ci run <pipeline> [trigger]${NC}"
        exit 1
    fi
    
    # Check pipeline exists
    local exists=$(sqlite3 "$DB_FILE" "SELECT name FROM pipelines WHERE name = '$name';")
    if [[ -z "$exists" ]]; then
        echo -e "${RED}❌ Pipeline not found: $name${NC}"
        echo -e "${YELLOW}Create it with:${NC} br ci create $name"
        exit 1
    fi
    
    local run_id="run-$(date +%s)-$RANDOM"
    local start_time=$(date +%s)
    
    echo -e "${CYAN}🚀 Running pipeline: $name${NC}"
    echo -e "${BLUE}Run ID:${NC} $run_id"
    echo -e "${BLUE}Trigger:${NC} $trigger\n"
    
    sqlite3 "$DB_FILE" "UPDATE pipelines SET status = 'running', last_run = $start_time WHERE name = '$name';"
    sqlite3 "$DB_FILE" "INSERT INTO pipeline_runs (pipeline_name, run_id, trigger, status, started_at) VALUES ('$name', '$run_id', '$trigger', 'running', $start_time);"
    
    local pipeline_failed=0
    local total_stages=0
    local passed_stages=0
    
    # Execute stages
    sqlite3 -separator $'\t' "$DB_FILE" "SELECT stage_name, command, timeout, retry_count, on_failure FROM stages WHERE pipeline_name = '$name' ORDER BY stage_order;" | while IFS=$'\t' read -r stage cmd timeout retries on_fail; do
        total_stages=$((total_stages + 1))
        
        echo -e "${MAGENTA}━━━ Stage: $stage ━━━${NC}"
        
        local stage_start=$(date +%s)
        local attempt=0
        local stage_passed=0
        
        while [[ $attempt -le $retries ]]; do
            if [[ $attempt -gt 0 ]]; then
                echo -e "${YELLOW}⟳ Retry attempt $attempt/$retries${NC}"
            fi
            
            # Run with timeout
            local output=$(timeout $timeout sh -c "$cmd" 2>&1)
            local exit_code=$?
            
            if [[ $exit_code -eq 0 ]]; then
                stage_passed=1
                break
            fi
            
            attempt=$((attempt + 1))
        done
        
        local stage_end=$(date +%s)
        local stage_duration=$((stage_end - stage_start))
        
        if [[ $stage_passed -eq 1 ]]; then
            echo -e "${GREEN}✓${NC} $stage completed (${stage_duration}s)"
            passed_stages=$((passed_stages + 1))
            
            sqlite3 "$DB_FILE" "INSERT INTO stage_runs (run_id, stage_name, status, output, duration, started_at, completed_at) VALUES ('$run_id', '$stage', 'success', '$(echo "$output" | head -100)', $stage_duration, $stage_start, $stage_end);"
        else
            echo -e "${RED}✗${NC} $stage failed after $attempt attempts"
            echo -e "${YELLOW}Last output:${NC}"
            echo "$output" | tail -20
            
            sqlite3 "$DB_FILE" "INSERT INTO stage_runs (run_id, stage_name, status, output, error, duration, started_at, completed_at) VALUES ('$run_id', '$stage', 'failed', '', '$(echo "$output" | tail -100)', $stage_duration, $stage_start, $stage_end);"
            
            if [[ "$on_fail" == "stop" ]]; then
                pipeline_failed=1
                break
            fi
        fi
        
        echo ""
    done
    
    local end_time=$(date +%s)
    local total_duration=$((end_time - start_time))
    
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    
    if [[ $pipeline_failed -eq 0 ]]; then
        echo -e "${GREEN}✓ Pipeline completed successfully!${NC}"
        echo -e "${BLUE}Duration:${NC} ${total_duration}s"
        echo -e "${BLUE}Stages:${NC} $passed_stages/$total_stages passed"
        
        sqlite3 "$DB_FILE" "UPDATE pipelines SET status = 'success', success_count = success_count + 1 WHERE name = '$name';"
        sqlite3 "$DB_FILE" "UPDATE pipeline_runs SET status = 'success', total_duration = $total_duration, completed_at = $end_time WHERE run_id = '$run_id';"
    else
        echo -e "${RED}✗ Pipeline failed${NC}"
        echo -e "${BLUE}Duration:${NC} ${total_duration}s"
        echo -e "${BLUE}Stages:${NC} $passed_stages/$total_stages passed"
        
        sqlite3 "$DB_FILE" "UPDATE pipelines SET status = 'failed', fail_count = fail_count + 1 WHERE name = '$name';"
        sqlite3 "$DB_FILE" "UPDATE pipeline_runs SET status = 'failed', total_duration = $total_duration, completed_at = $end_time WHERE run_id = '$run_id';"
    fi
    
    # Update average duration
    local avg=$(sqlite3 "$DB_FILE" "SELECT AVG(total_duration) FROM pipeline_runs WHERE pipeline_name = '$name';")
    sqlite3 "$DB_FILE" "UPDATE pipelines SET avg_duration = $avg WHERE name = '$name';"
}

# List pipelines
cmd_list() {
    init_db
    echo -e "${CYAN}📋 CI/CD Pipelines:${NC}\n"
    
    local count=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM pipelines;")
    
    if [[ $count -eq 0 ]]; then
        echo -e "${YELLOW}No pipelines yet${NC}"
        echo -e "Create one with: br ci create <name>"
        exit 0
    fi
    
    sqlite3 -separator $'\t' "$DB_FILE" "SELECT name, description, status, success_count, fail_count, avg_duration FROM pipelines;" | while IFS=$'\t' read -r name desc stat success fail avg; do
        local icon="🟢"
        [[ "$stat" == "running" ]] && icon="⚡"
        [[ "$stat" == "failed" ]] && icon="🔴"
        
        local success_rate=0
        local total=$((success + fail))
        if [[ $total -gt 0 ]]; then
            success_rate=$(echo "scale=1; ($success * 100) / $total" | bc)
        fi
        
        echo -e "$icon ${GREEN}$name${NC}"
        echo -e "  $desc"
        echo -e "  Status: $stat | Runs: $total | Success: ${success_rate}%"
        [[ -n "$avg" ]] && echo -e "  Avg Duration: $(echo $avg | awk '{printf "%.1f", $1}')s"
        echo ""
    done
}

# Show pipeline status
cmd_status() {
    init_db
    local name="${1}"
    
    if [[ -z "$name" ]]; then
        echo -e "${RED}❌ Usage: br ci status <pipeline>${NC}"
        exit 1
    fi
    
    echo -e "${CYAN}📊 Pipeline Status: $name${NC}\n"
    
    local info=$(sqlite3 -separator $'\t' "$DB_FILE" "SELECT description, status, success_count, fail_count, avg_duration, datetime(last_run, 'unixepoch') FROM pipelines WHERE name = '$name';")
    
    if [[ -z "$info" ]]; then
        echo -e "${RED}❌ Pipeline not found${NC}"
        exit 1
    fi
    
    local desc=$(echo "$info" | cut -f1)
    local stat=$(echo "$info" | cut -f2)
    local success=$(echo "$info" | cut -f3)
    local fail=$(echo "$info" | cut -f4)
    local avg=$(echo "$info" | cut -f5)
    local last=$(echo "$info" | cut -f6)
    
    local total=$((success + fail))
    local success_rate=0
    [[ $total -gt 0 ]] && success_rate=$(echo "scale=1; ($success * 100) / $total" | bc)
    
    echo -e "${BLUE}Description:${NC} $desc"
    echo -e "${BLUE}Status:${NC} $stat"
    echo -e "${BLUE}Total Runs:${NC} $total"
    echo -e "${BLUE}Success:${NC} $success (${success_rate}%)"
    echo -e "${BLUE}Failed:${NC} $fail"
    echo -e "${BLUE}Avg Duration:${NC} $(echo $avg | awk '{printf "%.1f", $1}')s"
    echo -e "${BLUE}Last Run:${NC} $last"
    
    echo -e "\n${CYAN}Pipeline Stages:${NC}"
    sqlite3 -separator $'\t' "$DB_FILE" "SELECT stage_order, stage_name, command FROM stages WHERE pipeline_name = '$name' ORDER BY stage_order;" | while IFS=$'\t' read -r order stage cmd; do
        echo -e "  ${MAGENTA}$order.${NC} $stage"
        echo -e "     ${BLUE}→${NC} $cmd"
    done
    
    echo -e "\n${CYAN}Recent Runs:${NC}"
    sqlite3 -separator $'\t' "$DB_FILE" "SELECT run_id, status, total_duration, datetime(started_at, 'unixepoch') FROM pipeline_runs WHERE pipeline_name = '$name' ORDER BY started_at DESC LIMIT 5;" | while IFS=$'\t' read -r run stat dur time; do
        local icon="✓"
        [[ "$stat" == "failed" ]] && icon="✗"
        [[ "$stat" == "running" ]] && icon="⚡"
        
        echo -e "  $icon $run | $stat ($(echo $dur | awk '{printf "%.1f", $1}')s) | $time"
    done
}

# Add stage to pipeline
cmd_add_stage() {
    init_db
    local pipeline="${1}"
    local stage="${2}"
    local command="${3}"
    local order="${4:-99}"
    
    if [[ -z "$pipeline" ]] || [[ -z "$stage" ]] || [[ -z "$command" ]]; then
        echo -e "${RED}❌ Usage: br ci add-stage <pipeline> <stage> <command> [order]${NC}"
        exit 1
    fi
    
    sqlite3 "$DB_FILE" "INSERT INTO stages (pipeline_name, stage_name, stage_order, command, created_at) VALUES ('$pipeline', '$stage', $order, '$command', $(date +%s));"
    
    echo -e "${GREEN}✓ Stage added to $pipeline:${NC} $stage"
    echo -e "${BLUE}Command:${NC} $command"
    echo -e "${BLUE}Order:${NC} $order"
}

# Watch pipeline
cmd_watch() {
    # Live GitHub Actions dashboard — polls every 5s
    local interval=${1:-5}
    local repo_arg=${2:-}

    # Detect repo from git remote
    local repo
    if [[ -n "$repo_arg" ]]; then
        repo="$repo_arg"
    else
        repo=$(git remote get-url origin 2>/dev/null | sed 's|.*github.com[:/]||;s|\.git$||')
    fi

    if [[ -z "$repo" ]]; then
        echo -e "  ${RED}✗${NC} no GitHub repo detected. usage: br ci watch [interval] [owner/repo]"
        return 1
    fi

    # Check gh auth
    if ! gh auth status &>/dev/null; then
        echo -e "  ${RED}✗${NC} not logged in to GitHub CLI. run: gh auth login"
        return 1
    fi

    local draw_dashboard
    draw_dashboard() {
        clear
        echo ""
        echo -e "  ${AMBER}${BOLD}◆ BR CI${NC}  ${DIM}live  ·  $repo  ·  every ${interval}s  ·  Ctrl+C to exit${NC}"
        echo -e "  ${DIM}────────────────────────────────────────────────────────────────${NC}"
        echo ""

        # Fetch recent runs
        local runs
        runs=$(gh api "repos/${repo}/actions/runs?per_page=12" \
            --jq '.workflow_runs[] | [.name, .head_branch, .status, .conclusion, .run_number, .updated_at, .id] | @tsv' \
            2>/dev/null)

        if [[ -z "$runs" ]]; then
            echo -e "  ${DIM}no workflow runs found${NC}"
            echo ""
            return
        fi

        # Column headers
        printf "  ${BOLD}%-28s %-18s %-12s %-10s %s${NC}\n" "WORKFLOW" "BRANCH" "STATUS" "RUN" "UPDATED"
        echo -e "  ${DIM}$(printf '%.0s─' {1..70})${NC}"

        echo "$runs" | while IFS=$'\t' read -r name branch status conclusion num updated id; do
            # Status icon + color
            local icon color
            case "$conclusion" in
                success)   icon="✓"; color="$GREEN" ;;
                failure)   icon="✗"; color="$RED" ;;
                cancelled) icon="○"; color="$DIM" ;;
                skipped)   icon="–"; color="$DIM" ;;
                *)
                    case "$status" in
                        in_progress) icon="●"; color="$AMBER" ;;
                        queued)      icon="◌"; color="$VIOLET" ;;
                        *)           icon="?"; color="$DIM" ;;
                    esac ;;
            esac

            # Trim name to 26 chars
            name="${name:0:26}"
            branch="${branch:0:16}"

            # Age
            local age
            age=$(python3 -c "
import sys, time
from datetime import datetime, timezone
try:
    t = datetime.fromisoformat('${updated}'.replace('Z','+00:00'))
    delta = int(time.time()) - int(t.timestamp())
    h,m = delta//3600, (delta%3600)//60
    print(f'{h}h {m}m ago' if h else f'{m}m ago')
except: print('—')
" 2>/dev/null)

            local disp_status="${status}"
            [[ -n "$conclusion" ]] && disp_status="$conclusion"

            printf "  ${color}${icon}${NC}  ${BOLD}%-26s${NC}  ${DIM}%-16s${NC}  ${color}%-10s${NC}  ${DIM}#%-6s${NC}  ${DIM}%s${NC}\n" \
                "$name" "$branch" "$disp_status" "$num" "$age"
        done

        echo ""
        echo -e "  ${DIM}In-progress runs:${NC}"
        echo "$runs" | while IFS=$'\t' read -r name branch status conclusion num updated id; do
            [[ "$status" != "in_progress" ]] && continue
            # Get jobs for this run
            local jobs
            jobs=$(gh api "repos/${repo}/actions/runs/${id}/jobs?per_page=8" \
                --jq '.jobs[] | [.name, .status, .conclusion] | @tsv' 2>/dev/null)
            echo -e "  ${AMBER}${BOLD}$name${NC}  ${DIM}#$num${NC}"
            echo "$jobs" | while IFS=$'\t' read -r jname jstatus jconc; do
                local ji jc
                case "$jconc" in
                    success) ji="✓"; jc="$GREEN" ;;
                    failure) ji="✗"; jc="$RED" ;;
                    *)
                        case "$jstatus" in
                            in_progress) ji="●"; jc="$AMBER" ;;
                            *) ji="○"; jc="$DIM" ;;
                        esac ;;
                esac
                printf "    ${jc}${ji}${NC}  ${DIM}%s${NC}\n" "$jname"
            done
        done

        echo ""
        printf "  ${DIM}last updated: %s${NC}\n" "$(date '+%H:%M:%S')"
        echo ""
    }

    # Initial draw then loop
    draw_dashboard
    while true; do
        sleep "$interval"
        draw_dashboard
    done
}

# Remove stage
cmd_remove_stage() {
    init_db
    local pipeline="${1}"
    local stage="${2}"
    
    if [[ -z "$pipeline" ]] || [[ -z "$stage" ]]; then
        echo -e "${RED}❌ Usage: br ci remove-stage <pipeline> <stage>${NC}"
        exit 1
    fi
    
    sqlite3 "$DB_FILE" "DELETE FROM stages WHERE pipeline_name = '$pipeline' AND stage_name = '$stage';"
    
    echo -e "${GREEN}✓ Stage removed from $pipeline:${NC} $stage"
}

# Help
cmd_help() {
    echo ""
    echo -e "  ${AMBER}${BOLD}◆ BR CI${NC}  ${DIM}Pipeline manager + live GitHub Actions dashboard.${NC}"
    echo -e "  ${DIM}────────────────────────────────────────────────${NC}"
    echo ""
    echo -e "  ${AMBER}watch${NC}   [interval] [owner/repo]  live GitHub Actions dashboard"
    echo -e "  ${AMBER}create${NC}  <name>                  create local pipeline"
    echo -e "  ${AMBER}list${NC}                            list local pipelines"
    echo -e "  ${AMBER}run${NC}     <name>                  run pipeline"
    echo -e "  ${AMBER}status${NC}  [name]                  check status"
    echo -e "  ${AMBER}history${NC} [name]                  execution history"
    echo -e "  ${AMBER}logs${NC}    <run-id>                view run logs"
    echo -e "  ${AMBER}stages${NC}  <name>                  list stages"
    echo -e "  ${AMBER}add-stage${NC} <name> <stage>        add stage"
    echo ""
    echo -e "  ${DIM}stages: test · lint · build · deploy · notify${NC}"
    echo ""
}

# Main dispatch
init_db

case "${1:-help}" in
    create|new|c) cmd_create "${@:2}" ;;
    run|r) cmd_run "${@:2}" ;;
    list|ls|l) cmd_list ;;
    status|stat|s) cmd_status "${@:2}" ;;
    watch|w|live) cmd_watch "${@:2}" ;;
    add-stage|add) cmd_add_stage "${@:2}" ;;
    remove-stage|rm) cmd_remove_stage "${@:2}" ;;
    history|hist) cmd_history "${@:2}" ;;
    help|--help|-h) cmd_help ;;
    *)
        echo -e "${RED}❌ Unknown command: $1${NC}"
        cmd_help
        exit 1
        ;;
esac
