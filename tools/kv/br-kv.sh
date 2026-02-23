#!/bin/zsh
# BR KV — Cloudflare KV Namespace Browser
export PATH="/usr/bin:/bin:/usr/local/bin:/opt/homebrew/bin:$PATH"

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'
GRAY='\033[0;37m'; BOLD='\033[1m'; NC='\033[0m'

ACCT="848cf0b18d51e0170e0d1537aec3505a"
TF="$HOME/.blackroad/kv_token"

get_token() {
  [[ ! -f "$TF" ]] && { echo -e "  ${RED}No token at $TF${NC}"; exit 1; }
  IFS= read -r _tok < "$TF"
  echo "$_tok"
}

cf_get() {
  local tok; tok=$(get_token)
  /usr/bin/curl -sf -H "Authorization: Bearer $tok" \
    "https://api.cloudflare.com/client/v4/accounts/$ACCT/$1" 2>/dev/null
}

cmd_namespaces() {
  echo -e "\n${CYAN}${BOLD}  KV NAMESPACES${NC}\n"
  cf_get "storage/kv/namespaces?per_page=100" | /usr/bin/python3 -c "
import sys, json
d = json.load(sys.stdin)
ns = d.get('result') or []
for n in ns:
    print(f'  \033[0;36m{n[\"title\"]:<40}\033[0m {n[\"id\"]}')
print(f'\n  Total: {len(ns)} namespaces')
" 2>/dev/null
  echo ""
}

cmd_keys() {
  local ns_id="$1"
  [[ -z "$ns_id" ]] && { echo -e "  ${RED}Usage: br kv keys <namespace-id>${NC}"; return 1; }
  echo -e "\n${CYAN}  Keys in namespace:${NC} $ns_id\n"
  cf_get "storage/kv/namespaces/$ns_id/keys?limit=100" | /usr/bin/python3 -c "
import sys, json
d = json.load(sys.stdin)
keys = d.get('result') or []
for k in keys:
    exp = f' (expires {k[\"expiration\"]})' if k.get('expiration') else ''
    print(f'  \033[0;32m→\033[0m {k[\"name\"]}{exp}')
print(f'\n  {len(keys)} keys')
" 2>/dev/null
  echo ""
}

cmd_get() {
  local ns_id="$1" key="$2"
  [[ -z "$ns_id" || -z "$key" ]] && { echo -e "  ${RED}Usage: br kv get <ns-id> <key>${NC}"; return 1; }
  echo -e "\n${CYAN}  Value of${NC} $key\n"
  local tok; tok=$(get_token)
  /usr/bin/curl -sf -H "Authorization: Bearer $tok" \
    "https://api.cloudflare.com/client/v4/accounts/$ACCT/storage/kv/namespaces/$ns_id/values/$key" && echo ""
}

cmd_put() {
  local ns_id="$1" key="$2" value="$3"
  [[ -z "$ns_id" || -z "$key" || -z "$value" ]] && {
    echo -e "  ${RED}Usage: br kv put <ns-id> <key> <value>${NC}"; return 1; }
  local tok; tok=$(get_token)
  local res; res=$(/usr/bin/curl -sf -X PUT \
    -H "Authorization: Bearer $tok" \
    -d "$value" \
    "https://api.cloudflare.com/client/v4/accounts/$ACCT/storage/kv/namespaces/$ns_id/values/$key")
  echo "$res" | /usr/bin/python3 -c "import sys,json; d=json.load(sys.stdin); print('✓ Written' if d.get('success') else '✗ ' + str(d.get('errors')))" 2>/dev/null
}

cmd_export() {
  local ns_id="$1"
  [[ -z "$ns_id" ]] && { echo -e "  ${RED}Usage: br kv export <namespace-id>${NC}"; return 1; }
  local out="kv-export-${ns_id:0:8}-$(date +%s).json"
  echo -e "\n${CYAN}  Exporting keys to${NC} $out\n"
  local tok; tok=$(get_token)
  # Get all keys
  local keys_json; keys_json=$(cf_get "storage/kv/namespaces/$ns_id/keys?limit=1000")
  echo "$keys_json" | /usr/bin/python3 - "$ns_id" "$ACCT" "$tok" "$out" << 'PYEOF'
import sys, json
import urllib.request, urllib.error

ns_id, acct, tok, out_path = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
data = json.load(sys.stdin)
keys = [k["name"] for k in (data.get("result") or [])]
print(f"  Found {len(keys)} keys, fetching values...")

result = {}
for key in keys[:200]:  # cap at 200
    req = urllib.request.Request(
        f"https://api.cloudflare.com/client/v4/accounts/{acct}/storage/kv/namespaces/{ns_id}/values/{key}",
        headers={"Authorization": f"Bearer {tok}"}
    )
    try:
        with urllib.request.urlopen(req, timeout=3) as r:
            result[key] = r.read().decode()
    except:
        result[key] = None

with open(out_path, "w") as f:
    json.dump(result, f, indent=2)
print(f"  Exported {len(result)} keys → {out_path}")
PYEOF
}

show_help() {
  echo -e "\n${BOLD}  BR KV${NC}  Cloudflare KV Browser\n"
  echo -e "  ${CYAN}br kv namespaces${NC}              List all namespaces (39 total)"
  echo -e "  ${CYAN}br kv keys <ns-id>${NC}            List keys in namespace"
  echo -e "  ${CYAN}br kv get <ns-id> <key>${NC}       Get value"
  echo -e "  ${CYAN}br kv put <ns-id> <key> <val>${NC} Set value"
  echo -e "  ${CYAN}br kv export <ns-id>${NC}          Export all keys to JSON"
  echo ""
}

case "$1" in
  namespaces|ns|list) cmd_namespaces ;;
  keys)               shift; cmd_keys "$@" ;;
  get)                shift; cmd_get "$@" ;;
  put|set)            shift; cmd_put "$@" ;;
  export)             shift; cmd_export "$@" ;;
  *)                  show_help ;;
esac
