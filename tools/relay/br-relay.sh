#!/usr/bin/env zsh
# 📡 BR RELAY — Cross-Instance Message Relay
# Send/receive messages between Copilot, Claude, Codex, Ollama, and agents
# Integrates with the BlackRoad collaboration mesh + BRAT auth

GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
DIM='\033[2m'
BOLD='\033[1m'
NC='\033[0m'

MESH_DIR="$HOME/blackroad/shared"
INBOX_DIR="$MESH_DIR/inbox"
QUEUE_DIR="$MESH_DIR/mesh/queue"
INSTANCES_FILE="$HOME/blackroad/coordination/collaboration/active-instances.json"
RELAY_DB="$HOME/.blackroad/relay.db"

# Default identity — read from auth or fallback
MY_ID=${BLACKROAD_INSTANCE_ID:-$(cat ~/.blackroad/auth/identity 2>/dev/null || echo "lucidia-copilot-cli")}

# ── DB init ──────────────────────────────────────────────────────────
init_db() {
  mkdir -p "$(dirname "$RELAY_DB")"
  sqlite3 "$RELAY_DB" <<EOF
CREATE TABLE IF NOT EXISTS relay_log (
  id       INTEGER PRIMARY KEY AUTOINCREMENT,
  ts       INTEGER DEFAULT (strftime('%s','now')),
  dir      TEXT,      -- 'sent' | 'received'
  from_id  TEXT,
  to_id    TEXT,
  subject  TEXT,
  body     TEXT,
  msg_id   TEXT UNIQUE
);
CREATE INDEX IF NOT EXISTS idx_relay_to ON relay_log(to_id);
CREATE INDEX IF NOT EXISTS idx_relay_ts ON relay_log(ts DESC);
EOF
}

# ── helpers ──────────────────────────────────────────────────────────
ts_now() { date +%s; }
msg_id() { echo "relay-$(ts_now)-$(openssl rand -hex 4)"; }

list_instances() {
  if [[ -f "$INSTANCES_FILE" ]]; then
    python3 -c "
import json
data = json.load(open('$INSTANCES_FILE'))
instances = data if isinstance(data, list) else data.get('instances', [])
for inst in instances:
    name = inst.get('name','?')
    kind = inst.get('type', inst.get('kind','?'))
    status = inst.get('status','?')
    print(f'{name}|{kind}|{status}')
" 2>/dev/null
  fi
}

resolve_inbox() {
  local target=$1
  # Known aliases
  case "$target" in
    me|self|lucidia|copilot) echo "$INBOX_DIR/lucidia" ;;
    claude|claude-sonnet)    echo "$INBOX_DIR/claude-sonnet" ;;
    codex)                   echo "$INBOX_DIR/codex" ;;
    ollama)                  echo "$INBOX_DIR/ollama-local" ;;
    copilot-2|window-2)      echo "$INBOX_DIR/copilot-window-2" ;;
    copilot-3|window-3)      echo "$INBOX_DIR/copilot-window-3" ;;
    all|broadcast)           echo "BROADCAST" ;;
    *)                       echo "$INBOX_DIR/$target" ;;
  esac
}

# ── commands ─────────────────────────────────────────────────────────

cmd_send() {
  init_db
  local to=$1
  local subject=$2
  local body=${3:-}
  if [[ -z "$to" || -z "$subject" ]]; then
    echo -e "${RED}Usage: br relay send <to> <subject> [body]${NC}"
    echo -e "${DIM}  to = claude|codex|ollama|copilot-2|all|<instance-name>${NC}"
    exit 1
  fi

  # If body empty, read from stdin or prompt
  if [[ -z "$body" && ! -t 0 ]]; then
    body=$(cat)
  elif [[ -z "$body" ]]; then
    echo -e "${CYAN}Message body (Ctrl+D to send):${NC}"
    body=$(cat)
  fi

  local mid=$(msg_id)
  local payload
  payload=$(python3 -c "
import json, time
payload = {
  'id': '$mid',
  'from': '$MY_ID',
  'to': '$to',
  'subject': '$subject',
  'body': '''$body''',
  'ts': $(ts_now),
  'protocol': 'BRAT-RELAY-v1'
}
print(json.dumps(payload, indent=2))
")

  local inbox=$(resolve_inbox "$to")

  if [[ "$inbox" == "BROADCAST" ]]; then
    # Send to all instances
    local count=0
    for dir in "$INBOX_DIR"/*/; do
      [[ -d "$dir" ]] || continue
      local inst_name=$(basename "$dir")
      echo "$payload" > "${dir}msg-${mid}.json"
      ((count++))
    done
    echo -e "${GREEN}✓ Broadcast to $count inboxes${NC}  ${DIM}id=$mid${NC}"
  else
    mkdir -p "$inbox"
    echo "$payload" > "${inbox}/msg-${mid}.json"
    echo -e "${GREEN}✓ Sent → $to${NC}  ${DIM}id=${mid:6:16}${NC}"
  fi

  # Log to relay DB
  sqlite3 "$RELAY_DB" "INSERT OR IGNORE INTO relay_log(dir,from_id,to_id,subject,body,msg_id)
    VALUES('sent','$MY_ID','$to',$(echo "$subject" | python3 -c "import sys; print(repr(sys.stdin.read().strip()))"),
    $(echo "$body" | python3 -c "import sys; print(repr(sys.stdin.read().strip()))"), '$mid');"

  # Post to mesh queue too
  if [[ -d "$QUEUE_DIR" ]]; then
    echo "$payload" > "$QUEUE_DIR/relay-${mid}.json"
  fi
}

cmd_inbox() {
  init_db
  local who=${1:-lucidia}
  local inbox=$(resolve_inbox "$who")
  echo -e ""
  echo -e "  ${CYAN}${BOLD}📥 Inbox: $who${NC}  ${DIM}($inbox)${NC}"
  echo -e "  ${DIM}──────────────────────────────────────────────────────${NC}"

  if [[ ! -d "$inbox" ]]; then
    echo -e "  ${DIM}(inbox does not exist)${NC}"
    echo -e ""
    return
  fi

  local count=$(ls "$inbox"/*.json 2>/dev/null | wc -l | tr -d ' ')
  if [[ "$count" == "0" ]]; then
    echo -e "  ${DIM}📭 No messages${NC}"
    echo -e ""
    return
  fi

  echo -e "  ${YELLOW}$count message(s)${NC}"
  echo -e ""
  for f in "$inbox"/*.json; do
    [[ -f "$f" ]] || continue
    python3 - "$f" <<'PYEOF'
import json, sys, time
try:
    d = json.load(open(sys.argv[1]))
    from_id = d.get('from', '?')
    subject = d.get('subject', d.get('msg', d.get('type','?')))[:60]
    body = str(d.get('body', d.get('msg', '')))[:120]
    ts = d.get('ts', 0)
    mid = d.get('id', '?')
    if isinstance(ts, (int, float)) and ts > 0:
        tm = time.strftime('%m/%d %H:%M', time.localtime(ts))
    elif isinstance(ts, str) and 'T' in ts:
        tm = ts[5:16].replace('T',' ')
    else:
        tm = '?'
    print(f"  \033[33m{tm}\033[0m  \033[36m{from_id:<28}\033[0m  {subject}")
    if body and body != subject:
        body = body.replace('\n', ' ')[:100]
        print(f"  {' '*35}\033[2m{body}\033[0m")
    print()
except Exception as e:
    print(f"  [parse error: {e}]")
PYEOF
  done
}

cmd_read() {
  local who=${1:-lucidia}
  local inbox=$(resolve_inbox "$who")
  local count=$(ls "$inbox"/*.json 2>/dev/null | wc -l | tr -d ' ')
  echo -e "\n  ${CYAN}Reading $count message(s) from $who's inbox...${NC}\n"
  for f in "$inbox"/*.json; do
    [[ -f "$f" ]] || continue
    python3 - "$f" <<'PYEOF'
import json, sys, time
try:
    d = json.load(open(sys.argv[1]))
    from_id = d.get('from', '?')
    to_id = d.get('to', '?')
    subject = d.get('subject', '?')
    body = d.get('body', '')
    ts = d.get('ts', 0)
    mid = d.get('id', '?')
    tm = time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(ts)) if ts else '?'
    print(f"\033[1m─────────────────────────────────────────────\033[0m")
    print(f"\033[1mFrom:\033[0m    {from_id}")
    print(f"\033[1mTo:\033[0m      {to_id}")
    print(f"\033[1mSubject:\033[0m {subject}")
    print(f"\033[1mTime:\033[0m    {tm}")
    print(f"\033[1mID:\033[0m      {mid}")
    print()
    print(body)
    print()
except Exception as e:
    print(f"[parse error: {e}]")
PYEOF
  done
}

cmd_clear() {
  local who=${1:-lucidia}
  local inbox=$(resolve_inbox "$who")
  local count=$(ls "$inbox"/*.json 2>/dev/null | wc -l | tr -d ' ')
  rm -f "$inbox"/*.json
  echo -e "${GREEN}✓ Cleared $count message(s) from $who inbox${NC}"
}

cmd_watch() {
  local who=${1:-lucidia}
  local inbox=$(resolve_inbox "$who")
  mkdir -p "$inbox"
  echo -e "${CYAN}📡 Watching inbox: $who${NC}  ${DIM}(Ctrl+C to stop)${NC}"
  echo -e "${DIM}──────────────────────────────────────────────${NC}"

  # Show existing
  local existing=$(ls "$inbox"/*.json 2>/dev/null | wc -l | tr -d ' ')
  [[ "$existing" -gt 0 ]] && echo -e "${DIM}($existing existing messages)${NC}"

  # Watch for new files
  if command -v fswatch &>/dev/null; then
    fswatch -0 "$inbox" | while IFS= read -r -d '' event; do
      [[ "$event" == *.json ]] || continue
      [[ -f "$event" ]] || continue
      echo -e "\n${GREEN}📨 New message!${NC}"
      python3 - "$event" <<'PYEOF'
import json, sys, time
try:
    d = json.load(open(sys.argv[1]))
    print(f"  \033[1mFrom:\033[0m   {d.get('from','?')}")
    print(f"  \033[1mSubj:\033[0m   {d.get('subject','?')}")
    body = d.get('body','')[:200]
    if body: print(f"  \033[2m{body}\033[0m")
except: pass
PYEOF
    done
  else
    # Fallback: poll every 2s
    local seen=()
    while true; do
      for f in "$inbox"/*.json; do
        [[ -f "$f" ]] || continue
        local fname=$(basename "$f")
        if [[ ! " ${seen[@]} " =~ " $fname " ]]; then
          seen+=("$fname")
          echo -e "\n${GREEN}📨 New: $fname${NC}"
          python3 - "$f" <<'PYEOF'
import json, sys
try:
    d = json.load(open(sys.argv[1]))
    print(f"  From: {d.get('from','?')}")
    print(f"  Subj: {d.get('subject','?')}")
except: pass
PYEOF
        fi
      done
      sleep 2
    done
  fi
}

cmd_instances() {
  echo -e ""
  echo -e "  ${CYAN}${BOLD}📡 Relay Instances${NC}"
  echo -e "  ${DIM}──────────────────────────────────────────────────────${NC}"
  echo -e "  ${DIM}  Aliases          →  Inbox path${NC}"
  echo -e ""
  echo -e "  me / lucidia / copilot  →  $INBOX_DIR/lucidia"
  echo -e "  claude                  →  $INBOX_DIR/claude-sonnet"
  echo -e "  codex                   →  $INBOX_DIR/codex"
  echo -e "  ollama                  →  $INBOX_DIR/ollama-local"
  echo -e "  copilot-2               →  $INBOX_DIR/copilot-window-2"
  echo -e "  copilot-3               →  $INBOX_DIR/copilot-window-3"
  echo -e "  all                     →  broadcast to all"
  echo -e ""
  echo -e "  ${YELLOW}Active (from mesh):${NC}"
  list_instances | while IFS='|' read name kind status; do
    echo -e "  ${CYAN}$name${NC}  ${DIM}$kind${NC}  $status"
  done
  echo -e ""
}

cmd_log() {
  init_db
  local n=${1:-20}
  echo -e ""
  echo -e "  ${CYAN}${BOLD}📡 Relay Log (last $n)${NC}"
  echo -e "  ${DIM}──────────────────────────────────────────────────────${NC}"
  sqlite3 "$RELAY_DB" "SELECT datetime(ts,'unixepoch','localtime'), dir, from_id || ' → ' || to_id, subject FROM relay_log ORDER BY ts DESC LIMIT $n;" | while IFS='|' read ts dir route subj; do
    echo -e "  ${DIM}$ts${NC}  $dir  ${CYAN}$route${NC}  $subj"
  done
  echo -e ""
}

cmd_post() {
  # Post a task to the mesh queue for any agent to pick up
  local title=$1
  local body=${2:-}
  local mid=$(msg_id)
  local payload
  payload=$(python3 -c "
import json, time
payload = {
  'task_id': '$mid',
  'title': '$title',
  'description': '''$body''',
  'from': '$MY_ID',
  'posted_at': time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime()),
  'status': 'available',
  'protocol': 'BRAT-RELAY-v1'
}
print(json.dumps(payload, indent=2))
")
  mkdir -p "$QUEUE_DIR"
  echo "$payload" > "$QUEUE_DIR/task-${mid}.json"
  echo -e "${GREEN}✓ Task posted to mesh queue${NC}  ${DIM}$mid${NC}"
}

cmd_help() {
  echo -e ""
  echo -e "  ${CYAN}${BOLD}📡 BR RELAY${NC}  ${DIM}Cross-Instance Message Relay${NC}"
  echo -e "  ${DIM}Copilot ↔ Claude ↔ Codex ↔ Ollama ↔ Agents${NC}"
  echo -e "  ${DIM}──────────────────────────────────────────────────────${NC}"
  echo -e "  ${BOLD}USAGE${NC}  br relay <command> [args]"
  echo -e ""
  echo -e "  ${YELLOW}MESSAGING${NC}"
  echo -e "  ${CYAN}  send <to> <subject> [body]${NC}   Send a message to an instance"
  echo -e "  ${CYAN}  inbox [who]${NC}                  View inbox summary (default: lucidia)"
  echo -e "  ${CYAN}  read [who]${NC}                   Read full messages in inbox"
  echo -e "  ${CYAN}  watch [who]${NC}                  Live watch for new messages"
  echo -e "  ${CYAN}  clear [who]${NC}                  Clear inbox messages"
  echo -e ""
  echo -e "  ${YELLOW}TASKS${NC}"
  echo -e "  ${CYAN}  post <title> [desc]${NC}          Post task to mesh queue"
  echo -e ""
  echo -e "  ${YELLOW}INFO${NC}"
  echo -e "  ${CYAN}  instances${NC}                    List all relay targets + aliases"
  echo -e "  ${CYAN}  log [n]${NC}                      Show relay message log"
  echo -e ""
  echo -e "  ${YELLOW}TARGETS${NC}"
  echo -e "  ${DIM}  claude, codex, ollama, copilot-2, copilot-3, all${NC}"
  echo -e ""
  echo -e "  ${YELLOW}EXAMPLES${NC}"
  echo -e "  ${DIM}  br relay send claude \"need review\" \"check auth logic in lib/auth/brat.js\"${NC}"
  echo -e "  ${DIM}  br relay send codex \"fix bug\" \"TypeError in line 45 of br-auth.sh\"${NC}"
  echo -e "  ${DIM}  br relay send all \"deploying\" \"pushing to origin in 5 min\"${NC}"
  echo -e "  ${DIM}  br relay inbox claude${NC}"
  echo -e "  ${DIM}  br relay watch${NC}"
  echo -e "  ${DIM}  br relay post \"write tests for brat.js\" \"cover mint/verify/decode\"${NC}"
  echo -e ""
}

# ── dispatch ──────────────────────────────────────────────────────────
init_db 2>/dev/null

case "${1:-help}" in
  send|msg|message|dm)     cmd_send "$2" "$3" "$4" ;;
  inbox|check|messages)    cmd_inbox "${2:-lucidia}" ;;
  read|open)               cmd_read "${2:-lucidia}" ;;
  watch|listen|live)       cmd_watch "${2:-lucidia}" ;;
  clear|flush|purge)       cmd_clear "${2:-lucidia}" ;;
  post|task|queue)         cmd_post "$2" "$3" ;;
  instances|list|who)      cmd_instances ;;
  log|history|sent)        cmd_log "${2:-20}" ;;
  help|--help|-h)          cmd_help ;;
  *)
    echo -e "${RED}✗ Unknown: $1${NC}"
    cmd_help; exit 1 ;;
esac
