#!/bin/zsh
# BlackRoad OS — Boot both backend services
# Usage: ./boot-api.sh [--gateway-only | --api-only | --dev]

GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'

GATEWAY_PORT=8787
API_PORT=8788
GATEWAY_PID_FILE="/tmp/blackroad-gateway.pid"
API_PID_FILE="/tmp/blackroad-api.pid"

log()  { echo -e "${GREEN}✓${NC} $1"; }
info() { echo -e "${CYAN}→${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }
err()  { echo -e "${RED}✗${NC} $1"; }

stop_existing() {
  for pid_file in $GATEWAY_PID_FILE $API_PID_FILE; do
    if [[ -f "$pid_file" ]]; then
      local pid=$(cat "$pid_file")
      if kill -0 "$pid" 2>/dev/null; then
        kill "$pid" 2>/dev/null
        info "Stopped PID $pid"
      fi
      rm -f "$pid_file"
    fi
  done
}

start_gateway() {
  info "Starting BlackRoad Gateway on :$GATEWAY_PORT"
  cd "$(dirname $0)/blackroad-core" || { err "blackroad-core not found"; return 1; }
  node gateway/server.js > /tmp/blackroad-gateway.log 2>&1 &
  echo $! > $GATEWAY_PID_FILE
  sleep 1
  if curl -sf "http://127.0.0.1:$GATEWAY_PORT/healthz" > /dev/null 2>&1; then
    log "Gateway online at http://127.0.0.1:$GATEWAY_PORT"
  else
    warn "Gateway started (PID $(cat $GATEWAY_PID_FILE)) — healthz pending"
  fi
  cd - > /dev/null
}

start_api() {
  info "Starting BlackRoad API on :$API_PORT"
  cd "$(dirname $0)/blackroad-api" || { err "blackroad-api not found"; return 1; }

  # Check Python deps
  python3 -c "import fastapi, uvicorn, pydantic_settings" 2>/dev/null || {
    warn "Installing Python deps..."
    pip install -q fastapi uvicorn[standard] pydantic-settings httpx aiofiles celery
  }

  python3 -m uvicorn app.main:app \
    --host 0.0.0.0 \
    --port $API_PORT \
    --log-level warning \
    --workers 2 > /tmp/blackroad-api.log 2>&1 &
  echo $! > $API_PID_FILE
  sleep 2

  if curl -sf "http://127.0.0.1:$API_PORT/health" > /dev/null 2>&1; then
    log "API online at http://127.0.0.1:$API_PORT"
    log "Docs at http://127.0.0.1:$API_PORT/docs"
  else
    warn "API started (PID $(cat $API_PID_FILE)) — health pending"
  fi
  cd - > /dev/null
}

status_check() {
  echo ""
  echo -e "${CYAN}━━━ Service Status ━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

  # Gateway
  local gw=$(curl -sf "http://127.0.0.1:$GATEWAY_PORT/healthz" 2>/dev/null)
  if [[ -n "$gw" ]]; then
    log "Gateway :$GATEWAY_PORT — $(echo $gw | python3 -c 'import sys,json; d=json.load(sys.stdin); print(d.get("gateway","ok"))' 2>/dev/null || echo 'online')"
  else
    err "Gateway :$GATEWAY_PORT — offline"
  fi

  # API
  local api=$(curl -sf "http://127.0.0.1:$API_PORT/health" 2>/dev/null)
  if [[ -n "$api" ]]; then
    log "API :$API_PORT — $(echo $api | python3 -c 'import sys,json; d=json.load(sys.stdin); print(f"agents={d[\"agents\"]} tasks={d[\"tasks\"]} memory={d[\"memory\"]}")' 2>/dev/null || echo 'online')"
  else
    err "API :$API_PORT — offline"
  fi

  # Carpool
  local cp=$(curl -sf "http://127.0.0.1:4040/health" 2>/dev/null)
  if [[ -n "$cp" ]]; then
    log "CarPool :4040 — $(echo $cp | python3 -c 'import sys,json; d=json.load(sys.stdin); print(f"commands={d[\"commands\"]}")' 2>/dev/null || echo 'online')"
  else
    warn "CarPool :4040 — offline (run: node blackroad-web/carpool-server/server.js)"
  fi

  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo "  Logs:   tail -f /tmp/blackroad-gateway.log /tmp/blackroad-api.log"
  echo "  Docs:   http://127.0.0.1:$API_PORT/docs"
  echo "  Deploy: npx wrangler deploy --config wrangler-configs/api-edge.toml"
  echo ""
}

# ── Main ─────────────────────────────────────────────────────────────
case "${1:-all}" in
  stop)
    stop_existing
    log "Services stopped"
    ;;
  status)
    status_check
    ;;
  --gateway-only)
    stop_existing
    start_gateway
    status_check
    ;;
  --api-only)
    stop_existing
    start_api
    status_check
    ;;
  all|--dev|*)
    echo ""
    echo -e "${CYAN}  ██████╗ ██╗      █████╗  ██████╗██╗  ██╗██████╗  ██████╗  █████╗ ██████╗ ${NC}"
    echo -e "${CYAN}  ██╔══██╗██║     ██╔══██╗██╔════╝██║ ██╔╝██╔══██╗██╔═══██╗██╔══██╗██╔══██╗${NC}"
    echo -e "${CYAN}  ██████╔╝██║     ███████║██║     █████╔╝ ██████╔╝██║   ██║███████║██║  ██║${NC}"
    echo -e "${CYAN}  ██╔══██╗██║     ██╔══██║██║     ██╔═██╗ ██╔══██╗██║   ██║██╔══██║██║  ██║${NC}"
    echo -e "${CYAN}  ██████╔╝███████╗██║  ██║╚██████╗██║  ██╗██║  ██║╚██████╔╝██║  ██║██████╔╝${NC}"
    echo -e "${CYAN}  ╚═════╝ ╚══════╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═════╝ ${NC}"
    echo ""
    stop_existing
    start_gateway
    start_api
    status_check
    ;;
esac
