#!/bin/zsh
# BR Diff — Enhanced Git Diff Viewer
# Smart diffs with stats, filtering, and LLM summaries

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BLUE='\033[0;34m'; NC='\033[0m'; BOLD='\033[1m'

cmd_show() {
  # Enhanced diff with stats header
  local ref="${1:-HEAD}"
  local extra_args=("${@:2}")

  echo -e "\n${BOLD}${CYAN}📊 Diff: $ref${NC}\n"

  # Stats summary
  git --no-pager diff "$ref" -- "${extra_args[@]}" --stat 2>/dev/null | python3 -c "
import sys
lines = sys.stdin.read().strip().split('\n')
if not lines or not lines[-1]:
    print('  No changes')
    sys.exit(0)
summary = lines[-1] if lines else ''
print(f'  {summary}')
print()
for line in lines[:-1]:
    parts = line.split('|')
    if len(parts) == 2:
        fname = parts[0].strip()
        rest = parts[1].strip()
        adds = rest.count('+')
        dels = rest.count('-')
        print(f'  \033[1m{fname:<40}\033[0m  \033[32m+{adds}\033[0m \033[31m-{dels}\033[0m')
" 2>/dev/null

  echo ""
  git --no-pager diff --color=always "$ref" -- "${extra_args[@]}" 2>/dev/null | head -500
}

cmd_staged() {
  echo -e "\n${BOLD}${CYAN}📋 Staged Changes${NC}\n"
  local stat
  stat=$(git --no-pager diff --cached --stat 2>/dev/null)
  if [[ -z "$stat" ]]; then
    echo -e "  Nothing staged. Use: git add <file>"
    return
  fi
  echo "$stat" | sed 's/^/  /'
  echo ""
  git --no-pager diff --cached --color=always 2>/dev/null | head -300
}

cmd_branch() {
  # Diff current branch vs main/master
  local base="${1:-}"
  if [[ -z "$base" ]]; then
    base=$(git --no-pager symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||')
    [[ -z "$base" ]] && base="main"
  fi
  local current
  current=$(git --no-pager rev-parse --abbrev-ref HEAD 2>/dev/null)

  echo -e "\n${BOLD}${CYAN}🌿 Branch Diff: ${YELLOW}$current${CYAN} vs ${YELLOW}$base${NC}\n"

  git --no-pager diff --stat "$base...$current" 2>/dev/null | tail -1 | sed 's/^/  /'
  echo ""

  # Files changed
  local files
  files=$(git --no-pager diff --name-status "$base...$current" 2>/dev/null)
  if [[ -z "$files" ]]; then
    echo -e "  No differences from $base"
    return
  fi

  echo "$files" | python3 -c "
import sys
lines = sys.stdin.read().strip().split('\n')
for line in lines[:30]:
    parts = line.split('\t', 1)
    if len(parts) == 2:
        status, fname = parts
        colors = {'A': '\033[32m', 'M': '\033[33m', 'D': '\033[31m', 'R': '\033[36m'}
        labels = {'A': 'added   ', 'M': 'modified', 'D': 'deleted ', 'R': 'renamed '}
        c = colors.get(status[0], '')
        l = labels.get(status[0], status)
        print(f'  {c}{l}\033[0m  {fname}')
if len(lines) > 30:
    print(f'  \033[90m... and {len(lines)-30} more\033[0m')
"
  echo ""
}

cmd_file() {
  local file="$1" ref="${2:-HEAD}"
  [[ -z "$file" ]] && { echo -e "${RED}✗${NC} Usage: br diff file <path> [ref]"; return 1; }
  [[ ! -f "$file" ]] && { echo -e "${RED}✗${NC} File not found: $file"; return 1; }
  echo -e "\n${BOLD}${CYAN}📄 $file${NC}  vs $ref\n"
  git --no-pager diff --color=always "$ref" -- "$file" 2>/dev/null | head -500
}

cmd_summary() {
  # Concise diff summary suitable for LLM / commit msg
  local ref="${1:-HEAD}"
  echo -e "\n${BOLD}${CYAN}📝 Diff Summary${NC}\n"

  local diff_stat
  diff_stat=$(git --no-pager diff "$ref" --stat 2>/dev/null | tail -1)
  local files_changed
  files_changed=$(git --no-pager diff "$ref" --name-only 2>/dev/null)

  echo -e "  ${BOLD}Changes:${NC} $diff_stat"
  echo -e "\n  ${BOLD}Files:${NC}"
  echo "$files_changed" | sed 's/^/    /' | head -20

  local diff_text
  diff_text=$(git --no-pager diff "$ref" --unified=2 2>/dev/null | head -200)
  if [[ -n "$diff_text" ]]; then
    local added del
    added=$(echo "$diff_text" | grep -c '^+[^+]' 2>/dev/null || echo 0)
    del=$(echo "$diff_text" | grep -c '^-[^-]' 2>/dev/null || echo 0)
    echo -e "\n  ${GREEN}+$added${NC} lines added  ${RED}-$del${NC} lines removed"
    echo -e "\n  ${YELLOW}Tip:${NC} pipe to LLM: br diff summary | br llm ask fast 'write a commit message'"
  fi
}

cmd_pr() {
  # PR-style diff with full context
  local base="${1:-main}"
  local current
  current=$(git --no-pager rev-parse --abbrev-ref HEAD 2>/dev/null)
  echo -e "\n${BOLD}${CYAN}🔀 PR Diff: $current → $base${NC}\n"

  # Commits included
  echo -e "${BOLD}Commits:${NC}"
  git --no-pager log --oneline "$base..$current" 2>/dev/null | head -10 | sed 's/^/  /'
  echo ""

  # Full diff
  git --no-pager diff --color=always "$base..$current" 2>/dev/null | head -1000
}

cmd_watch() {
  # Live diff — reruns every 2s
  local ref="${1:-HEAD}"
  echo -e "${CYAN}Live diff mode (Ctrl+C to stop)...${NC}\n"
  while true; do
    clear
    echo -e "${BOLD}${CYAN}Live Diff: $(date '+%H:%M:%S')${NC}\n"
    git --no-pager diff --color=always --stat "$ref" 2>/dev/null | head -30
    sleep 2
  done
}

cmd_commits() {
  # Recent commits with their diffs
  local n="${1:-5}"
  echo -e "\n${BOLD}${CYAN}📜 Last $n Commits${NC}\n"
  git --no-pager log --oneline -"$n" 2>/dev/null | while read -r hash msg; do
    echo -e "  ${YELLOW}$hash${NC}  $msg"
    git --no-pager diff --stat "$hash^..$hash" 2>/dev/null | tail -1 | sed 's/^/    /'
  done
  echo ""
}

show_help() {
  echo -e "\n${BOLD}${CYAN}📊 BR Diff — Enhanced Git Diff${NC}\n"
  echo -e "  ${CYAN}br diff${NC}                    — working tree vs HEAD"
  echo -e "  ${CYAN}br diff staged${NC}             — staged changes"
  echo -e "  ${CYAN}br diff branch [base]${NC}      — branch vs main"
  echo -e "  ${CYAN}br diff file <path> [ref]${NC}  — single file diff"
  echo -e "  ${CYAN}br diff summary [ref]${NC}      — stats + summary"
  echo -e "  ${CYAN}br diff pr [base]${NC}          — PR-style with commits"
  echo -e "  ${CYAN}br diff commits [n]${NC}        — last N commit diffs"
  echo -e "  ${CYAN}br diff watch${NC}              — live diff (auto-refresh)"
  echo -e "\n  ${YELLOW}Tip:${NC} br diff summary | br llm ask fast 'write a commit message'\n"
}

case "${1:-show}" in
  show|view)           cmd_show "${@:2}" ;;
  staged|cached|index) cmd_staged ;;
  branch|br)           cmd_branch "$2" ;;
  file|f)              cmd_file "$2" "$3" ;;
  summary|stat|stats)  cmd_summary "$2" ;;
  pr|pull-request)     cmd_pr "$2" ;;
  watch|live)          cmd_watch "$2" ;;
  commits|log)         cmd_commits "$2" ;;
  help|--help|-h)      show_help ;;
  # Passthrough: br diff HEAD~3, br diff abc123, etc.
  *)
    if git rev-parse --verify "$1" &>/dev/null 2>&1; then
      cmd_show "$@"
    else
      show_help
    fi
    ;;
esac
