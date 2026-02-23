#!/bin/zsh
# BR Lint — Multi-language linter runner
# Runs shellcheck, eslint, pylint, tsc, and more with unified output

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BLUE='\033[0;34m'; PURPLE='\033[0;35m'; NC='\033[0m'; BOLD='\033[1m'

LINT_DB="$HOME/.blackroad/lint.db"

init_db() {
  mkdir -p "$(dirname "$LINT_DB")"
  sqlite3 "$LINT_DB" <<'SQL'
CREATE TABLE IF NOT EXISTS lint_runs (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  path        TEXT,
  linter      TEXT,
  errors      INTEGER DEFAULT 0,
  warnings    INTEGER DEFAULT 0,
  fixed       INTEGER DEFAULT 0,
  duration_ms INTEGER,
  passed      INTEGER DEFAULT 0,
  ts          INTEGER DEFAULT (strftime('%s','now'))
);
SQL
}

detect_linters() {
  local dir="${1:-.}"

  # Detect by files present
  [[ -f "$dir/package.json" ]] && echo "eslint"
  [[ -f "$dir/tsconfig.json" ]] && echo "tsc"
  find "$dir" -maxdepth 3 -name "*.py" -not -path "*/__pycache__/*" 2>/dev/null | head -1 | grep -q . && echo "pylint"
  find "$dir" -maxdepth 3 -name "*.sh" 2>/dev/null | head -1 | grep -q . && echo "shellcheck"
  [[ -f "$dir/go.mod" ]] && echo "golangci"
  [[ -f "$dir/Cargo.toml" ]] && echo "clippy"
}

run_eslint() {
  local dir="${1:-.}" fix="${2:-false}"
  echo -e "${CYAN}▶ ESLint${NC}"
  if ! command -v eslint &>/dev/null && ! [[ -f "$dir/node_modules/.bin/eslint" ]]; then
    echo -e "  ${YELLOW}⚠${NC} eslint not found — install: npm install eslint"
    return 1
  fi
  local eslint_cmd="eslint"
  [[ -f "$dir/node_modules/.bin/eslint" ]] && eslint_cmd="$dir/node_modules/.bin/eslint"

  local output errors=0 warnings=0
  local flags="--format=compact"
  [[ "$fix" == "true" ]] && flags="$flags --fix"

  output=$(cd "$dir" && "$eslint_cmd" . $flags 2>&1)
  errors=$(echo "$output" | grep -c "error" || echo 0)
  warnings=$(echo "$output" | grep -c "warning" || echo 0)

  if [[ $errors -eq 0 && $warnings -eq 0 ]]; then
    echo -e "  ${GREEN}✓${NC} No issues"
  else
    echo "$output" | head -30
    echo -e "  ${RED}✗${NC} $errors errors, $warnings warnings"
  fi
  return $errors
}

run_shellcheck() {
  local dir="${1:-.}"
  echo -e "${CYAN}▶ ShellCheck${NC}"
  if ! command -v shellcheck &>/dev/null; then
    echo -e "  ${YELLOW}⚠${NC} shellcheck not found — install: brew install shellcheck"
    return 1
  fi

  local files total_issues=0
  files=$(find "$dir" -name "*.sh" -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null)
  [[ -z "$files" ]] && { echo -e "  ${BLUE}ℹ${NC} No .sh files found"; return 0; }

  local file_count=0 issue_count=0
  while IFS= read -r f; do
    (( file_count++ ))
    local result
    result=$(shellcheck -S warning "$f" 2>&1)
    if [[ -n "$result" ]]; then
      echo -e "  ${YELLOW}$f${NC}"
      echo "$result" | sed 's/^/    /' | head -10
      issue_count=$(( issue_count + $(echo "$result" | grep -c "^In ") ))
    fi
  done <<< "$files"

  if [[ $issue_count -eq 0 ]]; then
    echo -e "  ${GREEN}✓${NC} $file_count files — clean"
  else
    echo -e "  ${YELLOW}⚠${NC} $issue_count issues in $file_count files"
  fi
}

run_pylint() {
  local dir="${1:-.}"
  echo -e "${CYAN}▶ Pylint${NC}"
  local py_cmd="pylint"
  command -v pylint &>/dev/null || py_cmd="python3 -m pylint"

  local files
  files=$(find "$dir" -name "*.py" -not -path "*/node_modules/*" -not -path "*/.git/*" -not -path "*/__pycache__/*" 2>/dev/null | head -20)
  [[ -z "$files" ]] && { echo -e "  ${BLUE}ℹ${NC} No .py files"; return 0; }

  local output score
  output=$(echo "$files" | xargs $py_cmd --output-format=text 2>&1 | tail -20)
  score=$(echo "$output" | grep "rated at" | grep -oE '[0-9]+\.[0-9]+' | head -1)
  errors=$(echo "$output" | grep -cE "^.*error" || echo 0)

  if [[ -n "$score" ]]; then
    local color="$GREEN"
    [[ $(echo "$score < 7" | bc 2>/dev/null) == "1" ]] && color="$YELLOW"
    [[ $(echo "$score < 5" | bc 2>/dev/null) == "1" ]] && color="$RED"
    echo -e "  Score: ${color}${score}/10${NC}"
  fi
  echo "$output" | grep -E "^.*\.py:[0-9]+" | head -15 | sed 's/^/  /'
  echo -e "  ${BLUE}ℹ${NC} $(echo "$files" | wc -l | tr -d ' ') files checked"
}

run_tsc() {
  local dir="${1:-.}"
  echo -e "${CYAN}▶ TypeScript${NC}"
  local tsc_cmd
  if command -v tsc &>/dev/null; then
    tsc_cmd="tsc"
  elif [[ -f "$dir/node_modules/.bin/tsc" ]]; then
    tsc_cmd="$dir/node_modules/.bin/tsc"
  else
    echo -e "  ${YELLOW}⚠${NC} tsc not found — install: npm install typescript"
    return 1
  fi

  local output errors=0
  output=$(cd "$dir" && $tsc_cmd --noEmit 2>&1)
  errors=$(echo "$output" | grep -c "error TS" || echo 0)

  if [[ $errors -eq 0 ]]; then
    echo -e "  ${GREEN}✓${NC} No type errors"
  else
    echo "$output" | head -20 | sed 's/^/  /'
    echo -e "  ${RED}✗${NC} $errors type errors"
  fi
  return $errors
}

run_golangci() {
  local dir="${1:-.}"
  echo -e "${CYAN}▶ GolangCI-Lint${NC}"
  if ! command -v golangci-lint &>/dev/null; then
    echo -e "  ${YELLOW}⚠${NC} golangci-lint not found — install: brew install golangci-lint"
    return 1
  fi
  local output
  output=$(cd "$dir" && golangci-lint run ./... 2>&1)
  local issues
  issues=$(echo "$output" | grep -c "^" || echo 0)
  if [[ $issues -le 1 ]]; then
    echo -e "  ${GREEN}✓${NC} No issues"
  else
    echo "$output" | head -20 | sed 's/^/  /'
    echo -e "  ${YELLOW}⚠${NC} $issues issues"
  fi
}

cmd_run() {
  local dir="${1:-.}" linter="${2:-auto}"
  local start_ms
  start_ms=$(python3 -c "import time; print(int(time.time()*1000))")

  echo -e "\n${BOLD}${CYAN}🔍 Lint: ${dir}${NC}\n"

  local total_errors=0

  if [[ "$linter" == "auto" ]]; then
    local detected
    detected=$(detect_linters "$dir")
    if [[ -z "$detected" ]]; then
      echo -e "  ${YELLOW}⚠${NC} No linters detected for this directory"
      echo -e "  Supported: eslint, shellcheck, pylint, tsc, golangci"
      return 1
    fi
    while IFS= read -r l; do
      [[ -z "$l" ]] && continue
      run_${l} "$dir"
      total_errors=$(( total_errors + $? ))
      echo ""
    done <<< "$detected"
  else
    run_$linter "$dir"
    total_errors=$?
  fi

  local end_ms duration
  end_ms=$(python3 -c "import time; print(int(time.time()*1000))")
  duration=$(( end_ms - start_ms ))

  sqlite3 "$LINT_DB" "INSERT INTO lint_runs (path, linter, errors, duration_ms, passed) VALUES ('$dir','$linter',$total_errors,$duration,$(( total_errors == 0 ? 1 : 0 )));"

  echo -e "${BLUE}⏱${NC} ${duration}ms"
  if [[ $total_errors -eq 0 ]]; then
    echo -e "${GREEN}✓ All clean${NC}\n"
  else
    echo -e "${RED}✗ $total_errors issues found${NC}\n"
  fi
  return $total_errors
}

cmd_history() {
  echo -e "\n${BOLD}${CYAN}📜 Lint History${NC}\n"
  python3 - "$LINT_DB" <<'PY'
import sqlite3, sys, time
conn = sqlite3.connect(sys.argv[1])
rows = conn.execute("SELECT path, linter, errors, warnings, duration_ms, passed, ts FROM lint_runs ORDER BY ts DESC LIMIT 20").fetchall()
for path, linter, errors, warns, dur, passed, ts in rows:
    t = time.strftime('%m/%d %H:%M', time.localtime(ts))
    ok = "\033[32m✓\033[0m" if passed else "\033[31m✗\033[0m"
    print(f"  {ok}  \033[36m{t}\033[0m  \033[1m{(path or '.'):<25}\033[0m  {linter:<12}  {errors}err  {dur}ms")
if not rows: print("  No lint history yet.")
print()
conn.close()
PY
}

cmd_ci() {
  # Strict mode — exit non-zero on any errors (for CI use)
  local dir="${1:-.}"
  echo -e "${BOLD}${CYAN}🔍 Lint CI Mode${NC}"
  cmd_run "$dir" auto
  local code=$?
  [[ $code -ne 0 ]] && exit $code
}

show_help() {
  echo -e "\n${BOLD}${CYAN}🔍 BR Lint — Multi-language Linter${NC}\n"
  echo -e "  ${CYAN}br lint [dir]${NC}                — auto-detect + run all linters"
  echo -e "  ${CYAN}br lint <dir> shellcheck${NC}     — run specific linter"
  echo -e "  ${CYAN}br lint <dir> eslint${NC}"
  echo -e "  ${CYAN}br lint <dir> pylint${NC}"
  echo -e "  ${CYAN}br lint <dir> tsc${NC}"
  echo -e "  ${CYAN}br lint history${NC}              — past lint runs"
  echo -e "  ${CYAN}br lint ci [dir]${NC}             — strict CI mode (exits non-zero)\n"
  echo -e "  ${YELLOW}Supported:${NC} shellcheck, eslint, tsc, pylint, golangci\n"
}

init_db
case "${1:-help}" in
  run|check|''|.) cmd_run "${2:-.}" "${3:-auto}" ;;
  history|log)    cmd_history ;;
  ci)             cmd_ci "${2:-.}" ;;
  shellcheck)     run_shellcheck "${2:-.}" ;;
  eslint)         run_eslint "${2:-.}" "${3:-false}" ;;
  pylint)         run_pylint "${2:-.}" ;;
  tsc|typescript) run_tsc "${2:-.}" ;;
  golangci|go)    run_golangci "${2:-.}" ;;
  help|--help)    show_help ;;
  # If first arg looks like a path, use it
  *) [[ -d "$1" ]] && cmd_run "$1" "${2:-auto}" || show_help ;;
esac
