#!/bin/bash
# Run this when lucidia-pi (192.168.4.64) comes back online
# Registers it as a GitHub self-hosted runner

PI_IP="192.168.4.64"
SSH_KEY="$HOME/.ssh/br_mesh_ed25519"
SSH_CMD="ssh -i $SSH_KEY -o ConnectTimeout=10 pi@$PI_IP"

echo "Checking lucidia-pi..."
$SSH_CMD "echo alive:$(hostname)" || { echo "❌ Still offline"; exit 1; }

echo "✅ Online! Setting up runner..."
bash scripts/setup-pi-runner.sh lucidia-pi "$PI_IP"
echo "✅ lucidia-pi runner registered"
