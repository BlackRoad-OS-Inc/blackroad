#!/usr/bin/env zsh
# BR Vercel - Vercel deployment manager

AMBER='[38;5;214m'; PINK='[38;5;205m'; VIOLET='[38;5;135m'; BBLUE='[38;5;69m'
GREEN='[0;32m'; RED='[0;31m'; BOLD='[1m'; DIM='[2m'; NC='[0m'
CYAN="$AMBER"; YELLOW="$PINK"; BLUE="$BBLUE"; MAGENTA="$VIOLET"; PURPLE="$VIOLET"

VERCEL_CMD=$(which vercel 2>/dev/null || which vc 2>/dev/null)

check_vercel() {
    if [[ -z "$VERCEL_CMD" ]]; then
        echo "${RED}✗ Vercel CLI not found. Install: npm i -g vercel${NC}"
        exit 1
    fi
}

show_help() {
    echo -e "  ${AMBER}${BOLD}◆ BR VERCEL${NC}  deployment manager\n"
    echo -e "  ${AMBER}br vercel deploy${NC}         preview deploy"
    echo -e "  ${AMBER}br vercel prod${NC}            production deploy"
    echo -e "  ${AMBER}br vercel list${NC}            list deployments"
    echo -e "  ${AMBER}br vercel logs [url]${NC}      tail logs"
    echo -e "  ${AMBER}br vercel domains${NC}         list domains"
    echo -e "  ${AMBER}br vercel env${NC}             list env vars"
    echo -e "  ${AMBER}br vercel env set K V${NC}     set env var"
    echo -e "  ${AMBER}br vercel projects${NC}        list projects"
    echo -e "  ${AMBER}br vercel open${NC}            open latest"
    echo -e "  ${AMBER}br vercel status${NC}          deployment status"
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
