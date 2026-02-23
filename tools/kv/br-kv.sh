#!/bin/zsh
# BR KV — Cloudflare KV Namespace Manager

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'
BLUE='\033[0;34m'; GRAY='\033[0;37m'; BOLD='\033[1m'; NC='\033[0m'

DB_FILE="$HOME/.blackroad/kv.db"
CF_ACCOUNT_ID="848cf0b18d51e0170e0d1537aec3505a"

init_db() {
  mkdir -p "$(dirname "$DB_FILE")"
  sqlite3 "$DB_FILE" <<'EOF'
CREATE TABLE IF NOT EXISTS namespaces (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  preview_id TEXT,
  created_at TEXT DEFAULT (datetime('now'))
);
CREATE TABLE IF NOT EXISTS config (
  key TEXT PRIMARY KEY,
  value TEXT
);
EOF
}

get_token() {
  local tok
  tok=$(sqlite3 "$DB_FILE" "SELECT value FROM config WHERE key='cf_token';" 2>/dev/null)
  if [[ -z "$tok" ]]; then
    tok=$CLOUDFLARE_API_TOKEN
  fi
  echo "$tok"
}

cf_api() {
  local path="$1"; shift
  local token; token=$(get_token)
  if [[ -z "$token" ]]; then
    echo -e "${RED}✗${NC} No Cloudflare API token. Run: br kv auth <token>" >&2
    return 1
  fi
  curl -s -H "Authorization: Bearer $token" -H "Content-Type: application/json" "$@" \
    "https://api.cloudflare.com/client/v4/accounts/$CF_ACCOUNT_ID$path"
}

cmd_auth() {
  local token="$1"
  if [[ -z "$token" ]]; then
    echo -e "${RED}✗${NC} Usage: br kv auth <cf-api-token>"
    exit 1
  fi
  init_db
  sqlite3 "$DB_FILE" "INSERT OR REPLACE INTO config (key,value) VALUES ('cf_token','$token');"
  echo -e "${GREEN}✓${NC} Token saved."
}

cmd_namespaces() {
  init_db
  echo -e "${CYAN}${BOLD}  ◆ KV NAMESPACES${NC}\n"
  local result; result=$(cf_api "/storage/kv/namespaces?per_page=100") || return 1
  local count; count=$(echo "$result" | python3 -c "import sys,json; d=json.load(sys.stdin); print(len(d.get('result',[])), d.get('result_info',{}).get('total_count','?'))" 2>/dev/null)
  echo "$result" | python3 -c "
import sys, json
d = json.load(sys.stdin)
rows = d.get('result', [])
if not rows:
    print('  No namespaces found.')
    sys.exit(0)
for r in rows:
    print(f\"  {r['id'][:16]}…  {r['title']}\")
" 2>/dev/null || echo -e "${RED}✗${NC} Failed to parse response."
  echo ""
}

cmd_list() {
  local ns="$1"
  if [[ -z "$ns" ]]; then
    cmd_namespaces
    return
  fi
  # Resolve namespace ID by name or use directly
  local ns_id; ns_id=$(resolve_ns "$ns")
  if [[ -z "$ns_id" ]]; then
    echo -e "${RED}✗${NC} Namespace not found: $ns"; exit 1
  fi
  echo -e "${CYAN}${BOLD}  ◆ KV KEYS  ${GRAY}$ns${NC}\n"
  local result; result=$(cf_api "/storage/kv/namespaces/$ns_id/keys?limit=100") || return 1
  echo "$result" | python3 -c "
import sys, json
d = json.load(sys.stdin)
keys = d.get('result', [])
if not keys:
    print('  (empty)')
    sys.exit(0)
for k in keys:
    exp = f\" (expires {k['expiration']})\" if 'expiration' in k else ''
    print(f\"  {k['name']}{exp}\")
print(f\"\n  {len(keys)} keys\")
" 2>/dev/null
  echo ""
}

cmd_get() {
  local ns="$1" key="$2"
  if [[ -z "$ns" || -z "$key" ]]; then
    echo -e "${RED}✗${NC} Usage: br kv get <namespace> <key>"; exit 1
  fi
  local ns_id; ns_id=$(resolve_ns "$ns")
  if [[ -z "$ns_id" ]]; then echo -e "${RED}✗${NC} Namespace not found: $ns"; exit 1; fi
  local token; token=$(get_token)
  local val; val=$(curl -s -H "Authorization: Bearer $token" \
    "https://api.cloudflare.com/client/v4/accounts/$CF_ACCOUNT_ID/storage/kv/namespaces/$ns_id/values/$key")
  echo "$val"
}

cmd_set() {
  local ns="$1" key="$2" value="$3"
  if [[ -z "$ns" || -z "$key" || -z "$value" ]]; then
    echo -e "${RED}✗${NC} Usage: br kv set <namespace> <key> <value>"; exit 1
  fi
  local ns_id; ns_id=$(resolve_ns "$ns")
  if [[ -z "$ns_id" ]]; then echo -e "${RED}✗${NC} Namespace not found: $ns"; exit 1; fi
  local token; token=$(get_token)
  local result; result=$(curl -s -X PUT -H "Authorization: Bearer $token" \
    -H "Content-Type: text/plain" \
    --data "$value" \
    "https://api.cloudflare.com/client/v4/accounts/$CF_ACCOUNT_ID/storage/kv/namespaces/$ns_id/values/$key")
  if echo "$result" | grep -q '"success":true'; then
    echo -e "${GREEN}✓${NC} Set $key in $ns"
  else
    echo -e "${RED}✗${NC} Failed: $(echo "$result" | python3 -c 'import sys,json;d=json.load(sys.stdin);print(d.get("errors",[{}])[0].get("message","unknown"))' 2>/dev/null)"
  fi
}

cmd_del() {
  local ns="$1" key="$2"
  if [[ -z "$ns" || -z "$key" ]]; then
    echo -e "${RED}✗${NC} Usage: br kv del <namespace> <key>"; exit 1
  fi
  local ns_id; ns_id=$(resolve_ns "$ns")
  if [[ -z "$ns_id" ]]; then echo -e "${RED}✗${NC} Namespace not found: $ns"; exit 1; fi
  local token; token=$(get_token)
  local result; result=$(curl -s -X DELETE -H "Authorization: Bearer $token" \
    "https://api.cloudflare.com/client/v4/accounts/$CF_ACCOUNT_ID/storage/kv/namespaces/$ns_id/values/$key")
  if echo "$result" | grep -q '"success":true'; then
    echo -e "${GREEN}✓${NC} Deleted $key from $ns"
  else
    echo -e "${RED}✗${NC} Failed."
  fi
}

cmd_create() {
  local name="$1"
  if [[ -z "$name" ]]; then
    echo -e "${RED}✗${NC} Usage: br kv create <name>"; exit 1
  fi
  local result; result=$(cf_api "/storage/kv/namespaces" -X POST --data "{\"title\":\"$name\"}") || return 1
  local id; id=$(echo "$result" | python3 -c "import sys,json;d=json.load(sys.stdin);print(d.get('result',{}).get('id',''))" 2>/dev/null)
  if [[ -n "$id" ]]; then
    sqlite3 "$DB_FILE" "INSERT OR REPLACE INTO namespaces (id,name) VALUES ('$id','$name');"
    echo -e "${GREEN}✓${NC} Created: ${BOLD}$name${NC}  ${GRAY}$id${NC}"
  else
    echo -e "${RED}✗${NC} Failed: $(echo "$result" | python3 -c 'import sys,json;d=json.load(sys.stdin);print(d.get("errors",[{}])[0].get("message","unknown"))' 2>/dev/null)"
  fi
}

resolve_ns() {
  # Accept full ID or look up by name/prefix in CF API
  local query="$1"
  if [[ ${#query} -ge 32 ]]; then echo "$query"; return; fi
  # Search by name via API
  local result; result=$(cf_api "/storage/kv/namespaces?per_page=100") 2>/dev/null || return 1
  echo "$result" | python3 -c "
import sys, json
q = sys.argv[1].lower()
d = json.load(sys.stdin)
for r in d.get('result', []):
    if q in r['title'].lower():
        print(r['id'])
        break
" "$query" 2>/dev/null
}

show_help() {
  echo -e "\n${BOLD}  BR KV${NC}  Cloudflare KV Manager\n"
  echo -e "  ${CYAN}br kv auth <token>${NC}          Save CF API token"
  echo -e "  ${CYAN}br kv list${NC}                  List all namespaces"
  echo -e "  ${CYAN}br kv list <namespace>${NC}       List keys in namespace"
  echo -e "  ${CYAN}br kv get <ns> <key>${NC}         Get a value"
  echo -e "  ${CYAN}br kv set <ns> <key> <val>${NC}   Set a value"
  echo -e "  ${CYAN}br kv del <ns> <key>${NC}         Delete a key"
  echo -e "  ${CYAN}br kv create <name>${NC}          Create new namespace"
  echo ""
}

init_db

case "$1" in
  auth)       cmd_auth "$2" ;;
  list|ls)    cmd_list "$2" ;;
  get)        cmd_get "$2" "$3" ;;
  set|put)    cmd_set "$2" "$3" "$4" ;;
  del|rm)     cmd_del "$2" "$3" ;;
  create|new) cmd_create "$2" ;;
  namespaces|ns) cmd_namespaces ;;
  *)          show_help ;;
esac
