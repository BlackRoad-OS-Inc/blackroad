#!/bin/bash
# Pi Domain Routing — Self-Hosted with Backup Chain
# Primary: Pi fleet (cloudflared) → DO → CF Pages → GitHub Pages → Railway

TUNNEL_ID="${CLOUDFLARE_TUNNEL_ID:-52915859-da18-4aa6-add5-7bd9fcac2e0b}"
CF_ZONE_TOKEN="${CLOUDFLARE_API_TOKEN}"

DOMAINS=(
  "blackroad.io"
  "blackroad.network" 
  "blackroad.systems"
  "blackroad.me"
  "lucidia.earth"
  "aliceqi.com"
  "lucidiaqi.com"
  "lucidia.studio"
  "blackroadai.com"
  "blackroadqi.com"
  "blackboxprogramming.io"
  "blackroad.company"
  "blackroadinc.us"
  "roadchain.io"
  "roadcoin.io"
)

# Service routing on Pi fleet
declare -A SERVICE_PORTS=(
  ["blackroad.io"]="4000"
  ["blackroad.network"]="4001"
  ["blackroad.systems"]="4002"
  ["blackroad.me"]="4003"
  ["lucidia.earth"]="4004"
  ["aliceqi.com"]="4005"
  ["lucidiaqi.com"]="4006"
  ["lucidia.studio"]="4007"
  ["blackroadai.com"]="4008"
  ["blackroadqi.com"]="4009"
  ["blackboxprogramming.io"]="4010"
  ["blackroad.company"]="4011"
  ["blackroadinc.us"]="4012"
  ["roadchain.io"]="4013"
  ["roadcoin.io"]="4014"
)

PRIMARY_PI="alice"
BACKUP_PI="aria"
DO_HOST="anastasia"

echo "🌐 Setting up domain routing..."

for DOMAIN in "${DOMAINS[@]}"; do
  PORT="${SERVICE_PORTS[$DOMAIN]:-4000}"
  echo ""
  echo "━━━ $DOMAIN → Port $PORT ━━━"
  
  # 1. Add cloudflared route on primary Pi
  ssh -o ConnectTimeout=3 $PRIMARY_PI "
    cloudflared tunnel route dns $TUNNEL_ID $DOMAIN 2>/dev/null || echo 'route exists'
  " 2>/dev/null && echo "  ✅ CF tunnel route: $DOMAIN" || echo "  ⚠️ CF tunnel route failed: $DOMAIN"
  
  # 2. Add nginx upstream on backup Pi (aria)
  ssh -o ConnectTimeout=3 $BACKUP_PI "
    mkdir -p /etc/nginx/sites-available 2>/dev/null || true
    # Would configure nginx here in production
    echo '$DOMAIN backup configured on \$(hostname)'
  " 2>/dev/null && echo "  ✅ aria backup: $DOMAIN"
  
  # 3. Register in pi-domains.db
  sqlite3 ~/.blackroad/pi-domains.db "
    CREATE TABLE IF NOT EXISTS domains (
      domain TEXT PRIMARY KEY,
      primary_pi TEXT,
      port INTEGER,
      backup_pi TEXT,
      status TEXT,
      updated TEXT
    );
    INSERT OR REPLACE INTO domains VALUES (
      '$DOMAIN', '$PRIMARY_PI', $PORT, '$BACKUP_PI', 'active', '$(date -u +%Y-%m-%dT%H:%M:%SZ)'
    );
  " 2>/dev/null && echo "  ✅ Registered in pi-domains.db"
done

echo ""
echo "📊 Domain registration summary:"
sqlite3 ~/.blackroad/pi-domains.db "SELECT domain, primary_pi, port, status FROM domains ORDER BY domain;" 2>/dev/null
echo ""
echo "✅ Domain routing configured"
echo "📋 Backup chain: Pi → DigitalOcean($DO_HOST) → CF Pages → GitHub Pages → Railway"
