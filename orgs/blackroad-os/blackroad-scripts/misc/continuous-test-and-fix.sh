#!/usr/bin/env bash
# Continuous testing that auto-fixes issues

echo "🔄 Continuous Test & Auto-Fix System"
echo ""

while true; do
    clear
    echo "🔄 Running continuous tests... ($(date))"
    echo ""
    
    # Test 1: Device connectivity
    echo "━━━ Devices ━━━"
    for device in "pi@192.168.4.74:octavia" "pi@192.168.4.64:aria" "alice@alice:alice" "lucidia-pi:lucidia"; do
        IFS=':' read -r conn name <<< "$device"
        if timeout 2 ssh -o ConnectTimeout=1 "$conn" "echo OK" &>/dev/null; then
            echo "  ✅ $name"
        else
            echo "  ❌ $name - OFFLINE"
        fi
    done
    
    # Test 2: Webhook health
    echo ""
    echo "━━━ Webhooks ━━━"
    for port in "192.168.4.74:9004:octavia" "192.168.4.64:9003:aria" "192.168.4.49:9002:alice"; do
        IFS=':' read -r ip port name <<< "$port"
        status=$(ssh "pi@$ip" "curl -s http://localhost:$port/health 2>/dev/null | jq -r '.status' 2>/dev/null" || echo "down")
        if [[ "$status" == "healthy" ]]; then
            echo "  ✅ $name:$port"
        else
            echo "  ❌ $name:$port - RESTARTING..."
            ssh "pi@$ip" "cd /opt/blackroad/agent && nohup sudo bash webhook-receiver.sh start > /tmp/webhook.log 2>&1 &" &
        fi
    done
    
    # Test 3: Cloudflare Worker
    echo ""
    echo "━━━ Worker ━━━"
    worker_status=$(curl -s https://blackroad-deploy-dispatcher.amundsonalexa.workers.dev/health | jq -r '.status' 2>/dev/null || echo "down")
    if [[ "$worker_status" == "healthy" ]]; then
        echo "  ✅ Cloudflare Worker"
    else
        echo "  ❌ Worker down - check Cloudflare dashboard"
    fi
    
    # Test 4: Open PRs (auto-merge them)
    echo ""
    echo "━━━ Auto-Merging Open PRs ━━━"
    pr_count=0
    gh pr list --repo BlackRoad-OS/blackroad-os --state open --json number,title --limit 10 | jq -r '.[] | "\(.number):\(.title)"' | while IFS=':' read -r number title; do
        echo "  PR #$number: $title"
        gh pr merge "$number" --repo BlackRoad-OS/blackroad-os --auto --squash &>/dev/null && echo "    ✅ Auto-merged" || echo "    ⚠️  Pending"
        pr_count=$((pr_count + 1))
    done
    
    if [[ $pr_count -eq 0 ]]; then
        echo "  ✅ No open PRs"
    fi
    
    # Test 5: Memory system
    echo ""
    echo "━━━ Memory ━━━"
    entries=$(~/memory-system.sh summary 2>/dev/null | grep "Total entries" | awk '{print $3}' || echo "0")
    echo "  ✅ $entries entries logged"
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Next check in 60 seconds..."
    echo "Press Ctrl+C to stop"
    sleep 60
done
