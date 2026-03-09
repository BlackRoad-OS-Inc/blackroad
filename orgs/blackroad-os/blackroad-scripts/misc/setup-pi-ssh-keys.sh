#!/bin/bash
# Add SSH keys to all BlackRoad Pis
# Usage: ./setup-pi-ssh-keys.sh

set -euo pipefail

# Pi addresses
PIS=(
    "pi@192.168.4.38"  # Lucidia
    "pi@192.168.4.64"  # Aria
    "pi@192.168.4.49"  # Alice
    "pi@192.168.4.99"  # Lucidia alternate
)

# SSH keys to add
KEYS=(
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAG0KSI0MH5FBBAL4QTjfRSE//n9VzEYFDG8zYG1eHOm alexa@mac"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB8NM5Hz85bDSyvgQsNKj85j3ODCpzahOZTbIci+LCHY #ssh.id - @blackroad-sandbox"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK3QFfJbQJhEqr6oA5EWMbD0nvIPzI7WST5cEGdyyrzQ #ssh.id - @blackroad-sandbox"
)

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Adding SSH Keys to BlackRoad Pis"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Pis to configure: ${#PIS[@]}"
echo "Keys to add: ${#KEYS[@]}"
echo ""

SUCCESS=0
FAILED=0

for pi in "${PIS[@]}"; do
    echo "Configuring: $pi"

    # Create authorized_keys file content
    KEYS_CONTENT=""
    for key in "${KEYS[@]}"; do
        KEYS_CONTENT="${KEYS_CONTENT}${key}\n"
    done

    # Add keys to Pi
    if ssh "$pi" "mkdir -p ~/.ssh && chmod 700 ~/.ssh && echo -e '$KEYS_CONTENT' >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys && sort -u ~/.ssh/authorized_keys -o ~/.ssh/authorized_keys" 2>/dev/null; then
        echo "  ✅ Keys added successfully"
        ((SUCCESS++))
    else
        echo "  ❌ Failed to add keys (check connectivity)"
        ((FAILED++))
    fi
    echo ""
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Summary:"
echo "  ✅ Configured: $SUCCESS"
echo "  ❌ Failed:     $FAILED"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [[ $SUCCESS -gt 0 ]]; then
    echo ""
    echo "✅ SSH keys added to $SUCCESS Pi(s)"
    echo ""
    echo "Next: Set up Termius SSH config"
    echo "See: TERMIUS_SSH_CONFIG.md"
fi
