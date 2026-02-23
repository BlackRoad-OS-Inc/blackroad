#!/usr/bin/env zsh
# 🪝 BR HOOK — Webhook Engine
# Register webhooks, emit events, receive and route inbound hooks

GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
DIM='\033[2m'
BOLD='\033[1m'
NC='\033[0m'

HOOK_DB="$HOME/.blackroad/hooks.db"
HOOK_DIR="$HOME/.blackroad/hooks"
HOOK_LOG="$HOME/.blackroad/hooks/events.jsonl"
mkdir -p "$HOOK_DIR"

# ── DB ───────────────────────────────────────────────────────────────
init_db() {
  sqlite3 "$HOOK_DB" <<'SQL'
CREATE TABLE IF NOT EXISTS hooks (
  id        TEXT PRIMARY KEY,
  event     TEXT,        -- e.g. 'deploy.start', 'chain.append', 'relay.message', 'git.push'
  target    TEXT,        -- URL or 'br:<cmd>' or 'relay:<instance>'
  method    TEXT DEFAULT 'POST',
  secret    TEXT,        -- HMAC secret for validation
  active    INTEGER DEFAULT 1,
  created   INTEGER DEFAULT (strftime('%s','now')),
  fire_count INTEGER DEFAULT 0,
  last_fired INTEGER
);
CREATE TABLE IF NOT EXISTS hook_events (
  id        INTEGER PRIMARY KEY AUTOINCREMENT,
  ts        INTEGER DEFAULT (strftime('%s','now')),
  event     TEXT,
  payload   TEXT,
  hooks_fired INTEGER DEFAULT 0,
  source    TEXT
);
SQL
}

# ── helpers ───────────────────────────────────────────────────────────
gen_secret() { openssl rand -hex 16; }
hook_id() { echo "hook-$(openssl rand -hex 4)"; }
event_id() { echo "evt-$(date +%s)-$(openssl rand -hex 3)"; }

# Compute HMAC-SHA256 signature for a payload
sign_payload() {
  local secret=$1
  local payload=$2
  echo -n "$payload" | openssl dgst -sha256 -hmac "$secret" -hex | awk '{print $2}'
}

# ── fire a hook ────────────────────────────────────────────────────────
fire_hook() {
  local hook_id=$1
  local event=$2
  local payload=$3

  local row=$(sqlite3 "$HOOK_DB" "SELECT id,target,method,secret FROM hooks WHERE id='$hook_id' AND active=1;")
  [[ -z "$row" ]] && return 1

  local target=$(echo "$row" | cut -d'|' -f2)
  local method=$(echo "$row" | cut -d'|' -f3)
  local secret=$(echo "$row" | cut -d'|' -f4)

  # Route based on target type
  if [[ "$target" == br:* ]]; then
    # Execute a br command
    local cmd="${target#br:}"
    eval "$cmd" >/dev/null 2>&1
    sqlite3 "$HOOK_DB" "UPDATE hooks SET fire_count=fire_count+1, last_fired=strftime('%s','now') WHERE id='$hook_id';"
    return $?

  elif [[ "$target" == relay:* ]]; then
    # Send to relay inbox
    local instance="${target#relay:}"
    /Users/alexa/blackroad/br relay send "$instance" "hook:$event" "$payload" >/dev/null 2>&1
    sqlite3 "$HOOK_DB" "UPDATE hooks SET fire_count=fire_count+1, last_fired=strftime('%s','now') WHERE id='$hook_id';"

  elif [[ "$target" == http* ]]; then
    # HTTP POST
    local sig=""
    [[ -n "$secret" ]] && sig=$(sign_payload "$secret" "$payload")
    local headers='-H "Content-Type: application/json"'
    [[ -n "$sig" ]] && headers="$headers -H \"X-BlackRoad-Signature: sha256=$sig\""
    curl -sf -X "$method" $headers -d "$payload" "$target" >/dev/null 2>&1
    local rc=$?
    sqlite3 "$HOOK_DB" "UPDATE hooks SET fire_count=fire_count+1, last_fired=strftime('%s','now') WHERE id='$hook_id';"
    return $rc

  elif [[ "$target" == log:* || "$target" == "log" ]]; then
    # Just log the event
    echo "{\"ts\":$(date +%s),\"event\":\"$event\",\"payload\":$(echo $payload | python3 -c 'import sys,json; print(json.dumps(sys.stdin.read().strip()))' 2>/dev/null || echo '\"\"')}" >> "$HOOK_LOG"
    sqlite3 "$HOOK_DB" "UPDATE hooks SET fire_count=fire_count+1, last_fired=strftime('%s','now') WHERE id='$hook_id';"
  fi
}

# ── emit: fire all hooks registered for an event ─────────────────────
cmd_emit() {
  init_db
  local event=$1
  local payload=${2:-"{}"}
  if [[ -z "$event" ]]; then
    echo -e "${RED}Usage: br hook emit <event> [payload_json]${NC}"; exit 1
  fi

  # Build full payload
  local full_payload
  full_payload=$(python3 -c "
import json, time
p = $payload
if not isinstance(p, dict): p = {'data': p}
p['event'] = '$event'
p['ts'] = int(time.time())
p['source'] = 'br-hook'
print(json.dumps(p))
" 2>/dev/null || echo "{\"event\":\"$event\",\"ts\":$(date +%s)}")

  # Log the event
  local eid=$(event_id)
  sqlite3 "$HOOK_DB" "INSERT INTO hook_events(event,payload,source) VALUES('$event',$(echo "$full_payload" | python3 -c 'import sys; print(repr(sys.stdin.read().strip()))' 2>/dev/null || echo "''"),'cli');"

  # Also append to chain
  /Users/alexa/blackroad/br chain append "hook-emit" "$event" "$eid" >/dev/null 2>&1

  # Fire matching hooks (exact + wildcard patterns)
  local fired=0
  sqlite3 "$HOOK_DB" "SELECT id FROM hooks WHERE active=1 AND (event='$event' OR event='*' OR event LIKE '${event%%.*}.%');" | while read hid; do
    fire_hook "$hid" "$event" "$full_payload"
    ((fired++))
  done

  echo -e "${GREEN}✓ Event emitted:${NC} $event  ${DIM}fired hooks matching pattern${NC}"

  # Relay broadcast for mesh events
  if [[ "$event" == mesh.* || "$event" == deploy.* || "$event" == auth.* ]]; then
    /Users/alexa/blackroad/br relay send all "hook:$event" "$full_payload" >/dev/null 2>&1
  fi
}

# ── register a hook ───────────────────────────────────────────────────
cmd_add() {
  init_db
  local event=$1
  local target=$2
  if [[ -z "$event" || -z "$target" ]]; then
    echo -e "${RED}Usage: br hook add <event> <target>${NC}"
    echo -e "${DIM}  target: http://..., br:<cmd>, relay:<instance>, log${NC}"
    exit 1
  fi
  local hid=$(hook_id)
  local secret=$(gen_secret)
  sqlite3 "$HOOK_DB" "INSERT INTO hooks(id,event,target,secret) VALUES('$hid','$event','$target','$secret');"
  echo -e "${GREEN}✓ Hook registered${NC}"
  echo -e "  ${YELLOW}ID${NC}     $hid"
  echo -e "  ${YELLOW}Event${NC}  $event"
  echo -e "  ${YELLOW}Target${NC} $target"
  echo -e "  ${YELLOW}Secret${NC} $secret"
}

cmd_list() {
  init_db
  echo -e ""
  echo -e "  ${CYAN}${BOLD}🪝 Registered Hooks${NC}"
  echo -e "  ${DIM}──────────────────────────────────────────────────────────────${NC}"
  local count=$(sqlite3 "$HOOK_DB" "SELECT COUNT(*) FROM hooks WHERE active=1;")
  if [[ "$count" == "0" ]]; then
    echo -e "  ${DIM}No hooks registered. Use: br hook add <event> <target>${NC}"
    echo -e ""
    echo -e "  ${DIM}Example events: deploy.start, git.push, auth.login, chain.append, *${NC}"
    echo -e "  ${DIM}Example targets: log, relay:claude, br:chain tip, http://localhost:3000/hook${NC}"
    echo -e ""
    return
  fi
  sqlite3 "$HOOK_DB" "SELECT id,event,target,fire_count,datetime(last_fired,'unixepoch','localtime') FROM hooks WHERE active=1 ORDER BY fire_count DESC;" | while IFS='|' read hid event target fires last; do
    echo -e "  ${YELLOW}$hid${NC}  ${CYAN}$event${NC}  →  $target  ${DIM}fired=$fires${NC}"
    [[ -n "$last" ]] && echo -e "  ${DIM}  last fired: $last${NC}"
  done
  echo -e ""
}

cmd_events() {
  init_db
  local n=${1:-15}
  echo -e ""
  echo -e "  ${CYAN}${BOLD}🪝 Recent Events (last $n)${NC}"
  echo -e "  ${DIM}──────────────────────────────────────────────────────────────${NC}"
  sqlite3 "$HOOK_DB" "SELECT datetime(ts,'unixepoch','localtime'), event, source FROM hook_events ORDER BY id DESC LIMIT $n;" | while IFS='|' read ts evt src; do
    echo -e "  ${DIM}$ts${NC}  ${CYAN}$evt${NC}  ${DIM}from: $src${NC}"
  done
  echo -e ""
}

cmd_delete() {
  init_db
  local hid=$1
  sqlite3 "$HOOK_DB" "UPDATE hooks SET active=0 WHERE id='$hid';"
  echo -e "${GREEN}✓ Hook removed: $hid${NC}"
}

cmd_test() {
  init_db
  local hid=$1
  local row=$(sqlite3 "$HOOK_DB" "SELECT id,event,target FROM hooks WHERE id='$hid' AND active=1;")
  [[ -z "$row" ]] && { echo -e "${RED}✗ Hook not found: $hid${NC}"; exit 1; }
  local event=$(echo "$row" | cut -d'|' -f2)
  local target=$(echo "$row" | cut -d'|' -f3)
  echo -e "${CYAN}Testing hook $hid ($event → $target)...${NC}"
  fire_hook "$hid" "$event" "{\"test\":true,\"hook\":\"$hid\"}"
  echo -e "${GREEN}✓ Test fired${NC}"
}

cmd_seed() {
  # Register useful default hooks
  init_db
  local added=0

  # Log everything to file
  sqlite3 "$HOOK_DB" "INSERT OR IGNORE INTO hooks(id,event,target,secret) VALUES('hook-log-all','*','log','$(gen_secret)');"
  # Relay deploy events to all instances
  sqlite3 "$HOOK_DB" "INSERT OR IGNORE INTO hooks(id,event,target,secret) VALUES('hook-deploy-relay','deploy.start','relay:all','$(gen_secret)');"
  # Chain-anchor auth events
  sqlite3 "$HOOK_DB" "INSERT OR IGNORE INTO hooks(id,event,target,secret) VALUES('hook-auth-chain','auth.login','br:chain append auth-hook login hook-fired','$(gen_secret)');"
  echo -e "${GREEN}✓ Default hooks registered (log-all, deploy-relay, auth-chain)${NC}"
}

cmd_help() {
  echo -e ""
  echo -e "  ${CYAN}${BOLD}🪝 BR HOOK${NC}  ${DIM}Webhook Engine${NC}"
  echo -e "  ${DIM}Register, emit, and route events across the BlackRoad mesh${NC}"
  echo -e "  ${DIM}────────────────────────────────────────────────────────${NC}"
  echo -e "  ${BOLD}USAGE${NC}  br hook <command> [args]"
  echo -e ""
  echo -e "  ${YELLOW}EMIT${NC}"
  echo -e "  ${CYAN}  emit <event> [json]${NC}          Fire an event to matching hooks"
  echo -e ""
  echo -e "  ${YELLOW}MANAGE${NC}"
  echo -e "  ${CYAN}  add <event> <target>${NC}         Register a new hook"
  echo -e "  ${CYAN}  list${NC}                         List active hooks"
  echo -e "  ${CYAN}  delete <id>${NC}                  Remove a hook"
  echo -e "  ${CYAN}  test <id>${NC}                    Test fire a hook"
  echo -e "  ${CYAN}  seed${NC}                         Register default hooks"
  echo -e ""
  echo -e "  ${YELLOW}OBSERVE${NC}"
  echo -e "  ${CYAN}  events [n]${NC}                   Show recent events"
  echo -e ""
  echo -e "  ${YELLOW}EVENT PATTERNS${NC}"
  echo -e "  ${DIM}  *                 Match all events${NC}"
  echo -e "  ${DIM}  deploy.*          Match all deploy events${NC}"
  echo -e "  ${DIM}  deploy.start      Exact match${NC}"
  echo -e ""
  echo -e "  ${YELLOW}TARGET TYPES${NC}"
  echo -e "  ${DIM}  log               Write to events log file${NC}"
  echo -e "  ${DIM}  relay:<instance>  Send to mesh inbox (claude, all, codex...)${NC}"
  echo -e "  ${DIM}  br:<command>      Execute a br command${NC}"
  echo -e "  ${DIM}  http://...        HTTP POST with HMAC signature${NC}"
  echo -e ""
  echo -e "  ${YELLOW}EXAMPLES${NC}"
  echo -e "  ${DIM}  br hook add deploy.start relay:all${NC}"
  echo -e "  ${DIM}  br hook add auth.login log${NC}"
  echo -e "  ${DIM}  br hook add git.push br:chain append git push hook${NC}"
  echo -e "  ${DIM}  br hook emit deploy.start '{\"env\":\"prod\",\"branch\":\"master\"}'${NC}"
  echo -e "  ${DIM}  br hook emit git.push${NC}"
  echo -e ""
}

# ── dispatch ──────────────────────────────────────────────────────────
init_db

case "${1:-help}" in
  emit|fire|trigger)    cmd_emit "$2" "$3" ;;
  add|register|on)      cmd_add "$2" "$3" ;;
  list|ls|hooks)        cmd_list ;;
  events|log|recent)    cmd_events "${2:-15}" ;;
  delete|rm|off)        cmd_delete "$2" ;;
  test|ping)            cmd_test "$2" ;;
  seed|defaults|init)   cmd_seed ;;
  help|--help|-h)       cmd_help ;;
  *)
    echo -e "${RED}✗ Unknown: $1${NC}"
    cmd_help; exit 1 ;;
esac
