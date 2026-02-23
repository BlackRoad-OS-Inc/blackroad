#!/bin/zsh
# BR WORKER — Live bridge to BlackRoad Cloudflare workers
# Connects br CLI → workers → Railway + GitHub + Agent mesh

AMBER='\033[38;5;214m'; PINK='\033[38;5;205m'; VIOLET='\033[38;5;135m'; BBLUE='\033[38;5;69m'
GREEN='\033[0;32m'; RED='\033[0;31m'; BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'
CYAN="$AMBER"; YELLOW="$PINK"

# ── Config ───────────────────────────────────────────────────
WORKER_BASE="${BLACKROAD_WORKER_URL:-https://blackroad-os-api.amundsonalexa.workers.dev}"
RAILWAY_TOKEN="${RAILWAY_TOKEN:-}"
GITHUB_TOKEN="${GITHUB_TOKEN:-}"
GITHUB_ORG="${GITHUB_ORG:-BlackRoad-OS-Inc}"
GITHUB_REPO="${GITHUB_REPO:-blackroad}"

# ── Helpers ──────────────────────────────────────────────────
_header() {
  echo ""
  echo -e "  ${AMBER}${BOLD}◆ BR WORKER${NC}  ${DIM}Live bridge to the BlackRoad edge.${NC}"
  echo -e "  ${DIM}────────────────────────────────────────────────${NC}"
  echo ""
}

_ok()    { echo -e "  ${GREEN}✓${NC} $*"; }
_err()   { echo -e "  ${RED}✗${NC} $*" >&2; }
_info()  { echo -e "  ${BBLUE}→${NC} $*"; }
_dim()   { echo -e "  ${DIM}$*${NC}"; }
_label() { echo -e "  ${AMBER}${BOLD}$1${NC}  ${DIM}$2${NC}"; }

_fetch() {
  local url="$1"
  local response
  response=$(curl -sf --max-time 10 "$url" 2>&1)
  local code=$?
  if [[ $code -ne 0 ]]; then
    _err "request failed (curl exit $code): $url"
    return 1
  fi
  echo "$response"
}

_jq_or_raw() {
  # pretty-print if jq available, else cat
  if command -v jq &>/dev/null; then
    echo "$1" | jq -r "${2:-.}"
  else
    echo "$1"
  fi
}

# ── Commands ─────────────────────────────────────────────────

cmd_health() {
  _header
  _info "pinging $WORKER_BASE/health …"
  local data; data=$(_fetch "$WORKER_BASE/health") || return 1
  if command -v jq &>/dev/null; then
    local sval;   sval=$(echo "$data"   | jq -r '.status')
    local version;  version=$(echo "$data"  | jq -r '.version')
    local online;   online=$(echo "$data"   | jq -r '.agents_online')
    local total;    total=$(echo "$data"    | jq -r '.agents_total')
    local ts;       ts=$(echo "$data"       | jq -r '.timestamp')
    _label "status"   "$sval"
    _label "version"  "$version"
    _label "agents"   "$online / $total online"
    _label "time"     "$ts"
  else
    echo "$data"
  fi
  echo ""
}

cmd_status() {
  _header
  _info "fetching platform status …"
  local data; data=$(_fetch "$WORKER_BASE/status") || return 1
  if command -v jq &>/dev/null; then
    echo -e "  ${BOLD}Platform${NC}"
    echo "$data" | jq -r '
      "  status:   \(.status)",
      "  version:  \(.version)",
      "  capacity: \(.capacity) agents"
    '
    echo ""
    echo -e "  ${BOLD}Services${NC}"
    echo "$data" | jq -r '.services | to_entries[] | "  \(.key): \(.value)"'
    echo ""
    echo -e "  ${BOLD}Agents${NC}"
    echo "$data" | jq -r '.agents | "  online: \(.online)  standby: \(.standby)  total: \(.total)"'
  else
    echo "$data"
  fi
  echo ""
}

cmd_agents() {
  _header
  _info "loading agent roster …"
  local data; data=$(_fetch "$WORKER_BASE/agents") || return 1
  if command -v jq &>/dev/null; then
    local total; total=$(echo "$data" | jq -r '.total')
    local online; online=$(echo "$data" | jq -r '.online')
    echo -e "  ${AMBER}${BOLD}$online/$total online${NC}\n"
    echo "$data" | jq -r '.agents[] |
      "  \(.emoji)  \(.name | ascii_downcase) (\(.status))  \(.role)  [\(.model)]"'
  else
    echo "$data"
  fi
  echo ""
}

cmd_railway() {
  _header
  local sub="${1:-projects}"
  local project="${2:-}"

  _info "fetching railway ${sub} …"

  local url="$WORKER_BASE/railway"
  [[ "$sub" == "deployments" ]] && url="$WORKER_BASE/railway/deployments${project:+?project=$project}"

  local data; data=$(_fetch "$url") || return 1

  if echo "$data" | grep -q '"error"'; then
    _err "worker says: $(echo "$data" | python3 -c 'import sys,json; d=json.load(sys.stdin); print(d.get("error","?"))')"
    _dim "→ set RAILWAY_TOKEN: wrangler secret put RAILWAY_TOKEN"
    return 1
  fi

  if command -v jq &>/dev/null; then
    if [[ "$sub" == "deployments" ]]; then
      local total; total=$(echo "$data" | jq -r '.total')
      echo -e "  ${AMBER}${BOLD}$total deployments${NC}\n"
      echo "$data" | jq -r '.deployments[] |
        "  [\(.status | ascii_upcase)] \(.service // "?")  branch:\(.branch // "?")  \(.created | split("T")[0])\n    \(.message // "")"'
    else
      local total; total=$(echo "$data" | jq -r '.total')
      echo -e "  ${AMBER}${BOLD}$total projects${NC}\n"
      echo "$data" | jq -r '.projects[] |
        "  ◆ \(.name)  \(.services) services  \(.environments) envs  updated:\(.updated | split("T")[0])"'
    fi
  else
    echo "$data"
  fi
  echo ""
}

cmd_github() {
  _header
  local sub="${1:-runs}"
  local repo_flag="${2:-}"

  local url="$WORKER_BASE/github/${sub}"
  [[ -n "$repo_flag" ]] && url="${url}?repo=$repo_flag"

  _info "fetching github ${sub} (${GITHUB_ORG}/${GITHUB_REPO}) …"
  local data; data=$(_fetch "$url") || return 1

  if echo "$data" | grep -q '"error"'; then
    _err "worker says: $(echo "$data" | python3 -c 'import sys,json; d=json.load(sys.stdin); print(d.get("error","?"))')"
    _dim "→ set GITHUB_TOKEN: wrangler secret put GITHUB_TOKEN"
    return 1
  fi

  if command -v jq &>/dev/null; then
    if [[ "$sub" == "runs" ]]; then
      local total; total=$(echo "$data" | jq -r '.total')
      echo -e "  ${AMBER}${BOLD}$total recent runs${NC}  (${GITHUB_ORG}/${GITHUB_REPO})\n"
      echo "$data" | jq -r '.runs[] |
        "  [\(.status | ascii_upcase)\(if .conclusion then "/\(.conclusion|ascii_upcase)" else "" end)]  \(.name)  branch:\(.branch)  by:\(.actor // "?")  \(.created | split("T")[0])"'
    elif [[ "$sub" == "repo" ]]; then
      echo "$data" | jq -r '"  \(.name)\n  \(.description // "")\n  ★ \(.stars)  forks: \(.forks)  issues: \(.open_issues)\n  branch: \(.default_branch)  updated: \(.updated | split("T")[0])"'
    elif [[ "$sub" == "orgs" ]]; then
      echo "$data" | jq -r '.repos[] | "  ◆ \(.name)  ★\(.stars)  \(.updated | split("T")[0])"'
    fi
  else
    echo "$data"
  fi
  echo ""
}

cmd_watch() {
  # Live polling dashboard — worker + railway + github
  local interval="${1:-10}"
  _header
  echo -e "  ${DIM}refreshing every ${interval}s — ctrl+c to quit${NC}\n"

  while true; do
    tput clear 2>/dev/null || printf '\033[2J\033[H'
    echo ""
    echo -e "  ${AMBER}${BOLD}◆ BLACKROAD LIVE${NC}  ${DIM}$(date '+%H:%M:%S')${NC}"
    echo -e "  ${DIM}────────────────────────────────────────────────${NC}"
    echo ""

    # Health
    local health; health=$(curl -sf --max-time 5 "$WORKER_BASE/health" 2>/dev/null)
    if [[ -n "$health" ]]; then
      local online; online=$(echo "$health" | python3 -c 'import sys,json;d=json.load(sys.stdin);print(d.get("agents_online","?"))' 2>/dev/null)
      local total;  total=$(echo "$health"  | python3 -c 'import sys,json;d=json.load(sys.stdin);print(d.get("agents_total","?"))' 2>/dev/null)
      local ver;    ver=$(echo "$health"    | python3 -c 'import sys,json;d=json.load(sys.stdin);print(d.get("version","?"))' 2>/dev/null)
      echo -e "  ${GREEN}●${NC} ${BOLD}Worker${NC}  ${DIM}v${ver}${NC}  agents ${AMBER}${online}/${total}${NC} online"
    else
      echo -e "  ${RED}●${NC} ${BOLD}Worker${NC}  unreachable"
    fi

    # Railway
    local rail; rail=$(curl -sf --max-time 5 "$WORKER_BASE/railway" 2>/dev/null)
    if echo "$rail" | grep -q '"error"' 2>/dev/null; then
      echo -e "  ${YELLOW}●${NC} ${BOLD}Railway${NC}  ${DIM}no token${NC}"
    elif [[ -n "$rail" ]]; then
      local rcount; rcount=$(echo "$rail" | python3 -c 'import sys,json;d=json.load(sys.stdin);print(d.get("total","?"))' 2>/dev/null)
      echo -e "  ${GREEN}●${NC} ${BOLD}Railway${NC}  ${AMBER}${rcount}${NC} projects"
    fi

    # GitHub
    local gh; gh=$(curl -sf --max-time 5 "$WORKER_BASE/github/runs" 2>/dev/null)
    if echo "$gh" | grep -q '"error"' 2>/dev/null; then
      echo -e "  ${YELLOW}●${NC} ${BOLD}GitHub${NC}   ${DIM}no token${NC}"
    elif [[ -n "$gh" ]]; then
      local gcount; gcount=$(echo "$gh" | python3 -c 'import sys,json;d=json.load(sys.stdin);print(d.get("total","?"))' 2>/dev/null)
      # Show last run status
      local last_run; last_run=$(echo "$gh" | python3 -c '
import sys, json
d = json.load(sys.stdin)
runs = d.get("runs", [])
if runs:
    r = runs[0]
    st = r.get("conclusion") or r.get("status","?")
    print(f"{r[\"name\"]} [{st.upper()}] {r[\"branch\"]}")
' 2>/dev/null)
      echo -e "  ${GREEN}●${NC} ${BOLD}GitHub${NC}   ${AMBER}${gcount}${NC} runs  ${DIM}${last_run}${NC}"
    fi

    echo ""
    echo -e "  ${DIM}next refresh in ${interval}s …${NC}"
    sleep "$interval"
  done
}

cmd_open() {
  local page="${1:-}"
  local url="$WORKER_BASE${page:+/$page}"
  _info "opening $url"
  open "$url" 2>/dev/null || xdg-open "$url" 2>/dev/null || echo "$url"
}

cmd_help() {
  echo ""
  echo -e "  ${AMBER}${BOLD}◆ BR WORKER${NC}  ${DIM}Live bridge to the BlackRoad edge.${NC}"
  echo -e "  ${DIM}────────────────────────────────────────────────${NC}"
  echo ""
  echo -e "  ${BOLD}worker${NC}"
  echo -e "  ${AMBER}health${NC}                          ping worker health"
  echo -e "  ${AMBER}status${NC}                          full platform status"
  echo -e "  ${AMBER}agents${NC}                          agent roster from worker"
  echo -e "  ${AMBER}watch${NC}  [interval=10]            live dashboard (worker+railway+github)"
  echo -e "  ${AMBER}open${NC}   [path]                   open in browser"
  echo ""
  echo -e "  ${BOLD}railway${NC}"
  echo -e "  ${AMBER}railway${NC}                         list Railway projects"
  echo -e "  ${AMBER}railway deployments${NC} [id]        recent deployments"
  echo ""
  echo -e "  ${BOLD}github${NC}"
  echo -e "  ${AMBER}github${NC}                          latest Actions runs"
  echo -e "  ${AMBER}github repo${NC}                     repo stats"
  echo -e "  ${AMBER}github orgs${NC}                     org repos"
  echo ""
  echo -e "  ${DIM}Worker URL: $WORKER_BASE${NC}"
  echo ""
}

# ── Dispatch ─────────────────────────────────────────────────
case "${1:-help}" in
  health|ping)               cmd_health ;;
  status)                    cmd_status ;;
  agents)                    cmd_agents ;;
  watch|live)                cmd_watch "${2:-10}" ;;
  open|browser)              cmd_open "${2:-}" ;;
  railway|rail)              cmd_railway "${2:-projects}" "${3:-}" ;;
  github|gh)                 cmd_github "${2:-runs}" "${3:-}" ;;
  help|--help|-h)            cmd_help ;;
  *)
    _err "unknown: $1"
    cmd_help
    exit 1
    ;;
esac
