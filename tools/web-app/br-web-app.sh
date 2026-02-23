#!/bin/zsh
# BR WEB — Manage blackroad-os-web Next.js app

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'
BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'

WEB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/../../orgs/core/blackroad-os-web" 2>/dev/null && pwd)"
APP_URL="${BLACKROAD_WEB_URL:-https://blackroad-os.vercel.app}"

show_help() {
  echo "${BLUE}${BOLD}◆ BR WEB${NC}  Next.js App Manager"
  echo ""
  echo "  ${CYAN}dev${NC}           Start local dev server (port 3000)"
  echo "  ${CYAN}build${NC}         Build for production"
  echo "  ${CYAN}deploy${NC}        Deploy to Vercel production"
  echo "  ${CYAN}preview${NC}       Deploy Vercel preview"
  echo "  ${CYAN}status${NC}        Show deploy + health status"
  echo "  ${CYAN}logs${NC}          Show Vercel logs"
  echo "  ${CYAN}pages${NC}         List all app pages"
  echo "  ${CYAN}env${NC}           Show required env vars"
  echo "  ${CYAN}env set${NC}       Set env var in Vercel"
  echo "  ${CYAN}open${NC}          Open app in browser"
  echo "  ${CYAN}lint${NC}          Run ESLint"
  echo ""
}

cmd_dev() {
  echo "${CYAN}◆ BR WEB${NC}  Starting dev server"
  echo "  ${YELLOW}→${NC} ${WEB_DIR}"
  cd "$WEB_DIR" && npm run dev
}

cmd_build() {
  echo "${CYAN}◆ BR WEB${NC}  Building"
  cd "$WEB_DIR" && npm run build
}

cmd_deploy() {
  echo "${CYAN}◆ BR WEB${NC}  Deploying to Vercel production"
  cd "$WEB_DIR" && vercel --prod
}

cmd_preview() {
  echo "${CYAN}◆ BR WEB${NC}  Deploying Vercel preview"
  cd "$WEB_DIR" && vercel
}

cmd_status() {
  echo "${CYAN}◆ BR WEB${NC}  Status"
  echo ""

  echo "  ${BLUE}App directory${NC}"
  if [[ -d "$WEB_DIR" ]]; then
    echo "  ${GREEN}✓${NC} ${WEB_DIR}"
    local pkg_ver
    pkg_ver=$(node -p "require('${WEB_DIR}/package.json').dependencies.next" 2>/dev/null || echo "?")
    echo "  ${GREEN}✓${NC} Next.js ${pkg_ver}"
  else
    echo "  ${RED}✗${NC} Not found"
  fi

  echo ""
  echo "  ${BLUE}Production URL${NC}"
  local http_code
  http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$APP_URL" 2>/dev/null)
  if [[ "$http_code" == "200" ]]; then
    echo "  ${GREEN}✓${NC} ${APP_URL} (HTTP ${http_code})"
  elif [[ -n "$http_code" ]]; then
    echo "  ${YELLOW}⚠${NC} ${APP_URL} (HTTP ${http_code})"
  else
    echo "  ${RED}✗${NC} ${APP_URL} (unreachable)"
  fi

  echo ""
  echo "  ${BLUE}Vercel CLI${NC}"
  if command -v vercel &>/dev/null; then
    echo "  ${GREEN}✓${NC} $(vercel --version 2>/dev/null | head -1)"
  else
    echo "  ${YELLOW}⚠${NC} vercel CLI not installed (npm i -g vercel)"
  fi
}

cmd_logs() {
  echo "${CYAN}◆ BR WEB${NC}  Vercel logs"
  vercel logs "$APP_URL" "$@"
}

cmd_pages() {
  echo "${CYAN}◆ BR WEB${NC}  App pages"
  echo ""
  find "$WEB_DIR/app" -name "page.tsx" | sed "s|${WEB_DIR}/app||" | sed 's|/page.tsx||' | sort | while read -r p; do
    local display="${p:-/}"
    echo "  ${CYAN}◦${NC} ${display:-/}"
  done
}

cmd_env() {
  echo "${CYAN}◆ BR WEB${NC}  Required env vars"
  echo ""
  echo "  ${YELLOW}Required${NC}"
  echo "  BRAT_MASTER_KEY             Token signing secret"
  echo "  BLACKROAD_GATEWAY_URL       Gateway endpoint (default: http://127.0.0.1:8787)"
  echo "  BLACKROAD_WORKER_URL        CF Worker chat endpoint"
  echo "  BLACKROAD_DEFAULT_MODEL     Model to use (default: cece3b)"
  echo ""
  echo "  ${BLUE}Optional${NC}"
  echo "  NEXT_PUBLIC_APP_URL         Canonical URL"
  echo "  NEXTAUTH_URL                Auth callback URL"
  echo ""
  echo "  ${CYAN}Set with:${NC} br web env set KEY=value"
}

cmd_env_set() {
  local pair="$1"
  if [[ -z "$pair" ]]; then
    echo "${RED}✗${NC} Usage: br web env set KEY=value"
    exit 1
  fi
  echo "${CYAN}◆ BR WEB${NC}  Setting ${pair%%=*} in Vercel"
  local key="${pair%%=*}"
  local val="${pair#*=}"
  echo "$val" | vercel env add "$key" production
}

cmd_open() {
  open "$APP_URL" 2>/dev/null || xdg-open "$APP_URL" 2>/dev/null || echo "Open: $APP_URL"
}

cmd_lint() {
  echo "${CYAN}◆ BR WEB${NC}  Linting"
  cd "$WEB_DIR" && npm run lint
}

case "${1:-help}" in
  dev)     cmd_dev ;;
  build)   cmd_build ;;
  deploy)  cmd_deploy ;;
  preview) cmd_preview ;;
  status)  cmd_status ;;
  logs)    shift; cmd_logs "$@" ;;
  pages)   cmd_pages ;;
  env)
    if [[ "$2" == "set" ]]; then cmd_env_set "$3"
    else cmd_env; fi ;;
  open)    cmd_open ;;
  lint)    cmd_lint ;;
  *)       show_help ;;
esac
