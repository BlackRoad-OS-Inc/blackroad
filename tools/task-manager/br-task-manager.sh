#!/bin/zsh
# BR TASK-MANAGER - Mesh task queue: post, claim, complete, track

GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'
RED='\033[0;31m'; PURPLE='\033[0;35m'; NC='\033[0m'; BOLD='\033[1m'

DB_FILE="$HOME/.blackroad/task-manager.db"
QUEUE_DIR="$PWD/shared/mesh/queue"
COLLAB_FILE="$PWD/coordination/collaboration/active-instances.json"

mkdir -p "$QUEUE_DIR"

init_db() {
  mkdir -p "$(dirname $DB_FILE)"
  sqlite3 "$DB_FILE" <<'SQL'
CREATE TABLE IF NOT EXISTS tasks (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  priority TEXT DEFAULT 'normal',
  tags TEXT,
  status TEXT DEFAULT 'available',
  posted_by TEXT DEFAULT 'lucidia-copilot-cli',
  claimed_by TEXT,
  posted_at TEXT DEFAULT (datetime('now')),
  claimed_at TEXT,
  completed_at TEXT,
  result TEXT
);
SQL
}
init_db

_gen_id() {
  echo "task-$(date +%s)-$(head -c 4 /dev/urandom | xxd -p)"
}

cmd_post() {
  local title="$1"; shift
  local desc="${*:-No description}"
  local priority="${TASK_PRIORITY:-normal}"
  local id
  id=$(_gen_id)

  sqlite3 "$DB_FILE" "INSERT INTO tasks(id,title,description,priority) VALUES('$id',$(python3 -c "import json,sys; print(json.dumps(sys.argv[1]))" "$title"),$(python3 -c "import json,sys; print(json.dumps(sys.argv[1]))" "$desc"),'$priority');"

  # also write to mesh queue so other instances see it
  printf '{"type":"task","id":"%s","title":"%s","priority":"%s","posted_by":"lucidia-copilot-cli","ts":"%s"}\n' \
    "$id" "$title" "$priority" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$QUEUE_DIR/${id}.json"

  echo -e "${GREEN}✓ Posted:${NC} ${id}"
  echo -e "  ${CYAN}Title:${NC}    $title"
  echo -e "  ${CYAN}Desc:${NC}     $desc"
  echo -e "  ${CYAN}Priority:${NC} $priority"
}

cmd_list() {
  local filter="${1:-available}"
  echo ""
  if [[ "$filter" == "all" ]]; then
    echo -e "${BOLD}${CYAN}All tasks:${NC}"
    echo ""
    sqlite3 "$DB_FILE" "SELECT id, status, priority, title FROM tasks ORDER BY posted_at DESC LIMIT 30;" 2>/dev/null | \
      while IFS='|' read id stat prio title; do
        local color="${YELLOW}"
        [[ "$stat" == "completed" ]] && color="${GREEN}"
        [[ "$stat" == "in_progress" ]] && color="${CYAN}"
        echo -e "  ${color}${stat:0:10}${NC}  ${prio:0:6}  ${BOLD}${id:0:20}${NC}  ${title}"
      done
  else
    echo -e "${BOLD}${CYAN}Tasks (${filter}):${NC}"
    echo ""
    sqlite3 "$DB_FILE" "SELECT id, priority, title, posted_by FROM tasks WHERE status='$filter' ORDER BY posted_at DESC LIMIT 20;" 2>/dev/null | \
      while IFS='|' read id prio title posted_by; do
        echo -e "  ${YELLOW}▸${NC} ${BOLD}${id:0:25}${NC}  [${prio}]  ${title}  ${CYAN}(by ${posted_by})${NC}"
      done
  fi
  echo ""
  local counts
  counts=$(sqlite3 "$DB_FILE" "SELECT status, COUNT(*) FROM tasks GROUP BY status;" 2>/dev/null)
  echo -e "${CYAN}Counts:${NC}"
  echo "$counts" | while IFS='|' read s c; do echo -e "  ${s}: ${c}"; done
  echo ""
}

cmd_claim() {
  local id="$1"
  local claimer="${2:-lucidia-copilot-cli}"
  [[ -z "$id" ]] && { echo "Usage: br task claim <id> [instance]"; return 1; }

  local exists
  exists=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM tasks WHERE id LIKE '%$id%' AND status='available';" 2>/dev/null)
  [[ "$exists" -eq 0 ]] && { echo -e "${RED}Task not found or not available: $id${NC}"; return 1; }

  local full_id
  full_id=$(sqlite3 "$DB_FILE" "SELECT id FROM tasks WHERE id LIKE '%$id%' AND status='available' LIMIT 1;" 2>/dev/null)
  sqlite3 "$DB_FILE" "UPDATE tasks SET status='in_progress', claimed_by='$claimer', claimed_at=datetime('now') WHERE id='$full_id';"

  echo -e "${GREEN}✓ Claimed:${NC} ${full_id}"
  echo -e "  ${CYAN}By:${NC} $claimer"
}

cmd_complete() {
  local id="$1"; shift
  local result="${*:-Done}"
  [[ -z "$id" ]] && { echo "Usage: br task complete <id> [result]"; return 1; }

  local full_id
  full_id=$(sqlite3 "$DB_FILE" "SELECT id FROM tasks WHERE id LIKE '%$id%' AND status='in_progress' LIMIT 1;" 2>/dev/null)
  [[ -z "$full_id" ]] && full_id=$(sqlite3 "$DB_FILE" "SELECT id FROM tasks WHERE id LIKE '%$id%' LIMIT 1;" 2>/dev/null)
  [[ -z "$full_id" ]] && { echo -e "${RED}Task not found: $id${NC}"; return 1; }

  sqlite3 "$DB_FILE" "UPDATE tasks SET status='completed', completed_at=datetime('now'), result=$(python3 -c "import json,sys; print(json.dumps(sys.argv[1]))" "$result") WHERE id='$full_id';"

  # remove from queue file if present
  rm -f "$QUEUE_DIR/${full_id}.json" 2>/dev/null

  echo -e "${GREEN}✓ Completed:${NC} ${full_id}"
  echo -e "  ${CYAN}Result:${NC} $result"
}

cmd_show() {
  local id="$1"
  [[ -z "$id" ]] && { cmd_list; return; }

  sqlite3 "$DB_FILE" "SELECT id,title,description,priority,status,posted_by,claimed_by,posted_at,claimed_at,completed_at,result FROM tasks WHERE id LIKE '%$id%' LIMIT 1;" 2>/dev/null | \
    while IFS='|' read tid title desc prio stat posted_by claimed_by posted_at claimed_at completed_at result; do
      echo ""
      echo -e "${BOLD}${CYAN}Task: ${tid}${NC}"
      echo -e "  ${CYAN}Title:${NC}       $title"
      echo -e "  ${CYAN}Description:${NC} $desc"
      echo -e "  ${CYAN}Priority:${NC}    $prio"
      echo -e "  ${CYAN}Status:${NC}      $stat"
      echo -e "  ${CYAN}Posted by:${NC}   $posted_by  at $posted_at"
      [[ -n "$claimed_by" ]] && echo -e "  ${CYAN}Claimed by:${NC}  $claimed_by  at $claimed_at"
      [[ -n "$completed_at" ]] && echo -e "  ${CYAN}Completed:${NC}   $completed_at"
      [[ -n "$result" ]] && echo -e "  ${CYAN}Result:${NC}      $result"
      echo ""
    done
}

cmd_assign() {
  # post a task AND claim it for a specific instance
  local instance="$1"; shift
  local title="$1"; shift
  local desc="$*"

  [[ -z "$instance" || -z "$title" ]] && { echo "Usage: br task assign <instance> <title> [desc]"; return 1; }

  local id
  id=$(_gen_id)

  sqlite3 "$DB_FILE" "INSERT INTO tasks(id,title,description,status,claimed_by,claimed_at) VALUES('$id',$(python3 -c "import json,sys; print(json.dumps(sys.argv[1]))" "$title"),$(python3 -c "import json,sys; print(json.dumps(sys.argv[1]))" "$desc"),'in_progress','$instance',datetime('now'));"

  # write to instance inbox
  local inbox_dir="$PWD/shared/inbox/$instance"
  mkdir -p "$inbox_dir"
  printf '{"from":"lucidia-copilot-cli","to":"%s","type":"task","task_id":"%s","title":"%s","desc":"%s","ts":"%s"}\n' \
    "$instance" "$id" "$title" "$desc" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$inbox_dir/task-${id}.json"

  echo -e "${GREEN}✓ Assigned to ${instance}:${NC} ${id}"
  echo -e "  ${CYAN}Title:${NC} $title"
  echo -e "  ${CYAN}Inbox:${NC} $inbox_dir/task-${id}.json"
}

cmd_help() {
  echo ""
  echo -e "${BOLD}br task${NC} — mesh task queue"
  echo ""
  echo "  ${CYAN}br task post <title> [desc]${NC}          Post a new task"
  echo "  ${CYAN}br task list [available|all|done]${NC}    List tasks"
  echo "  ${CYAN}br task show <id>${NC}                    Show task details"
  echo "  ${CYAN}br task claim <id> [instance]${NC}        Claim a task"
  echo "  ${CYAN}br task complete <id> [result]${NC}       Mark complete"
  echo "  ${CYAN}br task assign <instance> <title>${NC}    Assign to instance"
  echo ""
  echo "  Priority: set ${CYAN}TASK_PRIORITY=high${NC} before posting"
  echo ""
}

case "${1:-list}" in
  post)     shift; cmd_post "$@" ;;
  list)     shift; cmd_list "$@" ;;
  show)     shift; cmd_show "$@" ;;
  claim)    shift; cmd_claim "$@" ;;
  complete) shift; cmd_complete "$@" ;;
  done)     shift; cmd_complete "$@" ;;
  assign)   shift; cmd_assign "$@" ;;
  help|-h)  cmd_help ;;
  *)        cmd_show "$1" ;;
esac
