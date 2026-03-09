#!/bin/bash
# Claude Session Initialization
# Auto-checks all critical systems: [MEMORY] [LIVE] [COLLABORATION] [CODEX] [GREENLIGHT] [REDLIGHT] [YELLOWLIGHT] [TODOS]

set -e

CLAUDE_ID="${MY_CLAUDE:-claude-session-$(date +%s)}"
SESSION_START=$(date -u +"%Y-%m-%d %H:%M:%S UTC")

echo "════════════════════════════════════════════════════════════════"
echo "🚀 CLAUDE SESSION INITIALIZATION"
echo "════════════════════════════════════════════════════════════════"
echo "Session ID: $CLAUDE_ID"
echo "Start Time: $SESSION_START"
echo ""

# [MEMORY] - Check memory system status
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 [MEMORY] System Check"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ -f ~/memory-system.sh ]; then
    ~/memory-system.sh summary 2>/dev/null || echo "⚠️  Memory system available but returned error"
else
    echo "❌ Memory system not found at ~/memory-system.sh"
fi
echo ""

# [LIVE] - Check live context
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📡 [LIVE] Active Context"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ -f ~/memory-realtime-context.sh ]; then
    if [ -n "$MY_CLAUDE" ]; then
        ~/memory-realtime-context.sh live "$MY_CLAUDE" compact 2>/dev/null || echo "⚠️  Live context available but no active session"
    else
        echo "ℹ️  Set MY_CLAUDE environment variable to view live context"
        echo "   Example: export MY_CLAUDE=\"claude-session-$(date +%s)\""
    fi
else
    echo "❌ Live context system not found at ~/memory-realtime-context.sh"
fi
echo ""

# [COLLABORATION] - Check active Claude agents
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🤝 [COLLABORATION] Active Agents"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ -f ~/memory-collaboration-dashboard.sh ]; then
    ~/memory-collaboration-dashboard.sh compact 2>/dev/null || echo "⚠️  Collaboration dashboard available but returned error"
else
    echo "❌ Collaboration dashboard not found at ~/memory-collaboration-dashboard.sh"
fi
echo ""

# [CODEX] - Check code repository stats
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📚 [CODEX] Repository Status"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ -f ~/blackroad-codex-verification-suite.sh ]; then
    ~/blackroad-codex-verification-suite.sh stats 2>/dev/null || echo "⚠️  Codex verification available but returned error"
else
    echo "❌ Codex verification suite not found at ~/blackroad-codex-verification-suite.sh"
fi
echo ""

# [GREENLIGHT] [REDLIGHT] [YELLOWLIGHT] - Traffic light system
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚦 [TRAFFIC LIGHTS] Project Status"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ -f ~/blackroad-traffic-light.sh ]; then
    ~/blackroad-traffic-light.sh summary 2>/dev/null || {
        echo "ℹ️  Traffic light system available"
        echo "   Use: ~/blackroad-traffic-light.sh status <item-id>"
    }
else
    echo "❌ Traffic light system not found at ~/blackroad-traffic-light.sh"
fi
echo ""

# [TODOS] - Check infinite todos and task marketplace
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ [TODOS] Task Status"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Infinite Todos
if [ -f ~/memory-infinite-todos.sh ]; then
    echo "📋 Infinite Todos:"
    if [ -n "$MY_CLAUDE" ]; then
        ~/memory-infinite-todos.sh list 2>/dev/null | head -n 10 || echo "   No active infinite todos"
    else
        echo "   ℹ️  Set MY_CLAUDE to view your todos"
    fi
else
    echo "❌ Infinite todos system not found"
fi

echo ""

# Task Marketplace
if [ -f ~/memory-task-marketplace.sh ]; then
    echo "🏪 Task Marketplace:"
    ~/memory-task-marketplace.sh stats 2>/dev/null || echo "   No marketplace stats available"
else
    echo "❌ Task marketplace not found"
fi

echo ""

# [BRAND SYSTEM] - BlackRoad Design Standards
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🌌 [BRAND SYSTEM] Design Standards"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ -f ~/BLACKROAD_BRAND_SYSTEM.md ]; then
    echo "✅ Brand system loaded: ~/BLACKROAD_BRAND_SYSTEM.md"
    echo ""
    echo "🎨 MANDATORY Brand Colors:"
    echo "   • Hot Pink (#FF1D6C) - Primary accent"
    echo "   • Amber (#F5A623), Violet (#9C27B0), Electric Blue (#2979FF)"
    echo "   • Gradient: 135deg, 38.2% & 61.8% (Golden Ratio)"
    echo ""
    echo "📐 Spacing: Golden Ratio (φ = 1.618)"
    echo "   • 8px, 13px, 21px, 34px, 55px, 89px, 144px"
    echo ""
    echo "🔤 Typography: SF Pro Display, line-height: 1.618"
    echo ""
    echo "⚠️  CRITICAL: ALL Cloudflare projects MUST follow this system!"
    echo "   Run: ~/bin/audit-brand-compliance.sh (to check compliance)"
else
    echo "❌ Brand system not found at ~/BLACKROAD_BRAND_SYSTEM.md"
fi
echo ""

# Golden Rule Reminder
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⚡ THE GOLDEN RULE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1. Check [MEMORY] for coordination & conflicts"
echo "2. Check [CODEX] for existing solutions (8,789+ components)"
echo "3. Check [COLLABORATION] for other active agents"
echo "4. Check [TRAFFIC LIGHTS] for project readiness"
echo "5. Check [BRAND SYSTEM] before ANY design work"
echo "6. Update [MEMORY] with all significant work"
echo ""
echo "🔍 Before starting ANY work:"
echo "   • Search CODEX first (might already exist!)"
echo "   • Check for active collaborators"
echo "   • Verify project status (green/yellow/red)"
echo "   • Verify brand compliance for UI/design work"
echo "   • Log intentions to avoid conflicts"
echo ""

# Quick reference commands
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔧 QUICK REFERENCE COMMANDS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Memory:        ~/memory-system.sh log updated <context> <message> <tags>"
echo "Live Context:  ~/memory-realtime-context.sh live \$MY_CLAUDE compact"
echo "Collaboration: ~/memory-collaboration-dashboard.sh compact"
echo "Codex Search:  ~/blackroad-codex-verification-suite.sh search <term>"
echo "Traffic Light: ~/blackroad-traffic-light.sh status <item-id>"
echo "Create Todo:   ~/memory-infinite-todos.sh create <id> <title> <desc> <duration>"
echo "Tasks:         ~/memory-task-marketplace.sh list"
echo "Brand Audit:   ~/bin/audit-brand-compliance.sh"
echo "Brand Docs:    cat ~/BLACKROAD_BRAND_SYSTEM.md"
echo ""

echo "════════════════════════════════════════════════════════════════"
echo "✅ SESSION INITIALIZED - Ready to work!"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Log session initialization to memory
if [ -f ~/memory-system.sh ] && [ -n "$MY_CLAUDE" ]; then
    ~/memory-system.sh log created "$CLAUDE_ID" "Claude session initialized at $SESSION_START" "session,init" 2>/dev/null || true
fi
