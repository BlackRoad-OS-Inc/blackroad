#!/bin/zsh
# BR Deploy - Quick Deployment Manager
DEPLOY_HOME="/Users/alexa/blackroad/tools/deploy-manager"
DEPLOY_DB="${DEPLOY_HOME}/deployments.db"
GREEN='\033[0;32m'; RED='\033[0;31m'; BOLD='\033[1m'; DIM='\033[2m'
AMBER='\033[38;5;214m'; PINK='\033[38;5;205m'; VIOLET='\033[38;5;135m'; BBLUE='\033[38;5;69m'; NC='\033[0m'
CYAN="$AMBER"; YELLOW="$PINK"; BLUE="$BBLUE"; PURPLE="$VIOLET"

init_db() {
    [[ -f "$DEPLOY_DB" ]] && return
    mkdir -p "$DEPLOY_HOME"
    sqlite3 "$DEPLOY_DB" "CREATE TABLE deployments (id INTEGER PRIMARY KEY, project TEXT, platform TEXT, environment TEXT, version TEXT, status TEXT, deployed_at INTEGER, deployed_by TEXT);"
}

record() { sqlite3 "$DEPLOY_DB" "INSERT INTO deployments VALUES (NULL, '$1', '$2', '$3', '$4', '$5', $(date +%s), '$(whoami)');"; }

detect() {
    echo -e "  ${AMBER}${BOLD}◆ BR DEPLOY${NC}  ${DIM}detect${NC}"
    echo -e "  ${DIM}──────────────────────────────${NC}\n"
    [[ -f "vercel.json" ]] && echo -e "  ${GREEN}✓${NC} Vercel"
    [[ -f "netlify.toml" ]] && echo -e "  ${GREEN}✓${NC} Netlify"
    [[ -f "Procfile" ]] && echo -e "  ${GREEN}✓${NC} Heroku"
    [[ -f "Dockerfile" ]] && echo -e "  ${GREEN}✓${NC} Docker"
    echo -e "\n  ${DIM}br deploy <platform>${NC}"
}

deploy_vercel() {
    echo -e "  ${AMBER}${BOLD}◆ BR DEPLOY${NC}  ${DIM}vercel${NC}"
    echo -e "  ${DIM}──────────────────────────────${NC}\n"
    command -v vercel &>/dev/null || { echo -e "  ${RED}✗${NC} Install: npm i -g vercel"; return 1; }
    [[ "$1" == "prod" ]] && vercel --prod || vercel
    [[ $? -eq 0 ]] && echo -e "\n  ${GREEN}✓${NC} deployed" && record "$(basename $(pwd))" "vercel" "${1:-preview}" "latest" "success"
}

deploy_netlify() {
    echo -e "  ${AMBER}${BOLD}◆ BR DEPLOY${NC}  ${DIM}netlify${NC}"
    echo -e "  ${DIM}──────────────────────────────${NC}\n"
    command -v netlify &>/dev/null || { echo -e "  ${RED}✗${NC} Install: npm i -g netlify-cli"; return 1; }
    [[ "$1" == "prod" ]] && netlify deploy --prod || netlify deploy
    [[ $? -eq 0 ]] && echo -e "\n  ${GREEN}✓${NC} deployed" && record "$(basename $(pwd))" "netlify" "${1:-preview}" "latest" "success"
}

deploy_heroku() {
    echo -e "  ${AMBER}${BOLD}◆ BR DEPLOY${NC}  ${DIM}heroku${NC}"
    echo -e "  ${DIM}──────────────────────────────${NC}\n"
    command -v heroku &>/dev/null || { echo -e "  ${RED}✗${NC} Install from heroku.com/cli"; return 1; }
    git push heroku main:main 2>/dev/null || git push heroku master:master
    [[ $? -eq 0 ]] && echo -e "\n  ${GREEN}✓${NC} deployed" && record "$(basename $(pwd))" "heroku" "production" "latest" "success"
}

deploy_docker() {
    echo -e "  ${AMBER}${BOLD}◆ BR DEPLOY${NC}  ${DIM}docker${NC}"
    echo -e "  ${DIM}──────────────────────────────${NC}\n"
    docker build -t "${1:-$(basename $(pwd))}:latest" .
    [[ $? -eq 0 ]] && echo -e "\n  ${GREEN}✓${NC} built" && record "${1:-$(basename $(pwd))}" "docker" "local" "latest" "success"
}

quick() {
    echo -e "  ${AMBER}${BOLD}◆ BR DEPLOY${NC}  ${DIM}quick${NC}"
    echo -e "  ${DIM}──────────────────────────────${NC}\n"
    [[ -f "vercel.json" ]] && deploy_vercel prod && return
    [[ -f "netlify.toml" ]] && deploy_netlify prod && return
    [[ -f "Procfile" ]] && deploy_heroku && return
    detect
}

deploy_status() {
    echo -e "  ${AMBER}${BOLD}◆ BR DEPLOY${NC}  ${DIM}history${NC}"
    echo -e "  ${DIM}──────────────────────────────${NC}\n"
    sqlite3 "$DEPLOY_DB" -separator $'\t' "SELECT project, platform, environment, datetime(deployed_at, 'unixepoch', 'localtime') FROM deployments ORDER BY deployed_at DESC LIMIT 10;" 2>/dev/null | \
        while IFS=$'\t' read -r p pl e t; do
            printf "  ${GREEN}✓${NC}  ${AMBER}%-18s${NC} → %-10s %-10s  ${DIM}%s${NC}\n" "$p" "$pl" "$e" "$t"
        done
}


deploy_watch() {
    local platform="${1:-auto}"
    echo ""
    echo -e "  ${AMBER}${BOLD}◆ BR DEPLOY${NC}  ${DIM}watching  ·  $platform  ·  Ctrl+C to exit${NC}"
    echo -e "  ${DIM}────────────────────────────────────────────────${NC}"

    case "$platform" in
        railway)
            command -v railway &>/dev/null || { echo -e "  ${RED}✗${NC} railway CLI not found"; return 1; }
            railway logs --tail 2>&1
            ;;
        vercel)
            command -v vercel &>/dev/null || { echo -e "  ${RED}✗${NC} vercel CLI not found"; return 1; }
            # Tail most recent deployment
            local deploy_id; deploy_id=$(vercel ls --json 2>/dev/null | python3 -c "import json,sys; d=json.loads(sys.stdin.read()); print(d[0]['uid'])" 2>/dev/null)
            [[ -z "$deploy_id" ]] && { echo -e "  ${RED}✗${NC} no recent deployment found"; return 1; }
            vercel logs "$deploy_id" --follow 2>&1
            ;;
        cloudflare|cf)
            command -v wrangler &>/dev/null || { echo -e "  ${RED}✗${NC} wrangler not found"; return 1; }
            wrangler tail 2>&1
            ;;
        github|gh|actions)
            # Live GitHub Actions tail via gh CLI
            local repo; repo=$(git remote get-url origin 2>/dev/null | sed "s|.*github.com[:/]||;s|\.git$||")
            [[ -z "$repo" ]] && { echo -e "  ${RED}✗${NC} no GitHub remote detected"; return 1; }
            echo -e "  ${DIM}repo: $repo${NC}\n"
            # Get latest in-progress or queued run
            local run_id; run_id=$(gh api "repos/${repo}/actions/runs?status=in_progress&per_page=1"                 --jq ".workflow_runs[0].id" 2>/dev/null)
            if [[ -z "$run_id" || "$run_id" == "null" ]]; then
                run_id=$(gh api "repos/${repo}/actions/runs?per_page=1" --jq ".workflow_runs[0].id" 2>/dev/null)
            fi
            [[ -z "$run_id" ]] && { echo -e "  ${RED}✗${NC} no runs found"; return 1; }
            echo -e "  ${DIM}run #$run_id — streaming logs...${NC}\n"
            gh run watch "$run_id" --repo "$repo" 2>&1
            ;;
        auto|*)
            # Smart auto-detect
            if [[ -f "wrangler.toml" ]]; then
                deploy_watch cloudflare
            elif [[ -f "railway.toml" ]]; then
                deploy_watch railway
            elif [[ -f "vercel.json" ]] || [[ -f ".vercel/project.json" ]]; then
                deploy_watch github
            else
                deploy_watch github
            fi
            ;;
    esac
}

deploy_rollback() {
    local platform="${1:-auto}"
    local target="${2:-}"
    echo ""
    echo -e "  ${AMBER}${BOLD}◆ BR DEPLOY${NC}  ${DIM}rollback  ·  $platform${NC}"
    echo -e "  ${DIM}────────────────────────────────────────────────${NC}"
    echo ""

    case "$platform" in
        vercel)
            command -v vercel &>/dev/null || { echo -e "  ${RED}✗${NC} vercel CLI not found"; return 1; }
            if [[ -n "$target" ]]; then
                vercel rollback "$target" 2>&1
            else
                # List last 5 deployments and pick previous
                local prev; prev=$(vercel ls --json 2>/dev/null | python3 -c "
import json,sys
d=json.loads(sys.stdin.read())
if len(d) > 1: print(d[1]['''uid'''])
" 2>/dev/null)
                [[ -z "$prev" ]] && { echo -e "  ${RED}✗${NC} no previous deployment found"; return 1; }
                echo -e "  ${DIM}rolling back to: $prev${NC}"
                vercel rollback "$prev" 2>&1
            fi
            ;;
        railway)
            command -v railway &>/dev/null || { echo -e "  ${RED}✗${NC} railway CLI not found"; return 1; }
            railway rollback 2>&1
            ;;
        cloudflare|cf)
            command -v wrangler &>/dev/null || { echo -e "  ${RED}✗${NC} wrangler not found"; return 1; }
            # List recent versions
            local worker; worker=$(grep "^name" wrangler.toml 2>/dev/null | head -1 | sed "s/.*= *\"\?//;s/\"\?$//")
            [[ -z "$worker" ]] && { echo -e "  ${RED}✗${NC} no worker name found in wrangler.toml"; return 1; }
            echo -e "  ${DIM}worker: $worker${NC}"
            wrangler rollback "${target:-}" 2>&1
            ;;
        github|gh)
            local repo; repo=$(git remote get-url origin 2>/dev/null | sed "s|.*github.com[:/]||;s|\.git$||")
            [[ -z "$repo" ]] && { echo -e "  ${RED}✗${NC} no GitHub remote detected"; return 1; }
            # Re-run last successful deployment workflow
            local run_id; run_id=$(gh api "repos/${repo}/actions/runs?status=success&per_page=2"                 --jq ".workflow_runs[1].id" 2>/dev/null)
            [[ -z "$run_id" ]] && { echo -e "  ${RED}✗${NC} no previous successful run found"; return 1; }
            echo -e "  ${DIM}re-running: run #$run_id${NC}"
            gh run rerun "$run_id" --repo "$repo" 2>&1 && echo -e "  ${GREEN}✓${NC}  rollback triggered"
            ;;
        *)
            echo -e "  ${DIM}usage: br deploy rollback <platform> [target]${NC}"
            echo -e "  ${DIM}platforms: vercel · railway · cloudflare · github${NC}"
            ;;
    esac
    echo ""
}

show_help() {
    echo ""
    echo -e "  ${AMBER}${BOLD}◆ BR DEPLOY${NC}  ${DIM}Ship code. Watch it land. Roll back in seconds.${NC}"
    echo -e "  ${DIM}────────────────────────────────────────────────${NC}"
    echo ""
    echo -e "  ${AMBER}watch${NC}    [platform]        stream live deploy logs"
    echo -e "  ${AMBER}rollback${NC} <platform> [id]   revert to previous deploy"
    echo -e "  ${AMBER}detect${NC}                     auto-detect platforms"
    echo -e "  ${AMBER}quick${NC}                      smart auto-deploy"
    echo -e "  ${AMBER}vercel${NC}   [prod]             deploy to Vercel"
    echo -e "  ${AMBER}netlify${NC}  [prod]             deploy to Netlify"
    echo -e "  ${AMBER}railway${NC}                    deploy to Railway"
    echo -e "  ${AMBER}cf${NC}                         deploy Cloudflare worker"
    echo -e "  ${AMBER}docker${NC}   [tag]              build Docker image"
    echo -e "  ${AMBER}status${NC}                     deployment history"
    echo ""
    echo -e "  ${DIM}platforms: vercel · railway · cloudflare · github · netlify${NC}"
    echo ""
}

init_db
case ${1:-detect} in
    detect|d|"") detect ;;
    quick|q) quick ;;
    watch|w|tail|live) deploy_watch "${2:-auto}" ;;
    rollback|rb|revert) deploy_rollback "${2:-auto}" "${3:-}" ;;
    vercel|v) deploy_vercel "$2" ;;
    netlify|n) deploy_netlify "$2" ;;
    heroku|h) deploy_heroku ;;
    railway|r) railway up 2>&1 ;;
    cf|cloudflare|wrangler) wrangler deploy 2>&1 ;;
    docker) deploy_docker "$2" ;;
    status|s|history) deploy_status ;;
    edge|worker)
        # Live railway deployments via edge worker
        exec "$(dirname "$0")/../worker-bridge/br-worker.sh" railway deployments "${@:2}"
        ;;
    help|--help|-h) show_help ;;
    *) show_help ;;
esac
