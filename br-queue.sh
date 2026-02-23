#!/bin/zsh
# BR Queue - Task Queue Manager

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; NC='\033[0m'; BOLD='\033[1m'

QUEUE_DIR="$HOME/.blackroad/queue"
QUEUE_DB="$QUEUE_DIR/queue.db"

init_db() {
  mkdir -p "$QUEUE_DIR"
  sqlite3 "$QUEUE_DB" <<'EOF'
CREATE TABLE IF NOT EXISTS tasks (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  priority TEXT DEFAULT 'normal',
  status TEXT DEFAULT 'pending',
  agent TEXT,
  tags TEXT,
  created_at TEXT DEFAULT (datetime('now')),
  updated_at TEXT DEFAULT (datetime('now'))
);
EOF
}

show_help() {
  echo -e "${CYAN}${BOLD}BR Queue{{NC}"
  echo "  br queue list              List all tasks"
  echo "  br queue post <title>      Post a new task"
  echo "  br queue claim <id>        Claim a task"
  echo "  br queue done <id>         Complete a task"
  echo "  br queue view <id>         View task details"
  echo "  br queue pending           List pending tasks"
  echo "  br queue clear             Clear completed tasks"
}

cmd_list() {
  init_db
  echo -e "${CYAN}Task Queue{{NC}\n"
  sqlite3 "$QUEUE_DB" "SELECT id, status, priority, title FROM tasks ORDER BY created_at DESC;" 2>/dev/null | \
    while IFS='|' read ID STATUS PRIORITY TITLE; do
      case "$STATUS" in
        pending)   echo -e "  ${YELLOW}⏳{{NC} [$ID] $TITLE (${PRIORITY})" ;;
        claimed)   echo -e "  ${CYAN}⚡{{NC} [$ID] $TITLE" ;;
        done)      echo -e "  ${GREEN}✓{{NC} [$ID] $TITLE" ;;
        *)         echo -e "  ${RED}?{{NC} [$ID] $TITLE" ;;
      esac
    done || echo -e "  ${YELLOW}No tasks{{NC}"
}

cmd_post() {
  local TITLE="${*:-Untitled task}"
  init_db
  local ID="task-$(date +%s | tail -c 6)"
  sqlite3 "$QUEUE_DB" "INSERT INTO tasks (id, title) VALUES ('$ID', '$TITLE');"
  echo -e "${GREEN}✓{{NC} Posted: [$ID] $TITLE"
}

cmd_claim() {
  local ID="$1"
  if [[ -z "$ID" ]]; then
    echo -e "${RED}Usage: br queue claim <id>{{NC}"
    return 1
  fi
  init_db
  sqlite3 "$QUEUE_DB" "UPDATE tasks SET status='claimed', updated_at=datetime('now') WHERE id='$ID';"
  echo -e "${CYAN}⚡ Claimed: $ID{{NC}"
}

cmd_done() {
  local ID="$1"
  if [[ -z "$ID" ]]; then
    echo -e "${RED}Usage: br queue done <id>{{NC}"
    return 1
  fi
  init_db
  sqlite3 "$QUEUE_DB" "UPDATE tasks SET status='done', updated_at=datetime('now') WHERE id='$ID';"
  echo -e "${GREEN}✓ Done: $ID{{NC}"
}

cmd_view() {
  local ID="$1"
  init_db
  sqlite3 "$QUEUE_DB" "SELECT id, title, description, priority, status, agent, created_at FROM tasks WHERE id='$ID';" 2>/dev/null | \
    while IFS='|' read ID TITLE DESC PRIORITY STATUS AGENT CREATED; do
      echo -e "${CYAN}Task: $ID{{NC}"
      echo -e "  Title:    $TITLE"
      echo -e "  Status:   $STATUS"
      echo -e "  Priority: $PRIORITY"
      echo -e "  Agent:    ${AGENT:-unassigned}"
      echo -e "  Created:  $CREATED"
      [[ -n "$DESC" ]] && echo -e "  Desc:     $DESC"
    done
}

cmd_pending() {
  init_db
  echo -e "${CYAN}Pending Tasks{{NC}\n"
  sqlite3 "$QUEUE_DB" "SELECT id, priority, title FROM tasks WHERE status='pending' ORDER BY created_at;" 2>/dev/null | \
    while IFS='|' read ID PRIORITY TITLE; do
      echo -e "  ${YELLOW}⏳{{NC} [$ID] $TITLE (${PRIORITY})"
    done || echo -e "  ${GREEN}No pending tasks{{NC}"
}

cmd_clear() {
  init_db
  COUNT=$(sqlite3 "$QUEUE_DB" "SELECT COUNT(*) FROM tasks WHERE status='done';" 2>/dev/null || echo 0)
  sqlite3 "$QUEUE_DB" "DELETE FROM tasks WHERE status='done';"
  echo -e "${GREEN}✓{{NC} Cleared $COUNT completed tasks"
}

case "${1:-help}" in
  list)    cmd_list ;;
  post)    cmd_post "${@:2}" ;;
  claim)   cmd_claim "$2" ;;
  done)    cmd_done "$2" ;;
  view)    cmd_view "$2" ;;
  pending) cmd_pending ;;
  clear)   cmd_clear ;;
  help|-h|--help) show_help ;;
  *)
    echo -e "${RED}Unknown command: $1{{NC}"
    show_help ;;
esac
