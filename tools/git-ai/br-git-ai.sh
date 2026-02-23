#!/bin/zsh
# BR GIT-AI - AI-powered commit messages, PR descriptions, and git helpers

GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'
RED='\033[0;31m'; PURPLE='\033[0;35m'; NC='\033[0m'; BOLD='\033[1m'

OLLAMA_URL="${OLLAMA_URL:-http://localhost:11434}"
MODEL="${GITAI_MODEL:-tinyllama:latest}"
DB_FILE="$HOME/.blackroad/git-ai.db"

init_db() {
  mkdir -p "$(dirname $DB_FILE)"
  sqlite3 "$DB_FILE" <<'SQL'
CREATE TABLE IF NOT EXISTS commits (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  sha TEXT, message TEXT, diff_summary TEXT, ts TEXT DEFAULT (datetime('now'))
);
SQL
}
init_db

_ollama_generate() {
  local prompt="$1"
  curl -s --max-time 60 -X POST "$OLLAMA_URL/api/generate" \
    -H "Content-Type: application/json" \
    -d "{\"model\":\"$MODEL\",\"prompt\":$(python3 -c "import json,sys; print(json.dumps(sys.argv[1]))" "$prompt"),\"stream\":false}" \
    2>/dev/null | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('response','').strip())" 2>/dev/null
}

cmd_commit() {
  local staged
  staged=$(git --no-pager diff --cached --stat 2>/dev/null)
  if [[ -z "$staged" ]]; then
    echo -e "${YELLOW}Nothing staged. Run: git add <files>${NC}"; return 1
  fi

  local diff
  diff=$(git --no-pager diff --cached 2>/dev/null | head -200)

  echo -e "${CYAN}🤖 Generating commit message...${NC}"

  local prompt="Write a concise git commit message (conventional commits format) for this diff.
Format: <type>(<scope>): <description>
Then 2-3 bullet points of what changed.
Keep it under 10 lines total.

Diff stats:
$staged

Sample diff (truncated):
$diff"

  local msg
  msg=$(_ollama_generate "$prompt")

  if [[ -z "$msg" ]]; then
    echo -e "${RED}✗ Ollama not responding. Using git diff summary.${NC}"
    msg="feat: $(echo $staged | head -1)"
  fi

  echo ""
  echo -e "${BOLD}${CYAN}Suggested commit message:${NC}"
  echo "────────────────────────────────────────"
  echo "$msg"
  echo "────────────────────────────────────────"
  echo ""

  local choice
  echo -ne "${YELLOW}Use this message? [y/e/n]: ${NC}"
  read -r choice
  case "$choice" in
    y|Y)
      git commit -m "$msg"
      local sha=$(git rev-parse --short HEAD 2>/dev/null)
      sqlite3 "$DB_FILE" "INSERT INTO commits(sha,message,diff_summary) VALUES('$sha',$(python3 -c "import json,sys; print(json.dumps(sys.argv[1]))" "$msg"),$(python3 -c "import json,sys; print(json.dumps(sys.argv[1]))" "$staged"));"
      echo -e "${GREEN}✓ Committed: $sha${NC}"
      ;;
    e|E)
      # open in $EDITOR
      local tmpfile=$(mktemp)
      echo "$msg" > "$tmpfile"
      ${EDITOR:-nano} "$tmpfile"
      git commit -F "$tmpfile"
      rm "$tmpfile"
      ;;
    *) echo -e "${YELLOW}Cancelled${NC}" ;;
  esac
}

cmd_suggest() {
  # just print suggestion without committing
  local staged=$(git --no-pager diff --cached --stat 2>/dev/null)
  local unstaged=$(git --no-pager diff --stat 2>/dev/null)

  [[ -z "$staged" && -z "$unstaged" ]] && { echo "No changes detected"; return 1; }

  echo -e "${CYAN}🤖 Analyzing changes...${NC}"
  local diff=$(git --no-pager diff --cached 2>/dev/null | head -150)
  [[ -z "$diff" ]] && diff=$(git --no-pager diff 2>/dev/null | head -150)

  local prompt="Suggest a git commit message for this diff (conventional commits format):
$diff"

  local msg
  msg=$(_ollama_generate "$prompt")
  echo ""
  echo -e "${BOLD}Suggested:${NC} $msg"
  echo ""
}

cmd_pr() {
  # generate PR description from branch vs main
  local base="${1:-main}"
  local branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)

  echo -e "${CYAN}🤖 Generating PR description for ${branch} → ${base}...${NC}"

  local commits
  commits=$(git --no-pager log "$base".."$branch" --oneline 2>/dev/null | head -20)
  local diff_stat
  diff_stat=$(git --no-pager diff "$base"..."$branch" --stat 2>/dev/null | head -30)

  [[ -z "$commits" ]] && { echo "No commits ahead of $base"; return 1; }

  local prompt="Write a GitHub pull request description for these changes.
Include: ## Summary, ## Changes, ## Testing sections.
Keep it professional and concise.

Branch: $branch → $base
Commits:
$commits

Files changed:
$diff_stat"

  local desc
  desc=$(_ollama_generate "$prompt")

  echo ""
  echo -e "${BOLD}${CYAN}PR Description:${NC}"
  echo "════════════════════════════════════════"
  echo "$desc"
  echo "════════════════════════════════════════"
  echo ""
  echo -e "${CYAN}Branch:${NC} $branch → $base"
  echo ""
}

cmd_log() {
  echo ""
  echo -e "${BOLD}${CYAN}AI commit history:${NC}"
  sqlite3 "$DB_FILE" "SELECT ts, sha, substr(message,1,70) FROM commits ORDER BY id DESC LIMIT 20;" 2>/dev/null | \
    while IFS='|' read ts sha msg; do
      echo -e "  ${CYAN}${ts}${NC}  ${YELLOW}${sha}${NC}  ${msg}"
    done
  echo ""
}

cmd_diff_summary() {
  local ref="${1:-HEAD}"
  echo -e "${CYAN}🤖 Summarizing diff at ${ref}...${NC}"
  local diff=$(git --no-pager show "$ref" --stat 2>/dev/null | head -30)
  local prompt="Summarize what changed in this git commit in 3 bullet points:
$diff"
  local summary
  summary=$(_ollama_generate "$prompt")
  echo ""
  echo -e "${BOLD}Summary:${NC}"
  echo "$summary"
  echo ""
}

cmd_help() {
  echo ""
  echo -e "${BOLD}br git-ai${NC} — AI-powered git helpers"
  echo ""
  echo "  ${CYAN}br git-ai commit${NC}         Stage → AI message → commit (interactive)"
  echo "  ${CYAN}br git-ai suggest${NC}        Suggest a commit message (no commit)"
  echo "  ${CYAN}br git-ai pr [base]${NC}      Generate PR description (default base: main)"
  echo "  ${CYAN}br git-ai diff [ref]${NC}     Summarize a commit diff"
  echo "  ${CYAN}br git-ai log${NC}            Show AI commit history"
  echo ""
  echo "  Model: $MODEL (set GITAI_MODEL to override)"
  echo ""
}

case "${1:-help}" in
  commit)  cmd_commit ;;
  suggest) cmd_suggest ;;
  pr)      shift; cmd_pr "$@" ;;
  diff)    shift; cmd_diff_summary "${1:-HEAD}" ;;
  log)     cmd_log ;;
  help|-h) cmd_help ;;
  *) echo "Unknown: $1. Try: commit suggest pr diff log"; exit 1 ;;
esac
