#!/bin/zsh
# BR Org Audit — scan GitHub orgs for empty repos, missing CI, outdated code

GREEN='\033[0;32m'; RED='\033[0;31m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

ORG="${2:-BlackRoad-OS}"

cmd_empty() {
    echo -e "${CYAN}🔍 Scanning ${ORG} for empty/sparse repos...${NC}\n"
    local empty=0 sparse=0
    gh api "orgs/$ORG/repos?per_page=100&sort=pushed&direction=asc" --jq '.[].name' 2>/dev/null | while read repo; do
        local count=$(gh api "repos/$ORG/$repo/contents" --jq 'length' 2>/dev/null || echo 0)
        if [[ "$count" -eq 0 ]]; then
            echo -e "  ${RED}EMPTY${NC}  $repo"
        elif [[ "$count" -le 3 ]]; then
            echo -e "  ${YELLOW}SPARSE${NC} $repo ($count files)"
        fi
    done
}

cmd_no_ci() {
    echo -e "${CYAN}🔍 Scanning ${ORG} for repos missing CI...${NC}\n"
    gh api "orgs/$ORG/repos?per_page=100" --jq '.[].name' 2>/dev/null | while read repo; do
        local has_ci=$(gh api "repos/$ORG/$repo/contents/.github/workflows" --jq 'length' 2>/dev/null || echo 0)
        [[ "$has_ci" -eq 0 ]] && echo -e "  ${YELLOW}NO CI${NC} $repo"
    done
}

cmd_stale() {
    echo -e "${CYAN}📅 Repos not pushed in 30+ days...${NC}\n"
    local cutoff=$(date -v -30d +%Y-%m-%dT 2>/dev/null || date -d '30 days ago' +%Y-%m-%dT 2>/dev/null)
    gh api "orgs/$ORG/repos?per_page=100&sort=pushed&direction=asc" \
        --jq ".[] | select(.pushed_at < \"$cutoff\") | .name + \" (\" + .pushed_at[:10] + \")\"" 2>/dev/null | \
        while read line; do echo -e "  ${YELLOW}STALE${NC} $line"; done
}

cmd_summary() {
    echo -e "${CYAN}📊 ${ORG} Summary${NC}\n"
    local data=$(gh api "orgs/$ORG/repos?per_page=100" 2>/dev/null)
    local total=$(echo "$data" | python3 -c "import json,sys; d=json.load(sys.stdin); print(len(d))" 2>/dev/null)
    local forks=$(echo "$data" | python3 -c "import json,sys; d=json.load(sys.stdin); print(sum(1 for r in d if r.get('fork')))" 2>/dev/null)
    local original=$((total - forks))
    local stars=$(echo "$data" | python3 -c "import json,sys; d=json.load(sys.stdin); print(sum(r.get('stargazers_count',0) for r in d))" 2>/dev/null)
    echo -e "  Total repos:     ${BLUE}$total${NC}"
    echo -e "  Original:        ${GREEN}$original${NC}"
    echo -e "  Forks:           ${YELLOW}$forks${NC}"
    echo -e "  Total stars:     ${BLUE}$stars${NC}"
    echo ""
    echo -e "  ${CYAN}Last 5 pushed:${NC}"
    gh api "orgs/$ORG/repos?per_page=5&sort=pushed&direction=desc" --jq '.[] | "  ✓ " + .name + " (" + .pushed_at[:10] + ")"' 2>/dev/null
}

show_help() {
    echo -e "${CYAN}BR Org Audit${NC}"
    echo "  br audit empty [org]    Find empty/sparse repos"
    echo "  br audit no-ci [org]    Find repos missing CI"
    echo "  br audit stale [org]    Find stale repos"
    echo "  br audit summary [org]  Org summary stats"
    echo ""
    echo "  Default org: BlackRoad-OS"
}

case "${1:-summary}" in
    empty)   cmd_empty ;;
    no-ci)   cmd_no_ci ;;
    stale)   cmd_stale ;;
    summary) cmd_summary ;;
    *)       show_help ;;
esac
