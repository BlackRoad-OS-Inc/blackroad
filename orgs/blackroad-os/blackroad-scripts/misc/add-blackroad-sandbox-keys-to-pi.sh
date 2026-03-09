#!/bin/bash
# Add BlackRoad Sandbox SSH Keys to Raspberry Pi
# Usage: Run this on aria or octavia when they come online

echo "🔑 Adding BlackRoad Sandbox SSH Keys"
echo "===================================="

mkdir -p ~/.ssh
chmod 700 ~/.ssh

cat >> ~/.ssh/authorized_keys << 'KEYS'
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB8NM5Hz85bDSyvgQsNKj85j3ODCpzahOZTbIci+LCHY #ssh.id - @blackroad-sandbox
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK3QFfJbQJhEqr6oA5EWMbD0nvIPzI7WST5cEGdyyrzQ #ssh.id - @blackroad-sandbox https://sshid.io/blackroad-sandbox
KEYS

chmod 600 ~/.ssh/authorized_keys

echo "✅ BlackRoad Sandbox SSH keys added!"
echo "Keys in authorized_keys: $(wc -l < ~/.ssh/authorized_keys)"
echo ""
echo "Test with: ssh pi@$(hostname -I | awk '{print $1}')"
