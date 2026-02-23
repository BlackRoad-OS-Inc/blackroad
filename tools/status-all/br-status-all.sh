#!/bin/zsh
# BR STATUS-ALL - Full system-wide health snapshot

GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'
RED='\033[0;31m'; PURPLE='\033[0;35m'; NC='\033[0m'; BOLD='\033[1m'

OLLAMA_URL="${OLLAMA_URL:-http://localhost:11434}"
COLLAB_FILE="$PWD/coordination/collaboration/active-instances.json"
LIVE_CTX="$PWD/coordination/live/real-time-context.json"
QUEUE_DIR="$PWD/shared/mesh/queue"
JOURNAL="$HOME/.blackroad/memory/journals/master-journal.jsonl"
AGENTS_DIR="$PWD/agents/active"

_ok()   { echo -e "  ${GREEN}✓${NC} $1"; }
_warn() { echo -e "  ${YELLOW}⚠${NC} $1"; }
_err()  { echo -e "  ${RED}✗${NC} $1"; }
_head() { echo -e "\n${BOLD}${CYAN}── $1 ──${NC}"; }

cmd_all() {
  echo ""
  echo -e "${BOLD}${PURPLE}╔══════════════════════════════════════════════════╗${NC}"
  echo -e "${BOLD}${PURPLE}║        🌐  BlackRoad System Status               ║${NC}"
  echo -e "${BOLD}${PURPLE}║        $(date '+%Y-%m-%d %H:%M:%S')                        ║${NC}"
  echo -e "${BOLD}${PURPLE}╚══════════════════════════════════════════════════╝${NC}"

  # ── GIT ──
  _head "GIT"
  local branch dirty ahead
  branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "—")
  dirty=$(git --no-pager status --porcelain 2>/dev/null | wc -l | tr -d ' ')
  ahead=$(git rev-list @{u}..HEAD 2>/dev/null | wc -l | tr -d ' ')
  local sha=$(git rev-parse --short HEAD 2>/dev/null || echo "—")
  _ok "Branch: ${branch}  SHA: ${sha}"
  [[ "$dirty" -gt 0 ]] && _warn "$dirty uncommitted file(s)" || _ok "Working tree clean"
  [[ "$ahead" -gt 0 ]] && _warn "$ahead commit(s) not pushed" || _ok "Up to date with remote"

  # ── MESH ──
  _head "COLLABORATION MESH"
  if [[ -f "$COLLAB_FILE" ]]; then
    local online total
    online=$(python3 -c "import json; d=json.load(open('$COLLAB_FILE')); print(sum(1 for v in d['instances'].values() if v.get('status')=='ONLINE'))" 2>/dev/null)
    total=$(python3 -c "import json; d=json.load(open('$COLLAB_FILE')); print(len(d['instances']))" 2>/dev/null)
    _ok "$online / $total instances ONLINE"
    python3 - "$COLLAB_FILE" 2>/dev/null <<'EOF'
import json, sys
d = json.load(open(sys.argv[1]))
for k, v in d.get("instances", {}).items():
    st = v.get("status","?")
    color = "\033[0;32m" if st == "ONLINE" else "\033[1;33m"
    nc = "\033[0m"
    print(f"    {color}{st:8}{nc} {k}")
EOF
  else
    _warn "No mesh file found"
  fi

  local q_count=0
  [[ -d "$QUEUE_DIR" ]] && q_count=$(ls "$QUEUE_DIR" 2>/dev/null | wc -l | tr -d ' ')
  _ok "Queue: $q_count task(s)"

  # ── JOURNAL ──
  _head "MEMORY / JOURNAL"
  if [[ -f "$JOURNAL" ]]; then
    local j_count j_today
    j_count=$(wc -l < "$JOURNAL" | tr -d ' ')
    j_today=$(grep "$(date '+%Y-%m-%d')" "$JOURNAL" 2>/dev/null | wc -l | tr -d ' ')
    _ok "$j_count total entries  ($j_today today)"
  else
    _warn "Journal not found"
  fi

  # ── AGENTS ──
  _head "ACTIVE AGENTS"
  if [[ -d "$AGENTS_DIR" ]]; then
    local agent_count=0
    local aname astatus
    for f in "$AGENTS_DIR"/*.json; do
      [[ -f "$f" ]] || continue
      agent_count=$((agent_count+1))
      aname=$(python3 -c "import json; d=json.load(open('$f')); print(d.get('name','?'))" 2>/dev/null)
      astatus=$(python3 -c "import json; d=json.load(open('$f')); print(d.get('status','?'))" 2>/dev/null)
      [[ "$astatus" == "running" ]] && _ok "$aname ($astatus)" || _warn "$aname ($astatus)"
    done
    [[ "$agent_count" -eq 0 ]] && _warn "No agent files in agents/active/"
  else
    _warn "agents/active/ not found"
  fi

  # ── OLLAMA ──
  _head "OLLAMA"
  local ollama_resp
  ollama_resp=$(curl -s --max-time 3 "$OLLAMA_URL/api/tags" 2>/dev/null)
  if [[ -n "$ollama_resp" ]]; then
    local model_count
    model_count=$(echo "$ollama_resp" | python3 -c "import json,sys; d=json.load(sys.stdin); print(len(d.get('models',[])))" 2>/dev/null)
    _ok "Ollama running — $model_count model(s) available"
  else
    _warn "Ollama not responding at $OLLAMA_URL"
  fi

  # ── SYSTEM ──
  _head "SYSTEM"
  local cpu_pct mem_used_gb mem_total_gb
  cpu_pct=$(top -l 1 -n 0 2>/dev/null | grep "CPU usage" | awk '{print $3}' | tr -d '%')
  local mem_total_bytes=$(sysctl -n hw.memsize 2>/dev/null || echo 0)
  mem_total_gb=$(python3 -c "print(round($mem_total_bytes/1024**3,1))" 2>/dev/null)
  local active_pages=$(vm_stat 2>/dev/null | awk '/Pages active/{print $3}' | tr -d '.')
  local wired_pages=$(vm_stat 2>/dev/null | awk '/Pages wired/{print $4}' | tr -d '.')
  mem_used_gb=$(python3 -c "print(round(($active_pages+$wired_pages)*4096/1024**3,1))" 2>/dev/null)
  _ok "CPU: ${cpu_pct:-%}%  Memory: ${mem_used_gb}GB / ${mem_total_gb}GB"

  # ── CRON ──
  _head "SCHEDULED JOBS"
  local cron_db="$HOME/.blackroad/cron.db"
  if [[ -f "$cron_db" ]]; then
    local enabled_count total_cron
    enabled_count=$(sqlite3 "$cron_db" "SELECT COUNT(*) FROM schedules WHERE enabled=1;" 2>/dev/null)
    total_cron=$(sqlite3 "$cron_db" "SELECT COUNT(*) FROM schedules;" 2>/dev/null)
    _ok "$enabled_count enabled / $total_cron total schedules"
  else
    _warn "No cron database"
  fi

  echo ""
  echo -e "${CYAN}Run ${BOLD}br status-all full${NC}${CYAN} for more detail${NC}"
  echo ""
}

cmd_quick() {
  # One-line summary
  local branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "—")
  local dirty=$(git --no-pager status --porcelain 2>/dev/null | wc -l | tr -d ' ')
  local online=0
  [[ -f "$COLLAB_FILE" ]] && online=$(python3 -c "import json; d=json.load(open('$COLLAB_FILE')); print(sum(1 for v in d['instances'].values() if v.get('status')=='ONLINE'))" 2>/dev/null)
  local q=0
  [[ -d "$QUEUE_DIR" ]] && q=$(ls "$QUEUE_DIR" 2>/dev/null | wc -l | tr -d ' ')
  local j=0
  [[ -f "$JOURNAL" ]] && j=$(wc -l < "$JOURNAL" | tr -d ' ')
  echo -e "${CYAN}branch:${NC}${branch}  ${CYAN}dirty:${NC}${dirty}  ${CYAN}mesh:${NC}${online}/6  ${CYAN}queue:${NC}${q}  ${CYAN}journal:${NC}${j}"
}

cmd_watch() {
  local interval="${1:-10}"
  echo -e "${CYAN}Watching system status every ${interval}s — Ctrl+C to stop${NC}"
  while true; do
    clear
    cmd_all
    sleep "$interval"
  done
}

cmd_help() {
  echo ""
  echo -e "${BOLD}br status-all${NC} — full system health snapshot"
  echo ""
  echo "  ${CYAN}br status-all${NC}           Full health report"
  echo "  ${CYAN}br status-all quick${NC}     One-line summary"
  echo "  ${CYAN}br status-all watch [N]${NC} Refresh every N seconds"
  echo ""
}

case "${1:-all}" in
  all|full|"") cmd_all ;;
  quick|line)  cmd_quick ;;
  watch)       shift; cmd_watch "$@" ;;
  help|-h)     cmd_help ;;
  *) echo "Unknown: $1. Try: all quick watch"; exit 1 ;;
esac
