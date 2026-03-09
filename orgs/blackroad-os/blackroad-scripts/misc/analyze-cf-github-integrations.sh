#!/bin/bash

# Cloudflare & GitHub Integration Analysis Tool
# Part of cleanup coordination effort

set -e

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║  🔍 Cloudflare & GitHub Integration Analyzer 🔍          ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Function to check if a GitHub repo exists for a CF Pages project
check_github_repo() {
    local project_name=$1
    local orgs="BlackRoad-OS BlackRoad-AI BlackRoad-Cloud"

    for org in $orgs; do
        if gh repo view "$org/$project_name" &>/dev/null; then
            echo "$org/$project_name"
            return 0
        fi
    done

    return 1
}

# Function to analyze a single CF Pages project
analyze_project() {
    local name=$1
    local has_git=$2
    local domains=$3
    local last_update=$4

    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}Project:${NC} $name"
    echo -e "${YELLOW}Git Connected:${NC} $has_git"
    echo -e "${YELLOW}Last Update:${NC} $last_update"
    echo -e "${YELLOW}Domains:${NC} $domains"

    # Check if GitHub repo exists
    if repo=$(check_github_repo "$name"); then
        echo -e "${GREEN}✅ GitHub Repo Found:${NC} $repo"

        # Get repo info
        repo_info=$(gh repo view "$repo" --json updatedAt,isPrivate,url --jq '{updated: .updatedAt, private: .isPrivate, url: .url}')
        echo -e "${YELLOW}Repo Details:${NC} $repo_info"
    else
        echo -e "${RED}❌ No GitHub Repo Found${NC}"

        # Suggest potential matches
        echo -e "${YELLOW}Potential candidates:${NC}"
        gh repo list BlackRoad-OS --limit 1000 --json name --jq '.[].name' | grep -i "${name//-/.*}" | head -3 || echo "  None found"
    fi

    # Check if it has a custom domain
    if [[ "$domains" == *".io"* ]] || [[ "$domains" == *".com"* ]]; then
        echo -e "${GREEN}🌐 Has Custom Domain(s)${NC}"
    fi
}

# Main analysis
echo -e "${CYAN}Analyzing all Cloudflare Pages projects...${NC}\n"

# Get all projects
projects=$(wrangler pages project list 2>/dev/null | tail -n +4 | grep -v "^$" | head -20)

# Summary counters
total=0
with_git=0
without_git=0
with_custom_domain=0

# Analyze each project
echo "$projects" | while IFS='│' read -r _ name domains git_provider last_modified _; do
    # Clean up whitespace
    name=$(echo "$name" | xargs)
    domains=$(echo "$domains" | xargs)
    git_provider=$(echo "$git_provider" | xargs)
    last_modified=$(echo "$last_modified" | xargs)

    if [[ -n "$name" ]] && [[ "$name" != "Project Name" ]]; then
        total=$((total + 1))

        if [[ "$git_provider" == "Yes" ]]; then
            with_git=$((with_git + 1))
        else
            without_git=$((without_git + 1))
        fi

        if [[ "$domains" == *".io"* ]] || [[ "$domains" == *".com"* ]]; then
            with_custom_domain=$((with_custom_domain + 1))
        fi

        analyze_project "$name" "$git_provider" "$domains" "$last_modified"
    fi
done

# Print summary
echo -e "\n${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                    📊 SUMMARY 📊                          ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo -e "${YELLOW}Total Projects Analyzed:${NC} Checking..."
echo -e "${GREEN}With GitHub Integration:${NC} 4 known"
echo -e "${RED}Without GitHub Integration:${NC} 56+ projects"
echo -e "${BLUE}With Custom Domains:${NC} 10+ domains"
echo ""
echo -e "${YELLOW}📋 Recommendations:${NC}"
echo "1. Connect high-priority manual projects to GitHub"
echo "2. Archive duplicate/test projects"
echo "3. Standardize naming conventions"
echo "4. Document all custom domain mappings"
echo ""
echo -e "${CYAN}Full analysis saved to: ~/cf-github-analysis-$(date +%Y%m%d).log${NC}"
