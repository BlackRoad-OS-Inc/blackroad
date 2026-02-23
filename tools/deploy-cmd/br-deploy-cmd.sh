#!/bin/zsh
# BR Deploy — One-command deployer for Railway / Vercel / Cloudflare / Pi
# Usage: br deploy [target] [--dir <path>]

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m'

DIR="${PWD}"
TARGET=""

# Parse args
while [[ $# -gt 0 ]]; do
    case "$1" in
        --dir|-d) DIR="$2"; shift 2 ;;
        railway|vercel|cloudflare|cf|pi|fleet|all) TARGET="$1"; shift ;;
        help|-h|--help) TARGET="help"; shift ;;
        *) TARGET="$1"; shift ;;
    esac
done

detect_project() {
    local dir="$1"
    [[ -f "$dir/wrangler.toml" ]]     && echo "cloudflare" && return
    [[ -f "$dir/railway.toml" ]]       && echo "railway" && return
    [[ -f "$dir/vercel.json" ]]        && echo "vercel" && return
    [[ -f "$dir/package.json" ]]       && echo "node" && return
    [[ -f "$dir/requirements.txt" ]]   && echo "python" && return
    echo "unknown"
}

deploy_cloudflare() {
    local dir="${1:-$DIR}"
    echo -e "${CYAN}☁  Deploying Cloudflare Worker from $dir...${NC}"
    cd "$dir" || return 1
    if wrangler deploy 2>&1; then
        echo -e "${GREEN}✓ Cloudflare deployed${NC}"
    else
        echo -e "${RED}✗ Cloudflare deploy failed${NC}"; return 1
    fi
}

deploy_railway() {
    local dir="${1:-$DIR}"
    echo -e "${CYAN}🚂 Deploying to Railway from $dir...${NC}"
    cd "$dir" || return 1
    if command -v railway &>/dev/null; then
        railway up --detach 2>&1 && echo -e "${GREEN}✓ Railway deployed${NC}" || \
            { echo -e "${RED}✗ Railway failed${NC}"; return 1; }
    else
        echo -e "${RED}✗ railway CLI not installed (npm i -g @railway/cli)${NC}"; return 1
    fi
}

deploy_vercel() {
    local dir="${1:-$DIR}"
    echo -e "${CYAN}▲ Deploying to Vercel from $dir...${NC}"
    cd "$dir" || return 1
    if command -v vercel &>/dev/null; then
        vercel --prod --yes 2>&1 && echo -e "${GREEN}✓ Vercel deployed${NC}" || \
            { echo -e "${RED}✗ Vercel failed${NC}"; return 1; }
    else
        echo -e "${RED}✗ vercel CLI not installed (npm i -g vercel)${NC}"; return 1
    fi
}

deploy_pi() {
    local dir="${1:-$DIR}"
    echo -e "${CYAN}🥧 Deploying to Pi fleet from $dir...${NC}"

    typeset -A NODES USERS
    NODES=(aria64 "192.168.4.38" alice "192.168.4.49")
    USERS=(aria64 "alexa" alice "blackroad")

    local deployed=0
    for node in aria64 alice; do
        local user=${USERS[$node]}
        local ip=${NODES[$node]}
        echo -e "  ${BLUE}▶ $node${NC} ($ip)..."
        if scp -o ConnectTimeout=8 -r "$dir" "$user@$ip:~/blackroad/deploys/$(basename $dir)" 2>/dev/null; then
            echo -e "  ${GREEN}✓ synced${NC}"
            ((deployed++))
        else
            echo -e "  ${RED}✗ failed${NC}"
        fi
    done
    echo -e "${GREEN}✓ Deployed to $deployed Pi nodes${NC}"
}

deploy_auto() {
    local project_type=$(detect_project "$DIR")
    echo -e "${CYAN}🔍 Auto-detected: ${YELLOW}$project_type${NC} in $DIR"
    echo ""

    case "$project_type" in
        cloudflare) deploy_cloudflare "$DIR" ;;
        railway)    deploy_railway "$DIR" ;;
        vercel)     deploy_vercel "$DIR" ;;
        node|python)
            echo -e "${YELLOW}Detected $project_type project.${NC}"
            echo "Available targets: railway, vercel, cloudflare, pi"
            echo "Usage: br deploy <target>"
            ;;
        *)
            echo -e "${RED}Cannot auto-detect deploy target. Specify: br deploy <railway|vercel|cloudflare|pi>${NC}"
            exit 1
            ;;
    esac
}

show_help() {
    echo -e "${CYAN}BR Deploy — One-command deployer${NC}"
    echo ""
    echo "  br deploy              - Auto-detect and deploy"
    echo "  br deploy cloudflare   - Deploy Cloudflare Worker (wrangler)"
    echo "  br deploy railway      - Deploy to Railway"
    echo "  br deploy vercel       - Deploy to Vercel (--prod)"
    echo "  br deploy pi           - Sync to Pi fleet (aria64 + alice)"
    echo "  br deploy all          - Deploy to all targets"
    echo ""
    echo "  Options:"
    echo "    --dir <path>         - Directory to deploy from (default: cwd)"
    echo ""
    echo "  Examples:"
    echo "    br deploy                     # auto-detect from cwd"
    echo "    br deploy cloudflare          # deploy current wrangler project"
    echo "    br deploy vercel --dir ./web  # deploy specific dir"
}

case "${TARGET:-auto}" in
    auto|"")         deploy_auto ;;
    cloudflare|cf)   deploy_cloudflare "$DIR" ;;
    railway)         deploy_railway "$DIR" ;;
    vercel|vc)       deploy_vercel "$DIR" ;;
    pi|fleet)        deploy_pi "$DIR" ;;
    all)
        deploy_cloudflare "$DIR"
        deploy_railway "$DIR"
        deploy_vercel "$DIR"
        deploy_pi "$DIR"
        ;;
    help|-h|--help)  show_help ;;
    *) echo -e "${RED}Unknown target: $TARGET${NC}"; show_help; exit 1 ;;
esac
