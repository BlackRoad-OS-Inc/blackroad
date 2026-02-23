#!/bin/zsh
# BR Git — AI-powered smart git operations

GIT_TOOLS="/Users/alexa/blackroad/tools/git-integration"

# ── Brand Palette ──────────────────────────────────────────────────────────────
AMBER='\033[38;5;214m'
PINK='\033[38;5;205m'
VIOLET='\033[38;5;135m'
BBLUE='\033[38;5;69m'
GREEN='\033[0;32m'
RED='\033[0;31m'
DIM='\033[2m'
BOLD='\033[1m'
NC='\033[0m'
# compat aliases
BLUE="$BBLUE"; CYAN="$AMBER"; YELLOW="$PINK"; PURPLE="$VIOLET"

# ── Ollama-powered commit message generation ───────────────────────────────────
_ai_commit_msg() {
    local diff_stat="$1"
    local diff_body="$2"

    command -v ollama &>/dev/null || { echo ""; return 1; }
    local model
    for m in lucidia llama3.2:1b qwen2.5:1.5b tinyllama; do
        ollama list 2>/dev/null | grep -q "^$m" && { model="$m"; break; }
    done
    [[ -z "$model" ]] && { echo ""; return 1; }

    local prompt="Write a conventional commit message for this git diff.
Rules: one line only, format is type(scope): description, be specific and concise.
Types: feat fix docs refactor test perf style chore.
Only output the commit message line, nothing else.

Files changed:
$diff_stat

Diff (first 80 lines):
$diff_body"

    local msg
    msg=$(echo "$prompt" | ollama run "$model" 2>/dev/null | head -1 | tr -d '\n')
    # strip any markdown fences or quotes
    msg=$(echo "$msg" | sed "s/^\`//;s/\`$//;s/^'//;s/'$//;s/^\"/\"/")
    echo "$msg"
}

# Smart commit with AI message generation
smart_commit() {
    echo ""
    echo -e "  ${AMBER}${BOLD}◆ BR GIT COMMIT${NC}  ${DIM}AI-powered message generation${NC}"
    echo -e "  ${DIM}──────────────────────────────────────────────${NC}"
    echo ""

    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        echo -e "  ${RED}✗${NC} Not in a git repository"; return 1
    fi

    # Auto-stage if nothing staged
    local staged
    staged=$(git diff --cached --stat 2>/dev/null)
    if [[ -z "$staged" ]]; then
        echo -e "  ${DIM}Nothing staged — running git add -A${NC}"
        git add -A
        staged=$(git diff --cached --stat 2>/dev/null)
        [[ -z "$staged" ]] && echo -e "  ${RED}✗${NC} Nothing to commit" && return 1
    fi

    # Show what's staged
    echo -e "  ${DIM}staged files:${NC}"
    git diff --cached --name-only | while read -r f; do
        echo -e "    ${DIM}+${NC} $f"
    done
    echo ""
    git --no-pager diff --cached --stat | tail -1 | while read -r line; do
        echo -e "  ${DIM}$line${NC}"
    done
    echo ""

    # Generate AI message
    local diff_stat diff_body commit_msg
    diff_stat=$(git diff --cached --stat)
    diff_body=$(git diff --cached | head -80)

    echo -e "  ${AMBER}◆${NC} Generating commit message with AI…"
    commit_msg=$(_ai_commit_msg "$diff_stat" "$diff_body")

    if [[ -z "$commit_msg" ]]; then
        # Fallback: keyword-based
        local diff_full files added removed
        diff_full=$(git diff --cached)
        files=$(git diff --cached --name-only | head -1)
        added=$(echo "$diff_full" | grep -c "^+" 2>/dev/null || echo 0)
        removed=$(echo "$diff_full" | grep -c "^-" 2>/dev/null || echo 0)
        local fbase
        fbase=$(basename "${files:-code}" | sed 's/\.[^.]*$//')
        if echo "$diff_full" | grep -qi "test\|spec"; then
            commit_msg="test: add $fbase tests"
        elif echo "$diff_full" | grep -qi "fix\|bug"; then
            commit_msg="fix: resolve $fbase issue"
        elif echo "$diff_full" | grep -qi "doc\|readme\|\.md"; then
            commit_msg="docs: update $fbase"
        elif (( removed > added * 2 )); then
            commit_msg="refactor: clean up $fbase"
        else
            commit_msg="feat: update $fbase"
        fi
        echo -e "  ${DIM}(Ollama unavailable — using keyword detection)${NC}"
    fi

    echo ""
    echo -e "  ${AMBER}${BOLD}$commit_msg${NC}"
    echo ""
    echo -ne "  ${DIM}[Enter] accept  [e] edit  [n] cancel:${NC}  "
    read -r resp

    case "${resp:l}" in
        n|no)
            echo -e "  ${DIM}Cancelled.${NC}"; return 0 ;;
        e|edit)
            echo -ne "  ${AMBER}commit message:${NC} "
            read -r commit_msg ;;
    esac

    # Append Co-authored-by trailer
    local full_msg="${commit_msg}

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"

    git commit -m "$full_msg"
    if [[ $? -eq 0 ]]; then
        echo ""
        echo -e "  ${GREEN}✓${NC} Committed"
        git --no-pager log -1 --oneline | while read -r line; do
            echo -e "  ${DIM}$line${NC}"
        done
        echo ""
    else
        echo -e "  ${RED}✗${NC} Commit failed"; return 1
    fi
}

# Suggest branch name
smart_branch() {
    echo -e "${VIOLET}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${VIOLET}║     🌿 Smart Branch Name Suggester           ║${NC}"
    echo -e "${VIOLET}╚═══════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Get current branch
    local current_branch=$(git branch --show-current 2>/dev/null)
    echo -e "${CYAN}Current branch:${NC} ${current_branch:-main}"
    echo ""
    
    # Analyze recent changes
    local changed_files=$(git status --short | head -5)
    
    if [[ -z "$changed_files" ]]; then
        echo -e "${YELLOW}No changes detected. What are you working on?${NC}"
        echo -ne "${CYAN}Feature/fix/refactor:${NC} "
        read -r work_type
        echo -ne "${CYAN}Brief description:${NC} "
        read -r description
    else
        echo -e "${GREEN}Recent changes:${NC}"
        echo "$changed_files"
        echo ""
        
        # Detect work type
        if echo "$changed_files" | grep -q "test"; then
            work_type="test"
        elif echo "$changed_files" | grep -q "fix"; then
            work_type="fix"
        elif echo "$changed_files" | grep -q "doc\|README"; then
            work_type="docs"
        else
            work_type="feature"
        fi
        
        # Extract file context
        local main_file=$(echo "$changed_files" | head -1 | awk '{print $2}')
        local file_base=$(basename "$main_file" | sed 's/\.[^.]*$//' | tr '[:upper:]' '[:lower:]' | tr '_' '-')
        description="$file_base"
        
        echo -e "${YELLOW}Detected work type:${NC} $work_type"
        echo -e "${YELLOW}Context:${NC} $description"
        echo ""
        echo -ne "${CYAN}Customize? [y/N]:${NC} "
        read -r customize
        
        if [[ ${customize:l} == "y" ]]; then
            echo -ne "${CYAN}Work type:${NC} "
            read -r work_type
            echo -ne "${CYAN}Description:${NC} "
            read -r description
        fi
    fi
    
    # Generate branch name
    local clean_desc=$(echo "$description" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g')
    local branch_name="${work_type}/${clean_desc}"
    
    echo ""
    echo -e "${GREEN}Suggested branch name:${NC}"
    echo -e "  ${CYAN}$branch_name${NC}"
    echo ""
    echo -ne "${YELLOW}Create this branch? [Y/n]:${NC} "
    read -r response
    
    if [[ ${response:l} != "n" ]] && [[ ${response:l} != "no" ]]; then
        git checkout -b "$branch_name"
        echo -e "${GREEN}✓ Branch created and checked out!${NC}"
    else
        echo -e "${YELLOW}Branch not created${NC}"
    fi
}

# Pre-commit code review
smart_review() {
    echo -e "${CYAN}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║     🔍 Pre-Commit Code Review                ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════╝${NC}"
    echo ""
    
    local diff=$(git diff --cached)
    
    if [[ -z "$diff" ]]; then
        echo -e "${YELLOW}No staged changes to review. Checking unstaged...${NC}"
        diff=$(git diff)
        if [[ -z "$diff" ]]; then
            echo -e "${YELLOW}No changes to review${NC}"
            return 0
        fi
    fi
    
    echo -e "${GREEN}Analyzing changes...${NC}"
    echo ""
    
    # Basic checks
    local issues=0
    
    # Check for console.log / debugging statements
    if echo "$diff" | grep -q "console\.log\|debugger\|print("; then
        echo -e "${YELLOW}⚠  Found debugging statements${NC}"
        echo "$diff" | grep -n "console\.log\|debugger\|print(" | head -3
        ((issues++))
        echo ""
    fi
    
    # Check for TODO/FIXME
    if echo "$diff" | grep -q "TODO\|FIXME\|HACK"; then
        echo -e "${YELLOW}⚠  Found TODO/FIXME comments${NC}"
        echo "$diff" | grep -n "TODO\|FIXME\|HACK" | head -3
        ((issues++))
        echo ""
    fi
    
    # Check for large functions
    local large_functions=$(echo "$diff" | grep -A 50 "^+.*function\|^+.*def " | grep -c "^+")
    if (( large_functions > 50 )); then
        echo -e "${YELLOW}⚠  Detected large function additions (${large_functions} lines)${NC}"
        echo "   Consider breaking into smaller functions"
        ((issues++))
        echo ""
    fi
    
    # Check for hardcoded values
    if echo "$diff" | grep -E "password|secret|api_key|token" | grep -q "="; then
        echo -e "${RED}⚠  WARNING: Possible hardcoded secrets detected!${NC}"
        ((issues++))
        echo ""
    fi
    
    # Summary
    if (( issues == 0 )); then
        echo -e "${GREEN}✓ No obvious issues found!${NC}"
        echo -e "${GREEN}✓ Code looks good to commit${NC}"
    else
        echo -e "${YELLOW}Found $issues potential issue(s)${NC}"
        echo -e "${YELLOW}Review recommended before committing${NC}"
    fi
    
    echo ""
    git diff --cached --stat 2>/dev/null || git diff --stat
}

# Enhanced git status
smart_status() {
    echo -e "${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║     📊 Smart Git Status                      ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Basic git status
    git status --short
    
    echo ""
    echo -e "${CYAN}Repository Info:${NC}"
    
    # Current branch
    local branch=$(git branch --show-current)
    echo "  Branch: ${GREEN}${branch}${NC}"
    
    # Commit count
    local commits=$(git rev-list --count HEAD 2>/dev/null || echo "0")
    echo "  Commits: ${commits}"
    
    # Last commit
    local last_commit=$(git log -1 --oneline 2>/dev/null)
    echo "  Last: ${last_commit}"
    
    # File stats
    local modified=$(git status --short | grep "^ M" | wc -l | tr -d ' ')
    local added=$(git status --short | grep "^??" | wc -l | tr -d ' ')
    local staged=$(git diff --cached --name-only | wc -l | tr -d ' ')
    
    echo ""
    echo -e "${CYAN}Changes:${NC}"
    echo "  Modified: ${modified}"
    echo "  New: ${added}"
    echo "  Staged: ${staged}"
    
    # Suggest next action
    echo ""
    echo -e "${YELLOW}Suggested next action:${NC}"
    if (( staged > 0 )); then
        echo "  ${GREEN}br git commit${NC} - Commit staged changes"
    elif (( modified > 0 || added > 0 )); then
        echo "  ${GREEN}git add -A${NC} - Stage all changes"
        echo "  ${GREEN}br git review${NC} - Review before committing"
    else
        echo "  ${GREEN}Working tree clean!${NC}"
    fi
}

# Pretty git log — last 10 commits with color
cmd_log() {
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        echo -e "  ${RED}✗${NC} Not a git repository"; return 1
    fi
    local branch
    branch=$(git branch --show-current 2>/dev/null || echo "HEAD")
    echo ""
    echo -e "  ${AMBER}${BOLD}◆ BR GIT LOG${NC}  ${DIM}${branch}${NC}"
    echo -e "  ${DIM}──────────────────────────────────────────────${NC}"
    echo ""
    git --no-pager log --oneline --graph --decorate -12 --color=always \
        --format="%C(bold yellow)%h%C(reset) %C(dim)%ar%C(reset) %s %C(dim)%an%C(reset)" 2>/dev/null \
    | while IFS= read -r line; do
        echo "  $line"
    done
    echo ""
}

# Compact status snapshot
cmd_summary() {
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        echo -e "  ${RED}✗${NC} Not a git repository"; return 1
    fi
    local branch remote ahead behind
    branch=$(git branch --show-current 2>/dev/null || echo "HEAD")
    remote=$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || echo "")
    local staged_n unstaged_n untracked_n
    staged_n=$(git diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')
    unstaged_n=$(git diff --name-only 2>/dev/null | wc -l | tr -d ' ')
    untracked_n=$(git ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')
    if [[ -n "$remote" ]]; then
        ahead=$(git rev-list "@{u}..HEAD" --count 2>/dev/null || echo 0)
        behind=$(git rev-list "HEAD..@{u}" --count 2>/dev/null || echo 0)
    fi
    local last_commit
    last_commit=$(git --no-pager log -1 --format="%h %s" 2>/dev/null)

    echo ""
    echo -e "  ${AMBER}${BOLD}◆ BR GIT${NC}  ${DIM}$(git rev-parse --show-toplevel 2>/dev/null | xargs basename)${NC}"
    echo -e "  ${DIM}──────────────────────────────────────────────${NC}"
    printf "  ${BOLD}%-12s${NC}${AMBER}%s${NC}" "branch" "$branch"
    [[ -n "$remote" ]] && printf "  ${DIM}%s${NC}" "$remote"
    echo ""
    [[ -n "$ahead" && $ahead -gt 0 ]]   && printf "  ${BOLD}%-12s${NC}${GREEN}↑ $ahead to push${NC}\n" "ahead"
    [[ -n "$behind" && $behind -gt 0 ]] && printf "  ${BOLD}%-12s${NC}${PINK}↓ $behind to pull${NC}\n" "behind"
    echo -e "  $(printf '%-12s' 'staged')${GREEN}$staged_n${NC} files"
    echo -e "  $(printf '%-12s' 'unstaged')${PINK}$unstaged_n${NC} files"
    echo -e "  $(printf '%-12s' 'untracked')${DIM}$untracked_n${NC} files"
    echo -e "  $(printf '%-12s' 'last')${DIM}$last_commit${NC}"
    echo ""
    # Hint
    if (( staged_n > 0 )); then
        echo -e "  ${DIM}→  br git commit   (${staged_n} staged)${NC}"
    elif (( unstaged_n > 0 )); then
        echo -e "  ${DIM}→  br git commit   (will stage all)${NC}"
    else
        echo -e "  ${DIM}✓  working tree clean${NC}"
    fi
    echo ""
}

#──────────────────────────────────────────────────────────────────────────────
# Standup — last 24h commits across all branches
#──────────────────────────────────────────────────────────────────────────────
cmd_standup() {
    if ! git rev-parse --is-inside-work-tree &>/dev/null; then
        echo -e "  ${RED}✗ Not in a git repo${NC}"; return 1
    fi
    local since="${1:-24 hours ago}"
    local author; author=$(git config user.name 2>/dev/null || echo "")
    echo -e "\n  ${AMBER}${BOLD}◆ BR GIT STANDUP${NC}  ${DIM}Last 24h — $(git rev-parse --show-toplevel 2>/dev/null | xargs basename)${NC}\n"

    # All branches, last 24h
    local commits; commits=$(git --no-pager log \
        --all \
        --since="$since" \
        ${author:+--author="$author"} \
        --format="%C(yellow)%h%Creset %C(cyan)%ar%Creset %s" \
        2>/dev/null)

    if [[ -z "$commits" ]]; then
        echo -e "  ${DIM}No commits in the last 24 hours${NC}\n"; return 0
    fi

    echo "$commits" | while read -r line; do
        echo "  $line"
    done

    local total; total=$(echo "$commits" | wc -l | tr -d ' ')
    echo -e "\n  ${DIM}${total} commit(s) · since: ${since}${NC}"

    # Changed files summary
    echo -e "\n  ${BOLD}Files touched:${NC}"
    git --no-pager log --all --since="$since" \
        ${author:+--author="$author"} \
        --name-only --pretty=format:"" 2>/dev/null \
        | grep -v '^$' | sort | uniq -c | sort -rn | head -8 \
        | while read -r count file; do
            printf "  ${AMBER}%-3s${NC}  ${DIM}%s${NC}\n" "$count" "$file"
        done
    echo ""
}

#──────────────────────────────────────────────────────────────────────────────
# Help
#──────────────────────────────────────────────────────────────────────────────
show_help() {
    echo -e ""
    echo -e "  ${AMBER}${BOLD}◆ BR GIT${NC}  ${DIM}AI-powered git. Smart commits, fast reviews, daily standups.${NC}"
    echo -e "  ${DIM}Your git workflow, supercharged. No excuses for bad commit messages.${NC}"
    echo -e "  ${DIM}────────────────────────────────────────────────${NC}"
    echo -e "  ${BOLD}USAGE${NC}  br git ${DIM}<command>${NC}"
    echo -e ""
    echo -e "  ${BOLD}COMMANDS${NC}"
    echo -e "  ${AMBER}  (default)         ${NC} Status summary — branch, staged, ahead/behind"
    echo -e "  ${AMBER}  commit            ${NC} Smart commit — AI message, stages, pushes"
    echo -e "  ${AMBER}  review            ${NC} Pre-commit code review — debug, TODOs, large diffs"
    echo -e "  ${AMBER}  standup [period]  ${NC} Last 24h commits + files touched"
    echo -e "  ${AMBER}  log               ${NC} Pretty log — last 12 commits"
    echo -e "  ${AMBER}  branch            ${NC} Suggest + create branch name from staged changes"
    echo -e "  ${AMBER}  status            ${NC} Smart status with suggestions"
    echo -e ""
    echo -e "  ${BOLD}EXAMPLES${NC}"
    echo -e "  ${DIM}  br git commit${NC}"
    echo -e "  ${DIM}  br git review${NC}"
    echo -e "  ${DIM}  br git standup${NC}"
    echo -e "  ${DIM}  br git standup \"48 hours ago\"${NC}"
    echo -e ""
}

# Main dispatch
case ${1:-summary} in
    summary|snap|"")         cmd_summary ;;
    commit|c)                smart_commit ;;
    log|l)                   cmd_log ;;
    branch|b)                smart_branch ;;
    review|r)                smart_review ;;
    status|s)                smart_status ;;
    standup|daily|yesterday) cmd_standup "${2:-}" ;;
    suggest)                 smart_status ;;
    help|-h|--help)          show_help ;;
    *)
        echo -e "  ${RED}✗${NC} Unknown: $1"
        show_help; exit 1 ;;
esac
