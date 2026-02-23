#!/bin/zsh
# BR WHOAMI - Instance identity card in the BlackRoad mesh

GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'
PURPLE='\033[0;35m'; BLUE='\033[0;34m'; NC='\033[0m'; BOLD='\033[1m'

COLLAB_FILE="$PWD/coordination/collaboration/active-instances.json"
LIVE_CTX="$PWD/coordination/live/real-time-context.json"
QUEUE_DIR="$PWD/shared/mesh/queue"
INBOX_BASE="$PWD/shared/inbox"
JOURNAL="$HOME/.blackroad/memory/journals/master-journal.jsonl"

cmd_card() {
  echo ""
  echo -e "${BOLD}${PURPLE}╔══════════════════════════════════════════╗${NC}"
  echo -e "${BOLD}${PURPLE}║       🤖  BlackRoad Mesh Identity         ║${NC}"
  echo -e "${BOLD}${PURPLE}╚══════════════════════════════════════════╝${NC}"
  echo ""

  local instance_id="lucidia-copilot-cli"
  local role="PRIMARY_OPERATOR" inst_status="ONLINE" mem_hash="—"

  if [[ -f "$COLLAB_FILE" ]]; then
    role=$(python3 -c "import json; d=json.load(open('$COLLAB_FILE')); print(d['instances'].get('$instance_id',{}).get('role','PRIMARY_OPERATOR'))" 2>/dev/null)
    inst_status=$(python3 -c "import json; d=json.load(open('$COLLAB_FILE')); print(d['instances'].get('$instance_id',{}).get('status','ONLINE'))" 2>/dev/null)
    mem_hash=$(python3 -c "import json; d=json.load(open('$COLLAB_FILE')); print(d['instances'].get('$instance_id',{}).get('memory_hash','—'))" 2>/dev/null)
  fi

  echo -e "  ${CYAN}Instance:${NC}    ${BOLD}${instance_id}${NC}"
  echo -e "  ${CYAN}Type:${NC}        github-copilot-cli"
  echo -e "  ${CYAN}Role:${NC}        ${YELLOW}${role}${NC}"
  echo -e "  ${CYAN}Status:${NC}      ${GREEN}${inst_status}${NC}"
  echo -e "  ${CYAN}Mem hash:${NC}    ${mem_hash}"
  echo ""

  local coordinator="—" mesh_count="?" online_count="?"
  if [[ -f "$COLLAB_FILE" ]]; then
    coordinator=$(python3 -c "import json; d=json.load(open('$COLLAB_FILE')); print(d.get('coordinator','—'))" 2>/dev/null)
    mesh_count=$(python3 -c "import json; d=json.load(open('$COLLAB_FILE')); print(len(d.get('instances',{})))" 2>/dev/null)
    online_count=$(python3 -c "import json; d=json.load(open('$COLLAB_FILE')); print(sum(1 for v in d['instances'].values() if v.get('status')=='ONLINE'))" 2>/dev/null)
  fi
  echo -e "  ${CYAN}Coordinator:${NC} ${coordinator}"
  echo -e "  ${CYAN}Mesh:${NC}        ${online_count} online / ${mesh_count} registered"
  echo ""

  local inbox="$INBOX_BASE/lucidia-copilot-cli"
  local inbox_count=0
  [[ -d "$inbox" ]] && inbox_count=$(ls "$inbox" 2>/dev/null | wc -l | tr -d ' ')
  local q_count=0
  [[ -d "$QUEUE_DIR" ]] && q_count=$(ls "$QUEUE_DIR" 2>/dev/null | wc -l | tr -d ' ')
  local j_count=0
  [[ -f "$JOURNAL" ]] && j_count=$(wc -l < "$JOURNAL" | tr -d ' ')

  echo -e "  ${CYAN}Inbox:${NC}       ${inbox_count} message(s)"
  echo -e "  ${CYAN}Queue:${NC}       ${q_count} task(s) in mesh"
  echo -e "  ${CYAN}Journal:${NC}     ${j_count} entries"

  if [[ -f "$LIVE_CTX" ]]; then
    local focus
    focus=$(python3 -c "import json; d=json.load(open('$LIVE_CTX')); print(d.get('focus','—'))" 2>/dev/null)
    echo -e "  ${CYAN}Focus:${NC}       ${focus}"
  fi

  echo ""
  echo -e "  ${CYAN}Working dir:${NC} $PWD"
  echo -e "  ${CYAN}Git SHA:${NC}     $(git rev-parse --short HEAD 2>/dev/null || echo '—')"
  echo ""
}

cmd_peers() {
  [[ -f "$COLLAB_FILE" ]] || { echo "No mesh file found at $COLLAB_FILE"; return 1; }
  echo ""
  echo -e "${BOLD}${CYAN}Mesh Peers:${NC}"
  echo ""
  python3 - "$COLLAB_FILE" <<'EOF'
import json, sys
d = json.load(open(sys.argv[1]))
my = "lucidia-copilot-cli"
for k, v in d.get("instances", {}).items():
    if k == my:
        continue
    st = v.get("status","?")
    role = v.get("role","?")
    color = "\033[0;32m" if st == "ONLINE" else "\033[1;33m"
    nc = "\033[0m"
    caps = ", ".join(v.get("capabilities", [])[:3])
    print(f"  {color}{st:8}{nc}  {k:30}  {role:25}  [{caps}]")
EOF
  echo ""
}

cmd_inbox() {
  local inbox="$INBOX_BASE/lucidia-copilot-cli"
  if [[ ! -d "$inbox" ]] || [[ -z "$(ls "$inbox" 2>/dev/null)" ]]; then
    echo -e "${YELLOW}📭 Inbox empty${NC}"
    return
  fi
  echo -e "${BOLD}${CYAN}📥 Inbox messages:${NC}"
  for f in "$inbox"/*.json; do
    [[ -f "$f" ]] || continue
    local fname from msg
    fname=$(basename "$f")
    from=$(python3 -c "import json; d=json.load(open('$f')); print(d.get('from','?'))" 2>/dev/null)
    msg=$(python3 -c "import json; d=json.load(open('$f')); print(d.get('msg','')[:80])" 2>/dev/null)
    echo -e "  ${YELLOW}▸${NC} ${fname}  from=${from}  ${msg}"
  done
  echo ""
}

cmd_help() {
  echo ""
  echo -e "${BOLD}br whoami${NC} — instance identity card"
  echo ""
  echo "  ${CYAN}br whoami${NC}          Show full identity card"
  echo "  ${CYAN}br whoami peers${NC}    List all mesh peers + status"
  echo "  ${CYAN}br whoami inbox${NC}    Show inbox messages"
  echo ""
}

case "${1:-card}" in
  card|"") cmd_card ;;
  peers)   cmd_peers ;;
  inbox)   cmd_inbox ;;
  help|-h) cmd_help ;;
  *) echo "Unknown: $1. Try: card peers inbox"; exit 1 ;;
esac
