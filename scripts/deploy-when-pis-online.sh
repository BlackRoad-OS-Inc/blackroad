#!/bin/bash
# Run this once Tailscale is back online to deploy runners and domain hosting to all Pis

set -e
GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'
RUNNER_TOKEN="${1:-$RUNNER_TOKEN}"

PIES=(
  "octavia:100.66.235.47"
  "alice:100.77.210.18"
  "aria:100.109.14.17"
  "lucidia:100.83.149.86"
  "cecilia:100.72.180.98"
)

for entry in "${PIES[@]}"; do
  NAME="${entry%%:*}"
  IP="${entry##*:}"
  echo -e "${CYAN}🚀 Deploying to ${NAME} (${IP})...${NC}"
  
  # Deploy runner
  ssh -o ConnectTimeout=5 -o BatchMode=yes blackroad@${IP} \
    "bash -s $NAME 'self-hosted,pi,arm64,${NAME},blackroad-pi-cluster' blackboxprogramming/blackroad ${RUNNER_TOKEN}" \
    < scripts/install-runner.sh 2>/dev/null && echo -e "${GREEN}  ✅ Runner: ${NAME}${NC}" || echo "  ⚠️ Runner failed"
  
  # Deploy Caddyfile
  scp -o ConnectTimeout=5 -o BatchMode=yes \
    scripts/Caddyfile.pi blackroad@${IP}:/tmp/Caddyfile 2>/dev/null && \
    ssh -o ConnectTimeout=5 -o BatchMode=yes blackroad@${IP} \
      "sudo cp /tmp/Caddyfile /etc/caddy/Caddyfile && sudo systemctl reload caddy" 2>/dev/null && \
    echo -e "${GREEN}  ✅ Caddy: ${NAME}${NC}" || echo "  ⚠️ Caddy failed (ok if no sudo)"
    
  # Deploy domain hosting setup
  scp -o ConnectTimeout=5 -o BatchMode=yes \
    scripts/pi-domain-hosting-setup.sh blackroad@${IP}:~/pi-domain-hosting-setup.sh 2>/dev/null && \
    echo -e "${GREEN}  ✅ Domain setup staged: ${NAME}${NC}" || echo "  ⚠️ SCP failed"
done

echo -e "${GREEN}🎉 Pi cluster deployment complete!${NC}"
