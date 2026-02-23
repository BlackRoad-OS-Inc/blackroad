#!/bin/zsh
# BR Git Smart - Intelligent git operations
GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
BLUE='\033[0;34m'; BOLD='\033[1m'

cmd_smart_commit() {
  # Get staged diff summary
  local staged
  staged=$(git --no-pager diff --cached --stat 2>/dev/null)
  if [[ -z "$staged" ]]; then
    echo -e "${YELLOW}⚠ No staged changes. Running git add -A first…${NC}"
    git add -A
    staged=$(git --no-pager diff --cached --stat 2>/dev/null)
  fi
  [[ -z "$staged" ]] && { echo -e "${RED}Nothing to commit${NC}"; exit 0; }

  # Count changed files
  local files_changed
  files_changed=$(git --no-pager diff --cached --name-only | wc -l | tr -d ' ')
  
  # Detect what changed
  local has_new has_modified has_deleted has_ts has_sh has_md msg_parts=()
  git --no-pager diff --cached --name-only | grep -q "^tools/" && msg_parts+=("CLI tools")
  git --no-pager diff --cached --name-only | grep -q "app/api/" && msg_parts+=("API routes")
  git --no-pager diff --cached --name-only | grep -q "app/(app)/" && msg_parts+=("pages")
  git --no-pager diff --cached --name-only | grep -q "components/" && msg_parts+=("components")
  git --no-pager diff --cached --name-only | grep -q "shared/" && msg_parts+=("agent mesh")
  git --no-pager diff --cached --name-only | grep -q "\.md$" && msg_parts+=("docs")
  git --no-pager diff --cached --name-only | grep -q "br$" && msg_parts+=("br CLI")
  git --no-pager diff --cached --name-only | grep -q "\.sh$" && msg_parts+=("scripts")

  # Build auto commit message
  local parts_str="${msg_parts[*]}"
  local auto_msg
  if [[ "${#msg_parts[@]}" -eq 0 ]]; then
    auto_msg="chore: update ${files_changed} file(s)"
  else
    auto_msg="feat: update ${parts_str// /, } (${files_changed} files)"
  fi

  # Try Ollama for better message if available
  local ollama_msg=""
  if curl -s http://localhost:11434/api/tags &>/dev/null; then
    local diff_summary
    diff_summary=$(git --no-pager diff --cached --stat | head -20)
    ollama_msg=$(curl -s -X POST http://localhost:11434/api/generate \
      -H "Content-Type: application/json" \
      -d "{\"model\":\"llama3.2\",\"prompt\":\"Write a concise git commit message (max 72 chars, conventional commits format) for these changes:\\n${diff_summary}\\nReply with ONLY the commit message line, nothing else.\",\"stream\":false}" 2>/dev/null | \
      python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('response','').strip().split('\n')[0])" 2>/dev/null)
  fi

  local final_msg="${ollama_msg:-$auto_msg}"
  echo -e "\n${CYAN}${BOLD}Auto-generated commit message:${NC}"
  echo -e "  ${GREEN}${final_msg}${NC}\n"
  echo -e "${YELLOW}Files staged (${files_changed}):${NC}"
  echo "$staged" | head -15
  echo ""
  
  printf "${CYAN}Use this message? [Y/n/edit]: ${NC}"
  read -r choice
  
  case "${choice:-Y}" in
    [Yy]*|"")
      git commit -m "${final_msg}

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>" && echo -e "${GREEN}✓ Committed${NC}"
      ;;
    [Ee]*)
      printf "${CYAN}Enter message: ${NC}"
      read -r custom_msg
      git commit -m "${custom_msg}

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>" && echo -e "${GREEN}✓ Committed${NC}"
      ;;
    [Nn]*)
      echo -e "${YELLOW}Aborted${NC}"
      ;;
  esac
}

cmd_log() {
  local n="${1:-10}"
  echo -e "${CYAN}${BOLD}Recent commits (${n}):${NC}\n"
  git --no-pager log --oneline --graph --decorate --color=always -"$n" | while IFS= read -r line; do
    local hash="${line:2:7}"
    local rest="${line:9}"
    echo -e "  ${BLUE}${line}${NC}"
  done
}

cmd_status() {
  echo -e "${CYAN}${BOLD}Git Status${NC}\n"
  local branch
  branch=$(git --no-pager rev-parse --abbrev-ref HEAD 2>/dev/null)
  local remote
  remote=$(git --no-pager remote -v | head -1 | awk '{print $2}')
  echo -e "  Branch: ${GREEN}${branch}${NC}"
  echo -e "  Remote: ${CYAN}${remote}${NC}\n"
  
  local staged=$(git --no-pager diff --cached --name-only | wc -l | tr -d ' ')
  local unstaged=$(git --no-pager diff --name-only | wc -l | tr -d ' ')
  local untracked=$(git --no-pager ls-files --others --exclude-standard | wc -l | tr -d ' ')
  
  echo -e "  ${GREEN}●${NC} Staged:    ${staged} files"
  echo -e "  ${YELLOW}●${NC} Unstaged:  ${unstaged} files"
  echo -e "  ${BLUE}●${NC} Untracked: ${untracked} files\n"
  
  if [[ $((staged + unstaged + untracked)) -gt 0 ]]; then
    git --no-pager status --short | head -20
  else
    echo -e "  ${GREEN}✓ Clean working tree${NC}"
  fi
}

cmd_push() {
  local branch
  branch=$(git --no-pager rev-parse --abbrev-ref HEAD 2>/dev/null)
  echo -e "${CYAN}Pushing to origin/${branch}…${NC}"
  git push origin "$branch" && echo -e "${GREEN}✓ Pushed${NC}"
}

cmd_pull() {
  echo -e "${CYAN}Pulling latest…${NC}"
  git pull --rebase && echo -e "${GREEN}✓ Up to date${NC}"
}

show_help() {
  echo -e "${CYAN}${BOLD}BR Git Smart — Intelligent Git Operations${NC}\n"
  echo -e "  ${GREEN}br git smart${NC}      Auto-commit with AI-generated message"
  echo -e "  ${GREEN}br git log [n]${NC}    Pretty log (default 10)"
  echo -e "  ${GREEN}br git status${NC}     Enhanced status with counts"
  echo -e "  ${GREEN}br git push${NC}       Push current branch"
  echo -e "  ${GREEN}br git pull${NC}       Pull with rebase"
}

case "${1:-help}" in
  smart|commit|auto) cmd_smart_commit ;;
  log|history) cmd_log "${2:-10}" ;;
  status|st) cmd_status ;;
  push) cmd_push ;;
  pull) cmd_pull ;;
  *) show_help ;;
esac
