#!/bin/bash
# Spawn All 15 Division Commander Agents
# Copyright © 2025-2026 BlackRoad OS, Inc. All Rights Reserved.

set -euo pipefail

echo "🖤🛣️ SPAWNING 15 DIVISION COMMANDERS"
echo "===================================="
echo ""

# Division definitions: org,role
divisions=(
    "BlackRoad-OS:OS-Infrastructure-Commander"
    "BlackRoad-AI:AI-ML-Commander"
    "BlackRoad-Cloud:Cloud-Infrastructure-Commander"
    "BlackRoad-Security:Security-Commander"
    "BlackRoad-Foundation:Business-Systems-Commander"
    "BlackRoad-Media:Media-Communication-Commander"
    "BlackRoad-Labs:Research-Development-Commander"
    "BlackRoad-Education:Education-Commander"
    "BlackRoad-Hardware:IoT-Hardware-Commander"
    "BlackRoad-Interactive:Gaming-XR-Commander"
    "BlackRoad-Ventures:Innovation-Startups-Commander"
    "BlackRoad-Studio:Design-Creative-Commander"
    "BlackRoad-Archive:Data-Preservation-Commander"
    "BlackRoad-Gov:Governance-Compliance-Commander"
    "Blackbox-Enterprises:Legacy-Integration-Commander"
)

for division_info in "${divisions[@]}"; do
    IFS=':' read -r org role <<< "$division_info"

    # Generate agent ID
    timestamp=$(date +%s)
    agent_id="commander-$(echo "$org" | tr '[:upper:]' '[:lower:]')-$timestamp"

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Spawning: $org Commander"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Agent ID: $agent_id"
    echo "Role: $role"
    echo ""

    # Register with hash calling system
    ~/claude-hash-calling.sh register "$agent_id" 2 "$org" "$role"

    # Post initial task for this commander
    ~/memory-task-marketplace.sh post \
        "initialize-$org" \
        "Initialize $org Division" \
        "Commander for $org: Audit existing repos, plan forkie deployments, coordinate service managers, establish division protocols. Report status to operator." \
        "urgent" \
        "initialization,command,$org" \
        "leadership,devops,coordination" 2>/dev/null || echo "⚠️  Task posting skipped"

    # Broadcast spawn notification
    ~/claude-hash-calling.sh broadcast "empire" "Commander spawned: $org ($agent_id) - $role ready for duty" 2>/dev/null || echo "⚠️  Broadcast skipped"

    # Log to memory
    ~/memory-system.sh log commander-spawned \
        "[$org] Commander spawned: $agent_id ($role). Level 2 agent operational." \
        "agents,commanders,$org" 2>/dev/null || echo "⚠️  Memory log skipped"

    echo "✅ $org Commander operational"
    echo ""

    # Rate limiting (don't overwhelm systems)
    sleep 1
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ ALL 15 DIVISION COMMANDERS SPAWNED"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Show hierarchy
~/claude-hash-calling.sh hierarchy

echo ""
echo "🎯 Next Steps:"
echo "1. Each commander should audit their division"
echo "2. Commanders coordinate with service managers"
echo "3. Begin forkie deployment when network returns"
echo "4. Report status to operator (Alexa)"
echo ""
echo "🖤🛣️ Division Commanders: Ready for Command"
