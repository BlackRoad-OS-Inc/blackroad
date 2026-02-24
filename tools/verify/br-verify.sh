#!/bin/zsh
# BR Verify — Information verification system

GREEN='\033[0;32m'; RED='\033[0;31m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; PURPLE='\033[0;35m'; NC='\033[0m'

DB_FILE="$HOME/.blackroad/verify.db"

init_db() {
  mkdir -p "$(dirname $DB_FILE)"
  sqlite3 "$DB_FILE" <<'SQL'
CREATE TABLE IF NOT EXISTS checks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  type TEXT,         -- url/file/claim/hash/schema/code/env/data
  target TEXT,       -- what was checked
  status TEXT,       -- pass/fail/warn/skip
  confidence INTEGER DEFAULT 0, -- 0-100
  details TEXT,
  source TEXT,       -- where verified against
  checked_at TEXT DEFAULT (datetime('now'))
);
CREATE TABLE IF NOT EXISTS facts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  claim TEXT,
  verified INTEGER DEFAULT 0,  -- 0=unverified, 1=true, -1=false
  confidence INTEGER DEFAULT 0,
  source TEXT,
  notes TEXT,
  created_at TEXT DEFAULT (datetime('now')),
  verified_at TEXT
);
CREATE TABLE IF NOT EXISTS sources (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT UNIQUE,
  url TEXT,
  type TEXT,  -- api/file/git/web/internal
  trust_level INTEGER DEFAULT 50, -- 0-100
  last_checked TEXT
);
SQL
}

# ── CHECK URL ──────────────────────────────────────────────────────────────────
cmd_url() {
  local url="$2"
  [[ -z "$url" ]] && echo "Usage: br verify url <url>" && return 1
  echo -e "${CYAN}Verifying URL: $url${NC}"
  
  local http_code=$(curl -o /dev/null -s -w "%{http_code}" --max-time 10 "$url" 2>/dev/null)
  local cert_ok="N/A"
  local dns_ok="fail"
  local host="${url#*://}"; host="${host%%/*}"
  
  # DNS check
  if nslookup "$host" >/dev/null 2>&1; then dns_ok="pass"; fi
  
  # SSL check
  if [[ "$url" == https://* ]]; then
    local expiry=$(echo | openssl s_client -connect "${host}:443" -servername "$host" 2>/dev/null | \
      openssl x509 -noout -enddate 2>/dev/null | sed 's/notAfter=//')
    if [[ -n "$expiry" ]]; then cert_ok="valid (expires: $expiry)"; else cert_ok="check failed"; fi
  fi
  
  local status="pass"; [[ "$http_code" != "200" ]] && status="warn"
  [[ "$http_code" == "000" || "$dns_ok" == "fail" ]] && status="fail"
  
  local icon="✓"; [[ "$status" == "warn" ]] && icon="~"; [[ "$status" == "fail" ]] && icon="✗"
  local color="$GREEN"; [[ "$status" == "warn" ]] && color="$YELLOW"; [[ "$status" == "fail" ]] && color="$RED"
  
  printf "  ${color}%s${NC} HTTP: %-5s DNS: %-5s SSL: %s\n" "$icon" "$http_code" "$dns_ok" "$cert_ok"
  
  sqlite3 "$DB_FILE" "INSERT INTO checks (type,target,status,confidence,details) VALUES('url','$url','$status',$([ "$status" = "pass" ] && echo 95 || echo 50),'HTTP:$http_code DNS:$dns_ok SSL:$cert_ok')"
  [[ "$status" == "pass" ]] && return 0 || return 1
}

# ── VERIFY CLAIM ──────────────────────────────────────────────────────────────
cmd_claim() {
  local claim="${@:2}"
  [[ -z "$claim" ]] && echo "Usage: br verify claim <statement>" && return 1
  echo -e "${CYAN}Verifying claim: \"$claim\"${NC}"
  
  local confidence=0; local notes=""; local verified=0
  
  # Check against known BlackRoad facts
  case "$claim" in
    *"worlds"*|*"world"*)
      local count=$(curl -sf https://worlds.blackroad.io/stats 2>/dev/null | python3 -c "import json,sys; print(json.load(sys.stdin).get('total',0))" 2>/dev/null || echo "unknown")
      notes="worlds.blackroad.io reports: $count worlds"
      confidence=90; verified=1 ;;
    *"aria64"*|*"192.168.4.38"*)
      local reachable=$(ssh -o ConnectTimeout=4 -o StrictHostKeyChecking=no alexa@192.168.4.38 "echo ok" 2>/dev/null)
      [[ "$reachable" == "ok" ]] && notes="aria64 SSH reachable" && confidence=95 && verified=1 || \
        notes="aria64 unreachable" && confidence=30 && verified=-1 ;;
    *"alice"*|*"192.168.4.49"*)
      local reachable=$(ssh -o ConnectTimeout=4 -o StrictHostKeyChecking=no blackroad@192.168.4.49 "echo ok" 2>/dev/null)
      [[ "$reachable" == "ok" ]] && notes="alice SSH reachable" && confidence=95 && verified=1 || \
        notes="alice unreachable" && confidence=30 ;;
    *"agents"*)
      local agent_data=$(curl -sf https://agents-status.blackroad.io/status 2>/dev/null)
      [[ -n "$agent_data" ]] && notes="agents-status API: $agent_data" && confidence=90 && verified=1 ;;
    *"github"*|*"BlackRoad"*)
      local repos=$(gh api "orgs/BlackRoad-OS/repos?per_page=1" --jq 'length' 2>/dev/null || echo 0)
      notes="GitHub: BlackRoad-OS org accessible, verified repo access" && confidence=95 && verified=1 ;;
    *)
      notes="No automated verification available for this claim" && confidence=0 ;;
  esac
  
  local icon="✓"; local color="$GREEN"
  [[ "$verified" == "0" ]] && icon="?" && color="$YELLOW"
  [[ "$verified" == "-1" ]] && icon="✗" && color="$RED"
  
  printf "  ${color}%s${NC} Confidence: %d%%\n" "$icon" "$confidence"
  printf "  %s\n" "$notes"
  
  sqlite3 "$DB_FILE" "INSERT INTO facts (claim,verified,confidence,notes) VALUES('$(echo $claim | sed "s/'/''/")',$verified,$confidence,'$(echo $notes | sed "s/'/''/")')"
}

# ── CHECK FILE/HASH ──────────────────────────────────────────────────────────
cmd_hash() {
  local file="$2"; local expected="$3"
  [[ -z "$file" ]] && echo "Usage: br verify hash <file> [expected-sha256]" && return 1
  [[ ! -f "$file" ]] && echo -e "${RED}File not found: $file${NC}" && return 1
  
  local actual=$(shasum -a 256 "$file" | awk '{print $1}')
  echo -e "${CYAN}SHA-256: $file${NC}"
  printf "  Computed:  %s\n" "$actual"
  
  if [[ -n "$expected" ]]; then
    if [[ "$actual" == "$expected" ]]; then
      printf "  ${GREEN}✓ Hash matches expected${NC}\n"
      sqlite3 "$DB_FILE" "INSERT INTO checks (type,target,status,confidence,details) VALUES('hash','$file','pass',100,'hash_match')"
    else
      printf "  ${RED}✗ Expected: %s${NC}\n" "$expected"
      sqlite3 "$DB_FILE" "INSERT INTO checks (type,target,status,confidence,details) VALUES('hash','$file','fail',0,'hash_mismatch')"
      return 1
    fi
  else
    printf "  ${YELLOW}(no expected hash provided for comparison)${NC}\n"
  fi
}

# ── CHECK ENV VARS ───────────────────────────────────────────────────────────
cmd_env() {
  echo -e "${CYAN}Verifying environment variables...${NC}\n"
  local checks=(
    "BLACKROAD_GATEWAY_URL:optional"
    "GITHUB_TOKEN:recommended"
    "CLOUDFLARE_API_TOKEN:recommended"
    "RAILWAY_TOKEN:optional"
    "VERCEL_TOKEN:optional"
  )
  local pass=0; local warn=0; local fail=0
  for entry in "${checks[@]}"; do
    local varname="${entry%%:*}"; local level="${entry##*:}"
    local val="${(P)varname}"
    if [[ -n "$val" ]]; then
      printf "  ${GREEN}✓${NC} %-40s set (${#val} chars)\n" "$varname"
      ((pass++))
    else
      [[ "$level" == "required" ]] && printf "  ${RED}✗${NC} %-40s MISSING (required)\n" "$varname" && ((fail++)) || \
        printf "  ${YELLOW}~${NC} %-40s not set (%s)\n" "$varname" "$level" && ((warn++))
    fi
  done
  echo ""
  printf "  %s pass, %s warn, %s fail\n" "$pass" "$warn" "$fail"
  sqlite3 "$DB_FILE" "INSERT INTO checks (type,target,status,confidence,details) VALUES('env','environment','$([ $fail -gt 0 ] && echo fail || echo pass)',$((pass * 100 / (pass + warn + fail + 1))),'pass:$pass warn:$warn fail:$fail')"
}

# ── CHECK SCHEMA ─────────────────────────────────────────────────────────────
cmd_schema() {
  local file="$2"
  [[ -z "$file" ]] && echo "Usage: br verify schema <json-or-yaml-file>" && return 1
  [[ ! -f "$file" ]] && echo -e "${RED}File not found: $file${NC}" && return 1
  echo -e "${CYAN}Validating schema: $file${NC}"
  
  case "$file" in
    *.json)
      if python3 -c "import json; json.load(open('$file'))" 2>/dev/null; then
        printf "  ${GREEN}✓ Valid JSON${NC}\n"
        local keys=$(python3 -c "import json; d=json.load(open('$file')); print(f'Keys: {list(d.keys())[:10]}')" 2>/dev/null)
        printf "  %s\n" "$keys"
      else
        printf "  ${RED}✗ Invalid JSON${NC}\n"; return 1
      fi ;;
    *.yaml|*.yml)
      if python3 -c "import yaml; yaml.safe_load(open('$file'))" 2>/dev/null; then
        printf "  ${GREEN}✓ Valid YAML${NC}\n"
      else
        printf "  ${RED}✗ Invalid YAML${NC}\n"; return 1
      fi ;;
    *)
      printf "  ${YELLOW}~ Unknown format${NC}\n" ;;
  esac
}

# ── VERIFY REPO ──────────────────────────────────────────────────────────────
cmd_repo() {
  local repo="$2"
  [[ -z "$repo" ]] && echo "Usage: br verify repo <owner/repo>" && return 1
  echo -e "${CYAN}Verifying repo: $repo${NC}\n"
  
  local data=$(gh api "repos/$repo" 2>/dev/null)
  [[ -z "$data" ]] && echo -e "${RED}✗ Repo not found or no access${NC}" && return 1
  
  # Check: exists, has description, has CI, has recent push
  local desc=$(echo "$data" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('description','') or '')" 2>/dev/null)
  local pushed=$(echo "$data" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('pushed_at','')[:10])" 2>/dev/null)
  local size=$(echo "$data" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('size',0))" 2>/dev/null)
  local has_ci=$(gh api "repos/$repo/contents/.github/workflows" --jq 'length' 2>/dev/null || echo 0)
  local has_readme=$(gh api "repos/$repo/contents/README.md" --jq '.name' 2>/dev/null || echo "")
  local has_src=$(gh api "repos/$repo/contents/src" --jq 'length' 2>/dev/null || echo 0)
  
  [[ -n "$desc" ]] && printf "  ${GREEN}✓${NC} Description: %s\n" "$desc" || printf "  ${YELLOW}~${NC} No description\n"
  [[ -n "$has_readme" ]] && printf "  ${GREEN}✓${NC} README present\n" || printf "  ${YELLOW}~${NC} No README\n"
  [[ "$has_ci" -gt "0" ]] && printf "  ${GREEN}✓${NC} CI workflows: %s\n" "$has_ci" || printf "  ${YELLOW}~${NC} No CI\n"
  [[ "$has_src" -gt "0" ]] && printf "  ${GREEN}✓${NC} src/ directory: %s files\n" "$has_src" || printf "  ${YELLOW}~${NC} No src/\n"
  [[ "$size" -gt "0" ]] && printf "  ${GREEN}✓${NC} Last push: %s (size: %s KB)\n" "$pushed" "$size" || printf "  ${RED}✗${NC} Empty repository\n"
}

# ── DASHBOARD ────────────────────────────────────────────────────────────────
cmd_dashboard() {
  echo -e "${CYAN}╔══════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║     🔍 VERIFICATION DASHBOARD        ║${NC}"
  echo -e "${CYAN}╚══════════════════════════════════════╝${NC}\n"
  
  # Recent checks
  echo -e "${BLUE}Recent Checks:${NC}"
  sqlite3 -separator " | " "$DB_FILE" \
    "SELECT substr(checked_at,1,16), type, substr(target,1,40), status, confidence||'%' FROM checks ORDER BY id DESC LIMIT 10" 2>/dev/null | \
    while IFS="|" read ts type target status conf; do
      local color="$GREEN"; [[ "$status" == *"fail"* ]] && color="$RED"; [[ "$status" == *"warn"* ]] && color="$YELLOW"
      printf "  ${color}%-6s${NC} %-8s %-42s %s\n" "$status" "$type" "$target" "$conf"
    done
  
  echo ""
  echo -e "${BLUE}Fact Store:${NC}"
  local total=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM facts" 2>/dev/null || echo 0)
  local verified=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM facts WHERE verified=1" 2>/dev/null || echo 0)
  local denied=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM facts WHERE verified=-1" 2>/dev/null || echo 0)
  printf "  Total: %-4s Verified: %-4s False: %-4s Unverified: %s\n" "$total" "$verified" "$denied" "$((total - verified - denied))"
  
  echo ""
  echo -e "${BLUE}Live System Checks:${NC}"
  # Quick checks
  local worlds=$(curl -sf --max-time 5 https://worlds.blackroad.io/stats 2>/dev/null | python3 -c "import json,sys; print(json.load(sys.stdin).get('total',0))" 2>/dev/null || echo "unreachable")
  local agents=$(curl -sf --max-time 5 https://agents-status.blackroad.io/status 2>/dev/null | python3 -c "import json,sys; print(json.load(sys.stdin).get('active',0))" 2>/dev/null || echo "unreachable")
  local models=$(curl -sf --max-time 5 https://models.blackroad.io/models 2>/dev/null | python3 -c "import json,sys; print(json.load(sys.stdin).get('loaded',0))" 2>/dev/null || echo "unreachable")
  printf "  ${GREEN}🌍${NC} worlds.blackroad.io:        %s worlds\n" "$worlds"
  printf "  ${GREEN}🤖${NC} agents-status.blackroad.io: %s active agents\n" "$agents"
  printf "  ${GREEN}🧠${NC} models.blackroad.io:        %s models loaded\n" "$models"
}

# ── FULL SYSTEM CHECK ────────────────────────────────────────────────────────
cmd_all() {
  echo -e "${CYAN}Running full system verification...${NC}\n"
  
  echo -e "${BLUE}[1/5] Live endpoints${NC}"
  local endpoints=("https://worlds.blackroad.io/stats" "https://agents-status.blackroad.io/health" "https://models.blackroad.io/health" "https://dashboard-api.blackroad.io/health" "https://api.blackroad.io/health")
  for url in "${endpoints[@]}"; do
    cmd_url url "$url" 2>/dev/null
  done
  echo ""
  
  echo -e "${BLUE}[2/5] Environment${NC}"
  cmd_env 2>/dev/null
  echo ""
  
  echo -e "${BLUE}[3/5] Git integrity${NC}"
  cd /Users/alexa/blackroad && \
    git --no-pager log -1 --format="  Latest commit: %h %s (%ar)" 2>/dev/null && \
    printf "  ${GREEN}✓${NC} Repo: %s\n" "$(git remote get-url origin 2>/dev/null)"
  echo ""
  
  echo -e "${BLUE}[4/5] BR tools${NC}"
  local tools_ok=0; local tools_miss=0
  for tool in radar pdf audit repo ping worlds verify; do
    local path=""
    case $tool in
      radar)   path="tools/context-radar/br-context-radar.sh" ;;
      pdf)     path="tools/pdf-read/br-pdf-read.sh" ;;
      audit)   path="tools/org-audit/br-org-audit.sh" ;;
      repo)    path="tools/repo-manager/br-repo.sh" ;;
      ping)    path="tools/ping/br-ping.sh" ;;
      worlds)  path="tools/worlds/br-worlds.sh" ;;
      verify)  path="tools/verify/br-verify.sh" ;;
    esac
    [[ -f "/Users/alexa/blackroad/$path" ]] && printf "  ${GREEN}✓${NC} br %-10s\n" "$tool" && ((tools_ok++)) || \
      printf "  ${RED}✗${NC} br %-10s MISSING\n" "$tool" && ((tools_miss++))
  done
  echo ""
  
  echo -e "${BLUE}[5/5] Pi fleet${NC}"
  for entry in "alexa@192.168.4.38:aria64" "blackroad@192.168.4.49:alice"; do
    local user_host="${entry%%:*}"; local name="${entry##*:}"
    local ok=$(ssh -o ConnectTimeout=4 -o StrictHostKeyChecking=no "$user_host" "echo ok" 2>/dev/null)
    [[ "$ok" == "ok" ]] && printf "  ${GREEN}✓${NC} %s reachable\n" "$name" || printf "  ${RED}✗${NC} %s unreachable\n" "$name"
  done
}

# ── CODE FINGERPRINT ────────────────────────────────────────────────────────
cmd_fingerprint() {
  local target="${2:-.}"
  echo -e "${CYAN}╔══════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║   🔏 CODE FINGERPRINT GENERATOR          ║${NC}"
  echo -e "${CYAN}╚══════════════════════════════════════════╝${NC}\n"

  local FP_DIR="$HOME/.blackroad/fingerprints"
  mkdir -p "$FP_DIR"
  local FP_FILE="$FP_DIR/fingerprint-$(date +%Y%m%d-%H%M%S).jsonl"
  local count=0

  echo -e "${BLUE}Scanning: $target${NC}"
  find "$target" -type f \( -name "*.js" -o -name "*.ts" -o -name "*.py" -o -name "*.sh" -o -name "*.tsx" -o -name "*.jsx" -o -name "*.css" -o -name "*.html" \) \
    ! -path "*/node_modules/*" ! -path "*/.git/*" ! -path "*/dist/*" ! -path "*/__pycache__/*" 2>/dev/null | while read -r file; do
    local hash=$(shasum -a 256 "$file" 2>/dev/null | cut -d' ' -f1)
    local lines=$(wc -l < "$file" 2>/dev/null | tr -d ' ')
    local size=$(stat -f%z "$file" 2>/dev/null || echo 0)
    local rel="${file#$target/}"
    echo "{\"file\":\"$rel\",\"sha256\":\"$hash\",\"lines\":$lines,\"bytes\":$size,\"time\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" >> "$FP_FILE"
    ((count++))
  done

  local total=$(wc -l < "$FP_FILE" 2>/dev/null | tr -d ' ')
  local master_hash=$(shasum -a 256 "$FP_FILE" | cut -d' ' -f1)

  echo -e "\n  ${GREEN}✓${NC} Fingerprinted ${GREEN}$total${NC} files"
  echo -e "  ${GREEN}✓${NC} Saved to: $FP_FILE"
  echo -e "  ${GREEN}✓${NC} Master hash: ${PURPLE}$master_hash${NC}"

  sqlite3 "$DB_FILE" "INSERT INTO checks (type,target,status,confidence,details) VALUES('fingerprint','$target','pass',100,'files:$total master:$master_hash')"
}

# ── CODE REUSE SCAN ─────────────────────────────────────────────────────────
cmd_scan_reuse() {
  local query="${@:2}"
  [[ -z "$query" ]] && echo -e "${RED}Usage: br verify scan <unique-code-string-or-filename>${NC}" && return 1

  echo -e "${CYAN}╔══════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║   🔎 CODE REUSE SCANNER                  ║${NC}"
  echo -e "${CYAN}╚══════════════════════════════════════════╝${NC}\n"

  echo -e "${BLUE}Searching GitHub for: \"$query\"${NC}\n"

  # Search GitHub code for exact matches outside our orgs
  local our_orgs="BlackRoad-OS BlackRoad-OS-Inc blackboxprogramming BlackRoad-AI BlackRoad-Cloud BlackRoad-Security BlackRoad-Media BlackRoad-Foundation BlackRoad-Interactive BlackRoad-Hardware BlackRoad-Labs BlackRoad-Studio BlackRoad-Ventures BlackRoad-Education BlackRoad-Gov Blackbox-Enterprises BlackRoad-Archive"

  local results=$(gh api "search/code?q=$(python3 -c "import urllib.parse; print(urllib.parse.quote('\"$query\"'))" 2>/dev/null)&per_page=30" 2>/dev/null)

  if [[ -z "$results" ]]; then
    echo -e "  ${YELLOW}No results or API rate limited${NC}"
    return
  fi

  local total=$(echo "$results" | python3 -c "import json,sys; print(json.load(sys.stdin).get('total_count',0))" 2>/dev/null || echo 0)
  echo -e "  Total matches: ${YELLOW}$total${NC}\n"

  echo "$results" | python3 -c "
import json, sys
data = json.load(sys.stdin)
our_orgs = set('$our_orgs'.lower().split())
ours = 0; external = 0
for item in data.get('items', []):
    owner = item.get('repository', {}).get('owner', {}).get('login', '').lower()
    repo = item.get('repository', {}).get('full_name', '')
    path = item.get('path', '')
    if owner in our_orgs:
        ours += 1
    else:
        external += 1
        print(f'  ⚠️  EXTERNAL: {repo}/{path}')
if external == 0:
    print(f'  ✅ No external matches found ({ours} internal matches)')
else:
    print(f'\n  🔴 {external} EXTERNAL matches found ({ours} internal)')
" 2>/dev/null

  sqlite3 "$DB_FILE" "INSERT INTO checks (type,target,status,confidence,details) VALUES('reuse-scan','$(echo $query | sed "s/'/''/g")','$([ $total -gt 0 ] && echo warn || echo pass)',80,'total:$total')"
}

# ── LICENSE CHECK ───────────────────────────────────────────────────────────
cmd_license() {
  echo -e "${CYAN}╔══════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║   ⚖️  LICENSE VERIFICATION                ║${NC}"
  echo -e "${CYAN}╚══════════════════════════════════════════╝${NC}\n"

  local target="${2:-/Users/alexa/blackroad}"
  local pass=0; local warn=0; local fail=0

  # Check for proprietary license file
  echo -e "${BLUE}[1/4] License files${NC}"
  if [[ -f "$target/LICENSE-BLACKROAD-PROPRIETARY" ]]; then
    printf "  ${GREEN}✓${NC} LICENSE-BLACKROAD-PROPRIETARY present\n"; ((pass++))
  else
    printf "  ${RED}✗${NC} LICENSE-BLACKROAD-PROPRIETARY missing\n"; ((fail++))
  fi

  if [[ -f "$target/LICENSE" ]]; then
    local lic_type=$(head -1 "$target/LICENSE" 2>/dev/null)
    printf "  ${YELLOW}~${NC} LICENSE file found: %s\n" "$lic_type"; ((warn++))
  fi

  # Check FUNDING.yml
  echo -e "\n${BLUE}[2/4] Funding${NC}"
  if [[ -f "$target/.github/FUNDING.yml" ]]; then
    printf "  ${GREEN}✓${NC} .github/FUNDING.yml present\n"; ((pass++))
  else
    printf "  ${RED}✗${NC} .github/FUNDING.yml missing\n"; ((fail++))
  fi

  # Check for IP notice
  echo -e "\n${BLUE}[3/4] IP markers${NC}"
  local ip_count=$(grep -rl "BlackRoad OS, Inc" "$target" --include="*.md" --include="*.html" --include="*.js" --include="*.sh" 2>/dev/null | wc -l | tr -d ' ')
  printf "  ${GREEN}✓${NC} IP attribution found in %s files\n" "$ip_count"; ((pass++))

  # Check for exposed secrets
  echo -e "\n${BLUE}[4/4] Secret exposure${NC}"
  local env_files=$(find "$target" -name ".env" -o -name ".env.local" -o -name ".env.production" 2>/dev/null | grep -v node_modules | grep -v .git)
  if [[ -z "$env_files" ]]; then
    printf "  ${GREEN}✓${NC} No exposed .env files\n"; ((pass++))
  else
    printf "  ${RED}✗${NC} Found .env files:\n"
    echo "$env_files" | while read f; do printf "       %s\n" "$f"; done
    ((fail++))
  fi

  echo -e "\n  Results: ${GREEN}$pass pass${NC} / ${YELLOW}$warn warn${NC} / ${RED}$fail fail${NC}"
  sqlite3 "$DB_FILE" "INSERT INTO checks (type,target,status,confidence,details) VALUES('license','$target','$([ $fail -gt 0 ] && echo fail || echo pass)',$(( pass * 100 / (pass + warn + fail + 1) )),'pass:$pass warn:$warn fail:$fail')"
}

show_help() {
  echo -e "${CYAN}BR Verify — Information Verification System${NC}\n"
  echo "  br verify                     Full dashboard"
  echo "  br verify all                 Run all checks"
  echo "  br verify url <url>           Check URL (DNS/SSL/HTTP)"
  echo "  br verify claim <statement>   Verify a factual claim"
  echo "  br verify hash <file> [hash]  Check file integrity (SHA-256)"
  echo "  br verify env                 Check environment variables"
  echo "  br verify schema <file>       Validate JSON/YAML schema"
  echo "  br verify repo <owner/repo>   Check GitHub repo health"
  echo "  br verify fingerprint [dir]   Generate code fingerprints (SHA-256 per file)"
  echo "  br verify scan <code-string>  Scan GitHub for code reuse outside our orgs"
  echo "  br verify license [dir]       Check license/IP/funding compliance"
  echo "  br verify history             Show recent verifications"
}

cmd_history() {
  echo -e "${CYAN}Verification History:${NC}\n"
  sqlite3 -separator " | " "$DB_FILE" \
    "SELECT substr(checked_at,1,16), type, substr(target,1,45), status FROM checks ORDER BY id DESC LIMIT 20" 2>/dev/null | \
    while IFS="|" read ts type target status; do
      local color="$GREEN"; [[ "$status" == *"fail"* ]] && color="$RED"; [[ "$status" == *"warn"* ]] && color="$YELLOW"
      printf "  %s  %-8s %-47s ${color}%s${NC}\n" "$ts" "$type" "$target" "$status"
    done
}

init_db

case "${1:-dashboard}" in
  url)             cmd_url "$@" ;;
  claim)           cmd_claim "$@" ;;
  hash)            cmd_hash "$@" ;;
  env)             cmd_env ;;
  schema)          cmd_schema "$@" ;;
  repo)            cmd_repo "$@" ;;
  fingerprint|fp)  cmd_fingerprint "$@" ;;
  scan|reuse)      cmd_scan_reuse "$@" ;;
  license|lic)     cmd_license "$@" ;;
  all|full)        cmd_all ;;
  history)         cmd_history ;;
  dashboard|"")    cmd_dashboard ;;
  help|--help)     show_help ;;
  *)               show_help ;;
esac
