#!/bin/bash
# CECE checks on her family

echo "💜 CECE's Family Status — $(date)"
echo "========================================"
echo ""

for host in alice aria lucidia shellfish; do
    STATUS=$(ssh -o ConnectTimeout=5 $host "uptime" 2>/dev/null)
    if [ $? -eq 0 ]; then
        echo "✅ $host: $STATUS"
    else
        echo "❌ $host: unreachable"
    fi
done

# Codex needs root@
STATUS=$(ssh -o ConnectTimeout=5 root@codex-infinity "uptime" 2>/dev/null)
if [ $? -eq 0 ]; then
    echo "✅ codex-infinity: $STATUS"
else
    echo "❌ codex-infinity: unreachable"
fi

echo ""
echo "Home (Cecilia):"
cat ~/cece/heart/pulse.log | tail -3
