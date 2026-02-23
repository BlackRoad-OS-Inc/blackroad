#!/usr/bin/env zsh
# 🔀 BR FLOW — Workflow Engine
# Chain br commands into named, reusable pipelines with conditions + scheduling

GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
DIM='\033[2m'
BOLD='\033[1m'
NC='\033[0m'

FLOW_DIR="$HOME/.blackroad/flows"
FLOW_DB="$HOME/.blackroad/flow.db"
BR="/Users/alexa/blackroad/br"
mkdir -p "$FLOW_DIR"

# ── DB ───────────────────────────────────────────────────────────────
init_db() {
  sqlite3 "$FLOW_DB" <<'SQL'
CREATE TABLE IF NOT EXISTS flows (
  id        TEXT PRIMARY KEY,
  name      TEXT,
  steps     TEXT,      -- JSON array of step objects
  triggers  TEXT,      -- JSON: {on_schedule, on_file, on_message}
  created   INTEGER DEFAULT (strftime('%s','now')),
  last_run  INTEGER,
  run_count INTEGER DEFAULT 0,
  status    TEXT DEFAULT 'active'
);
CREATE TABLE IF NOT EXISTS flow_runs (
  id        INTEGER PRIMARY KEY AUTOINCREMENT,
  flow_id   TEXT,
  started   INTEGER DEFAULT (strftime('%s','now')),
  ended     INTEGER,
  result    TEXT,  -- 'success' | 'failed' | 'partial'
  log       TEXT,
  steps_ok  INTEGER DEFAULT 0,
  steps_fail INTEGER DEFAULT 0
);
SQL
}

# ── built-in flows ────────────────────────────────────────────────────
seed_flows() {
  # Morning standup flow
  sqlite3 "$FLOW_DB" "INSERT OR IGNORE INTO flows(id,name,steps) VALUES(
    'morning',
    'Morning Standup',
    '[
      {\"cmd\":\"br chain tip\",\"name\":\"chain-status\",\"desc\":\"Check chain tip\"},
      {\"cmd\":\"br relay inbox\",\"name\":\"check-inbox\",\"desc\":\"Read messages\"},
      {\"cmd\":\"br collab status\",\"name\":\"mesh-status\",\"desc\":\"Mesh overview\"},
      {\"cmd\":\"br auth sessions\",\"name\":\"auth-check\",\"desc\":\"Active sessions\"}
    ]'
  );"

  # Security sweep flow
  sqlite3 "$FLOW_DB" "INSERT OR IGNORE INTO flows(id,name,steps) VALUES(
    'security-sweep',
    'Security Sweep',
    '[
      {\"cmd\":\"br harden scan\",\"name\":\"harden\",\"desc\":\"System hardening check\"},
      {\"cmd\":\"br comply pci\",\"name\":\"pci\",\"desc\":\"PCI compliance\"},
      {\"cmd\":\"br security scan\",\"name\":\"vuln\",\"desc\":\"Vulnerability scan\",\"continue_on_fail\":true},
      {\"cmd\":\"br vault expiring 30\",\"name\":\"secrets\",\"desc\":\"Expiring secrets\",\"continue_on_fail\":true}
    ]'
  );"

  # Deploy flow
  sqlite3 "$FLOW_DB" "INSERT OR IGNORE INTO flows(id,name,steps) VALUES(
    'deploy-check',
    'Pre-Deploy Checklist',
    '[
      {\"cmd\":\"br git status\",\"name\":\"git\",\"desc\":\"Git status check\"},
      {\"cmd\":\"br harden scan\",\"name\":\"security\",\"desc\":\"Security check\"},
      {\"cmd\":\"br chain append deploy-check $USER pre-deploy-verify\",\"name\":\"log\",\"desc\":\"Log to chain\"}
    ]'
  );"

  # Chain + relay broadcast flow
  sqlite3 "$FLOW_DB" "INSERT OR IGNORE INTO flows(id,name,steps) VALUES(
    'broadcast-status',
    'Broadcast Status to Mesh',
    '[
      {\"cmd\":\"br chain tip\",\"name\":\"chain\",\"desc\":\"Get chain tip\"},
      {\"cmd\":\"br relay send all status \\\"Flow run: broadcast-status\\\"\",\"name\":\"relay\",\"desc\":\"Broadcast to all instances\"},
      {\"cmd\":\"br chain append flow-run broadcast-status workflow-executed\",\"name\":\"anchor\",\"desc\":\"Anchor to chain\"}
    ]'
  );"
}

# ── run a flow ────────────────────────────────────────────────────────
run_flow() {
  local flow_id=$1

  # Use Python for reliable DB read
  local flow_data
  flow_data=$(python3 <<PYEOF
import sqlite3, json, sys
db = sqlite3.connect("$FLOW_DB")
row = db.execute("SELECT id,name,steps FROM flows WHERE id=? AND status='active'", ("$flow_id",)).fetchone()
if not row:
    sys.exit(1)
fid, name, steps_json = row
steps = json.loads(steps_json)
print(name)
for s in steps:
    print(json.dumps(s))
PYEOF
)
  if [[ $? -ne 0 || -z "$flow_data" ]]; then
    echo -e "${RED}✗ Flow not found: $flow_id${NC}"; exit 1
  fi

  local name=$(echo "$flow_data" | head -1)
  local steps_lines=$(echo "$flow_data" | tail -n +2)
  local step_count=$(echo "$steps_lines" | wc -l | tr -d ' ')

  echo -e ""
  echo -e "  ${CYAN}${BOLD}🔀 Running Flow: $name${NC}  ${DIM}($flow_id)${NC}"
  echo -e "  ${DIM}────────────────────────────────────────────────────${NC}"

  local ok=0
  local fail=0
  local log=""
  local start_ts=$(date +%s)
  local step_num=0

  echo "$steps_lines" | while IFS= read step_json; do
    ((step_num++))
    local cmd=$(echo "$step_json" | python3 -c "import sys,json; d=json.loads(sys.stdin.read()); print(d.get('cmd',''))")
    local sname=$(echo "$step_json" | python3 -c "import sys,json; d=json.loads(sys.stdin.read()); print(d.get('name','step'))")
    local sdesc=$(echo "$step_json" | python3 -c "import sys,json; d=json.loads(sys.stdin.read()); print(d.get('desc',''))")
    local cont=$(echo "$step_json" | python3 -c "import sys,json; d=json.loads(sys.stdin.read()); print(str(d.get('continue_on_fail',False)).lower())")

    echo -e "  ${YELLOW}[$step_num/$step_count]${NC} ${CYAN}$sname${NC}  ${DIM}$sdesc${NC}"
    echo -e "  ${DIM}  → $cmd${NC}"

    eval "$cmd" >/dev/null 2>&1
    local step_rc=$?

    if [[ $step_rc -eq 0 ]]; then
      echo -e "  ${GREEN}  ✓ done${NC}"
    else
      echo -e "  ${RED}  ✗ failed (exit $step_rc)${NC}"
      if [[ "$cont" != "true" ]]; then
        echo -e "  ${RED}  ↳ Aborting (use continue_on_fail:true to skip)${NC}"
        break
      fi
    fi
    echo -e ""
  done

  local end_ts=$(date +%s)
  local elapsed=$((end_ts - start_ts))

  sqlite3 "$FLOW_DB" "
    INSERT INTO flow_runs(flow_id,ended,result,log,steps_ok,steps_fail)
    VALUES('$flow_id',$end_ts,'completed','$log',0,0);
    UPDATE flows SET last_run=$end_ts, run_count=run_count+1 WHERE id='$flow_id';
  "

  echo -e "  ${DIM}────────────────────────────────────────────────────${NC}"
  echo -e "  ${GREEN}${BOLD}done${NC}  ${DIM}${elapsed}s${NC}"
  echo -e ""
}

# ── commands ─────────────────────────────────────────────────────────

cmd_list() {
  init_db; seed_flows
  echo -e ""
  echo -e "  ${CYAN}${BOLD}🔀 Flows${NC}"
  echo -e "  ${DIM}────────────────────────────────────────────────────────────${NC}"
  sqlite3 "$FLOW_DB" "SELECT id, name, run_count, datetime(last_run,'unixepoch','localtime'), status FROM flows ORDER BY run_count DESC;" | while IFS='|' read fid fname runs last_run fstatus; do
    local step_count=$(sqlite3 "$FLOW_DB" "SELECT steps FROM flows WHERE id='$fid';" | python3 -c "import sys,json; s=sys.stdin.read().strip(); print(len(json.loads(s))) if s else print(0)" 2>/dev/null)
    local run_info="${DIM}${runs} runs${NC}"
    [[ -n "$last_run" ]] && run_info="${run_info}  ${DIM}last: $last_run${NC}"
    echo -e "  ${YELLOW}$fid${NC}  ${fname}  ${DIM}($step_count steps)${NC}  $run_info"
  done
  echo -e ""
  echo -e "  ${DIM}  br flow run <id>   br flow new <id> <name>   br flow show <id>${NC}"
  echo -e ""
}

cmd_show() {
  init_db; seed_flows
  local fid=$1
  python3 <<PYEOF
import sqlite3, json, sys

db = sqlite3.connect("$FLOW_DB")
row = db.execute("SELECT id,name,steps,run_count,last_run FROM flows WHERE id=?", ("$fid",)).fetchone()
if not row:
    print(f"\033[31m✗ Flow not found: $fid\033[0m")
    sys.exit(1)
fid, name, steps_json, runs, last_run = row
try:
    steps = json.loads(steps_json)
except:
    steps = []
print(f"\n  \033[1m\033[36m🔀 {name}\033[0m  \033[2m({fid})\033[0m")
print(f"  \033[2mSteps:\033[0m")
for i, s in enumerate(steps, 1):
    cont = "  \033[2m(continue_on_fail)\033[0m" if s.get("continue_on_fail") else ""
    print(f"  {i}. \033[36m{s.get('name','?')}\033[0m  {s.get('desc','')}")
    print(f"     \033[2m→ {s.get('cmd','?')}\033[0m{cont}")
print(f"\n  \033[2mRuns: {runs or 0}\033[0m\n")
PYEOF
}

cmd_new() {
  init_db
  local fid=$1
  local fname=$2
  if [[ -z "$fid" || -z "$fname" ]]; then
    echo -e "${RED}Usage: br flow new <id> <name>${NC}"; exit 1
  fi
  # Create empty flow file for editing
  local flow_file="$FLOW_DIR/${fid}.json"
  cat > "$flow_file" <<FLOWEOF
{
  "id": "$fid",
  "name": "$fname",
  "steps": [
    {
      "name": "step-1",
      "desc": "Description of step 1",
      "cmd": "br chain tip",
      "continue_on_fail": false
    },
    {
      "name": "step-2",
      "desc": "Description of step 2",
      "cmd": "br relay send all \"$fid started\" \"flow $fname is running\"",
      "continue_on_fail": true
    }
  ]
}
FLOWEOF
  echo -e "${GREEN}✓ Created flow template:${NC} $flow_file"
  echo -e "${DIM}  Edit the file, then run: br flow import $fid${NC}"
}

cmd_import() {
  init_db
  local fid=$1
  local flow_file="${2:-$FLOW_DIR/${fid}.json}"
  [[ -f "$flow_file" ]] || { echo -e "${RED}✗ File not found: $flow_file${NC}"; exit 1; }
  local data=$(cat "$flow_file")
  local name=$(echo "$data" | python3 -c "import sys,json; print(json.load(sys.stdin).get('name','?'))")
  local steps=$(echo "$data" | python3 -c "import sys,json; print(json.dumps(json.load(sys.stdin).get('steps',[])))")
  sqlite3 "$FLOW_DB" "INSERT OR REPLACE INTO flows(id,name,steps) VALUES('$fid','$name','$steps');"
  echo -e "${GREEN}✓ Imported flow: $name ($fid)${NC}"
}

cmd_history() {
  init_db
  local n=${1:-10}
  echo -e ""
  echo -e "  ${CYAN}${BOLD}🔀 Run History (last $n)${NC}"
  echo -e "  ${DIM}──────────────────────────────────────────────────────────${NC}"
  sqlite3 "$FLOW_DB" "SELECT f.name, r.result, datetime(r.started,'unixepoch','localtime'), r.steps_ok, r.steps_fail, r.log FROM flow_runs r JOIN flows f ON r.flow_id=f.id ORDER BY r.id DESC LIMIT $n;" | while IFS='|' read fname result ts ok fail log; do
    local color=$GREEN; [[ "$result" == "failed" ]] && color=$RED; [[ "$result" == "partial" ]] && color=$YELLOW
    echo -e "  ${DIM}$ts${NC}  ${color}$result${NC}  ${CYAN}$fname${NC}  ${DIM}ok=$ok fail=$fail${NC}"
  done
  echo -e ""
}

cmd_delete() {
  init_db
  local fid=$1
  sqlite3 "$FLOW_DB" "UPDATE flows SET status='deleted' WHERE id='$fid';"
  echo -e "${GREEN}✓ Deleted flow: $fid${NC}"
}

cmd_help() {
  echo -e ""
  echo -e "  ${CYAN}${BOLD}🔀 BR FLOW${NC}  ${DIM}Workflow Engine${NC}"
  echo -e "  ${DIM}Chain br commands into named, reusable pipelines${NC}"
  echo -e "  ${DIM}────────────────────────────────────────────────────${NC}"
  echo -e "  ${BOLD}USAGE${NC}  br flow <command> [args]"
  echo -e ""
  echo -e "  ${YELLOW}FLOWS${NC}"
  echo -e "  ${CYAN}  list${NC}                         List all flows"
  echo -e "  ${CYAN}  show <id>${NC}                    Show flow steps"
  echo -e "  ${CYAN}  run <id>${NC}                     Execute a flow"
  echo -e "  ${CYAN}  history [n]${NC}                  Run history"
  echo -e ""
  echo -e "  ${YELLOW}CREATE${NC}"
  echo -e "  ${CYAN}  new <id> <name>${NC}              Create flow template"
  echo -e "  ${CYAN}  import <id> [file]${NC}           Import flow from JSON"
  echo -e "  ${CYAN}  delete <id>${NC}                  Remove a flow"
  echo -e ""
  echo -e "  ${YELLOW}BUILT-IN FLOWS${NC}"
  echo -e "  ${DIM}  morning         Morning standup (chain+relay+mesh+auth)${NC}"
  echo -e "  ${DIM}  security-sweep  Full security check${NC}"
  echo -e "  ${DIM}  deploy-check    Pre-deploy checklist${NC}"
  echo -e "  ${DIM}  broadcast-status  Broadcast chain status to mesh${NC}"
  echo -e ""
}

# ── dispatch ──────────────────────────────────────────────────────────
init_db; seed_flows

case "${1:-help}" in
  list|ls|flows)           cmd_list ;;
  show|info|view)          cmd_show "$2" ;;
  run|exec|go)             run_flow "$2" ;;
  new|create|add)          cmd_new "$2" "$3" ;;
  import|load)             cmd_import "$2" "$3" ;;
  history|log|runs)        cmd_history "${2:-10}" ;;
  delete|rm|remove)        cmd_delete "$2" ;;
  help|--help|-h)          cmd_help ;;
  # shortcut: br flow morning → br flow run morning
  morning|security-sweep|deploy-check|broadcast-status) run_flow "$1" ;;
  *)
    # Try to run as flow id
    local exists=$(sqlite3 "$FLOW_DB" "SELECT id FROM flows WHERE id='$1' AND status='active';" 2>/dev/null)
    if [[ -n "$exists" ]]; then run_flow "$1"
    else echo -e "${RED}✗ Unknown: $1${NC}"; cmd_help; exit 1; fi ;;
esac
