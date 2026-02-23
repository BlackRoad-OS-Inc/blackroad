#!/bin/bash
# Deploy runners and domain hosting to all Pis
# Uses local IPs directly (Tailscale not required)

set -e
GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; NC='\033[0m'
RUNNER_TOKEN="${1:-$RUNNER_TOKEN}"
GH_REPO="${2:-BlackRoad-OS-Inc/blackroad}"

# Local IPs confirmed working (Tailscale: 100.x.x.x also listed as fallback)
PIES=(
  "octavia:192.168.4.38:100.66.235.47"
  "alice:192.168.4.49:100.77.210.18"
  "aria:192.168.4.82:100.109.14.17"
  "lucidia:192.168.4.81:100.83.149.86"
  "cecilia:192.168.4.89:100.72.180.98"
)

for entry in "${PIES[@]}"; do
  NAME=$(echo "$entry" | cut -d: -f1)
  LOCAL_IP=$(echo "$entry" | cut -d: -f2)
  TS_IP=$(echo "$entry" | cut -d: -f3)
  
  # Try local IP first, fallback to Tailscale
  IP="$LOCAL_IP"
  if ! ssh -o ConnectTimeout=3 -o BatchMode=yes blackroad@${LOCAL_IP} "exit" 2>/dev/null; then
    echo -e "${YELLOW}  Local IP failed, trying Tailscale...${NC}"
    IP="$TS_IP"
  fi
  
  echo -e "${CYAN}🚀 Deploying to ${NAME} (${IP})...${NC}"
  
  # Deploy runner — reconfigure existing or fresh install
  if [ -n "$RUNNER_TOKEN" ]; then
    ssh -o ConnectTimeout=10 -o BatchMode=yes blackroad@${IP} \
      "cd ~/actions-runner 2>/dev/null || (mkdir -p ~/actions-runner && cd ~/actions-runner && \
       curl -sL https://github.com/actions/runner/releases/download/v2.323.0/actions-runner-linux-arm64-2.323.0.tar.gz | tar xz); \
       ./config.sh --url https://github.com/${GH_REPO} \
         --token ${RUNNER_TOKEN} --name ${NAME}-pi \
         --labels 'self-hosted,pi,arm64,${NAME},blackroad-fleet' \
         --work _work --unattended --replace 2>&1 | tail -2 && \
       nohup ./run.sh > ~/runner.log 2>&1 & echo \$! > ~/runner.pid && echo '✅ runner started'" \
      2>/dev/null && echo -e "${GREEN}  ✅ Runner: ${NAME}${NC}" || echo "  ⚠️ Runner failed"
  else
    echo -e "${YELLOW}  ⚠️ No RUNNER_TOKEN — skipping runner deploy${NC}"
  fi
  
  # Deploy Caddyfile
  scp -o ConnectTimeout=5 -o BatchMode=yes \
    scripts/Caddyfile.pi blackroad@${IP}:/tmp/Caddyfile 2>/dev/null && \
    ssh -o ConnectTimeout=5 -o BatchMode=yes blackroad@${IP} \
      "sudo cp /tmp/Caddyfile /etc/caddy/Caddyfile && sudo systemctl reload caddy 2>/dev/null || \
       sudo systemctl start caddy 2>/dev/null" 2>/dev/null && \
    echo -e "${GREEN}  ✅ Caddy: ${NAME}${NC}" || echo "  ⚠️ Caddy failed (ok if no sudo)"
    
  # Stage domain hosting setup + PI agent setup
  scp -o ConnectTimeout=5 -o BatchMode=yes \
    scripts/pi-domain-hosting-setup.sh \
    scripts/cloudflare-dns-pi-setup.sh \
    blackroad@${IP}:~/ 2>/dev/null && \
    echo -e "${GREEN}  ✅ Scripts staged: ${NAME}${NC}" || echo "  ⚠️ SCP failed"
done

echo -e "${GREEN}🎉 Pi cluster deployment complete!${NC}"
