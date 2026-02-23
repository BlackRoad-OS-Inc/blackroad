#!/bin/bash
# Install Caddy on Pi without root - uses user-space port 8088
CADDY_VERSION="2.9.1"
ARCH=$(uname -m)
case $ARCH in
  aarch64|arm64) ARCH_SUFFIX="linux_arm64" ;;
  armv7l|armhf)  ARCH_SUFFIX="linux_armv7" ;;
  x86_64)        ARCH_SUFFIX="linux_amd64" ;;
esac

mkdir -p ~/.local/bin ~/.caddy

echo "⬇️  Downloading Caddy $CADDY_VERSION for $ARCH_SUFFIX..."
curl -sSL "https://github.com/caddyserver/caddy/releases/download/v${CADDY_VERSION}/caddy_${CADDY_VERSION}_${ARCH_SUFFIX}.tar.gz" \
  -o /tmp/caddy.tar.gz

tar -xzf /tmp/caddy.tar.gz -C ~/.local/bin caddy
chmod +x ~/.local/bin/caddy
echo "✅ Caddy installed: $(~/.local/bin/caddy version)"
