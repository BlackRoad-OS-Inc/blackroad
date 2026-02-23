#!/bin/zsh
# Check Pi failover health and switch if needed
PRIMARY="alice@192.168.4.49"
SECONDARY="pi@192.168.4.38"

echo "Checking Pi fleet failover..."
if ping -c1 -W2 192.168.4.49 > /dev/null 2>&1; then
  echo "✓ Primary (alice) UP"
else
  echo "✗ Primary (alice) DOWN — failover to aria (192.168.4.38)"
  echo "  Manual step: update cloudflare DNS CNAME for tunnel"
  echo "  Or: restart cloudflared on aria: ssh $SECONDARY 'sudo systemctl start cloudflared'"
fi

if ping -c1 -W2 192.168.4.38 > /dev/null 2>&1; then
  echo "✓ Secondary (aria) UP"
else
  echo "✗ Secondary (aria) DOWN"
fi
