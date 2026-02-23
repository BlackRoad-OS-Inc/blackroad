#!/bin/zsh
# BR DOMAINS — Cloudflare DNS Manager
export PATH="/usr/bin:/bin:/usr/local/bin:/opt/homebrew/bin:$PATH"

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'
BLUE='\033[0;34m'; GRAY='\033[0;37m'; BOLD='\033[1m'; NC='\033[0m'

CF_ACCOUNT_ID="848cf0b18d51e0170e0d1537aec3505a"

get_token() {
  local tf="$HOME/.blackroad/kv_token"
  local tok=""
  [[ -f "$tf" ]] && IFS= read -r tok < "$tf"
  [[ -z "$tok" ]] && tok="${CLOUDFLARE_API_TOKEN:-}"
  printf '%s' "$tok"
}

cf_api() {
  local url="$1"; shift
  local token; token=$(get_token)
  [[ -z "$token" ]] && { echo -e "${RED}x${NC} No CF token. Run: br kv auth <token>" >&2; return 1; }
  /usr/bin/curl -s -H "Authorization: Bearer $token" -H "Content-Type: application/json" "$@" "$url"
}

# Get zone ID for a domain name
get_zone_id() {
  local name="$1"
  cf_api "https://api.cloudflare.com/client/v4/zones?name=$name" | \
    /usr/bin/python3 -c "import sys,json;d=json.load(sys.stdin);r=d.get('result',[]);print(r[0]['id'] if r else '')" 2>/dev/null
}

cmd_zones() {
  echo -e "\n${CYAN}${BOLD}  ZONES${NC}\n"
  cf_api "https://api.cloudflare.com/client/v4/zones?per_page=50&account.id=$CF_ACCOUNT_ID" | \
    /usr/bin/python3 -c "
import sys,json
d=json.load(sys.stdin)
zones=d.get('result',[])
print(f'  {len(zones)} zones\n')
for z in sorted(zones,key=lambda x:x['name']):
    status = z.get('status','?')
    icon = '●' if status=='active' else '○'
    plan = z.get('plan',{}).get('name','?')[:10]
    ns = ', '.join(z.get('name_servers',[])[:2])
    print(f'  {icon} {z[\"name\"]:<35} {plan:<12} {z[\"id\"][:8]}...')
" 2>/dev/null
  echo ""
}

cmd_records() {
  local domain="$1"
  if [[ -z "$domain" ]]; then echo -e "${RED}x${NC} Usage: br domains records <domain>"; exit 1; fi
  echo -e "\n${CYAN}${BOLD}  DNS: $domain${NC}\n"
  local zone_id; zone_id=$(get_zone_id "$domain")
  [[ -z "$zone_id" ]] && { echo -e "${RED}x${NC} Zone not found: $domain"; exit 1; }
  cf_api "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records?per_page=100" | \
    /usr/bin/python3 -c "
import sys,json
d=json.load(sys.stdin)
recs=d.get('result',[])
print(f'  {len(recs)} records  (zone: $(echo $zone_id | head -c 8)...)\n')
for r in recs:
    proxy = '🟠' if r.get('proxied') else '⚪'
    name = r['name']
    rtype = r['type']
    content = r['content'][:60]
    ttl = r.get('ttl',0)
    ttl_s = 'auto' if ttl==1 else str(ttl)
    print(f'  {proxy} {rtype:<6} {name:<45} {content}')
" 2>/dev/null
  echo ""
}

cmd_add() {
  local domain="$1" rtype="$2" name="$3" content="$4"
  if [[ -z "$domain" || -z "$rtype" || -z "$name" || -z "$content" ]]; then
    echo -e "${RED}x${NC} Usage: br domains add <domain> <type> <name> <content> [proxied=true]"
    echo -e "  Example: br domains add blackroad.io A sub 1.2.3.4"
    exit 1
  fi
  local proxied="${5:-true}"
  local zone_id; zone_id=$(get_zone_id "$domain")
  [[ -z "$zone_id" ]] && { echo -e "${RED}x${NC} Zone not found: $domain"; exit 1; }
  local body; body=$(/usr/bin/python3 -c "import json; print(json.dumps({'type':'$rtype','name':'$name','content':'$content','proxied':$proxied,'ttl':1}))")
  local result; result=$(cf_api "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records" -X POST -d "$body")
  echo "$result" | /usr/bin/python3 -c "
import sys,json
d=json.load(sys.stdin)
if d.get('success'):
    r=d['result']
    print(f'  ✓ Created: {r[\"type\"]} {r[\"name\"]} → {r[\"content\"]}')
else:
    errs=d.get('errors',[])
    print('  x Failed: ' + str(errs))
" 2>/dev/null
}

cmd_delete() {
  local domain="$1" record_id="$2"
  if [[ -z "$domain" || -z "$record_id" ]]; then
    echo -e "${RED}x${NC} Usage: br domains delete <domain> <record_id>"
    exit 1
  fi
  local zone_id; zone_id=$(get_zone_id "$domain")
  [[ -z "$zone_id" ]] && { echo -e "${RED}x${NC} Zone not found: $domain"; exit 1; }
  local result; result=$(cf_api "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records/$record_id" -X DELETE)
  echo "$result" | /usr/bin/python3 -c "
import sys,json
d=json.load(sys.stdin)
if d.get('success'):
    print('  ✓ Deleted')
else:
    print('  x Failed: ' + str(d.get('errors',[])))
" 2>/dev/null
}

cmd_search() {
  local domain="$1" query="$2"
  if [[ -z "$domain" || -z "$query" ]]; then
    echo -e "${RED}x${NC} Usage: br domains search <domain> <query>"
    exit 1
  fi
  local zone_id; zone_id=$(get_zone_id "$domain")
  [[ -z "$zone_id" ]] && { echo -e "${RED}x${NC} Zone not found"; exit 1; }
  echo -e "\n${CYAN}  Search: ${BOLD}$query${NC}${CYAN} in $domain${NC}\n"
  cf_api "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records?per_page=100&search=$query" | \
    /usr/bin/python3 -c "
import sys,json
d=json.load(sys.stdin)
recs=d.get('result',[])
for r in recs:
    proxy='🟠' if r.get('proxied') else '⚪'
    print(f'  {proxy} {r[\"type\"]:<6} {r[\"name\"]:<45} {r[\"content\"]}  [{r[\"id\"][:8]}]')
print(f'\n  {len(recs)} matches')
" 2>/dev/null
  echo ""
}

cmd_purge() {
  local domain="$1"
  if [[ -z "$domain" ]]; then echo -e "${RED}x${NC} Usage: br domains purge <domain>"; exit 1; fi
  local zone_id; zone_id=$(get_zone_id "$domain")
  [[ -z "$zone_id" ]] && { echo -e "${RED}x${NC} Zone not found: $domain"; exit 1; }
  echo -e "${YELLOW}  Purging cache for $domain...${NC}"
  local result; result=$(cf_api "https://api.cloudflare.com/client/v4/zones/$zone_id/purge_cache" -X POST -d '{"purge_everything":true}')
  echo "$result" | /usr/bin/python3 -c "
import sys,json
d=json.load(sys.stdin)
if d.get('success'):
    print('  ✓ Cache purged')
else:
    print('  x Failed: ' + str(d.get('errors',[])))
" 2>/dev/null
}

show_help() {
  echo -e "\n${BOLD}  BR DOMAINS${NC}  Cloudflare DNS Manager\n"
  echo -e "  ${CYAN}br domains zones${NC}                        List all zones"
  echo -e "  ${CYAN}br domains records <domain>${NC}             Show DNS records"
  echo -e "  ${CYAN}br domains search <domain> <query>${NC}      Search records"
  echo -e "  ${CYAN}br domains add <domain> <type> <name> <content>${NC}  Add record"
  echo -e "  ${CYAN}br domains delete <domain> <record-id>${NC}  Delete record"
  echo -e "  ${CYAN}br domains purge <domain>${NC}               Purge CF cache"
  echo -e ""
  echo -e "  ${GRAY}Examples:${NC}"
  echo -e "  ${GRAY}  br domains records blackroad.io${NC}"
  echo -e "  ${GRAY}  br domains search blackroad.io api${NC}"
  echo -e "  ${GRAY}  br domains add blackroad.io A myapp 159.65.43.12${NC}"
  echo -e "  ${GRAY}  br domains purge blackroad.io${NC}"
  echo ""
}

case "$1" in
  zones|list|ls)       cmd_zones ;;
  records|show)        cmd_records "$2" ;;
  search|find)         cmd_search "$2" "$3" ;;
  add|create)          cmd_add "$2" "$3" "$4" "$5" "$6" ;;
  delete|del|rm)       cmd_delete "$2" "$3" ;;
  purge|flush)         cmd_purge "$2" ;;
  *)                   show_help ;;
esac
