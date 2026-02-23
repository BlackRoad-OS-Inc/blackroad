#!/bin/zsh
# BR REVIEW - AI code review via Ollama

GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'
RED='\033[0;31m'; PURPLE='\033[0;35m'; NC='\033[0m'; BOLD='\033[1m'

OLLAMA_URL="${OLLAMA_URL:-http://localhost:11434}"
MODEL="${REVIEW_MODEL:-tinyllama:latest}"
DB_FILE="$HOME/.blackroad/review.db"

init_db() {
  mkdir -p "$(dirname $DB_FILE)"
  sqlite3 "$DB_FILE" <<'SQL'
CREATE TABLE IF NOT EXISTS reviews (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  target TEXT, review_type TEXT, findings TEXT, ts TEXT DEFAULT (datetime('now'))
);
SQL
}
init_db

_ollama_review() {
  local prompt="$1"
  curl -s --max-time 90 -X POST "$OLLAMA_URL/api/generate" \
    -H "Content-Type: application/json" \
    -d "{\"model\":\"$MODEL\",\"prompt\":$(python3 -c "import json,sys; print(json.dumps(sys.argv[1]))" "$prompt"),\"stream\":false}" \
    2>/dev/null | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('response','').strip())" 2>/dev/null
}

cmd_diff() {
  # review staged or current diff
  local target="${1:-staged}"
  local diff

  if [[ "$target" == "staged" ]]; then
    diff=$(git --no-pager diff --cached 2>/dev/null | head -300)
    [[ -z "$diff" ]] && diff=$(git --no-pager diff 2>/dev/null | head -300)
  elif [[ "$target" == "last" ]]; then
    diff=$(git --no-pager show HEAD 2>/dev/null | head -300)
  else
    diff=$(git --no-pager diff "$target" 2>/dev/null | head -300)
  fi

  [[ -z "$diff" ]] && { echo -e "${YELLOW}No diff found for: $target${NC}"; return 1; }

  echo -e "${CYAN}🔍 Reviewing diff...${NC}"

  local prompt="You are a senior engineer doing a code review. Review this diff and provide:
1. ISSUES: bugs, security risks, logic errors (only real problems, not style)
2. SUGGESTIONS: one or two concrete improvements
3. VERDICT: LGTM / NEEDS CHANGES / CRITICAL ISSUES

Be concise. No fluff.

Diff:
$diff"

  local review
  review=$(_ollama_review "$prompt")

  if [[ -z "$review" ]]; then
    echo -e "${RED}✗ Ollama not responding${NC}"; return 1
  fi

  echo ""
  echo -e "${BOLD}${PURPLE}Code Review:${NC}"
  echo "════════════════════════════════════════"
  echo "$review"
  echo "════════════════════════════════════════"
  echo ""

  sqlite3 "$DB_FILE" "INSERT INTO reviews(target,review_type,findings) VALUES('$target','diff',$(python3 -c "import json,sys; print(json.dumps(sys.argv[1]))" "${review:0:500}"));"
}

cmd_file() {
  local file="$1"
  [[ -z "$file" ]] && { echo "Usage: br review file <path>"; return 1; }
  [[ -f "$file" ]] || { echo -e "${RED}File not found: $file${NC}"; return 1; }

  local ext="${file##*.}"
  local content=$(head -200 "$file")

  echo -e "${CYAN}🔍 Reviewing ${file}...${NC}"

  local prompt="You are a senior engineer. Review this $ext file for:
1. Bugs and logic errors
2. Security issues
3. Performance problems
4. One improvement suggestion

Be concise. File: $file

Content:
$content"

  local review
  review=$(_ollama_review "$prompt")

  echo ""
  echo -e "${BOLD}${PURPLE}File Review: ${file}${NC}"
  echo "════════════════════════════════════════"
  echo "${review:-No response from Ollama}"
  echo "════════════════════════════════════════"
  echo ""

  sqlite3 "$DB_FILE" "INSERT INTO reviews(target,review_type,findings) VALUES('$file','file',$(python3 -c "import json,sys; print(json.dumps(sys.argv[1]))" "${review:0:500}"));"
}

cmd_security() {
  # security-focused scan of staged changes or a file
  local target="${1:-.}"
  local diff=$(git --no-pager diff --cached 2>/dev/null | head -300)
  [[ -z "$diff" ]] && diff=$(git --no-pager diff 2>/dev/null | head -300)

  echo -e "${CYAN}🔐 Security review...${NC}"

  local prompt="Security-focused code review. Look ONLY for:
- Hardcoded secrets, API keys, passwords
- SQL injection, command injection, path traversal
- Authentication/authorization bypasses
- Insecure data handling

Report only real findings. Format: CRITICAL/HIGH/MEDIUM/LOW - description.

Code:
$diff"

  local review
  review=$(_ollama_review "$prompt")

  echo ""
  echo -e "${BOLD}${RED}Security Review:${NC}"
  echo "════════════════════════════════════════"
  echo "${review:-No response from Ollama}"
  echo "════════════════════════════════════════"
  echo ""

  sqlite3 "$DB_FILE" "INSERT INTO reviews(target,review_type,findings) VALUES('security-scan','security',$(python3 -c "import json,sys; print(json.dumps(sys.argv[1]))" "${review:0:500}"));"
}

cmd_log() {
  echo ""
  echo -e "${BOLD}${CYAN}Review history:${NC}"
  sqlite3 "$DB_FILE" "SELECT ts, review_type, target, substr(findings,1,60) FROM reviews ORDER BY id DESC LIMIT 15;" 2>/dev/null | \
    while IFS='|' read ts rtype target findings; do
      echo -e "  ${CYAN}${ts}${NC}  ${YELLOW}${rtype}${NC}  ${target}  ${findings}..."
    done
  echo ""
}

cmd_help() {
  echo ""
  echo -e "${BOLD}br review${NC} — AI code review via Ollama"
  echo ""
  echo "  ${CYAN}br review diff [staged|last|<ref>]${NC}  Review a diff"
  echo "  ${CYAN}br review file <path>${NC}               Review a specific file"
  echo "  ${CYAN}br review security${NC}                  Security-focused scan"
  echo "  ${CYAN}br review log${NC}                       Show review history"
  echo ""
  echo "  Model: $MODEL (set REVIEW_MODEL to override)"
  echo ""
}

case "${1:-diff}" in
  diff)     shift; cmd_diff "$@" ;;
  file)     shift; cmd_file "$@" ;;
  security) cmd_security ;;
  log)      cmd_log ;;
  help|-h)  cmd_help ;;
  *) echo "Unknown: $1. Try: diff file security log"; exit 1 ;;
esac
