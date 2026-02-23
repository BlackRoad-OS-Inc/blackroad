#!/bin/zsh
# BR ENV-CHECK - Validate environment variables, .env files, and secrets

GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'
RED='\033[0;31m'; PURPLE='\033[0;35m'; NC='\033[0m'; BOLD='\033[1m'

DB_FILE="$HOME/.blackroad/env-check.db"

init_db() {
  mkdir -p "$(dirname $DB_FILE)"
  sqlite3 "$DB_FILE" <<'SQL'
CREATE TABLE IF NOT EXISTS scans (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  path TEXT, findings INTEGER, secrets_found INTEGER,
  ts TEXT DEFAULT (datetime('now'))
);
CREATE TABLE IF NOT EXISTS required_vars (
  name TEXT PRIMARY KEY, description TEXT, required INTEGER DEFAULT 1
);
SQL
}
init_db

# Known secret patterns
_SECRET_PATTERNS=(
  "password" "passwd" "secret" "api_key" "apikey" "token"
  "auth" "credential" "private_key" "access_key" "client_secret"
  "db_pass" "database_pass" "smtp_pass" "jwt_secret" "signing_key"
)

cmd_scan() {
  local target="${1:-.}"
  echo ""
  echo -e "${BOLD}${CYAN}🔍 Scanning .env files in: ${target}${NC}"
  echo ""

  local total_files=0 total_vars=0 exposed=0
  local found_files=()

  # find .env files
  while IFS= read -r f; do
    [[ -f "$f" ]] && found_files+=("$f")
  done < <(find "$target" -maxdepth 3 -name "*.env" -o -name ".env" -o -name ".env.*" -o -name "*.env.local" 2>/dev/null | grep -v node_modules | grep -v .git)

  if [[ ${#found_files[@]} -eq 0 ]]; then
    echo -e "  ${YELLOW}No .env files found${NC}"
    return
  fi

  for f in "${found_files[@]}"; do
    total_files=$((total_files+1))
    local var_count secret_count
    var_count=$(grep -c '=' "$f" 2>/dev/null || echo 0)
    secret_count=0

    echo -e "  ${CYAN}▸ $f${NC}  (${var_count} vars)"

    # check each line
    while IFS='=' read -r key val; do
      [[ "$key" =~ ^#  ]] && continue
      [[ -z "$key" ]] && continue
      total_vars=$((total_vars+1))

      # check if value is populated
      local key_lower="${key:l}"
      local is_secret=0
      for pat in "${_SECRET_PATTERNS[@]}"; do
        [[ "$key_lower" == *"$pat"* ]] && is_secret=1 && break
      done

      if [[ "$is_secret" -eq 1 ]]; then
        if [[ -z "$val" || "$val" == '""' || "$val" == "''" || "$val" == "your_*" ]]; then
          echo -e "    ${YELLOW}⚠ ${key}${NC} = (empty/placeholder)"
        else
          # mask value
          local masked="${val:0:3}***${val: -3}"
          echo -e "    ${RED}⚠ ${key}${NC} = ${masked}  ${RED}[secret exposed in file]${NC}"
          exposed=$((exposed+1))
          secret_count=$((secret_count+1))
        fi
      else
        [[ -z "$val" ]] && echo -e "    ${YELLOW}  ${key}${NC} = (empty)"
      fi
    done < "$f"

    sqlite3 "$DB_FILE" "INSERT INTO scans(path,findings,secrets_found) VALUES('$f','$var_count','$secret_count');"
    echo ""
  done

  echo -e "  ${CYAN}Summary:${NC} ${total_files} files  ${total_vars} vars  ${exposed} exposed secrets"
  [[ "$exposed" -gt 0 ]] && echo -e "  ${RED}⚠ Move secrets to a vault or use env injection!${NC}"
  echo ""
}

cmd_check() {
  # check that required env vars are set in current shell
  echo ""
  echo -e "${BOLD}${CYAN}Checking required env vars:${NC}"
  echo ""

  # blackroad standard vars
  local vars=(
    "BLACKROAD_GATEWAY_URL:Gateway URL (default: http://127.0.0.1:8787)"
    "GITHUB_TOKEN:GitHub API token"
    "OLLAMA_URL:Ollama endpoint"
    "CLOUDFLARE_API_TOKEN:Cloudflare API"
    "RAILWAY_TOKEN:Railway deployment"
    "VERCEL_TOKEN:Vercel deployment"
  )

  local set_count=0 missing_count=0
  for entry in "${vars[@]}"; do
    local name="${entry%%:*}"
    local desc="${entry##*:}"
    local val="${(P)name}"
    if [[ -n "$val" ]]; then
      echo -e "  ${GREEN}✓${NC} ${name}  ${CYAN}(${desc})${NC}"
      set_count=$((set_count+1))
    else
      echo -e "  ${YELLOW}✗${NC} ${name}  ${CYAN}(${desc})${NC}"
      missing_count=$((missing_count+1))
    fi
  done

  echo ""
  echo -e "  ${set_count} set / $((set_count+missing_count)) total"
  echo ""
}

cmd_diff() {
  # compare .env.example with .env
  local example="${1:-.env.example}"
  local actual="${2:-.env}"

  [[ -f "$example" ]] || { echo -e "${RED}Not found: $example${NC}"; return 1; }
  [[ -f "$actual" ]] || { echo -e "${YELLOW}Not found: $actual (comparing against shell env)${NC}"; }

  echo ""
  echo -e "${BOLD}${CYAN}Comparing ${example} vs ${actual}:${NC}"
  echo ""

  local missing=0
  while IFS='=' read -r key _; do
    [[ "$key" =~ ^#  ]] && continue
    [[ -z "$key" ]] && continue

    local in_actual=0
    [[ -f "$actual" ]] && grep -q "^${key}=" "$actual" 2>/dev/null && in_actual=1
    [[ -z "${in_actual}" ]] && [[ -n "${(P)key}" ]] && in_actual=1

    if [[ "$in_actual" -eq 1 ]]; then
      echo -e "  ${GREEN}✓${NC} ${key}"
    else
      echo -e "  ${RED}✗${NC} ${key}  ${YELLOW}(missing)${NC}"
      missing=$((missing+1))
    fi
  done < "$example"

  echo ""
  [[ "$missing" -gt 0 ]] && echo -e "  ${RED}${missing} variable(s) missing from ${actual}${NC}" || echo -e "  ${GREEN}All variables present${NC}"
  echo ""
}

cmd_list_files() {
  echo ""
  echo -e "${BOLD}${CYAN}.env files in project:${NC}"
  find . -maxdepth 4 -name "*.env" -o -name ".env" -o -name ".env.*" 2>/dev/null | \
    grep -v node_modules | grep -v .git | \
    while read f; do
      local lines=$(wc -l < "$f" | tr -d ' ')
      echo -e "  ${CYAN}${f}${NC}  (${lines} lines)"
    done
  echo ""
}

cmd_log() {
  echo ""
  echo -e "${BOLD}${CYAN}Scan history:${NC}"
  sqlite3 "$DB_FILE" "SELECT ts, path, findings, secrets_found FROM scans ORDER BY id DESC LIMIT 15;" 2>/dev/null | \
    while IFS='|' read ts path findings secrets; do
      local color="${GREEN}"
      [[ "$secrets" -gt 0 ]] && color="${RED}"
      echo -e "  ${CYAN}${ts}${NC}  ${color}${secrets} secrets${NC}  ${path}  (${findings} vars)"
    done
  echo ""
}

cmd_help() {
  echo ""
  echo -e "${BOLD}br env-check${NC} — validate env files and secrets"
  echo ""
  echo "  ${CYAN}br env-check scan [dir]${NC}     Scan for .env files + exposed secrets"
  echo "  ${CYAN}br env-check check${NC}          Check required BlackRoad env vars"
  echo "  ${CYAN}br env-check diff [ex] [act]${NC} Compare .env.example vs .env"
  echo "  ${CYAN}br env-check files${NC}          List all .env files in project"
  echo "  ${CYAN}br env-check log${NC}            Show scan history"
  echo ""
}

case "${1:-help}" in
  scan)    shift; cmd_scan "${1:-.}" ;;
  check)   cmd_check ;;
  diff)    shift; cmd_diff "$@" ;;
  files)   cmd_list_files ;;
  log)     cmd_log ;;
  help|-h) cmd_help ;;
  *) echo "Unknown: $1. Try: scan check diff files log"; exit 1 ;;
esac
