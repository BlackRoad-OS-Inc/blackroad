#!/bin/zsh
# BR Format — Code Formatter Dispatcher
# prettier, black, gofmt, rustfmt, shfmt — one command for all

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BLUE='\033[0;34m'; NC='\033[0m'; BOLD='\033[1m'

FORMAT_DB="$HOME/.blackroad/format.db"

init_db() {
  mkdir -p "$(dirname "$FORMAT_DB")"
  sqlite3 "$FORMAT_DB" <<'SQL'
CREATE TABLE IF NOT EXISTS format_runs (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  path        TEXT,
  formatter   TEXT,
  files_changed INTEGER DEFAULT 0,
  dry_run     INTEGER DEFAULT 0,
  ts          INTEGER DEFAULT (strftime('%s','now'))
);
SQL
}

detect_formatters() {
  local dir="${1:-.}"
  local fmts=()
  [[ -f "$dir/package.json" ]] && fmts+=("prettier")
  find "$dir" -name "*.py" -not -path "*/__pycache__/*" 2>/dev/null | head -1 | grep -q . && fmts+=("black")
  [[ -f "$dir/go.mod" ]] && fmts+=("gofmt")
  [[ -f "$dir/Cargo.toml" ]] && fmts+=("rustfmt")
  find "$dir" -name "*.sh" 2>/dev/null | head -1 | grep -q . && fmts+=("shfmt")
  echo "${fmts[@]}"
}

run_prettier() {
  local dir="${1:-.}" dry="${2:-false}"
  echo -e "${CYAN}▶ Prettier${NC}"
  local cmd
  if command -v prettier &>/dev/null; then
    cmd="prettier"
  elif [[ -f "$dir/node_modules/.bin/prettier" ]]; then
    cmd="$dir/node_modules/.bin/prettier"
  else
    echo -e "  ${YELLOW}⚠${NC} prettier not installed — run: npm install prettier"
    return 1
  fi

  local flags="--write"
  [[ "$dry" == "true" ]] && flags="--check"

  local output changed=0
  output=$(cd "$dir" && $cmd $flags . 2>&1)
  changed=$(echo "$output" | grep -c "reformatted\|Reformatting" || echo 0)

  if [[ "$dry" == "true" ]]; then
    local unformatted
    unformatted=$(echo "$output" | grep "Code style issues" | grep -oE '[0-9]+' | head -1)
    [[ -z "$unformatted" ]] && unformatted=0
    if [[ "$unformatted" -eq 0 ]]; then
      echo -e "  ${GREEN}✓${NC} All files formatted"
    else
      echo -e "  ${YELLOW}⚠${NC} $unformatted files need formatting"
      echo "$output" | grep "\[warn\]" | head -10 | sed 's/^/  /'
    fi
  else
    echo -e "  ${GREEN}✓${NC} Formatted"
    echo "$output" | grep -v "^$" | head -10 | sed 's/^/  /'
  fi
}

run_black() {
  local dir="${1:-.}" dry="${2:-false}"
  echo -e "${CYAN}▶ Black (Python)${NC}"
  if ! command -v black &>/dev/null && ! python3 -m black --version &>/dev/null 2>&1; then
    echo -e "  ${YELLOW}⚠${NC} black not installed — run: pip install black"
    return 1
  fi
  local cmd="black"
  command -v black &>/dev/null || cmd="python3 -m black"

  local flags=""
  [[ "$dry" == "true" ]] && flags="--check --diff"

  local output changed=0
  output=$(cd "$dir" && $cmd $flags . 2>&1)
  changed=$(echo "$output" | grep -c "reformatted\|would reformat")

  if echo "$output" | grep -q "All done"; then
    echo -e "  ${GREEN}✓${NC} $changed files reformatted"
  elif [[ "$dry" == "true" ]] && echo "$output" | grep -q "would reformat"; then
    echo -e "  ${YELLOW}⚠${NC} $changed files need formatting"
    echo "$output" | grep "would reformat" | sed 's/^/  /'
  else
    echo "$output" | tail -5 | sed 's/^/  /'
  fi
}

run_gofmt() {
  local dir="${1:-.}" dry="${2:-false}"
  echo -e "${CYAN}▶ gofmt${NC}"
  if ! command -v gofmt &>/dev/null; then
    echo -e "  ${YELLOW}⚠${NC} gofmt not found (install Go)"
    return 1
  fi

  local files changed=0
  files=$(find "$dir" -name "*.go" -not -path "*/vendor/*" 2>/dev/null)
  [[ -z "$files" ]] && { echo -e "  ${BLUE}ℹ${NC} No .go files"; return 0; }

  while IFS= read -r f; do
    if [[ "$dry" == "true" ]]; then
      local diff
      diff=$(gofmt -l "$f")
      [[ -n "$diff" ]] && { echo -e "  ${YELLOW}$f${NC}"; (( changed++ )); }
    else
      gofmt -w "$f" && (( changed++ ))
    fi
  done <<< "$files"

  echo -e "  ${GREEN}✓${NC} $changed files processed"
}

run_rustfmt() {
  local dir="${1:-.}" dry="${2:-false}"
  echo -e "${CYAN}▶ rustfmt${NC}"
  if ! command -v rustfmt &>/dev/null; then
    echo -e "  ${YELLOW}⚠${NC} rustfmt not found (install Rust)"
    return 1
  fi
  local flags=""
  [[ "$dry" == "true" ]] && flags="--check"
  cd "$dir" && cargo fmt $flags 2>&1 | sed 's/^/  /'
}

run_shfmt() {
  local dir="${1:-.}" dry="${2:-false}"
  echo -e "${CYAN}▶ shfmt${NC}"
  if ! command -v shfmt &>/dev/null; then
    echo -e "  ${YELLOW}⚠${NC} shfmt not found — install: brew install shfmt"
    return 1
  fi

  local files changed=0
  files=$(find "$dir" -name "*.sh" -not -path "*/.git/*" -not -path "*/node_modules/*" 2>/dev/null)
  [[ -z "$files" ]] && { echo -e "  ${BLUE}ℹ${NC} No .sh files"; return 0; }

  local flags="-w -i 2"
  [[ "$dry" == "true" ]] && flags="-d"

  local total
  total=$(echo "$files" | wc -l | tr -d ' ')
  echo "$files" | xargs shfmt $flags 2>&1 | head -10 | sed 's/^/  /'
  echo -e "  ${GREEN}✓${NC} $total files processed"
}

cmd_run() {
  local dir="${1:-.}" dry="${2:-false}"
  echo -e "\n${BOLD}${CYAN}✨ Format: ${dir}${NC}"
  [[ "$dry" == "true" ]] && echo -e "  ${YELLOW}dry-run mode${NC}\n" || echo ""

  local fmts
  fmts=$(detect_formatters "$dir")
  if [[ -z "$fmts" ]]; then
    echo -e "  ${YELLOW}⚠${NC} No formatters detected"
    echo -e "  Supported: prettier, black, gofmt, rustfmt, shfmt"
    return 1
  fi

  local total_changed=0
  for f in $fmts; do
    run_$f "$dir" "$dry"
    echo ""
  done

  sqlite3 "$FORMAT_DB" "INSERT INTO format_runs (path, formatter, dry_run) VALUES ('$dir','auto',$([ "$dry" == "true" ] && echo 1 || echo 0));"

  echo -e "${GREEN}✓ Done${NC}\n"
}

cmd_check() {
  # Dry-run — check without modifying
  cmd_run "${1:-.}" true
}

show_help() {
  echo -e "\n${BOLD}${CYAN}✨ BR Format — Code Formatter${NC}\n"
  echo -e "  ${CYAN}br format [dir]${NC}               — auto-detect + format all"
  echo -e "  ${CYAN}br format check [dir]${NC}          — dry-run (check only)"
  echo -e "  ${CYAN}br format prettier [dir]${NC}"
  echo -e "  ${CYAN}br format black [dir]${NC}"
  echo -e "  ${CYAN}br format gofmt [dir]${NC}"
  echo -e "  ${CYAN}br format shfmt [dir]${NC}\n"
  echo -e "  ${YELLOW}Tip:${NC} br format check  — safe for CI pipelines\n"
}

init_db
case "${1:-help}" in
  run|fmt|''|.) cmd_run "${2:-.}" ;;
  check|dry|diff) cmd_check "${2:-.}" ;;
  prettier)     run_prettier "${2:-.}" "${3:-false}" ;;
  black)        run_black "${2:-.}" "${3:-false}" ;;
  gofmt|go)     run_gofmt "${2:-.}" "${3:-false}" ;;
  rustfmt|rust) run_rustfmt "${2:-.}" "${3:-false}" ;;
  shfmt|sh)     run_shfmt "${2:-.}" "${3:-false}" ;;
  help|--help)  show_help ;;
  *) [[ -d "$1" ]] && cmd_run "$1" || show_help ;;
esac
