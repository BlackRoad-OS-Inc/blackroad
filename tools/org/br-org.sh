#!/usr/bin/env zsh
# BR Org — GitHub organization management across all 17 BlackRoad orgs
# br org [list|status|repos|sparse|stats|sync|enrich|dirty|stale|push]

AMBER='\033[38;5;214m'
VIOLET='\033[38;5;135m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
DIM='\033[2m'
BOLD='\033[1m'
NC='\033[0m'

BR_ROOT="${BR_ROOT:-$HOME/blackroad}"
DB="$HOME/.blackroad/org-sync.db"
mkdir -p "$(dirname "$DB")"

# All 17 BlackRoad organizations
ALL_ORGS=(
    BlackRoad-OS-Inc
    BlackRoad-OS
    blackboxprogramming
    BlackRoad-AI
    BlackRoad-Cloud
    BlackRoad-Security
    BlackRoad-Media
    BlackRoad-Foundation
    BlackRoad-Interactive
    BlackRoad-Hardware
    BlackRoad-Labs
    BlackRoad-Studio
    BlackRoad-Ventures
    BlackRoad-Education
    BlackRoad-Gov
    Blackbox-Enterprises
    BlackRoad-Archive
)

init_db() {
    sqlite3 "$DB" <<'SQL'
CREATE TABLE IF NOT EXISTS repo_state (
    name        TEXT PRIMARY KEY,
    org         TEXT,
    last_push   TEXT,
    last_sha    TEXT,
    local_path  TEXT,
    dirty       INTEGER DEFAULT 0,
    ahead       INTEGER DEFAULT 0,
    status      TEXT DEFAULT 'unknown',
    updated_at  TEXT DEFAULT (datetime('now'))
);
SQL
}
init_db

hr()  { echo -e "${DIM}────────────────────────────────────────────────────────────────${NC}"; }
hdr() { echo; echo -e "${VIOLET}◈ $1${NC}"; hr; }

# ── list: all 17 orgs with repo counts ───────────────────────────────────────
cmd_list() {
    hdr "ALL 17 BLACKROAD ORGANIZATIONS"
    printf "  ${DIM}%-30s  %-8s  %s${NC}\n" "ORG" "REPOS" "TYPE"
    hr

    local total_orgs=0 total_repos=0
    for org in "${ALL_ORGS[@]}"; do
        local count
        count=$(gh api "orgs/$org" --jq '.public_repos' 2>/dev/null || echo "?")
        local private_count
        private_count=$(gh api "orgs/$org" --jq '.total_private_repos' 2>/dev/null || echo "0")
        local org_type="${DIM}public${NC}"
        [[ "$org" == "BlackRoad-OS-Inc" ]] && org_type="${RED}CORP${NC}"
        [[ "$org" == "blackboxprogramming" ]] && org_type="${AMBER}personal${NC}"

        printf "  ${CYAN}%-30s${NC}  " "$org"
        if [[ "$count" =~ ^[0-9]+$ ]]; then
            local display_count=$(( count + ${private_count:-0} ))
            printf "${GREEN}%-8s${NC}" "$display_count"
            total_repos=$(( total_repos + display_count ))
        else
            printf "${YELLOW}%-8s${NC}" "?"
        fi
        printf "  %b\n" "$org_type"
        total_orgs=$(( total_orgs + 1 ))
    done

    hr
    echo -e "  ${BOLD}Total: ${total_orgs} orgs · ${GREEN}${total_repos}${NC}${BOLD} repos${NC}"
    echo ""
}

# ── status: quick overview of each org ───────────────────────────────────────
cmd_status() {
    hdr "ORG STATUS OVERVIEW"
    printf "  ${DIM}%-30s  %-8s  %-8s  %s${NC}\n" "ORG" "PUBLIC" "PRIVATE" "LAST PUSH"
    hr

    for org in "${ALL_ORGS[@]}"; do
        local pub priv last_push
        pub=$(gh api "orgs/$org" --jq '.public_repos' 2>/dev/null || echo "?")
        priv=$(gh api "orgs/$org" --jq '.total_private_repos' 2>/dev/null || echo "?")
        last_push=$(gh repo list "$org" --limit 1 --json pushedAt \
            --jq '.[0].pushedAt[:10]' 2>/dev/null || echo "unknown")

        local pub_col="${GREEN}${pub}${NC}"
        local priv_col="${DIM}${priv}${NC}"
        [[ "$priv" =~ ^[0-9]+$ && "$priv" -gt 0 ]] && priv_col="${AMBER}${priv}${NC}"

        printf "  ${CYAN}%-30s${NC}  %b  %b  ${DIM}%s${NC}\n" \
            "$org" "${pub_col}" "${priv_col}" "${last_push}"
    done
    echo ""
}

# ── repos: list repos for a specific org ─────────────────────────────────────
cmd_repos() {
    local org="${1:-BlackRoad-OS}"
    hdr "REPOS — ${org}"
    printf "  ${DIM}%-40s  %-6s  %-10s  %s${NC}\n" "NAME" "STARS" "PUSHED" "DESCRIPTION"
    hr

    gh repo list "$org" --limit 100 \
        --json name,stargazersCount,pushedAt,description,isPrivate,isFork \
        --jq '.[] | [.name, (.stargazersCount|tostring), .pushedAt[:10], (if .isPrivate then "🔒" else "  " end), (if .isFork then "⎇" else " " end), (.description // "")] | @tsv' \
        2>/dev/null | sort | while IFS=$'\t' read -r name stars pushed priv fork desc; do
            local name_col="${CYAN}${name}${NC}"
            [[ "$fork" == "⎇" ]] && name_col="${DIM}${name}${NC}"
            local stars_col="${DIM}${stars}${NC}"
            [[ "$stars" -gt 0 ]] 2>/dev/null && stars_col="${YELLOW}★${stars}${NC}"
            printf "  %b  %-6s  %-10s  %s %s ${DIM}%s${NC}\n" \
                "$name_col" "$stars_col" "$pushed" "$priv" "$fork" "$desc"
        done
    echo ""
}

# ── sparse: repos needing enrichment (no description or README) ───────────────
cmd_sparse() {
    local org="${1:-BlackRoad-OS}"
    hdr "SPARSE REPOS — ${org}"
    echo -e "  ${DIM}Repos with no description or likely missing README:${NC}"
    echo ""

    local sparse_count=0
    gh repo list "$org" --limit 100 \
        --json name,description,pushedAt,isFork \
        --jq '.[] | [.name, (.description // ""), .pushedAt[:10], (.isFork|tostring)] | @tsv' \
        2>/dev/null | while IFS=$'\t' read -r name desc pushed is_fork; do
            local flags=""
            [[ -z "$desc" ]] && flags="${flags}${RED}NO DESC${NC} "
            [[ "$is_fork" == "true" ]] && flags="${flags}${DIM}fork${NC} "
            if [[ -z "$desc" ]]; then
                printf "  ${YELLOW}%-40s${NC}  %b  ${DIM}%s${NC}\n" "$name" "$flags" "$pushed"
                sparse_count=$(( sparse_count + 1 ))
            fi
        done

    echo ""
    echo -e "  ${DIM}Run: br org enrich ${org}  to see full enrichment plan${NC}"
    echo ""
}

# ── stats: totals across all orgs ────────────────────────────────────────────
cmd_stats() {
    hdr "STATS ACROSS ALL 17 ORGS"
    echo -e "  ${DIM}Fetching data (this may take a moment)...${NC}"
    echo ""

    local total_repos=0 total_forks=0 total_stars=0 total_private=0

    for org in "${ALL_ORGS[@]}"; do
        local data
        data=$(gh api "orgs/$org" 2>/dev/null)
        local pub priv
        pub=$(echo "$data" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('public_repos',0))" 2>/dev/null || echo 0)
        priv=$(echo "$data" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('total_private_repos',0))" 2>/dev/null || echo 0)
        total_repos=$(( total_repos + pub + priv ))
        total_private=$(( total_private + priv ))
        printf "  ${CYAN}%-30s${NC}  ${DIM}%d repos${NC}\n" "$org" "$(( pub + priv ))"
    done

    hr
    echo ""
    echo -e "  ${BOLD}TOTALS${NC}"
    printf "  %-22s  ${GREEN}%d${NC}\n" "Total repos" "$total_repos"
    printf "  %-22s  ${AMBER}%d${NC}\n" "Private repos" "$total_private"
    printf "  %-22s  ${DIM}%d${NC}\n" "Organizations" "${#ALL_ORGS[@]}"
    echo ""
}

# ── sync: trigger org enrichment ─────────────────────────────────────────────
cmd_sync() {
    hdr "ORG ENRICHMENT SYNC"
    echo -e "  ${CYAN}Scanning all orgs for sparse repos...${NC}"
    echo ""

    local total_sparse=0
    for org in "${ALL_ORGS[@]}"; do
        local sparse
        sparse=$(gh repo list "$org" --limit 100 \
            --json name,description \
            --jq '[.[] | select(.description == null or .description == "")] | length' \
            2>/dev/null || echo "0")
        if [[ "$sparse" =~ ^[0-9]+$ && "$sparse" -gt 0 ]]; then
            echo -e "  ${YELLOW}${org}${NC}  ${DIM}${sparse} repos need description${NC}"
            total_sparse=$(( total_sparse + sparse ))
        fi
    done

    echo ""
    hr
    echo -e "  ${BOLD}Would run enrichment agents for ${YELLOW}${total_sparse}${NC}${BOLD} sparse repos across all orgs${NC}"
    echo -e "  ${DIM}Run: br org enrich <ORG> to target a specific org${NC}"
    echo ""
}

# ── enrich: repos needing enrichment in a specific org ───────────────────────
cmd_enrich() {
    local org="${1:-BlackRoad-OS}"
    hdr "ENRICHMENT PLAN — ${org}"
    echo -e "  ${DIM}Checking repos for missing README, CI, or description...${NC}"
    echo ""

    local needs_desc=0 needs_ci=0 is_empty=0

    gh repo list "$org" --limit 100 \
        --json name,description,pushedAt,isEmpty \
        --jq '.[] | [.name, (.description // ""), .pushedAt[:10], (.isEmpty|tostring)] | @tsv' \
        2>/dev/null | while IFS=$'\t' read -r name desc pushed empty; do
            local issues=""
            [[ -z "$desc" ]]          && issues="${issues}${RED}[no desc]${NC} "
            [[ "$empty" == "true" ]]  && issues="${issues}${RED}[empty]${NC} "

            if [[ -n "$issues" ]]; then
                printf "  ${CYAN}%-40s${NC}  %b  ${DIM}%s${NC}\n" "$name" "$issues" "$pushed"
            fi
        done

    echo ""
    echo -e "  ${DIM}To enrich: add descriptions via gh repo edit <REPO> --description '...'${NC}"
    echo ""
}

# ── local subrepo status ──────────────────────────────────────────────────────
cmd_local_status() {
    hdr "LOCAL SUBREPO STATUS"
    printf "  ${DIM}%-28s  %-8s  %-6s  %-6s  %s${NC}\n" "REPO" "BRANCH" "DIRTY" "AHEAD" "LAST COMMIT"
    hr

    local found=0
    for dir in "$BR_ROOT"/blackroad-*/; do
        [[ -d "$dir/.git" ]] || continue
        found=$(( found + 1 ))
        local name branch dirty ahead msg
        name=$(basename "$dir")
        branch=$(cd "$dir" && git branch --show-current 2>/dev/null || echo "?")
        dirty=$(cd "$dir" && git status --short 2>/dev/null | wc -l | tr -d ' ')
        ahead=$(cd "$dir" && git --no-pager log --oneline @{u}.. 2>/dev/null | wc -l | tr -d ' ')
        msg=$(cd "$dir" && git --no-pager log -1 --format="%s" 2>/dev/null | cut -c1-35 || echo "—")

        local dirty_col="${DIM}0${NC}"
        [[ "$dirty" -gt 0 ]] && dirty_col="${AMBER}${dirty}${NC}"
        local ahead_col="${DIM}0${NC}"
        [[ "$ahead" -gt 0 ]] && ahead_col="${GREEN}${ahead}${NC}"

        printf "  ${CYAN}%-28s${NC}  %-8s  %b      %b      ${DIM}%s${NC}\n" \
            "$name" "$branch" "$dirty_col" "$ahead_col" "$msg"

        sqlite3 "$DB" "INSERT OR REPLACE INTO repo_state
            (name, org, local_path, dirty, ahead, status, updated_at)
            VALUES ('$name','${BR_ORG:-BlackRoad-OS-Inc}','$dir','$dirty','$ahead',
            '$([ "$dirty" -gt 0 ] && echo dirty || echo clean)',
            datetime('now'));" 2>/dev/null
    done

    [[ $found -eq 0 ]] && echo "  ${DIM}No blackroad-* dirs with git found in $BR_ROOT${NC}"
    echo ""
}

# ── dirty: repos with uncommitted changes ─────────────────────────────────────
cmd_dirty() {
    hdr "DIRTY LOCAL REPOS"
    local found=0
    for dir in "$BR_ROOT"/blackroad-*/; do
        [[ -d "$dir/.git" ]] || continue
        local dirty
        dirty=$(cd "$dir" && git status --short 2>/dev/null | wc -l | tr -d ' ')
        [[ "$dirty" -eq 0 ]] && continue
        found=$(( found + 1 ))
        local name branch msg
        name=$(basename "$dir")
        branch=$(cd "$dir" && git branch --show-current 2>/dev/null || echo "?")
        msg=$(cd "$dir" && git --no-pager log -1 --format="%s" 2>/dev/null | cut -c1-50)
        printf "  ${AMBER}%-28s${NC}  %s  ${DIM}+%s changes${NC}  %s\n" "$name" "$branch" "$dirty" "$msg"
    done
    [[ $found -eq 0 ]] && echo "  ${GREEN}All local repos clean${NC}"
    echo ""
}

# ── stale: repos not pushed in N days ─────────────────────────────────────────
cmd_stale() {
    local org="${1:-BlackRoad-OS}" days="${2:-7}"
    hdr "STALE REPOS — ${org}  (no push in ${days}d)"
    gh repo list "$org" --limit 100 --json name,pushedAt \
        --jq --argjson days "$days" \
        '.[] | select((.pushedAt | fromdateiso8601) < (now - ($days * 86400))) | [.name, .pushedAt[:10]] | @tsv' \
        2>/dev/null | while IFS=$'\t' read -r name pushed; do
            printf "  ${RED}%-38s${NC}  ${DIM}last push: %s${NC}\n" "$name" "$pushed"
        done
    echo ""
}

# ── push a specific local subrepo ─────────────────────────────────────────────
cmd_push() {
    local target="$1"
    [[ -z "$target" ]] && { echo "  Usage: br org push <repo-name>"; return 1; }
    local dir="$BR_ROOT/$target"
    [[ -d "$dir/.git" ]] || { echo "  ${RED}Not found: $dir${NC}"; return 1; }

    echo -e "  ${CYAN}Pushing ${target}...${NC}"
    cd "$dir" || return 1
    local dirty
    dirty=$(git status --short 2>/dev/null | wc -l | tr -d ' ')
    if [[ "$dirty" -gt 0 ]]; then
        git add -A
        git commit -m "chore: sync from blackroad operator" \
            --trailer "Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>" \
            2>&1 | tail -2
    fi
    git push 2>&1 | tail -3
    echo -e "  ${GREEN}✓ $target pushed${NC}"
}

# ── summary card ──────────────────────────────────────────────────────────────
cmd_summary() {
    hdr "ORG SUMMARY  ${DIM}BlackRoad OS, Inc.${NC}"

    local total_repos=0
    for org in "${ALL_ORGS[@]}"; do
        local count
        count=$(gh api "orgs/$org" --jq '.public_repos' 2>/dev/null || echo 0)
        total_repos=$(( total_repos + ${count:-0} ))
    done

    local local_count=0 dirty_count=0
    for dir in "$BR_ROOT"/blackroad-*/; do
        [[ -d "$dir/.git" ]] || continue
        local_count=$(( local_count + 1 ))
        local dirty
        dirty=$(cd "$dir" && git status --short 2>/dev/null | wc -l | tr -d ' ')
        [[ "$dirty" -gt 0 ]] && dirty_count=$(( dirty_count + 1 ))
    done

    printf "  %-22s  ${GREEN}%d${NC}\n"  "Organizations"  "${#ALL_ORGS[@]}"
    printf "  %-22s  ${GREEN}%d${NC}\n"  "GitHub repos"   "$total_repos"
    printf "  %-22s  ${CYAN}%d${NC}\n"   "Local subrepos" "$local_count"
    printf "  %-22s  ${AMBER}%d${NC}\n"  "Dirty local"    "$dirty_count"
    echo ""
}

show_help() {
    echo ""
    echo -e "  ${VIOLET}${BOLD}BR ORG${NC} — GitHub org management across all 17 BlackRoad orgs"
    echo ""
    echo -e "  ${CYAN}br org list${NC}               List all 17 orgs with repo counts"
    echo -e "  ${CYAN}br org status${NC}             Quick overview of each org"
    echo -e "  ${CYAN}br org repos <ORG>${NC}        List repos for a specific org"
    echo -e "  ${CYAN}br org sparse <ORG>${NC}       Repos with no description (need enrichment)"
    echo -e "  ${CYAN}br org stats${NC}              Totals across all orgs"
    echo -e "  ${CYAN}br org sync${NC}               Scan for sparse repos, show enrichment plan"
    echo -e "  ${CYAN}br org enrich <ORG>${NC}       Full enrichment plan for an org"
    echo -e "  ${CYAN}br org dirty${NC}              Local repos with uncommitted changes"
    echo -e "  ${CYAN}br org stale <ORG> [days]${NC} Repos not pushed in N days (default 7)"
    echo -e "  ${CYAN}br org push <repo>${NC}        Commit + push a local subrepo"
    echo ""
    echo -e "  ${DIM}Orgs: ${#ALL_ORGS[@]} total · Set \$BR_ORG to change default org${NC}"
    echo ""
}

case "${1:-summary}" in
    list|ls)            cmd_list ;;
    status|st)          cmd_local_status ;;
    repos|repo)         cmd_repos "${2:-BlackRoad-OS}" ;;
    sparse)             cmd_sparse "${2:-BlackRoad-OS}" ;;
    stats)              cmd_stats ;;
    sync)               cmd_sync ;;
    enrich)             cmd_enrich "${2:-BlackRoad-OS}" ;;
    dirty|changes)      cmd_dirty ;;
    stale)              cmd_stale "${2:-BlackRoad-OS}" "${3:-7}" ;;
    push)               cmd_push "$2" ;;
    summary|"")         cmd_summary ;;
    help|--help|-h)     show_help ;;
    *)                  cmd_summary ;;
esac
