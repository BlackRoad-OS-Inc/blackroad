#!/bin/zsh
# BR Scan — Security and code scanning

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'; BOLD='\033[1m'

show_help() {
  echo "${CYAN}${BOLD}BR Scan — Security + Code Analysis${NC}"
  echo ""
  echo "${BOLD}Commands:${NC}"
  echo "  ${GREEN}secrets${NC}  [path]    Scan for hardcoded secrets/tokens"
  echo "  ${GREEN}deps${NC}     [path]    Check dependency vulnerabilities"
  echo "  ${GREEN}code${NC}     [path]    Static code analysis (patterns)"
  echo "  ${GREEN}env${NC}      [file]    Scan .env file for weak values"
  echo "  ${GREEN}all${NC}      [path]    Run all scans"
}

cmd_secrets() {
  local dir="${1:-.}"
  echo "${CYAN}${BOLD}🔍 Scanning for secrets: $dir${NC}"
  echo ""
  local issues=0

  local found=$(grep -rn --include="*.py" --include="*.js" --include="*.ts" --include="*.sh" --include="*.env" \
    -E "(AKIA[0-9A-Z]{16}|sk-[a-zA-Z0-9]{48}|sk-ant-[a-zA-Z0-9]{90,}|ghp_[a-zA-Z0-9]{36}|ghs_[a-zA-Z0-9]{36})" \
    "$dir" 2>/dev/null | grep -v ".git" | grep -v "test_" | head -5)

  if [ -n "$found" ]; then
    echo "${RED}⚠  Potential secrets found:${NC}"
    echo "$found" | while read line; do echo "   ${YELLOW}${line}${NC}"; done
    issues=1
  fi

  local pwdfound=$(grep -rn --include="*.py" --include="*.env" \
    -E "(password|secret|api_key)\s*=\s*['\"][^'\"]{8,}['\"]" \
    "$dir" 2>/dev/null | grep -v ".git" | grep -v "test" | grep -v "placeholder\|changeme\|example" | head -3)

  if [ -n "$pwdfound" ]; then
    echo "${YELLOW}△  Possible hardcoded credentials:${NC}"
    echo "$pwdfound" | while read line; do echo "   $line"; done
    ((issues++))
  fi

  if [ "$issues" -eq 0 ]; then
    echo "${GREEN}✓ No secrets found${NC}"
  else
    echo ""
    echo "${RED}Found potential issue(s) — review above${NC}"
  fi
}

cmd_deps() {
  local dir="${1:-.}"
  echo "${CYAN}${BOLD}📦 Dependency scan: $dir${NC}"
  echo ""

  if [ -f "$dir/requirements.txt" ]; then
    echo "${YELLOW}Python (requirements.txt):${NC}"
    local vulns=0
    while read pkg; do
      pkg=$(echo "$pkg" | tr '[:upper:]' '[:lower:]' | sed 's/[>=<! ].*//' | tr -d ' ')
      case "$pkg" in
        pillow) echo "  ${YELLOW}⚠${NC}  pillow — ensure ≥10.0.0"; ((vulns++)) ;;
        requests) echo "  ${YELLOW}⚠${NC}  requests — ensure ≥2.28.0"; ((vulns++)) ;;
        pyyaml) echo "  ${YELLOW}⚠${NC}  pyyaml — use yaml.safe_load only"; ((vulns++)) ;;
        django) echo "  ${YELLOW}⚠${NC}  django — ensure using LTS (≥4.2)"; ((vulns++)) ;;
        cryptography) echo "  ${GREEN}✓${NC}  cryptography" ;;
        pytest|flake8|black) echo "  ${GREEN}✓${NC}  $pkg (dev)" ;;
        "") ;;
        *) echo "  ${GREEN}✓${NC}  $pkg" ;;
      esac
    done < "$dir/requirements.txt" 2>/dev/null
    [ "$vulns" -gt 0 ] && echo "  ${YELLOW}$vulns package(s) need version review${NC}" || echo "  ${GREEN}✓ Dependencies look good${NC}"
  fi

  if [ -f "$dir/package.json" ]; then
    echo "${YELLOW}Node.js (package.json):${NC}"
    echo "  Run: ${CYAN}npm audit --prefix $dir${NC} for full report"
  fi

  if [ -f "$dir/go.mod" ]; then
    echo "${YELLOW}Go (go.mod):${NC}"
    echo "  Run: ${CYAN}cd $dir && go list -m -u all${NC} for updates"
  fi
}

cmd_code() {
  local dir="${1:-.}"
  echo "${CYAN}${BOLD}🔎 Code analysis: $dir${NC}"
  echo ""
  local issues=0

  local patterns=(
    "eval\(.*input\|eval\(.*request:eval() with user input — code injection"
    "subprocess\.call.*shell=True\|os\.system:shell=True — shell injection risk"
    "pickle\.loads\|pickle\.load\|cPickle:pickle.load — unsafe deserialization"
    "hashlib\.md5()\|hashlib\.sha1():MD5/SHA1 — use SHA256+"
    "random\.random()\|random\.randint:random — use secrets module for crypto"
  )

  for pattern_pair in "${patterns[@]}"; do
    local pattern="${pattern_pair%%:*}"
    local label="${pattern_pair##*:}"
    local matches=$(grep -rn --include="*.py" -E "$pattern" "$dir" 2>/dev/null | grep -v ".git" | grep -v "test" | head -2)
    if [ -n "$matches" ]; then
      echo "${YELLOW}⚠  $label${NC}"
      echo "$matches" | while read l; do echo "   $l"; done
      ((issues++))
    fi
  done

  [ "$issues" -eq 0 ] && echo "${GREEN}✓ No code issues detected${NC}" || echo ""
  [ "$issues" -gt 0 ] && echo "${RED}$issues issue(s) found${NC}"
}

cmd_env() {
  local file="${1:-.env}"
  [ ! -f "$file" ] && echo "${RED}File not found: $file${NC}" && return 1
  echo "${CYAN}${BOLD}🔑 Env scan: $file${NC}"
  echo ""
  local issues=0

  while IFS='=' read key value; do
    [[ "$key" =~ ^[[:space:]]*# ]] && continue
    [[ -z "$key" ]] && continue
    value="${value//\"/}"
    local vl="${value:l}"
    case "$vl" in
      "changeme"|"password"|"secret"|"your_key_here"|"xxx"|"todo"|"placeholder"|"replace_me")
        echo "${RED}⚠  $key — placeholder value '$value'${NC}"; ((issues++)) ;;
      ""|"null"|"none"|"false")
        echo "${YELLOW}△  $key — empty/unset${NC}" ;;
      *)
        echo "${GREEN}✓  $key${NC}" ;;
    esac
  done < "$file" 2>/dev/null

  echo ""
  [ "$issues" -eq 0 ] && echo "${GREEN}✓ All values configured${NC}" || echo "${YELLOW}$issues placeholder(s) need real values${NC}"
}

case "${1:-help}" in
  secrets|secret) shift; cmd_secrets "$@" ;;
  deps|dep)       shift; cmd_deps "$@" ;;
  code)           shift; cmd_code "$@" ;;
  env)            shift; cmd_env "$@" ;;
  all)
    shift; DIR="${1:-.}"
    cmd_secrets "$DIR"; echo ""
    cmd_deps "$DIR"; echo ""
    cmd_code "$DIR"
    ;;
  *) show_help ;;
esac
