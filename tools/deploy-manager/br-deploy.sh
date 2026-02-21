#!/bin/zsh
# BR Deploy - Quick Deployment Manager
DEPLOY_HOME="/Users/alexa/blackroad/tools/deploy-manager"
DEPLOY_DB="${DEPLOY_HOME}/deployments.db"
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; CYAN='\033[0;36m'; PURPLE='\033[0;35m'; RED='\033[0;31m'; NC='\033[0m'

init_db() {
    [[ -f "$DEPLOY_DB" ]] && return
    mkdir -p "$DEPLOY_HOME"
    sqlite3 "$DEPLOY_DB" "CREATE TABLE deployments (id INTEGER PRIMARY KEY, project TEXT, platform TEXT, environment TEXT, version TEXT, status TEXT, deployed_at INTEGER, deployed_by TEXT);"
}

record() { sqlite3 "$DEPLOY_DB" "INSERT INTO deployments VALUES (NULL, '$1', '$2', '$3', '$4', '$5', $(date +%s), '$(whoami)');"; }

detect() {
    echo -e "${CYAN}🔍 Detecting platforms...${NC}\n"
    [[ -f "vercel.json" ]] && echo -e "${GREEN}✓ Vercel${NC}"
    [[ -f "netlify.toml" ]] && echo -e "${GREEN}✓ Netlify${NC}"
    [[ -f "Procfile" ]] && echo -e "${GREEN}✓ Heroku${NC}"
    [[ -f "Dockerfile" ]] && echo -e "${GREEN}✓ Docker${NC}"
    echo -e "\nUse: br deploy <platform>"
}

deploy_vercel() {
    echo -e "${PURPLE}▲ Vercel...${NC}\n"
    command -v vercel &>/dev/null || { echo "Install: npm i -g vercel"; return 1; }
    [[ "$1" == "prod" ]] && vercel --prod || vercel
    [[ $? -eq 0 ]] && echo -e "\n${GREEN}✓ Deployed!${NC}" && record "$(basename $(pwd))" "vercel" "${1:-preview}" "latest" "success"
}

deploy_netlify() {
    echo -e "${CYAN}🌐 Netlify...${NC}\n"
    command -v netlify &>/dev/null || { echo "Install: npm i -g netlify-cli"; return 1; }
    [[ "$1" == "prod" ]] && netlify deploy --prod || netlify deploy
    [[ $? -eq 0 ]] && echo -e "\n${GREEN}✓ Deployed!${NC}" && record "$(basename $(pwd))" "netlify" "${1:-preview}" "latest" "success"
}

deploy_heroku() {
    echo -e "${PURPLE}⬢ Heroku...${NC}\n"
    command -v heroku &>/dev/null || { echo "Install from heroku.com/cli"; return 1; }
    git push heroku main:main 2>/dev/null || git push heroku master:master
    [[ $? -eq 0 ]] && echo -e "\n${GREEN}✓ Deployed!${NC}" && record "$(basename $(pwd))" "heroku" "production" "latest" "success"
}

deploy_docker() {
    echo -e "${BLUE}🐳 Docker...${NC}\n"
    docker build -t "${1:-$(basename $(pwd))}:latest" .
    [[ $? -eq 0 ]] && echo -e "\n${GREEN}✓ Built!${NC}" && record "${1:-$(basename $(pwd))}" "docker" "local" "latest" "success"
}

quick() {
    echo -e "${PURPLE}⚡ Quick Deploy${NC}\n"
    [[ -f "vercel.json" ]] && deploy_vercel prod && return
    [[ -f "netlify.toml" ]] && deploy_netlify prod && return
    [[ -f "Procfile" ]] && deploy_heroku && return
    detect
}

status() {
    echo -e "${BLUE}📊 Recent Deployments${NC}\n"
    sqlite3 "$DEPLOY_DB" -separator $'\t' "SELECT project, platform, environment, datetime(deployed_at, 'unixepoch', 'localtime') FROM deployments ORDER BY deployed_at DESC LIMIT 10;" 2>/dev/null | \
        while IFS=$'\t' read -r p pl e t; do echo -e "  ${GREEN}✓${NC} ${CYAN}$p${NC} → $pl ($e) - $t"; done
}

init_db
case ${1:-detect} in
    detect|d) detect ;;
    quick|q) quick ;;
    vercel|v) deploy_vercel "$2" ;;
    netlify|n) deploy_netlify "$2" ;;
    heroku|h) deploy_heroku "$2" ;;
    docker) deploy_docker "$2" ;;
    status|s) status ;;
    *) echo "Usage: br deploy {detect|quick|vercel|netlify|heroku|docker|status}" ;;
esac
