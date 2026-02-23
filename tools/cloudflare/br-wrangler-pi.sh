#!/bin/zsh
# BR WRANGLER PI - Deploy Cloudflare Workers from Pi fleet
# Deploys all workers via self-hosted runners

GREEN='\033[0;32m'; RED='\033[0;31m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; NC='\033[0m'

WRANGLER="${HOME}/bin/wrangler"
command -v wrangler &>/dev/null && WRANGLER="wrangler"
test -f "$WRANGLER" || WRANGLER="${HOME}/npm-global/bin/wrangler"

case "$1" in
  deploy-all)
    echo -e "${CYAN}Deploying all Cloudflare Workers from Pi...${NC}"
    WORKERS_DIR="${0:A:h:h:h}/tools/cloudflare/workers"
    if [[ -d "$WORKERS_DIR" ]]; then
      for wf in "$WORKERS_DIR"/*/; do
        name=$(basename "$wf")
        echo -n "  Deploying $name... "
        (cd "$wf" && $WRANGLER deploy 2>&1 | tail -1) && echo "✅" || echo "❌"
      done
    else
      echo "  No workers dir found. Run: br cloudflare deploy"
    fi
    ;;
  deploy)
    WORKER="${2:?Usage: br wrangler deploy <worker-name>}"
    echo -e "${CYAN}Deploying worker: $WORKER${NC}"
    $WRANGLER deploy --name "$WORKER" "${@:3}"
    ;;
  tail)
    WORKER="${2:?Usage: br wrangler tail <worker-name>}"
    $WRANGLER tail "$WORKER"
    ;;
  kv-sync)
    echo -e "${CYAN}Syncing KV namespaces...${NC}"
    $WRANGLER kv namespace list 2>/dev/null | head -20
    ;;
  status)
    echo -e "${CYAN}Cloudflare Workers status:${NC}"
    curl -sf "https://api.cloudflare.com/client/v4/accounts/${CLOUDFLARE_ACCOUNT_ID}/workers/scripts" \
      -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
      2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); [print(f'  {s[\"id\"]}') for s in d.get('result',[])]" 2>/dev/null || \
      echo "  Set CLOUDFLARE_API_TOKEN and CLOUDFLARE_ACCOUNT_ID"
    ;;
  help|*)
    echo "br wrangler [deploy-all|deploy <worker>|tail <worker>|kv-sync|status]"
    ;;
esac
