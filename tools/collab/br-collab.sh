#!/usr/bin/env zsh
# BR Collab — Collaboration mesh management
# br collab join|status|send|route|handoff|instances|inbox|broadcast

AMBER=$'\033[38;5;214m'; PINK=$'\033[38;5;205m'; VIOLET=$'\033[38;5;135m'
CYAN=$'\033[0;36m'; GREEN=$'\033[0;32m'; RED=$'\033[0;31m'
YELLOW=$'\033[1;33m'; BOLD=$'\033[1m'; DIM=$'\033[2m'; NC=$'\033[0m'

BR_ROOT="${BR_ROOT:-$HOME/blackroad}"
INSTANCES_FILE="$BR_ROOT/coordination/collaboration/active-instances.json"
CONTEXT_FILE="$BR_ROOT/coordination/live/real-time-context.json"
INBOX_ROOT="$BR_ROOT/shared/inbox"
QUEUE_DIR="$BR_ROOT/shared/mesh/queue"
JOURNAL="$HOME/.blackroad/memory/journals/master-journal.jsonl"

header() {
  echo ""
  echo "  ${BOLD}${PINK}⬡ BLACKROAD COLLAB MESH${NC}  ${DIM}multi-agent coordination${NC}"
  echo "  ${DIM}────────────────────────────────────────────${NC}"
}

# Show mesh status dashboard
cmd_status() {
  header
  [[ ! -f "$INSTANCES_FILE" ]] && { echo "  ${RED}Instances file not found${NC}"; exit 1; }

  echo "  ${BOLD}Active Instances${NC}"
  echo ""
  python3 -c "
import json
with open('$INSTANCES_FILE') as f:
    data = json.load(f)
instances = data.get('instances', data) if isinstance(data, dict) else data
if isinstance(instances, dict):
    instances = list(instances.values())
for inst in instances:
    iid  = inst.get('id', inst.get('instance_id','?'))
    typ  = inst.get('type','?')
    stat = inst.get('status','?')
    ts   = inst.get('last_seen','')[:19].replace('T',' ')
    col  = '\033[32m' if stat == 'ONLINE' else '\033[33m' if stat == 'STANDBY' else '\033[31m'
    print(f'  {col}●\033[0m  {iid:<30} {typ:<20} {col}{stat}\033[0m  \033[2m{ts}\033[0m')
" 2>/dev/null

  echo ""
  echo "  ${BOLD}Task Queue${NC}  ${DIM}($QUEUE_DIR)${NC}"
  local qcount=$(ls "$QUEUE_DIR"/*.txt "$QUEUE_DIR"/*.json 2>/dev/null | wc -l | tr -d ' ')
  echo "  ${CYAN}$qcount${NC} task(s) in queue"
  ls "$QUEUE_DIR" 2>/dev/null | while read -r f; do
    echo "  ${DIM}  → $f${NC}"
  done

  echo ""
  echo "  ${BOLD}Inboxes${NC}"
  for inbox in "$INBOX_ROOT"/*/; do
    local name=$(basename "$inbox")
    local msgs=$(ls "$inbox" 2>/dev/null | wc -l | tr -d ' ')
    [[ "$msgs" -gt 0 ]] && echo "  ${CYAN}$name${NC}  ${AMBER}$msgs msg(s)${NC}" || echo "  ${DIM}$name  empty${NC}"
  done
  echo ""
}

# Join the mesh as a named instance
cmd_join() {
  local instance="${1:-copilot-$(date +%s | tail -c4)}"
  header
  echo "  ${CYAN}Joining mesh as:${NC} ${BOLD}$instance${NC}"
  bash "$BR_ROOT/join-collaboration.sh" "$instance" 2>/dev/null || {
    echo "  ${YELLOW}join-collaboration.sh not found, registering directly…${NC}"
    _register_instance "$instance"
  }
}

_register_instance() {
  local iid="$1"
  local ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  python3 -c "
import json, sys
with open('$INSTANCES_FILE') as f:
    data = json.load(f)
instances = data.get('instances', {})
instances['$iid'] = {
    'id': '$iid',
    'type': 'github-copilot-cli',
    'status': 'ONLINE',
    'last_seen': '$ts',
    'inbox': 'shared/inbox/$iid/'
}
data['instances'] = instances
with open('$INSTANCES_FILE', 'w') as f:
    json.dump(data, f, indent=2)
print('  Registered $iid')
" 2>/dev/null
  mkdir -p "$INBOX_ROOT/$iid"
  echo "  ${GREEN}✓ Joined mesh as $iid${NC}"
}

# Send a message to an instance's inbox
cmd_send() {
  local to="$1"; shift
  local msg="$*"
  [[ -z "$to" || -z "$msg" ]] && { echo "  Usage: br collab send <instance> <message>"; exit 1; }
  local inbox="$INBOX_ROOT/$to"
  mkdir -p "$inbox"
  local ts=$(date +%s)
  local fname="$inbox/msg-${ts}.json"
  python3 -c "
import json
payload = {'from': 'lucidia-copilot-cli', 'to': '$to', 'msg': '$msg', 'ts': $ts}
with open('$fname', 'w') as f:
    json.dump(payload, f, indent=2)
print('  Sent to $to')
"
  echo "  ${GREEN}✓ Message sent to ${BOLD}$to${NC}${GREEN} inbox${NC}"
  echo "  ${DIM}$fname${NC}"
}

# Read inbox for an instance
cmd_inbox() {
  local who="${1:-lucidia}"
  local inbox="$INBOX_ROOT/$who"
  header
  echo "  ${BOLD}Inbox: $who${NC}"
  echo ""
  if [[ ! -d "$inbox" ]]; then
    echo "  ${DIM}No inbox directory for $who${NC}"; echo ""; return
  fi
  local count=$(ls "$inbox" 2>/dev/null | wc -l | tr -d ' ')
  [[ "$count" -eq 0 ]] && { echo "  ${DIM}📭 Empty${NC}"; echo ""; return; }
  for f in "$inbox"/*.json "$inbox"/*.txt; do
    [[ ! -f "$f" ]] && continue
    echo "  ${CYAN}$(basename $f)${NC}"
    if [[ "$f" == *.json ]]; then
      python3 -c "import json; d=json.load(open('$f')); print('  from:', d.get('from','?'), '  msg:', str(d.get('msg',''))[:100])" 2>/dev/null
    else
      head -3 "$f" | sed 's/^/  /'
    fi
    echo ""
  done
}

# Broadcast to all instances
cmd_broadcast() {
  local msg="$*"
  [[ -z "$msg" ]] && { echo "  Usage: br collab broadcast <message>"; exit 1; }
  local ts=$(date +%s)
  local sent=0
  for inbox in "$INBOX_ROOT"/*/; do
    local name=$(basename "$inbox")
    [[ "$name" == "lucidia" ]] && continue  # don't self-send
    echo "{\"from\":\"lucidia-copilot-cli\",\"to\":\"$name\",\"msg\":\"$msg\",\"ts\":$ts}" \
      > "$inbox/broadcast-${ts}.json"
    ((sent++))
  done
  echo "  ${GREEN}✓ Broadcast to $sent instance(s)${NC}"
  echo "  ${DIM}\"$msg\"${NC}"
}

# Post a task to the mesh queue
cmd_post() {
  local title="$1"; shift
  local desc="$*"
  [[ -z "$title" ]] && { echo "  Usage: br collab post <title> [description]"; exit 1; }
  local ts=$(date +%s)
  local fname="$QUEUE_DIR/${ts}_task.txt"
  mkdir -p "$QUEUE_DIR"
  cat > "$fname" << EOF
TASK: $title
FROM: lucidia-copilot-cli
TIME: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
DESC: $desc
EOF
  echo "  ${GREEN}✓ Task posted to mesh queue${NC}"
  echo "  ${DIM}$(basename $fname)${NC}"
}

# Route a task based on keywords
cmd_route() {
  local task="$*"
  [[ -z "$task" ]] && { echo "  Usage: br collab route <task description>"; exit 1; }
  bash "$BR_ROOT/collab-task-router.sh" "$task" 2>/dev/null || \
    echo "  ${DIM}Router: $BR_ROOT/collab-task-router.sh not found${NC}"
}

# Handoff context to another instance
cmd_handoff() {
  local to="${1:-copilot-window-2}"
  header
  echo "  ${CYAN}Handing off context to:${NC} ${BOLD}$to${NC}"
  bash "$BR_ROOT/handoff.sh" "$to" 2>/dev/null || {
    echo "  ${DIM}handoff.sh not found, writing context snapshot…${NC}"
    local snap="$INBOX_ROOT/$to/handoff-$(date +%s).json"
    mkdir -p "$INBOX_ROOT/$to"
    python3 -c "
import json
ctx = {}
try:
    ctx = json.load(open('$CONTEXT_FILE'))
except: pass
ctx['handoff_from'] = 'lucidia-copilot-cli'
ctx['handoff_time'] = '$(date -u +%Y-%m-%dT%H:%M:%SZ)'
with open('$snap', 'w') as f:
    json.dump(ctx, f, indent=2)
print('  Snapshot written to $snap')
"
  }
  echo "  ${GREEN}✓ Handoff complete${NC}"
}

# List all known instances with their capabilities
cmd_instances() {
  header
  python3 -c "
import json
with open('$INSTANCES_FILE') as f:
    data = json.load(f)
instances = data.get('instances', data) if isinstance(data, dict) else data
if isinstance(instances, dict):
    instances = list(instances.values())
print(f'  Total instances: {len(instances)}')
print()
for inst in instances:
    iid  = inst.get('id', inst.get('instance_id','?'))
    typ  = inst.get('type','?')
    stat = inst.get('status','?')
    caps = inst.get('capabilities', [])
    col  = '\033[32m' if stat == 'ONLINE' else '\033[33m' if stat == 'STANDBY' else '\033[31m'
    print(f'  {col}●\033[0m  \033[1m{iid}\033[0m')
    print(f'       type: {typ}  status: {col}{stat}\033[0m')
    if caps:
        print(f'       caps: {\" | \".join(caps[:5])}')
    inbox = inst.get('inbox','')
    if inbox: print(f'       \033[2minbox: {inbox}\033[0m')
    print()
" 2>/dev/null
}

show_help() {
  echo ""
  echo "  ${PINK}${BOLD}br collab${NC}  — collaboration mesh"
  echo ""
  echo "  ${BOLD}Commands:${NC}"
  echo "    ${CYAN}status${NC}                   Mesh dashboard: instances + queue + inboxes"
  echo "    ${CYAN}instances${NC}                List all registered instances"
  echo "    ${CYAN}join [name]${NC}              Join mesh as named instance"
  echo "    ${CYAN}send <to> <msg>${NC}          Send message to instance inbox"
  echo "    ${CYAN}inbox [who]${NC}              Read inbox (default: lucidia)"
  echo "    ${CYAN}broadcast <msg>${NC}          Send to all instance inboxes"
  echo "    ${CYAN}post <title> [desc]${NC}      Post task to mesh queue"
  echo "    ${CYAN}route <task>${NC}             Auto-route task to best instance"
  echo "    ${CYAN}handoff [to]${NC}             Hand off context to another instance"
  echo ""
  echo "  ${BOLD}Instances file:${NC}  ${DIM}$INSTANCES_FILE${NC}"
  echo ""
}

case "${1:-help}" in
  status|dash)      cmd_status ;;
  instances|list)   cmd_instances ;;
  join)             cmd_join "$2" ;;
  send|msg)         shift; cmd_send "$@" ;;
  inbox|read)       cmd_inbox "$2" ;;
  broadcast|bcast)  shift; cmd_broadcast "$@" ;;
  post|task)        shift; cmd_post "$@" ;;
  route)            shift; cmd_route "$@" ;;
  handoff|pass)     cmd_handoff "$2" ;;
  help|*)           show_help ;;
esac
