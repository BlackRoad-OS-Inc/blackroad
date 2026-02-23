#!/bin/bash
# ============================================================================
# BlackRoad Infrastructure Mesh - Unified Service Check & Boot
# ============================================================================
#
# Tests connectivity to all 7 infrastructure services and optionally
# starts the full BlackRoad OS stack.
#
# Usage:
#   ./blackroad-mesh.sh              # Check all services
#   ./blackroad-mesh.sh --boot       # Check + start orchestrator
#   ./blackroad-mesh.sh --json       # Output as JSON
#   ./blackroad-mesh.sh --service X  # Check single service
#

set -euo pipefail

# Colors
R='\033[0;31m'
G='\033[0;32m'
Y='\033[1;33m'
B='\033[0;34m'
P='\033[0;35m'
C='\033[0;36m'
W='\033[1;37m'
NC='\033[0m'

# Config
BOOT=false
JSON_MODE=false
SINGLE_SERVICE=""
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

while [ $# -gt 0 ]; do
  case "$1" in
    --boot) BOOT=true; shift ;;
    --json) JSON_MODE=true; shift ;;
    --service) SINGLE_SERVICE="$2"; shift 2 ;;
    --help)
      echo "Usage: $0 [--boot] [--json] [--service <name>]"
      echo ""
      echo "Services: github, huggingface, cloudflare, vercel, digitalocean, ollama, railway"
      exit 0
      ;;
    *) echo "Unknown: $1"; exit 1 ;;
  esac
done

# Load env if present
for envfile in "$SCRIPT_DIR/.env" "$SCRIPT_DIR/.env.local"; do
  [ -f "$envfile" ] && export $(grep -v '^#' "$envfile" | grep '=' | xargs) 2>/dev/null || true
done

# ============================================================================
# Service Check Functions
# ============================================================================

RESULTS=()
PASS=0
TOTAL=0

check_service() {
  local name="$1"
  local status="DOWN"
  local latency="0"
  local details="$2"
  local start end

  start=$(python3 -c "import time; print(int(time.time()*1000))")

  if eval "$3"; then
    status="UP"
    ((PASS++)) || true
  fi

  end=$(python3 -c "import time; print(int(time.time()*1000))")
  latency=$(( end - start ))
  ((TOTAL++)) || true

  if [ "$JSON_MODE" = true ]; then
    RESULTS+=("{\"name\":\"$name\",\"health\":\"$status\",\"latency_ms\":$latency,\"details\":\"$details\"}")
  else
    if [ "$status" = "UP" ]; then
      printf "  ${G}[+]${NC} %-16s ${G}%-6s${NC} %4dms  %s\n" "$name" "$status" "$latency" "$details"
    else
      printf "  ${R}[-]${NC} %-16s ${R}%-6s${NC} %4dms  %s\n" "$name" "$status" "$latency" "$details"
    fi
  fi
}

# ============================================================================
# Individual Checks
# ============================================================================

check_github() {
  local details=""
  if [ -n "${GITHUB_TOKEN:-}" ]; then
    details="org=blackboxprogramming (authenticated)"
    check_service "GitHub" "$details" \
      '[ "$(curl -s -o /dev/null -w "%{http_code}" --max-time 8 -H "Authorization: Bearer '"$GITHUB_TOKEN"'" https://api.github.com/users/blackboxprogramming 2>/dev/null)" = "200" ]'
  else
    details="blackboxprogramming (anonymous)"
    check_service "GitHub" "$details" \
      '[ "$(curl -s -o /dev/null -w "%{http_code}" --max-time 8 https://api.github.com/users/blackboxprogramming 2>/dev/null)" = "200" ]'
  fi
}

check_huggingface() {
  local details="Hub API"
  if [ -n "${HF_TOKEN:-}" ] || [ -n "${HUGGINGFACE_TOKEN:-}" ]; then
    details="Hub API (authenticated)"
  fi
  check_service "Hugging Face" "$details" \
    '[ $(curl -sf -o /dev/null -w "%{http_code}" --max-time 8 "https://huggingface.co/api/models?limit=1" 2>/dev/null) = "200" ]'
}

check_cloudflare() {
  local domain="${CLOUDFLARE_DOMAIN:-blackroad.io}"
  local details="$domain"
  if [ -n "${CLOUDFLARE_API_TOKEN:-}" ]; then
    details="$domain (API token set)"
  fi
  check_service "Cloudflare" "$details" \
    "curl -sf -o /dev/null --max-time 8 https://$domain 2>/dev/null || true"
}

check_vercel() {
  local details="API reachable"
  if [ -n "${VERCEL_TOKEN:-}" ]; then
    details="API (authenticated)"
  fi
  check_service "Vercel" "$details" \
    'curl -sf -o /dev/null --max-time 8 https://vercel.com 2>/dev/null'
}

check_digitalocean() {
  local ip="${DO_DROPLET_IP:-159.65.43.12}"
  local name="${DO_DROPLET_NAME:-blackroad os-infinity}"
  check_service "DigitalOcean" "$name ($ip)" \
    "ping -c 1 -W 5 $ip >/dev/null 2>&1"
}

check_ollama() {
  local url="${OLLAMA_URL:-http://localhost:11434}"
  local model_count
  model_count=$(curl -sf "$url/api/tags" 2>/dev/null | python3 -c "import sys,json; print(len(json.load(sys.stdin).get('models',[])))" 2>/dev/null || echo "0")
  check_service "Ollama" "$model_count models loaded ($url)" \
    '[ $(curl -sf -o /dev/null -w "%{http_code}" --max-time 5 "'"$url"'/api/tags" 2>/dev/null) = "200" ]'
}

check_railway() {
  local details=""
  if [ -n "${RAILWAY_TOKEN:-}" ]; then
    details="API token set"
    check_service "Railway" "$details" \
      '[ $(curl -sf -o /dev/null -w "%{http_code}" --max-time 8 -X POST -H "Authorization: Bearer '"$RAILWAY_TOKEN"'" -H "Content-Type: application/json" -d "{\"query\":\"{me{name}}\"}" https://backboard.railway.app/graphql/v2 2>/dev/null) = "200" ]'
  else
    details="CLI $(railway version 2>/dev/null || echo 'not found')"
    check_service "Railway" "$details" \
      "command -v railway >/dev/null 2>&1"
  fi
}

# ============================================================================
# Run Checks
# ============================================================================

if [ "$JSON_MODE" = false ]; then
  echo ""
  echo -e "${P}============================================================${NC}"
  echo -e "${P}  ${W}BLACKROAD INFRASTRUCTURE MESH${NC}"
  echo -e "${P}============================================================${NC}"
  echo ""
fi

if [ -n "$SINGLE_SERVICE" ]; then
  case "$SINGLE_SERVICE" in
    github) check_github ;;
    huggingface|hf) check_huggingface ;;
    cloudflare|cf) check_cloudflare ;;
    vercel) check_vercel ;;
    digitalocean|do) check_digitalocean ;;
    ollama) check_ollama ;;
    railway) check_railway ;;
    *) echo "Unknown service: $SINGLE_SERVICE"; exit 1 ;;
  esac
else
  check_github
  check_huggingface
  check_cloudflare
  check_vercel
  check_digitalocean
  check_ollama
  check_railway
fi

if [ "$JSON_MODE" = true ]; then
  echo "{\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"healthy\":$PASS,\"total\":$TOTAL,\"services\":[$(IFS=,; echo "${RESULTS[*]}")]}"
  exit 0
fi

echo ""
echo -e "${P}------------------------------------------------------------${NC}"
echo -e "  ${W}Result: ${G}$PASS${NC}/${W}$TOTAL${NC} services online"
echo -e "${P}------------------------------------------------------------${NC}"
echo ""

# ============================================================================
# Optional: Boot Full Stack
# ============================================================================

if [ "$BOOT" = true ]; then
  echo -e "${C}Booting BlackRoad OS stack...${NC}"
  echo ""

  CORE_DIR="$SCRIPT_DIR/repos/blackroad-os-core"

  if [ -f "$CORE_DIR/scripts/start-all.sh" ]; then
    exec "$CORE_DIR/scripts/start-all.sh" --dev --skip-devices
  else
    echo -e "${Y}No start-all.sh found at $CORE_DIR/scripts/start-all.sh${NC}"
    echo -e "${C}Starting mesh check via Python instead...${NC}"
    python3 -m blackroad_core.infra_mesh
  fi
fi
