#!/usr/bin/env zsh
# BR Vercel - Vercel deployment manager

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; BLUE='\033[0;34m'; NC='\033[0m'

VERCEL_CMD=$(which vercel 2>/dev/null || which vc 2>/dev/null)

check_vercel() {
    if [[ -z "$VERCEL_CMD" ]]; then
        echo "${RED}✗ Vercel CLI not found. Install: npm i -g vercel${NC}"
        exit 1
    fi
}

show_help() {
    echo "${CYAN}╔══════════════════════════════════════════════════════╗${NC}"
    echo "${CYAN}║  ▲ BR Vercel - Deployment Manager                    ║${NC}"
    echo "${CYAN}╠══════════════════════════════════════════════════════╣${NC}"
    echo "${CYAN}║${NC}  br vercel deploy        - Deploy to preview          ${CYAN}║${NC}"
    echo "${CYAN}║${NC}  br vercel prod          - Deploy to production        ${CYAN}║${NC}"
    echo "${CYAN}║${NC}  br vercel list          - List deployments            ${CYAN}║${NC}"
    echo "${CYAN}║${NC}  br vercel logs [url]    - Tail deployment logs        ${CYAN}║${NC}"
    echo "${CYAN}║${NC}  br vercel domains       - List domains                ${CYAN}║${NC}"
    echo "${CYAN}║${NC}  br vercel env           - List env variables          ${CYAN}║${NC}"
    echo "${CYAN}║${NC}  br vercel env set K V   - Set env variable            ${CYAN}║${NC}"
    echo "${CYAN}║${NC}  br vercel projects      - List all projects           ${CYAN}║${NC}"
    echo "${CYAN}║${NC}  br vercel open          - Open latest deployment      ${CYAN}║${NC}"
    echo "${CYAN}║${NC}  br vercel status        - Deployment status           ${CYAN}║${NC}"
    echo "${CYAN}╚══════════════════════════════════════════════════════╝${NC}"
}

cmd_deploy() {
    check_vercel
    echo "${CYAN}▲ Deploying to Vercel (preview)...${NC}"
    "$VERCEL_CMD" --yes
}

cmd_prod() {
    check_vercel
    echo "${CYAN}▲ Deploying to Vercel PRODUCTION...${NC}"
    "$VERCEL_CMD" --prod --yes
}

cmd_list() {
    check_vercel
    echo "${CYAN}▲ Recent deployments:${NC}"
    echo ""
    "$VERCEL_CMD" ls 2>/dev/null || echo "${RED}Run 'vercel login' first${NC}"
}

cmd_logs() {
    check_vercel
    local url=$1
    if [[ -n "$url" ]]; then
        "$VERCEL_CMD" logs "$url"
    else
        echo "${YELLOW}Usage: br vercel logs <deployment-url>${NC}"
        echo "Get URLs with: br vercel list"
    fi
}

cmd_domains() {
    check_vercel
    echo "${CYAN}▲ Vercel domains:${NC}"
    echo ""
    "$VERCEL_CMD" domains ls 2>/dev/null
}

cmd_env() {
    check_vercel
    local subcmd=${1:-list}
    case $subcmd in
        list|ls)
            echo "${CYAN}▲ Environment variables:${NC}"
            "$VERCEL_CMD" env ls 2>/dev/null
            ;;
        set|add)
            local key=$2 val=$3
            if [[ -z "$key" || -z "$val" ]]; then
                echo "${YELLOW}Usage: br vercel env set KEY VALUE${NC}"
            else
                echo "$val" | "$VERCEL_CMD" env add "$key" production 2>/dev/null \
                    && echo "${GREEN}✓ Set ${key}${NC}"
            fi
            ;;
        *)
            echo "${YELLOW}Usage: br vercel env [list|set KEY VALUE]${NC}"
            ;;
    esac
}

cmd_projects() {
    check_vercel
    echo "${CYAN}▲ Vercel projects:${NC}"
    echo ""
    "$VERCEL_CMD" projects ls 2>/dev/null
}

cmd_open() {
    check_vercel
    "$VERCEL_CMD" open 2>/dev/null || echo "${YELLOW}No active project found in current directory${NC}"
}

cmd_status() {
    check_vercel
    echo "${CYAN}▲ Vercel status${NC}"
    echo ""
    # Show current project info if in a vercel project dir
    if [[ -f ".vercel/project.json" ]]; then
        echo "${GREEN}✓ Vercel project detected${NC}"
        cat .vercel/project.json 2>/dev/null | python3 -m json.tool 2>/dev/null
    else
        echo "${YELLOW}Not in a Vercel project directory${NC}"
        echo "  Run 'vercel link' to link a project"
    fi
    echo ""
    # Show recent deployments
    "$VERCEL_CMD" ls --limit 5 2>/dev/null
}

case "${1:-help}" in
    deploy)    cmd_deploy ;;
    prod|production) cmd_prod ;;
    list|ls)   cmd_list ;;
    logs)      cmd_logs "$2" ;;
    domains)   cmd_domains ;;
    env)       cmd_env "$2" "$3" "$4" ;;
    projects)  cmd_projects ;;
    open)      cmd_open ;;
    status)    cmd_status ;;
    help|-h)   show_help ;;
    *)         show_help ;;
esac
