#!/usr/bin/env zsh
# BR Org — GitHub org repo dashboard: status, push sync, stale detection
# br org [list|status|sync|stale|push <repo>]

AMBER=$'\033[38;5;214m'; PINK=$'\033[38;5;205m'; VIOLET=$'\033[38;5;135m'
CYAN=$'\033[0;36m'; GREEN=$'\033[0;32m'; RED=$'\033[0;31m'
YELLOW=$'\033[1;33m'; DIM=$'\033[2m'; BOLD=$'\033[1m'; NC=$'\033[0m'

BR_ROOT="${BR_ROOT:-$HOME/blackroad}"
ORG="${BR_ORG:-BlackRoad-OS-Inc}"
DB="$HOME/.blackroad/org-sync.db"

mkdir -p "$(dirname "$DB")"

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

hr()  { echo "${DIM}────────────────────────────────────────────────────────────────────${NC}"; }
hdr() { echo; echo "${VIOLET}◈ $1${NC}"; hr; }

# ── list all repos in org via gh ──────────────────────────────────────────────
cmd_list() {
    local limit="${1:-50}"
    hdr "REPOS  ${DIM}${ORG}${NC}"
    gh repo list "$ORG" --limit "$limit" --json name,pushedAt,isPrivate,defaultBranchRef \
        --jq '.[] | [.name, .pushedAt[:10], (if .isPrivate then "🔒" else "🌐" end), (.defaultBranchRef.name // "?")] | @tsv' \
        2>/dev/null | sort | while IFS=$'\t' read -r name pushed vis branch; do
            printf "  ${CYAN}%-38s${NC}  ${DIM}%-12s${NC}  %s  %s\n" \
                "$name" "$pushed" "$vis" "$branch"
        done
    echo
}

# ── status of local blackroad-* subrepos ────────────────────────────────────
cmd_status() {
    hdr "LOCAL SUBREPO STATUS  ${DIM}${ORG}${NC}"
    printf "  ${DIM}%-28s  %-8s  %-6s  %-6s  %s${NC}\n" "REPO" "BRANCH" "DIRTY" "AHEAD" "LAST COMMIT"

    local found=0
    for dir in "$BR_ROOT"/blackroad-*/; do
        [[ -d "$dir/.git" ]] || continue
        found=$((found+1))
        local name branch dirty ahead msg remote_url
        name=$(basename "$dir")
        branch=$(cd "$dir" && git branch --show-current 2>/dev/null || echo "?")
        dirty=$(cd "$dir" && git status --short 2>/dev/null | wc -l | tr -d ' ')
        ahead=$(cd "$dir" && git --no-pager log --oneline @{u}.. 2>/dev/null | wc -l | tr -d ' ')
        msg=$(cd "$dir" && git --no-pager log -1 --format="%s" 2>/dev/null | cut -c1-35 || echo "—")
        remote_url=$(cd "$dir" && git remote get-url origin 2>/dev/null | sed 's|.*github.com[:/]||' || echo "?")

        local dirty_col ahead_col
        dirty_col="${DIM}0${NC}"
        [[ "$dirty" -gt 0 ]] && dirty_col="${AMBER}${dirty}${NC}"
        ahead_col="${DIM}0${NC}"
        [[ "$ahead" -gt 0 ]] && ahead_col="${GREEN}${ahead}${NC}"

        printf "  ${CYAN}%-28s${NC}  %-8s  %b      %b      ${DIM}%s${NC}\n" \
            "$name" "$branch" "$dirty_col" "$ahead_col" "$msg"

        # Record in DB
        sqlite3 "$DB" "INSERT OR REPLACE INTO repo_state
            (name, org, local_path, dirty, ahead, status, updated_at)
            VALUES ('$name','$ORG','$dir','$dirty','$ahead',
            '$([ $dirty -gt 0 ] && echo dirty || echo clean)',
            datetime('now'));" 2>/dev/null
    done

    [[ $found -eq 0 ]] && echo "  ${DIM}No blackroad-* dirs with git found in $BR_ROOT${NC}"
    echo
}

# ── show only dirty repos ─────────────────────────────────────────────────────
cmd_dirty() {
    hdr "DIRTY REPOS"
    local found=0
    for dir in "$BR_ROOT"/blackroad-*/; do
        [[ -d "$dir/.git" ]] || continue
        local dirty
        dirty=$(cd "$dir" && git status --short 2>/dev/null | wc -l | tr -d ' ')
        [[ "$dirty" -eq 0 ]] && continue
        found=$((found+1))
        local name branch msg
        name=$(basename "$dir")
        branch=$(cd "$dir" && git branch --show-current 2>/dev/null || echo "?")
        msg=$(cd "$dir" && git --no-pager log -1 --format="%s" 2>/dev/null | cut -c1-50)
        printf "  ${AMBER}%-28s${NC}  %s  ${DIM}+%s changes${NC}  %s\n" "$name" "$branch" "$dirty" "$msg"
    done
    [[ $found -eq 0 ]] && echo "  ${GREEN}All repos clean${NC}"
    echo
}

# ── stale: repos not pushed in N days ────────────────────────────────────────
cmd_stale() {
    local days="${1:-7}"
    hdr "STALE REPOS  ${DIM}(no push in ${days}d)${NC}"
    gh repo list "$ORG" --limit 100 --json name,pushedAt \
        --jq --argjson days "$days" \
        '.[] | select((.pushedAt | fromdateiso8601) < (now - ($days * 86400))) | [.name, .pushedAt[:10]] | @tsv' \
        2>/dev/null | while IFS=$'\t' read -r name pushed; do
            printf "  ${RED}%-38s${NC}  ${DIM}last push: %s${NC}\n" "$name" "$pushed"
        done
    echo
}

# ── push a specific local subrepo ────────────────────────────────────────────
cmd_push() {
    local target="$1"
    [[ -z "$target" ]] && { echo "  Usage: br org push <repo-name>"; return 1; }

    local dir="$BR_ROOT/$target"
    [[ -d "$dir/.git" ]] || { echo "  ${RED}Not found: $dir${NC}"; return 1; }

    echo "  ${CYAN}Pushing ${target}...${NC}"
    cd "$dir" || return 1

    local dirty
    dirty=$(git status --short 2>/dev/null | wc -l | tr -d ' ')
    if [[ "$dirty" -gt 0 ]]; then
        git add -A
        git commit -m "chore: sync from blackroad operator" \
            --trailer "Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>" 2>&1 | tail -2
    fi

    git push 2>&1 | tail -3
    echo "  ${GREEN}✓ $target pushed${NC}"
}

# ── summary card ──────────────────────────────────────────────────────────────
cmd_summary() {
    hdr "ORG SUMMARY  ${DIM}${ORG}${NC}"

    # Count repos from GitHub
    local total_repos
    total_repos=$(gh repo list "$ORG" --limit 200 --json name --jq 'length' 2>/dev/null || echo "?")

    # Count local subrepos
    local local_count=0 dirty_count=0 dirty
    for dir in "$BR_ROOT"/blackroad-*/; do
        [[ -d "$dir/.git" ]] || continue
        local_count=$((local_count+1))
        dirty=$(cd "$dir" && git status --short 2>/dev/null | wc -l | tr -d ' ')
        [[ "$dirty" -gt 0 ]] && dirty_count=$((dirty_count+1))
    done

    printf "  ${YELLOW}GitHub repos${NC}      %s total in %s\n" "$total_repos" "$ORG"
    printf "  ${YELLOW}Local subrepos${NC}    %s tracked\n" "$local_count"
    printf "  ${YELLOW}Dirty${NC}             %s need commit/push\n" "$dirty_count"

    # Recent pushes
    echo
    echo "  ${DIM}Recent pushes (last 5):${NC}"
    gh repo list "$ORG" --limit 100 --json name,pushedAt \
        --jq 'sort_by(.pushedAt) | reverse | .[0:5] | .[] | "  • \(.name)  \(.pushedAt[:16])"' \
        2>/dev/null
    echo
}

show_help() {
    echo
    echo "${VIOLET}${BOLD}BR ORG${NC} — GitHub org repo dashboard"
    echo
    echo "  ${CYAN}br org${NC}                  Org summary card"
    echo "  ${CYAN}br org list [N]${NC}         List all repos (default 50)"
    echo "  ${CYAN}br org status${NC}           Local subrepo status (branch/dirty/ahead)"
    echo "  ${CYAN}br org dirty${NC}            Show only repos with uncommitted changes"
    echo "  ${CYAN}br org stale [days]${NC}     Repos not pushed in N days (default 7)"
    echo "  ${CYAN}br org push <repo>${NC}      Commit + push a specific local subrepo"
    echo
    echo "  ${DIM}Org: \$BR_ORG (default: BlackRoad-OS-Inc)${NC}"
    echo
}

case "${1:-summary}" in
    list|ls)        cmd_list "${2:-50}" ;;
    status|st)      cmd_status ;;
    dirty|changes)  cmd_dirty ;;
    stale)          cmd_stale "${2:-7}" ;;
    push)           cmd_push "$2" ;;
    summary|"")     cmd_summary ;;
    help|--help|-h) show_help ;;
    *)              cmd_summary ;;
esac
