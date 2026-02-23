#!/usr/bin/env zsh
# BR Webhook Test — send test payloads to webhook endpoints

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; BLUE='\033[0;34m'; PURPLE='\033[0;35m'; NC='\033[0m'
BOLD='\033[1m'

DB="$HOME/.blackroad/webhook.db"

init_db() {
  mkdir -p "$(dirname "$DB")"
  sqlite3 "$DB" <<'SQL'
CREATE TABLE IF NOT EXISTS endpoints (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT UNIQUE NOT NULL,
  url TEXT NOT NULL,
  secret TEXT DEFAULT '',
  description TEXT DEFAULT '',
  created_at TEXT DEFAULT (datetime('now'))
);
CREATE TABLE IF NOT EXISTS templates (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT UNIQUE NOT NULL,
  category TEXT DEFAULT 'custom',
  payload TEXT NOT NULL,
  headers TEXT DEFAULT '{}',
  description TEXT DEFAULT '',
  created_at TEXT DEFAULT (datetime('now'))
);
CREATE TABLE IF NOT EXISTS history (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  endpoint_name TEXT,
  url TEXT NOT NULL,
  template_name TEXT DEFAULT '',
  payload TEXT,
  status_code INTEGER DEFAULT 0,
  response TEXT DEFAULT '',
  latency_ms REAL DEFAULT 0,
  success INTEGER DEFAULT 0,
  ts TEXT DEFAULT (datetime('now'))
);
INSERT OR IGNORE INTO templates (name, category, payload, description) VALUES
  ('github-push', 'github', '{"ref":"refs/heads/main","repository":{"name":"my-repo","full_name":"org/my-repo"},"commits":[{"id":"abc123","message":"Test commit","author":{"name":"Alexa"}}],"pusher":{"name":"alexa"}}', 'GitHub push event'),
  ('github-pr-open', 'github', '{"action":"opened","number":1,"pull_request":{"title":"Test PR","state":"open","body":"PR description","user":{"login":"alexa"},"head":{"ref":"feature-branch"},"base":{"ref":"main"}}}', 'GitHub PR opened'),
  ('github-pr-close', 'github', '{"action":"closed","number":1,"pull_request":{"title":"Test PR","merged":true,"merged_by":{"login":"alexa"}}}', 'GitHub PR closed/merged'),
  ('stripe-payment', 'stripe', '{"type":"payment_intent.succeeded","data":{"object":{"id":"pi_test123","amount":2000,"currency":"usd","status":"succeeded"}}}', 'Stripe payment succeeded'),
  ('stripe-sub', 'stripe', '{"type":"customer.subscription.created","data":{"object":{"id":"sub_test123","customer":"cus_test","plan":{"id":"pro","amount":2900},"status":"active"}}}', 'Stripe subscription created'),
  ('slack-event', 'slack', '{"type":"event_callback","event":{"type":"message","text":"Hello from test","user":"U12345","channel":"C12345"},"team_id":"T12345"}', 'Slack message event'),
  ('vercel-deploy', 'vercel', '{"type":"deployment.succeeded","payload":{"deployment":{"id":"dpl_test","url":"test.vercel.app","name":"my-project"},"target":"production"}}', 'Vercel deployment succeeded'),
  ('custom-ping', 'custom', '{"event":"ping","source":"br-webhook-test","timestamp":"__TS__"}', 'Generic ping payload');
SQL
}

_sign_payload() {
  local payload="$1" secret="$2"
  [[ -z "$secret" ]] && echo "" && return
  echo -n "$payload" | openssl dgst -sha256 -hmac "$secret" 2>/dev/null | awk '{print "sha256="$2}' || echo ""
}

_send() {
  local url="$1" payload="$2" secret="${3:-}" extra_headers="${4:-}"
  local ts sig=""
  ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  payload="${payload//__TS__/$ts}"
  [[ -n "$secret" ]] && sig=$(_sign_payload "$payload" "$secret")
  local start_ns end_ns lat
  start_ns=$(python3 -c "import time; print(int(time.time()*1000))" 2>/dev/null || echo "0")
  local resp
  local curl_args=(-s -w "\n__STATUS__%{http_code}" -X POST "$url" \
    -H "Content-Type: application/json" \
    -H "User-Agent: br-webhook-test/1.0" \
    -H "X-Webhook-Test: true" \
    -H "X-Timestamp: $ts" \
    --connect-timeout 10 \
    --max-time 30 \
    -d "$payload")
  [[ -n "$sig" ]] && curl_args+=(-H "X-Hub-Signature-256: $sig")
  # Parse extra headers (key:value pairs, comma-separated)
  if [[ -n "$extra_headers" ]]; then
    echo "$extra_headers" | tr ',' '\n' | while read -r hdr; do
      curl_args+=(-H "$hdr")
    done
  fi
  resp=$(curl "${curl_args[@]}" 2>&1)
  end_ns=$(python3 -c "import time; print(int(time.time()*1000))" 2>/dev/null || echo "0")
  local sc body
  sc=$(echo "$resp" | grep "__STATUS__" | sed 's/__STATUS__//')
  body=$(echo "$resp" | grep -v "__STATUS__")
  [[ -z "$sc" ]] && sc="0"
  local lat=$(( end_ns - start_ns ))
  echo "${sc}|${body}|${lat}"
}

# Send to a named endpoint with a template
cmd_send() {
  local endpoint_or_url="$1" template="${2:-custom-ping}" extra="${3:-}"
  [[ -z "$endpoint_or_url" ]] && { echo "Usage: br webhook send <endpoint|url> [template] [extra_headers]"; exit 1; }
  # Resolve endpoint
  local url secret=""
  local is_name
  is_name=$(sqlite3 "$DB" "SELECT COUNT(*) FROM endpoints WHERE name='$endpoint_or_url';")
  if [[ "$is_name" -gt 0 ]]; then
    url=$(sqlite3 "$DB" "SELECT url FROM endpoints WHERE name='$endpoint_or_url';")
    secret=$(sqlite3 "$DB" "SELECT secret FROM endpoints WHERE name='$endpoint_or_url';")
  else
    url="$endpoint_or_url"
  fi
  # Get payload
  local payload
  local tmpl_exists
  tmpl_exists=$(sqlite3 "$DB" "SELECT COUNT(*) FROM templates WHERE name='$template';")
  if [[ "$tmpl_exists" -gt 0 ]]; then
    payload=$(sqlite3 "$DB" "SELECT payload FROM templates WHERE name='$template';")
  else
    payload="$template"
  fi
  echo ""
  echo -e "${CYAN}${BOLD}📡 Sending webhook test${NC}"
  echo -e "  URL:      ${BOLD}$url${NC}"
  echo -e "  Template: ${BOLD}$template${NC}"
  [[ -n "$secret" ]] && echo -e "  Signed:   ${GREEN}✓ HMAC-SHA256${NC}"
  echo ""
  local result
  result=$(_send "$url" "$payload" "$secret" "$extra")
  local sc body lat
  sc=$(echo "$result" | cut -d'|' -f1)
  body=$(echo "$result" | cut -d'|' -f2)
  lat=$(echo "$result" | cut -d'|' -f3)
  local color="$GREEN"
  [[ "$sc" -ge 400 ]] && color="$YELLOW"
  [[ "$sc" -ge 500 ]] && color="$RED"
  [[ "$sc" -eq 0 ]] && color="$RED"
  echo -e "  Status:   ${color}${BOLD}$sc${NC}"
  echo -e "  Latency:  ${CYAN}${lat}ms${NC}"
  echo ""
  if [[ -n "$body" ]]; then
    echo -e "  ${BOLD}Response:${NC}"
    echo "$body" | head -20 | while read -r line; do
      echo "    $line"
    done
  fi
  # Save to history
  local success=0
  [[ "$sc" -ge 200 && "$sc" -lt 300 ]] && success=1
  local ep_name="$endpoint_or_url"
  [[ "$is_name" -gt 0 ]] && ep_name="$endpoint_or_url"
  local safe_body="${body//\'/''}"
  local safe_payload="${payload//\'/''}"
  sqlite3 "$DB" "INSERT INTO history (endpoint_name, url, template_name, payload, status_code, response, latency_ms, success) VALUES ('$ep_name', '$url', '$template', '$safe_payload', $sc, '${safe_body:0:500}', $lat, $success);"
  echo ""
  [[ "$success" -eq 1 ]] && echo -e "  ${GREEN}✓ Webhook delivered successfully${NC}" || echo -e "  ${RED}✗ Webhook delivery failed${NC}"
  echo ""
}

# Add endpoint
cmd_add() {
  local name="$1" url="$2" secret="${3:-}" desc="${4:-}"
  [[ -z "$name" || -z "$url" ]] && { echo "Usage: br webhook add <name> <url> [secret] [description]"; exit 1; }
  sqlite3 "$DB" "INSERT OR REPLACE INTO endpoints (name, url, secret, description) VALUES ('$name', '$url', '$secret', '$desc');"
  echo -e "${GREEN}✓ Endpoint '$name' added: $url${NC}"
}

# List endpoints
cmd_list() {
  echo ""
  echo -e "${CYAN}${BOLD}🔗 Webhook Endpoints${NC}"
  echo ""
  sqlite3 -separator "|" "$DB" "SELECT name, url, CASE WHEN secret!='' THEN '✓' ELSE '-' END, description FROM endpoints;" | while IFS="|" read -r name url signed desc; do
    echo -e "  ${GREEN}${BOLD}$name${NC}"
    printf "    URL:    %s\n" "$url"
    printf "    Signed: %s  %s\n" "$signed" "$desc"
  done
  echo ""
  echo -e "${CYAN}${BOLD}📋 Templates${NC}"
  echo ""
  sqlite3 -separator "|" "$DB" "SELECT name, category, description FROM templates ORDER BY category, name;" | while IFS="|" read -r name cat desc; do
    printf "  ${YELLOW}%-22s${NC}  %-10s  %s\n" "$name" "$cat" "$desc"
  done
  echo ""
}

# Show history
cmd_history() {
  local n="${1:-20}"
  echo ""
  echo -e "${CYAN}📜 Send History${NC}"
  echo ""
  printf "  ${BOLD}%-5s %-15s %-22s %4s %8s  %s${NC}\n" "ID" "Endpoint" "Template" "SC" "ms" "Time"
  printf "  %-5s %-15s %-22s %4s %8s  %s\n" "─────" "─────────────" "────────────────────" "────" "──────" "────────"
  sqlite3 -separator "|" "$DB" "SELECT id, endpoint_name, template_name, status_code, latency_ms, success, ts FROM history ORDER BY ts DESC LIMIT $n;" | while IFS="|" read -r id ep tmpl sc lat ok ts; do
    local color="$GREEN"; [[ "$ok" -eq 0 ]] && color="$RED"
    printf "  ${color}%-5s %-15s %-22s %4s %8.0f  %s${NC}\n" "$id" "${ep:0:15}" "${tmpl:0:22}" "$sc" "$lat" "${ts:0:16}"
  done
  echo ""
}

# Add custom template
cmd_template() {
  local sub="${1:-list}"
  case "$sub" in
    add)
      local name="$2" payload="$3" cat="${4:-custom}" desc="${5:-}"
      [[ -z "$name" || -z "$payload" ]] && { echo "Usage: br webhook template add <name> <payload> [category] [desc]"; exit 1; }
      sqlite3 "$DB" "INSERT OR REPLACE INTO templates (name, category, payload, description) VALUES ('$name', '$cat', '$payload', '$desc');"
      echo -e "${GREEN}✓ Template '$name' saved${NC}"
      ;;
    show)
      local name="$2"
      [[ -z "$name" ]] && { echo "Usage: br webhook template show <name>"; exit 1; }
      sqlite3 "$DB" "SELECT payload FROM templates WHERE name='$name';" | python3 -c "import json,sys; print(json.dumps(json.loads(sys.stdin.read()), indent=2))" 2>/dev/null || sqlite3 "$DB" "SELECT payload FROM templates WHERE name='$name';"
      ;;
    list|*)
      cmd_list ;;
  esac
}

show_help() {
  echo ""
  echo -e "${CYAN}${BOLD}br webhook${NC} — webhook test & delivery"
  echo ""
  echo -e "  ${GREEN}br webhook send <ep|url> [template]${NC}  Send test payload"
  echo -e "  ${GREEN}br webhook add <name> <url> [secret]${NC} Add endpoint"
  echo -e "  ${GREEN}br webhook list${NC}                     List endpoints & templates"
  echo -e "  ${GREEN}br webhook history [n]${NC}              Send history"
  echo -e "  ${GREEN}br webhook template show <name>${NC}     Show template payload"
  echo -e "  ${GREEN}br webhook template add <n> <payload>${NC} Add custom template"
  echo ""
  echo -e "  ${YELLOW}Templates:${NC} github-push, github-pr-open, stripe-payment, slack-event, vercel-deploy, custom-ping"
  echo -e "  ${YELLOW}Signing:${NC}  Endpoints with secrets send X-Hub-Signature-256 header"
  echo ""
}

init_db
case "${1:-list}" in
  send|fire|test)  shift; cmd_send "$@" ;;
  add)             shift; cmd_add "$@" ;;
  list|ls)         cmd_list ;;
  history|log)     shift; cmd_history "$@" ;;
  template|tmpl)   shift; cmd_template "$@" ;;
  help|-h|--help)  show_help ;;
  *)               show_help ;;
esac
