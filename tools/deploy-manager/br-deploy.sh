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

show_help() {
    echo -e "  ${AMBER}${BOLD}◆ BR DEPLOY${NC}  deployment manager\n"
    echo -e "  ${AMBER}br deploy detect${NC}        auto-detect platforms"
    echo -e "  ${AMBER}br deploy quick${NC}         smart auto-deploy"
    echo -e "  ${AMBER}br deploy vercel [prod]${NC}  deploy to Vercel"
    echo -e "  ${AMBER}br deploy netlify [prod]${NC} deploy to Netlify"
    echo -e "  ${AMBER}br deploy heroku${NC}         push to Heroku"
    echo -e "  ${AMBER}br deploy docker [tag]${NC}   build Docker image"
    echo -e "  ${AMBER}br deploy status${NC}         deployment history"
}

init_db
case ${1:-detect} in
    detect|d|"") detect ;;
    quick|q) quick ;;
    vercel|v) deploy_vercel "$2" ;;
    netlify|n) deploy_netlify "$2" ;;
    heroku|h) deploy_heroku ;;
    docker) deploy_docker "$2" ;;
    status|s|history) deploy_status ;;
    help|--help|-h) show_help ;;
    *) show_help ;;
esac
