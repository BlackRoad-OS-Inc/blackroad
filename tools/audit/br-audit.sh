#!/bin/zsh
# BR AUDIT — Security & Health Audit Tool
export PATH="/usr/bin:/bin:/usr/local/bin:/opt/homebrew/bin:$PATH"

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'
GRAY='\033[0;37m'; BOLD='\033[1m'; NC='\033[0m'

REPO_ROOT="/Users/alexa/blackroad"

cmd_secrets() {
  echo -e "\n${CYAN}${BOLD}  SCANNING FOR SECRETS${NC}\n"
  local found=0

  # Patterns to detect
  local patterns=(
    "sk-[a-zA-Z0-9]{40,}"
    "AKIA[0-9A-Z]{16}"
    "eyJhbGciO"
    "ghp_[a-zA-Z0-9]{36}"
    "gho_[a-zA-Z0-9]{36}"
    "railway_[a-zA-Z0-9]+"
    "-----BEGIN .* PRIVATE KEY-----"
  )

  for pat in "${patterns[@]}"; do
    local hits; hits=$(grep -r --include="*.ts" --include="*.js" --include="*.tsx" --include="*.env" \
      --exclude-dir=node_modules --exclude-dir=".git" --exclude-dir=".next" \
      -lE "$pat" "$REPO_ROOT" 2>/dev/null)
    if [[ -n "$hits" ]]; then
      echo -e "  ${RED}FOUND${NC} pattern: ${BOLD}$pat${NC}"
      echo "$hits" | head -3 | sed 's/^/    /'
      found=$((found+1))
    fi
  done

  # Check for .env files with real values
  find "$REPO_ROOT" -name ".env" -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null | while read ef; do
    local lines; lines=$(grep -c "=.\+" "$ef" 2>/dev/null || echo 0)
    [[ "$lines" -gt 0 ]] && echo -e "  ${YELLOW}WARN${NC} .env file with $lines vars: $ef"
  done

  if [[ $found -eq 0 ]]; then
    echo -e "  ${GREEN}✓ No secrets patterns detected in source files${NC}"
  else
    echo -e "\n  ${RED}Found $found potential secret patterns${NC}"
  fi
  echo ""
}

cmd_permissions() {
  echo -e "\n${CYAN}${BOLD}  FILE PERMISSIONS${NC}\n"
  # Check shell scripts are executable
  local non_exec; non_exec=$(find "$REPO_ROOT/tools" -name "*.sh" ! -perm -u+x 2>/dev/null | head -10)
  if [[ -n "$non_exec" ]]; then
    echo -e "  ${YELLOW}WARN${NC} Non-executable scripts:"
    echo "$non_exec" | sed 's/^/    /'
    echo -e "  ${GRAY}Fix: chmod +x tools/**/*.sh${NC}"
  else
    echo -e "  ${GREEN}✓ All tool scripts are executable${NC}"
  fi

  # Check sensitive files
  for f in ~/.blackroad/kv_token ~/.blackroad/vercel_token ~/.blackroad/railway_token; do
    [[ -f "$f" ]] && {
      local perms; perms=$(stat -f "%OLp" "$f" 2>/dev/null || stat -c "%a" "$f" 2>/dev/null)
      if [[ "$perms" != "600" ]]; then
        echo -e "  ${RED}FAIL${NC} $f has permissions $perms (should be 600)"
      else
        echo -e "  ${GREEN}✓${NC} $f permissions OK (600)"
      fi
    }
  done
  echo ""
}

cmd_deps() {
  echo -e "\n${CYAN}${BOLD}  DEPENDENCY AUDIT${NC}\n"
  local web="$REPO_ROOT/orgs/core/blackroad-os-web"
  if [[ -f "$web/package.json" ]]; then
    cd "$web"
    echo -e "  ${GRAY}Running npm audit...${NC}"
    npm audit --audit-level=high 2>&1 | grep -E "high|critical|found|vulnerabilities" | head -10 | sed 's/^/  /'
  else
    echo -e "  ${GRAY}No package.json found${NC}"
  fi
  echo ""
}

cmd_workers() {
  echo -e "\n${CYAN}${BOLD}  TOKENLESS WORKERS CHECK${NC}\n"
  local issues=0
  # Check agents don't embed tokens
  local forbidden=("ANTHROPIC_API_KEY" "OPENAI_API_KEY" "sk-ant-" "sk-proj-")
  for f in "${forbidden[@]}"; do
    local hits; hits=$(grep -r --include="*.sh" --include="*.ts" --include="*.js" \
      --exclude-dir=node_modules --exclude-dir=".next" --exclude-dir=".git" \
      -l "$f" "$REPO_ROOT/tools" "$REPO_ROOT/orgs" 2>/dev/null)
    if [[ -n "$hits" ]]; then
      echo -e "  ${RED}FAIL${NC} Found $f in:"
      echo "$hits" | sed 's/^/    /'
      issues=$((issues+1))
    fi
  done
  [[ $issues -eq 0 ]] && echo -e "  ${GREEN}✓ All agents are tokenless — no provider keys embedded${NC}"
  echo ""
}

cmd_full() {
  echo -e "\n${BOLD}╔══════════════════════════════════╗${NC}"
  echo -e "${BOLD}║     BR AUDIT — Full Scan          ║${NC}"
  echo -e "${BOLD}╚══════════════════════════════════╝${NC}"
  cmd_secrets
  cmd_permissions
  cmd_workers
}

show_help() {
  echo -e "\n${BOLD}  BR AUDIT${NC}  Security & Health Scanner\n"
  echo -e "  ${CYAN}br audit full${NC}          Run all checks"
  echo -e "  ${CYAN}br audit secrets${NC}       Scan for leaked secrets/tokens"
  echo -e "  ${CYAN}br audit permissions${NC}   Check file permissions"
  echo -e "  ${CYAN}br audit deps${NC}          npm audit for vulnerabilities"
  echo -e "  ${CYAN}br audit workers${NC}       Verify agents are tokenless"
  echo ""
}

case "$1" in
  full|all)        cmd_full ;;
  secrets)         cmd_secrets ;;
  permissions|perm) cmd_permissions ;;
  deps)            cmd_deps ;;
  workers)         cmd_workers ;;
  *)               show_help ;;
esac
