#!/bin/zsh
#===============================================================================
# BR Git - Smart Git Integration
# AI-powered git operations for BlackRoad
#===============================================================================

GIT_TOOLS="/Users/alexa/blackroad/tools/git-integration"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
RED='\033[0;31m'
NC='\033[0m'

# Generate smart commit message from git diff
smart_commit() {
    echo -e "${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║     🤖 Smart Commit Message Generator        ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Check if in git repo
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo -e "${RED}Error: Not in a git repository${NC}"
        return 1
    fi
    
    # Get staged changes
    local staged=$(git diff --cached --stat)
    if [[ -z "$staged" ]]; then
        echo -e "${YELLOW}No staged changes. Staging all changes...${NC}"
        git add -A
        staged=$(git diff --cached --stat)
        if [[ -z "$staged" ]]; then
            echo -e "${RED}No changes to commit${NC}"
            return 1
        fi
    fi
    
    echo -e "${CYAN}Analyzing changes...${NC}"
    echo ""
    git diff --cached --stat
    echo ""
    
    # Analyze the diff
    local diff=$(git diff --cached)
    local files_changed=$(echo "$staged" | wc -l | tr -d ' ')
    ((files_changed--))
    
    # Smart commit message generation
    local commit_msg=""
    local commit_type="feat"
    
    # Detect commit type from diff
    if echo "$diff" | grep -q "test\|spec"; then
        commit_type="test"
        commit_msg="Add tests"
    elif echo "$diff" | grep -q "fix\|bug"; then
        commit_type="fix"
        commit_msg="Fix issue"
    elif echo "$diff" | grep -q "doc\|README\|\.md"; then
        commit_type="docs"
        commit_msg="Update documentation"
    elif echo "$diff" | grep -q "refactor"; then
        commit_type="refactor"
        commit_msg="Refactor code"
    elif echo "$diff" | grep -q "style\|format"; then
        commit_type="style"
        commit_msg="Update code style"
    elif echo "$diff" | grep -q "perf\|performance"; then
        commit_type="perf"
        commit_msg="Improve performance"
    else
        # Detect from files
        local added=$(echo "$diff" | grep "^+" | grep -v "^+++" | wc -l | tr -d ' ')
        local removed=$(echo "$diff" | grep "^-" | grep -v "^---" | wc -l | tr -d ' ')
        
        if (( removed > added * 2 )); then
            commit_type="refactor"
            commit_msg="Clean up code"
        elif (( added > 100 )); then
            commit_type="feat"
            commit_msg="Add new feature"
        else
            commit_type="feat"
            commit_msg="Update functionality"
        fi
    fi
    
    # Analyze file names for better context
    local file_list=$(git diff --cached --name-only)
    local first_file=$(echo "$file_list" | head -1)
    local file_base=$(basename "$first_file" | sed 's/\.[^.]*$//')
    
    # Make message more specific
    if [[ -n "$file_base" ]]; then
        case $commit_type in
            feat)
                commit_msg="feat: add ${file_base} functionality"
                ;;
            fix)
                commit_msg="fix: resolve ${file_base} issues"
                ;;
            docs)
                commit_msg="docs: update ${file_base} documentation"
                ;;
            test)
                commit_msg="test: add ${file_base} tests"
                ;;
            refactor)
                commit_msg="refactor: improve ${file_base} structure"
                ;;
            style)
                commit_msg="style: format ${file_base}"
                ;;
            perf)
                commit_msg="perf: optimize ${file_base}"
                ;;
        esac
    fi
    
    echo -e "${GREEN}Suggested commit message:${NC}"
    echo ""
    echo -e "  ${CYAN}$commit_msg${NC}"
    echo ""
    
    # Add detailed body
    echo -e "${YELLOW}Changes summary:${NC}"
    echo "  - $files_changed file(s) changed"
    git diff --cached --stat | tail -1
    echo ""
    
    # Interactive confirmation
    echo -ne "${YELLOW}Use this message? [Y/n/e(dit)]:${NC} "
    read -r response
    
    case ${response:l} in
        n|no)
            echo -e "${YELLOW}Commit cancelled${NC}"
            return 0
            ;;
        e|edit)
            echo -ne "${CYAN}Enter your commit message:${NC} "
            read -r custom_msg
            commit_msg="$custom_msg"
            ;;
    esac
    
    # Commit with the message
    git commit -m "$commit_msg"
    
    if [[ $? -eq 0 ]]; then
        echo ""
        echo -e "${GREEN}✓ Committed successfully!${NC}"
        git log -1 --oneline
    else
        echo -e "${RED}✗ Commit failed${NC}"
        return 1
    fi
}

# Suggest branch name
smart_branch() {
    echo -e "${PURPLE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║     🌿 Smart Branch Name Suggester           ║${NC}"
    echo -e "${PURPLE}╚═══════════════════════════════════════════════╝${NC}"
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

# Help
show_help() {
    cat <<EOF
BR Git - Smart Git Integration

Usage: br git {command} [args]

Commands:
  commit [files]  - Generate smart commit message and commit
  branch          - Suggest and create branch name
  review          - Pre-commit code review
  status          - Enhanced git status with insights
  suggest         - Suggest next git action

Examples:
  br git commit                  # Smart commit with auto message
  br git branch                  # Create feature branch
  br git review                  # Review changes before commit
  br git status                  # See smart git status

EOF
}

# Main dispatch
case ${1:-status} in
    commit|c)
        smart_commit
        ;;
    branch|b)
        smart_branch
        ;;
    review|r)
        smart_review
        ;;
    status|s)
        smart_status
        ;;
    suggest)
        smart_status
        ;;
    help|-h|--help)
        show_help
        ;;
    *)
        echo "Unknown command: $1"
        show_help
        exit 1
        ;;
esac
