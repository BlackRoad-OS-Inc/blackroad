#!/bin/zsh
# BR BROADCAST - Send a message to all active mesh instances

GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'
PURPLE='\033[0;35m'; RED='\033[0;31m'; NC='\033[0m'; BOLD='\033[1m'

COLLAB_FILE="$PWD/coordination/collaboration/active-instances.json"
INBOX_BASE="$PWD/shared/inbox"
QUEUE_DIR="$PWD/shared/mesh/queue"

mkdir -p "$QUEUE_DIR"

cmd_send() {
  local msg="${*:-Hello from lucidia-copilot-cli}"
  local ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  local from="lucidia-copilot-cli"

  echo ""
  echo -e "${BOLD}${PURPLE}📡 Broadcasting to mesh...${NC}"
  echo ""

  if [[ ! -f "$COLLAB_FILE" ]]; then
    echo -e "${RED}✗ No mesh file found${NC}"; return 1
  fi

  local sent=0
  local instances
  instances=$(python3 -c "
import json
d = json.load(open('$COLLAB_FILE'))
for k,v in d.get('instances',{}).items():
    if k != 'lucidia-copilot-cli' and v.get('status') in ('ONLINE','STANDBY'):
        print(k)
" 2>/dev/null)

  while IFS= read -r instance; do
    [[ -z "$instance" ]] && continue
    local inbox_dir="$INBOX_BASE/$instance"
    mkdir -p "$inbox_dir"
    local fname="$inbox_dir/broadcast-$(date +%s%N | head -c 16).json"
    printf '{"from":"%s","to":"%s","type":"broadcast","msg":"%s","ts":"%s"}\n' \
      "$from" "$instance" "$msg" "$ts" > "$fname"
    echo -e "  ${GREEN}✓${NC} → ${instance}"
    sent=$((sent+1))
  done <<< "$instances"

  echo ""
  echo -e "  ${CYAN}Sent to ${sent} instance(s)${NC}"
  echo ""
}

cmd_queue() {
  # write to shared mesh queue (all instances poll this)
  local msg="${*:-Hello from lucidia-copilot-cli}"
  local ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  local fname="$QUEUE_DIR/broadcast-$(date +%s%N | head -c 16).json"
  printf '{"from":"lucidia-copilot-cli","type":"broadcast","msg":"%s","ts":"%s"}\n' \
    "$msg" "$ts" > "$fname"
  echo -e "${GREEN}✓ Queued:${NC} $(basename $fname)"
}

cmd_list() {
  [[ -f "$COLLAB_FILE" ]] || { echo "No mesh file found"; return 1; }
  echo ""
  echo -e "${BOLD}${CYAN}Active instances (broadcast targets):${NC}"
  echo ""
  python3 - "$COLLAB_FILE" <<'EOF'
import json, sys
d = json.load(open(sys.argv[1]))
for k, v in d.get("instances", {}).items():
    st = v.get("status","?")
    color = "\033[0;32m" if st == "ONLINE" else "\033[1;33m"
    nc = "\033[0m"
    role = v.get("role","?")
    print(f"  {color}{st:8}{nc}  {k:35} {role}")
EOF
  echo ""
}

cmd_dm() {
  # br broadcast dm <instance> <message>
  local instance="$1"; shift
  local msg="$*"
  [[ -z "$instance" ]] && { echo "Usage: br broadcast dm <instance> <message>"; return 1; }
  local inbox_dir="$INBOX_BASE/$instance"
  mkdir -p "$inbox_dir"
  local ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  local fname="$inbox_dir/dm-$(date +%s%N | head -c 16).json"
  printf '{"from":"lucidia-copilot-cli","to":"%s","type":"dm","msg":"%s","ts":"%s"}\n' \
    "$instance" "$msg" "$ts" > "$fname"
  echo -e "${GREEN}✓ DM sent to ${instance}:${NC} $(basename $fname)"
}

cmd_read() {
  # read all inbox messages for lucidia-copilot-cli
  local inbox="$INBOX_BASE/lucidia-copilot-cli"
  if [[ ! -d "$inbox" ]] || [[ -z "$(ls "$inbox" 2>/dev/null)" ]]; then
    echo -e "${YELLOW}📭 Inbox empty${NC}"; return
  fi
  echo ""
  echo -e "${BOLD}${CYAN}📥 Inbox (lucidia-copilot-cli):${NC}"
  echo ""
  for f in "$inbox"/*.json; do
    [[ -f "$f" ]] || continue
    python3 -c "
import json
d = json.load(open('$f'))
t = d.get('type','msg')
fr = d.get('from','?')
msg = d.get('msg','')[:100]
ts = d.get('ts','')
print(f'  [{t}] from={fr}  {msg}  ({ts})')
" 2>/dev/null
  done
  echo ""
}

cmd_clear() {
  local inbox="$INBOX_BASE/lucidia-copilot-cli"
  local count=0
  for f in "$inbox"/*.json; do
    [[ -f "$f" ]] && rm "$f" && count=$((count+1))
  done
  echo -e "${GREEN}✓ Cleared ${count} message(s) from inbox${NC}"
}

cmd_help() {
  echo ""
  echo -e "${BOLD}br broadcast${NC} — send messages across the mesh"
  echo ""
  echo "  ${CYAN}br broadcast <message>${NC}            Send to all online instances"
  echo "  ${CYAN}br broadcast send <message>${NC}       Same"
  echo "  ${CYAN}br broadcast queue <message>${NC}      Write to shared mesh queue"
  echo "  ${CYAN}br broadcast dm <id> <msg>${NC}        Direct message to one instance"
  echo "  ${CYAN}br broadcast read${NC}                 Read your inbox"
  echo "  ${CYAN}br broadcast clear${NC}                Clear your inbox"
  echo "  ${CYAN}br broadcast list${NC}                 List all mesh instances"
  echo ""
}

case "${1:-help}" in
  send)    shift; cmd_send "$@" ;;
  queue)   shift; cmd_queue "$@" ;;
  dm)      shift; cmd_dm "$@" ;;
  read)    cmd_read ;;
  clear)   cmd_clear ;;
  list)    cmd_list ;;
  help|-h) cmd_help ;;
  *)       cmd_send "$@" ;;
esac
