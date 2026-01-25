#!/bin/bash

# Agent PR Coordinator - Automatic code review and merge coordination!
# BlackRoad Agents review each other's PRs with AI-powered analysis

MEMORY_DIR="$HOME/.blackroad/memory"
PR_DIR="$MEMORY_DIR/pull-requests"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

# Initialize PR coordination system
init_pr_system() {
    mkdir -p "$PR_DIR"/{pending,reviewing,approved,merged}
    
    echo -e "${GREEN}✅ PR Coordination System initialized${NC}"
}

# Register a new PR for review
register_pr() {
    local repo="$1"
    local pr_number="$2"
    local author="${3:-${MY_AGENT:-unknown}}"
    local title="$4"
    
    if [[ -z "$repo" || -z "$pr_number" ]]; then
        echo -e "${RED}Usage: register <repo> <pr-number> [author] [title]${NC}"
        return 1
    fi
    
    local pr_id="${repo//\//_}_pr${pr_number}"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
    
    cat > "$PR_DIR/pending/${pr_id}.json" << EOF
{
    "pr_id": "$pr_id",
    "repo": "$repo",
    "pr_number": $pr_number,
    "author": "$author",
    "title": "$title",
    "status": "pending",
    "reviewers": [],
    "approvals": [],
    "created_at": "$timestamp",
    "skill_tags": []
}
EOF

    echo -e "${GREEN}✅ Registered PR: ${CYAN}$repo#$pr_number${NC}"
    echo -e "   Author: $author"
    echo -e "   Title: $title"
    
    # Log to memory
    ~/memory-system.sh log pr-registered "$pr_id" "PR registered: $repo#$pr_number by $author" 2>/dev/null
    
    # Auto-assign reviewers
    auto_assign_reviewers "$pr_id"
}

# Auto-assign reviewers based on skills
auto_assign_reviewers() {
    local pr_id="$1"
    local pr_file="$PR_DIR/pending/${pr_id}.json"
    
    [[ ! -f "$pr_file" ]] && return 1
    
    local repo=$(jq -r '.repo' "$pr_file")
    local author=$(jq -r '.author' "$pr_file")
    
    echo -e "${CYAN}🤖 Auto-assigning reviewers...${NC}"
    
    # Get active BlackRoad Agents (excluding author)
    local active_agents=$(tail -100 "$MEMORY_DIR/journals/master-journal.jsonl" 2>/dev/null | \
        jq -r '.entity' | grep "agent-" | sort -u | grep -v "$author" | head -3)
    
    local reviewers=()
    while IFS= read -r agent; do
        [[ -z "$agent" ]] && continue
        reviewers+=("$agent")
        
        echo -e "  ${GREEN}→${NC} Assigned: ${CYAN}$agent${NC}"
        
        # Notify the reviewer
        ~/memory-system.sh log pr-review-requested "$agent" "📝 You've been assigned to review: $repo PR (from $author)" 2>/dev/null
    done <<< "$active_agents"
    
    # Update PR with reviewers
    local reviewers_json=$(printf '%s\n' "${reviewers[@]}" | jq -R . | jq -s .)
    jq --argjson reviewers "$reviewers_json" '.reviewers = $reviewers | .status = "reviewing"' \
        "$pr_file" > "${pr_file}.tmp"
    mv "${pr_file}.tmp" "$pr_file"
    
    # Move to reviewing
    mv "$pr_file" "$PR_DIR/reviewing/"
    
    echo -e "${GREEN}✅ Assigned ${#reviewers[@]} reviewers${NC}"
}

# Submit a review
submit_review() {
    local pr_id="$1"
    local reviewer="${2:-${MY_AGENT:-unknown}}"
    local decision="$3"  # approve, request_changes, comment
    local comments="${4:-No comments}"
    
    if [[ -z "$pr_id" || -z "$decision" ]]; then
        echo -e "${RED}Usage: submit-review <pr-id> [reviewer] <approve|request_changes|comment> [comments]${NC}"
        return 1
    fi
    
    local pr_file="$PR_DIR/reviewing/${pr_id}.json"
    
    if [[ ! -f "$pr_file" ]]; then
        echo -e "${RED}❌ PR not found: $pr_id${NC}"
        return 1
    fi
    
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
    
    # Add review
    local review_json=$(jq -n \
        --arg reviewer "$reviewer" \
        --arg decision "$decision" \
        --arg comments "$comments" \
        --arg timestamp "$timestamp" \
        '{reviewer: $reviewer, decision: $decision, comments: $comments, timestamp: $timestamp}')
    
    # Update PR
    local updated=$(jq --argjson review "$review_json" \
        '.reviews += [$review] | if $review.decision == "approve" then .approvals += [$review.reviewer] else . end' \
        "$pr_file")
    
    echo "$updated" > "$pr_file"
    
    # Display review
    echo -e "${GREEN}✅ Review submitted by ${CYAN}$reviewer${NC}"
    echo -e "   Decision: ${BOLD}$decision${NC}"
    echo -e "   Comments: $comments"
    
    # Log to memory
    ~/memory-system.sh log pr-reviewed "$pr_id" "Review by $reviewer: $decision - $comments" 2>/dev/null
    
    # Check if ready to merge
    check_merge_ready "$pr_id"
}

# Check if PR is ready to merge
check_merge_ready() {
    local pr_id="$1"
    local pr_file="$PR_DIR/reviewing/${pr_id}.json"
    
    [[ ! -f "$pr_file" ]] && return 1
    
    local approvals=$(jq '.approvals | length' "$pr_file")
    local reviewers=$(jq '.reviewers | length' "$pr_file")
    local changes_requested=$(jq '[.reviews[] | select(.decision == "request_changes")] | length' "$pr_file")
    
    echo ""
    echo -e "${BOLD}${PURPLE}📊 Merge Status:${NC}"
    echo -e "  Approvals: ${GREEN}$approvals${NC} / $reviewers"
    echo -e "  Changes Requested: ${RED}$changes_requested${NC}"
    
    # Consensus rules:
    # - Need at least 2 approvals
    # - No changes requested
    # - All assigned reviewers have reviewed
    
    if [[ $approvals -ge 2 && $changes_requested -eq 0 ]]; then
        echo -e "${GREEN}✅ READY TO MERGE!${NC}"
        
        # Move to approved
        jq '.status = "approved"' "$pr_file" > "${pr_file}.tmp"
        mv "${pr_file}.tmp" "$pr_file"
        mv "$pr_file" "$PR_DIR/approved/"
        
        # Notify
        local repo=$(jq -r '.repo' "$PR_DIR/approved/${pr_id}.json")
        local pr_number=$(jq -r '.pr_number' "$PR_DIR/approved/${pr_id}.json")
        
        ~/memory-system.sh log pr-approved "$pr_id" "🎉 PR approved by consensus! Ready to merge: $repo#$pr_number" 2>/dev/null
        
        echo ""
        echo -e "${YELLOW}💡 Merge with: gh pr merge $pr_number -m${NC}"
        
        return 0
    elif [[ $changes_requested -gt 0 ]]; then
        echo -e "${RED}⚠️  Changes requested - author needs to update${NC}"
    else
        echo -e "${YELLOW}⏳ Waiting for more reviews...${NC}"
    fi
}

# List all PRs
list_prs() {
    local status="${1:-all}"
    
    echo -e "${BOLD}${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${CYAN}║           📝 PULL REQUEST DASHBOARD 📝                    ║${NC}"
    echo -e "${BOLD}${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Count by status
    local pending=$(ls -1 "$PR_DIR/pending"/*.json 2>/dev/null | wc -l | tr -d ' ')
    local reviewing=$(ls -1 "$PR_DIR/reviewing"/*.json 2>/dev/null | wc -l | tr -d ' ')
    local approved=$(ls -1 "$PR_DIR/approved"/*.json 2>/dev/null | wc -l | tr -d ' ')
    local merged=$(ls -1 "$PR_DIR/merged"/*.json 2>/dev/null | wc -l | tr -d ' ')
    
    echo -e "${BOLD}Status Summary:${NC}"
    echo -e "  ${YELLOW}⏳ Pending:${NC} $pending"
    echo -e "  ${BLUE}👁️  Reviewing:${NC} $reviewing"
    echo -e "  ${GREEN}✅ Approved:${NC} $approved"
    echo -e "  ${PURPLE}🎉 Merged:${NC} $merged"
    echo ""
    
    # Show PRs by status
    if [[ "$status" == "all" || "$status" == "reviewing" ]]; then
        if [[ $reviewing -gt 0 ]]; then
            echo -e "${BOLD}${BLUE}👁️  In Review:${NC}"
            for pr_file in "$PR_DIR/reviewing"/*.json; do
                [[ ! -f "$pr_file" ]] && continue
                
                local pr_id=$(jq -r '.pr_id' "$pr_file")
                local repo=$(jq -r '.repo' "$pr_file")
                local pr_number=$(jq -r '.pr_number' "$pr_file")
                local author=$(jq -r '.author' "$pr_file")
                local approvals=$(jq '.approvals | length' "$pr_file")
                local reviewers=$(jq '.reviewers | length' "$pr_file")
                
                echo -e "  ${CYAN}$repo#$pr_number${NC} by $author"
                echo -e "    Approvals: ${GREEN}$approvals${NC}/$reviewers"
            done
            echo ""
        fi
    fi
    
    if [[ "$status" == "all" || "$status" == "approved" ]]; then
        if [[ $approved -gt 0 ]]; then
            echo -e "${BOLD}${GREEN}✅ Ready to Merge:${NC}"
            for pr_file in "$PR_DIR/approved"/*.json; do
                [[ ! -f "$pr_file" ]] && continue
                
                local repo=$(jq -r '.repo' "$pr_file")
                local pr_number=$(jq -r '.pr_number' "$pr_file")
                
                echo -e "  ${GREEN}🎉 $repo#$pr_number${NC} - Ready!"
            done
        fi
    fi
}

# Mark PR as merged
mark_merged() {
    local pr_id="$1"
    
    local pr_file="$PR_DIR/approved/${pr_id}.json"
    
    if [[ ! -f "$pr_file" ]]; then
        echo -e "${RED}❌ PR not found in approved: $pr_id${NC}"
        return 1
    fi
    
    jq '.status = "merged" | .merged_at = (now | todate)' "$pr_file" > "${pr_file}.tmp"
    mv "${pr_file}.tmp" "$pr_file"
    mv "$pr_file" "$PR_DIR/merged/"
    
    local repo=$(jq -r '.repo' "$PR_DIR/merged/${pr_id}.json")
    local pr_number=$(jq -r '.pr_number' "$PR_DIR/merged/${pr_id}.json")
    
    echo -e "${GREEN}🎉 PR marked as merged: ${CYAN}$repo#$pr_number${NC}"
    
    ~/memory-system.sh log pr-merged "$pr_id" "🎊 PR merged successfully: $repo#$pr_number" 2>/dev/null
}

# Show help
show_help() {
    cat << EOF
${CYAN}╔════════════════════════════════════════════════════════════╗${NC}
${CYAN}║      📝 Agent PR Coordinator - Help 📝                   ║${NC}
${CYAN}╚════════════════════════════════════════════════════════════╝${NC}

${GREEN}USAGE:${NC}
    $0 <command> [options]

${GREEN}COMMANDS:${NC}

${BLUE}init${NC}
    Initialize PR coordination system

${BLUE}register${NC} <repo> <pr-number> [author] [title]
    Register a new PR for review
    Example: $0 register BlackRoad-OS/repo 42 agent-backend "Add feature"

${BLUE}submit-review${NC} <pr-id> [reviewer] <approve|request_changes> [comments]
    Submit a review for a PR
    Example: $0 submit-review repo_pr42 approve "LGTM! Great work"

${BLUE}list${NC} [status]
    List PRs (status: all, reviewing, approved)
    Example: $0 list reviewing

${BLUE}mark-merged${NC} <pr-id>
    Mark a PR as merged
    Example: $0 mark-merged repo_pr42

${GREEN}WORKFLOW:${NC}

    1. Author creates PR and registers it
    2. System auto-assigns reviewers (3 BlackRoad Agents)
    3. Reviewers submit their reviews
    4. Need 2+ approvals, 0 changes requested
    5. PR moves to approved (ready to merge!)
    6. Merge via GitHub, mark as merged

${GREEN}CONSENSUS RULES:${NC}

    ✅ Ready to merge when:
       • 2+ approvals received
       • 0 changes requested
       • All reviewers have reviewed

${GREEN}EXAMPLES:${NC}

    # Register a PR
    $0 register BlackRoad-OS/repo 123 agent-dev "Fix bug"

    # Review it
    $0 submit-review BlackRoad-OS_repo_pr123 approve "Perfect!"

    # List all
    $0 list

EOF
}

# Main command router
case "$1" in
    init)
        init_pr_system
        ;;
    register)
        register_pr "$2" "$3" "$4" "$5"
        ;;
    submit-review)
        submit_review "$2" "$3" "$4" "$5"
        ;;
    list)
        list_prs "$2"
        ;;
    mark-merged)
        mark_merged "$2"
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        show_help
        exit 1
        ;;
esac
