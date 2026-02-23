#!/bin/zsh
# BR git-graph — Visual git history, branch topology, contributor stats

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'
BLUE='\033[0;34m'; MAGENTA='\033[0;35m'; BOLD='\033[1m'; NC='\033[0m'

cmd_log() {
    local limit="${1:-20}"
    echo -e "${BOLD}${BLUE}📊 Git Graph${NC}\n"
    git --no-pager log \
        --graph \
        --pretty=format:"${CYAN}%h${NC} ${YELLOW}%D${NC} ${NC}%s ${MAGENTA}(%an)${NC} ${BLUE}%ar${NC}" \
        --abbrev-commit \
        --all \
        -n "$limit" \
        --color=always 2>/dev/null \
        | sed 's/%NC/\x1b[0m/g' \
        | head -"$((limit * 3))"
    echo ""
}

cmd_branches() {
    echo -e "${BOLD}${BLUE}🌿 Branches${NC}\n"
    # Local branches with last commit
    echo -e "  ${BOLD}Local:${NC}"
    git --no-pager branch -v --sort=-committerdate 2>/dev/null | while read -r line; do
        if echo "$line" | grep -q '^\*'; then
            echo -e "  ${GREEN}$line${NC}"
        else
            echo -e "  ${CYAN}$line${NC}"
        fi
    done
    echo ""
    echo -e "  ${BOLD}Remote:${NC}"
    git --no-pager branch -rv --sort=-committerdate 2>/dev/null | grep -v 'HEAD' | head -10 | while read -r line; do
        echo -e "  ${YELLOW}$line${NC}"
    done
}

cmd_stats() {
    local since="${1:-1 month ago}"
    echo -e "${BOLD}${BLUE}📈 Contributor Stats${NC} (since: $since)\n"

    echo -e "  ${BOLD}Commits by author:${NC}"
    git --no-pager shortlog -sn --since="$since" --all 2>/dev/null | while read -r count author; do
        local bar=$(printf '█%.0s' $(seq 1 $((count > 40 ? 40 : count))))
        printf "  %-20s ${CYAN}%4d${NC} ${GREEN}%s${NC}\n" "$author" "$count" "$bar"
    done
    echo ""

    echo -e "  ${BOLD}Files changed most:${NC}"
    git --no-pager log --since="$since" --name-only --pretty=format: 2>/dev/null \
        | grep -v '^$' | sort | uniq -c | sort -rn | head -10 \
        | while read -r count file; do
            printf "  %-45s ${CYAN}%d${NC} changes\n" "$file" "$count"
        done
    echo ""

    echo -e "  ${BOLD}Activity by day:${NC}"
    git --no-pager log --since="7 days ago" --pretty=format:"%ad" --date=format:"%a %Y-%m-%d" 2>/dev/null \
        | sort | uniq -c | while read -r count day; do
            local bar=$(printf '█%.0s' $(seq 1 $((count > 30 ? 30 : count))))
            printf "  %-15s ${CYAN}%3d${NC} ${BLUE}%s${NC}\n" "$day" "$count" "$bar"
        done
}

cmd_diff_stat() {
    local ref="${1:-HEAD~10}"
    echo -e "${BOLD}${BLUE}📄 Diff Stats${NC} since $ref\n"
    git --no-pager diff --stat "$ref" 2>/dev/null || git --no-pager diff --stat HEAD~1 2>/dev/null
    echo ""
    echo -e "  ${BOLD}Lines changed:${NC}"
    git --no-pager diff --shortstat "$ref" 2>/dev/null
}

cmd_blame_summary() {
    local file="$1"
    [[ -z "$file" ]] && echo -e "${RED}✗ Usage: br git-graph blame <file>${NC}" && return 1
    [[ ! -f "$file" ]] && echo -e "${RED}✗ File not found: $file${NC}" && return 1
    echo -e "${BOLD}${BLUE}👤 Blame Summary${NC}: $file\n"
    git --no-pager blame --line-porcelain "$file" 2>/dev/null \
        | grep '^author ' | sort | uniq -c | sort -rn \
        | while read -r count author; do
            author="${author#author }"
            printf "  %-25s ${CYAN}%d${NC} lines\n" "$author" "$count"
        done
}

cmd_timeline() {
    local days="${1:-30}"
    echo -e "${BOLD}${BLUE}📅 Commit Timeline${NC} (last $days days)\n"
    local today=$(date +%Y-%m-%d)
    for i in $(seq $((days-1)) -1 0); do
        local day
        day=$(date -v-${i}d +%Y-%m-%d 2>/dev/null || date -d "$i days ago" +%Y-%m-%d 2>/dev/null)
        local count
        count=$(git --no-pager log --oneline --after="${day}T00:00:00" --before="${day}T23:59:59" 2>/dev/null | wc -l | tr -d ' ')
        if [[ $count -gt 0 ]]; then
            local bar=$(printf '▪%.0s' $(seq 1 $((count > 20 ? 20 : count))))
            local color="$GREEN"
            [[ $count -gt 5 ]] && color="$CYAN"
            [[ $count -gt 10 ]] && color="$YELLOW"
            printf "  ${CYAN}%-12s${NC} ${color}%-22s${NC} ${BOLD}%d${NC}\n" "$day" "$bar" "$count"
        else
            printf "  ${CYAN}%-12s${NC} ${BLUE}·${NC}\n" "$day"
        fi
    done
}

cmd_recent() {
    local n="${1:-10}"
    echo -e "${BOLD}${BLUE}🕐 Recent Commits${NC}\n"
    git --no-pager log --oneline --color=always -"$n" 2>/dev/null | while read -r line; do
        local hash=$(echo "$line" | awk '{print $1}')
        local msg=$(echo "$line" | cut -d' ' -f2-)
        echo -e "  ${CYAN}$hash${NC} $msg"
    done
    echo ""
    echo -e "  ${BOLD}Last commit:${NC}"
    git --no-pager show --stat HEAD --no-patch 2>/dev/null | head -5
}

show_help() {
    echo -e "${BOLD}${BLUE}BR git-graph${NC} — Visual git history & stats\n"
    echo -e "${BOLD}Usage:${NC}"
    echo -e "  ${CYAN}br git-graph [n]${NC}             — Graph log (default: 20 commits)"
    echo -e "  ${CYAN}br git-graph branches${NC}         — Branch overview"
    echo -e "  ${CYAN}br git-graph stats [since]${NC}    — Contributor stats"
    echo -e "  ${CYAN}br git-graph timeline [days]${NC}  — Commit activity calendar"
    echo -e "  ${CYAN}br git-graph recent [n]${NC}       — Recent commits with stats"
    echo -e "  ${CYAN}br git-graph diff [ref]${NC}       — Diff stats since ref"
    echo -e "  ${CYAN}br git-graph blame <file>${NC}     — Blame summary by author\n"
    echo -e "${BOLD}Examples:${NC}"
    echo -e "  br git-graph 50"
    echo -e "  br git-graph stats '2 weeks ago'"
    echo -e "  br git-graph timeline 14"
    echo -e "  br git-graph blame src/auth.ts"
}

[[ ! -d .git ]] && git -C "$(git rev-parse --show-toplevel 2>/dev/null || echo .)" status &>/dev/null

case "${1:-log}" in
    log|graph|''|[0-9]*)   cmd_log "${1:-20}" ;;
    branches|branch|br)    cmd_branches ;;
    stats|contributors)    shift; cmd_stats "${*:-1 month ago}" ;;
    timeline|cal|calendar) cmd_timeline "${2:-30}" ;;
    recent|last)           cmd_recent "${2:-10}" ;;
    diff|changes)          cmd_diff_stat "${2:-HEAD~10}" ;;
    blame|authors)         cmd_blame_summary "$2" ;;
    help|--help|-h)        show_help ;;
    *)                     cmd_log "${1:-20}" ;;
esac
