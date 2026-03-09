#!/usr/bin/env bash
# Test BlackRoad OS on all devices
# Simple automatic test you run manually

set -euo pipefail

echo "🖤🛣️  Testing BlackRoad-OS on All Devices"
echo ""

DEVICES=("lucidia-pi" "alice-pi" "aria-pi" "octavia-pi")
REPO_PATH="/opt/blackroad/workspace/repos/blackroad-os"

for device in "${DEVICES[@]}"; do
    echo "━━━ $device ━━━"
    
    # Check if device is online
    if ! timeout 3 ssh -o ConnectTimeout=2 "$device" "echo OK" &>/dev/null; then
        echo "  ❌ OFFLINE"
        continue
    fi
    
    # Clone/update repo
    echo -n "  Repo ... "
    if ssh "$device" "test -d $REPO_PATH" 2>/dev/null; then
        ssh "$device" "cd $REPO_PATH && git fetch && git pull" &>/dev/null && echo "✅ Updated" || echo "❌ Failed"
    else
        ssh "$device" "sudo mkdir -p /opt/blackroad/workspace/repos && cd /opt/blackroad/workspace/repos && git clone ~/blackroad-os blackroad-os" &>/dev/null && echo "✅ Cloned" || echo "❌ Failed"
    fi
    
    # Check Node.js
    echo -n "  Node ... "
    if ssh "$device" "command -v node &>/dev/null"; then
        version=$(ssh "$device" "node --version")
        echo "✅ $version"
    else
        echo "❌ Not installed"
    fi
    
    # Check disk space
    echo -n "  Disk ... "
    usage=$(ssh "$device" "df / | tail -1 | awk '{print \$5}'")
    echo "✅ $usage used"
    
    # Check if scripts exist
    echo -n "  Scripts ... "
    if ssh "$device" "test -d /opt/blackroad/scripts" 2>/dev/null; then
        count=$(ssh "$device" "ls /opt/blackroad/scripts/*.sh 2>/dev/null | wc -l")
        echo "✅ $count files"
    else
        echo "⚠️  None"
    fi
    
    echo ""
done

echo "━━━ Local (operator-mac) ━━━"
echo -n "  blackroad-cli ... "
[[ -x ~/blackroad-cli.sh ]] && echo "✅ Installed" || echo "❌ Missing"

echo -n "  blackroad-os dir ... "
[[ -d ~/blackroad-os ]] && echo "✅ Exists" || echo "❌ Missing"

echo ""
echo "✅ Test complete!"
