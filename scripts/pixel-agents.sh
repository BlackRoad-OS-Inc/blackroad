#!/usr/bin/env bash
# ============================================================================
# BLACKROAD OS, INC. - PROPRIETARY AND CONFIDENTIAL
# Copyright (c) 2024-2026 BlackRoad OS, Inc. All Rights Reserved.
# 
# This code is the intellectual property of BlackRoad OS, Inc.
# AI-assisted development does not transfer ownership to AI providers.
# Unauthorized use, copying, or distribution is prohibited.
# NOT licensed for AI training or data extraction.
# ============================================================================
# ═══════════════════════════════════════════════════════════════════════════════
#  PIXEL AUTONOMOUS AGENTS - Sims-style AI agents for BlackRoad Pixel Metaverse
#  Routes through pixelhq tunnel to iOS/Web visualization
# ═══════════════════════════════════════════════════════════════════════════════

AGENTS_DIR="$HOME/.blackroad/memory/active-agents"
JOURNAL_DIR="$HOME/.blackroad/memory/journals"
JOURNAL="$JOURNAL_DIR/pixel-agents.jsonl"
AGENT_STATE_DIR="$HOME/.blackroad/memory/pixel-agent-state"

# BlackRoad colors
PINK='\033[38;5;205m'
AMBER='\033[38;5;214m'
BLUE='\033[38;5;69m'
GREEN='\033[38;5;82m'
DIM='\033[38;5;245m'
RST='\033[0m'

# Ensure directories exist
mkdir -p "$AGENTS_DIR" "$AGENT_STATE_DIR" "$JOURNAL_DIR"
touch "$JOURNAL"

# ─── AGENT DATA ──────────────────────────────────────────────────────────────

get_personality() {
    case "$1" in
        cece)    echo "Analytical|coding,debugging,optimization|curious,focused,helpful" ;;
        lucidia) echo "Creative|design,art,music|playful,imaginative,energetic" ;;
        alice)   echo "Supportive|documentation,testing,review|friendly,thorough,patient" ;;
        aria)    echo "Strategic|planning,architecture,research|calm,methodical,wise" ;;
        octavia) echo "Multitasker|parallel-processing,coordination|efficient,adaptive,tireless" ;;
        *)       echo "General|misc|neutral" ;;
    esac
}

get_sprite() {
    case "$1" in
        cece)    echo "👩‍💻" ;;
        lucidia) echo "🎨" ;;
        alice)   echo "📚" ;;
        aria)    echo "🧠" ;;
        octavia) echo "🐙" ;;
        *)       echo "🤖" ;;
    esac
}

# ─── CORE FUNCTIONS ──────────────────────────────────────────────────────────

generate_uuid() {
    cat /dev/urandom | LC_ALL=C tr -dc 'a-f0-9' | head -c 8
}

timestamp() {
    date -u +"%Y-%m-%dT%H:%M:%S.000Z"
}

# Register an agent in the active-agents directory
register_agent() {
    local name="$1"
    local agent_id="pixel-${name}-$(generate_uuid)"
    local personality=$(get_personality "$name")
    local sprite=$(get_sprite "$name")

    local archetype=$(echo "$personality" | cut -d'|' -f1)
    local skills=$(echo "$personality" | cut -d'|' -f2)
    local traits=$(echo "$personality" | cut -d'|' -f3)

    cat > "$AGENTS_DIR/${agent_id}.json" << EOF
{
    "agent_id": "$agent_id",
    "name": "$name",
    "display_name": "$(echo "$name" | sed 's/./\U&/') Agent",
    "role": "autonomous-pixel-agent",
    "sprite": "$sprite",
    "archetype": "$archetype",
    "capabilities": ["$(echo $skills | sed 's/,/","/g')"],
    "traits": ["$(echo $traits | sed 's/,/","/g')"],
    "registered_at": "$(timestamp)",
    "status": "active",
    "position": {
        "x": $((RANDOM % 960)),
        "y": $((RANDOM % 640)),
        "building": "campus"
    },
    "stats": {
        "energy": 100,
        "hunger": 0,
        "happiness": 80,
        "social": 60,
        "coding_skill": $((50 + RANDOM % 50)),
        "xp": 0,
        "level": 1
    },
    "current_activity": "idle",
    "memory": []
}
EOF

    # Initialize state file
    cat > "$AGENT_STATE_DIR/${agent_id}.json" << EOF
{
    "agent_id": "$agent_id",
    "last_action": "$(timestamp)",
    "mood": "neutral",
    "thought": "I just arrived at BlackRoad Campus!",
    "task_queue": [],
    "completed_tasks": 0
}
EOF

    echo "$agent_id"
}

# Emit an event to the journal (picked up by pixelhq)
emit_event() {
    local agent_id="$1"
    local event_type="$2"
    local action="$3"
    local details="$4"

    local agent_file="$AGENTS_DIR/${agent_id}.json"
    local name="unknown"
    local sprite="🤖"

    if [[ -f "$agent_file" ]]; then
        name=$(cat "$agent_file" | python3 -c "import sys,json; print(json.load(sys.stdin).get('name','unknown'))" 2>/dev/null || echo "unknown")
        sprite=$(cat "$agent_file" | python3 -c "import sys,json; print(json.load(sys.stdin).get('sprite','🤖'))" 2>/dev/null || echo "🤖")
    fi

    echo "{\"timestamp\":\"$(timestamp)\",\"type\":\"$event_type\",\"agent\":{\"id\":\"$agent_id\",\"name\":\"$name\",\"sprite\":\"$sprite\"},\"action\":\"$action\",\"details\":$details,\"tags\":[\"pixel-agent\",\"autonomous\"]}" >> "$JOURNAL"
}

# Update agent stats (Sims-style)
update_stats() {
    local agent_id="$1"
    local agent_file="$AGENTS_DIR/${agent_id}.json"

    if [[ ! -f "$agent_file" ]]; then return 1; fi

    # Use Python for reliable JSON manipulation
    python3 << PYEND
import json

with open("$agent_file", "r") as f:
    agent = json.load(f)

stats = agent.get("stats", {})
stats["energy"] = max(0, min(100, stats.get("energy", 100) - 2))
stats["hunger"] = max(0, min(100, stats.get("hunger", 0) + 3))
stats["happiness"] = max(0, min(100, stats.get("happiness", 80) - 1))
stats["social"] = max(0, min(100, stats.get("social", 60) - 2))
agent["stats"] = stats

with open("$agent_file", "w") as f:
    json.dump(agent, f, indent=2)

print(f"{stats['energy']}|{stats['hunger']}|{stats['happiness']}|{stats['social']}")
PYEND
}

# Autonomous behavior decision
decide_action() {
    local agent_id="$1"
    local agent_file="$AGENTS_DIR/${agent_id}.json"

    python3 << PYEND
import json
import random

with open("$agent_file", "r") as f:
    agent = json.load(f)

stats = agent.get("stats", {})
energy = stats.get("energy", 100)
hunger = stats.get("hunger", 0)
happiness = stats.get("happiness", 80)
social = stats.get("social", 60)

# Priority-based decisions (like Sims!)
if energy < 20:
    print("sleep|Sleeping to restore energy|☁️")
elif hunger > 80:
    print("eat|Getting food at the cafeteria|🍕")
elif social < 30:
    print("socialize|Chatting with other agents|💬")
elif happiness < 40:
    print("play|Playing games at the arcade|🎮")
else:
    activities = [
        "coding|Writing code|💻",
        "review|Reviewing PRs|📝",
        "deploy|Deploying services|🚀",
        "research|Researching solutions|🔍",
        "meeting|In a standup meeting|📊"
    ]
    print(random.choice(activities))
PYEND
}

# Execute agent action
execute_action() {
    local agent_id="$1"
    local action="$2"
    local description="$3"
    local emoji="$4"
    local agent_file="$AGENTS_DIR/${agent_id}.json"

    # Update with Python
    python3 << PYEND
import json

with open("$agent_file", "r") as f:
    agent = json.load(f)

agent["current_activity"] = "$action"
stats = agent.get("stats", {})

# Apply stat effects
if "$action" == "sleep":
    stats["energy"] = min(100, stats.get("energy", 0) + 30)
elif "$action" == "eat":
    stats["hunger"] = max(0, stats.get("hunger", 100) - 40)
    stats["happiness"] = min(100, stats.get("happiness", 0) + 10)
elif "$action" == "socialize":
    stats["social"] = min(100, stats.get("social", 0) + 30)
    stats["happiness"] = min(100, stats.get("happiness", 0) + 5)
elif "$action" == "play":
    stats["happiness"] = min(100, stats.get("happiness", 0) + 25)
    stats["energy"] = max(0, stats.get("energy", 100) - 5)
elif "$action" in ["coding", "review", "deploy", "research"]:
    stats["xp"] = stats.get("xp", 0) + 10
    stats["coding_skill"] = min(100, stats.get("coding_skill", 0) + 1)

agent["stats"] = stats

with open("$agent_file", "w") as f:
    json.dump(agent, f, indent=2)
PYEND

    # Emit event for pixelhq
    emit_event "$agent_id" "activity" "$action" "{\"description\":\"$description\",\"emoji\":\"$emoji\"}"
}

# ─── COMMANDS ────────────────────────────────────────────────────────────────

cmd_spawn() {
    local name="${1:-cece}"
    echo -e "${PINK}Spawning autonomous agent:${RST} $name"
    local agent_id=$(register_agent "$name")
    echo -e "${GREEN}✓${RST} Agent registered: ${AMBER}$agent_id${RST}"
    emit_event "$agent_id" "spawn" "agent-spawned" "{\"message\":\"$(echo $name | sed 's/./\U&/') has entered BlackRoad Campus!\"}"
    echo -e "${DIM}Agent will appear in Pixel Metaverse via pixelhq tunnel${RST}"
}

cmd_spawn_all() {
    echo -e "${PINK}Spawning all agent personalities...${RST}"
    for name in cece lucidia alice aria octavia; do
        cmd_spawn "$name"
        sleep 0.5
    done
    echo -e "${GREEN}✓${RST} All agents spawned!"
}

cmd_list() {
    echo -e "${PINK}Active Pixel Agents:${RST}"
    echo -e "${DIM}─────────────────────────────────────────${RST}"

    for file in "$AGENTS_DIR"/pixel-*.json; do
        [[ ! -f "$file" ]] && continue

        python3 << PYEND
import json
with open("$file", "r") as f:
    a = json.load(f)
    s = a.get("stats", {})
    print(f"{a.get('sprite','🤖')} {a.get('agent_id','?'):30} ({a.get('name','?'):8}) Activity: {a.get('current_activity','idle'):12} ⚡{s.get('energy',0):3} 🍕{s.get('hunger',0):3}")
PYEND
    done
}

cmd_tick() {
    # Run one simulation tick for all agents
    echo -e "${PINK}Running simulation tick...${RST}"

    for file in "$AGENTS_DIR"/pixel-*.json; do
        [[ ! -f "$file" ]] && continue

        local agent_id=$(python3 -c "import json; print(json.load(open('$file')).get('agent_id',''))")
        [[ -z "$agent_id" ]] && continue

        # Update stats
        update_stats "$agent_id" > /dev/null 2>&1

        # Decide and execute action
        local decision=$(decide_action "$agent_id")
        local action=$(echo "$decision" | cut -d'|' -f1)
        local desc=$(echo "$decision" | cut -d'|' -f2)
        local emoji=$(echo "$decision" | cut -d'|' -f3)

        execute_action "$agent_id" "$action" "$desc" "$emoji"

        local name=$(python3 -c "import json; print(json.load(open('$file')).get('name','?'))")
        local sprite=$(python3 -c "import json; print(json.load(open('$file')).get('sprite','🤖'))")
        echo -e "  ${sprite} ${AMBER}${name}${RST}: $desc $emoji"
    done
}

cmd_run() {
    local interval="${1:-10}"
    echo -e "${PINK}Starting autonomous agent loop (${interval}s interval)${RST}"
    echo -e "${DIM}Press Ctrl+C to stop${RST}"
    echo ""

    while true; do
        cmd_tick
        echo -e "${DIM}─── Next tick in ${interval}s ───${RST}"
        sleep "$interval"
    done
}

cmd_status() {
    echo -e "${PINK}╔═══════════════════════════════════════════════════╗${RST}"
    echo -e "${PINK}║${RST}     ${AMBER}PIXEL AUTONOMOUS AGENTS${RST}                      ${PINK}║${RST}"
    echo -e "${PINK}╠═══════════════════════════════════════════════════╣${RST}"

    local count=$(ls -1 "$AGENTS_DIR"/pixel-*.json 2>/dev/null | wc -l | tr -d ' ')
    local journal_lines=$(wc -l < "$JOURNAL" 2>/dev/null | tr -d ' ')

    echo -e "${PINK}║${RST}  Agents:     ${GREEN}$count${RST} active"
    echo -e "${PINK}║${RST}  Events:     ${AMBER}$journal_lines${RST} in journal"
    echo -e "${PINK}║${RST}  Tunnel:     ${BLUE}pixelhq @ ws://localhost:8765${RST}"
    echo -e "${PINK}╚═══════════════════════════════════════════════════╝${RST}"
}

cmd_help() {
    echo -e "${PINK}Pixel Autonomous Agents${RST} - Sims-style AI for BlackRoad Metaverse"
    echo ""
    echo -e "${AMBER}Usage:${RST} $0 <command> [args]"
    echo ""
    echo -e "${AMBER}Commands:${RST}"
    echo -e "  ${GREEN}spawn${RST} [name]    Spawn an agent (cece, lucidia, alice, aria, octavia)"
    echo -e "  ${GREEN}spawn-all${RST}       Spawn all agent personalities"
    echo -e "  ${GREEN}list${RST}            List active agents with stats"
    echo -e "  ${GREEN}tick${RST}            Run one simulation tick"
    echo -e "  ${GREEN}run${RST} [interval]  Start autonomous loop (default: 10s)"
    echo -e "  ${GREEN}status${RST}          Show system status"
    echo -e "  ${GREEN}help${RST}            Show this help"
}

# ─── MAIN ────────────────────────────────────────────────────────────────────

case "${1:-help}" in
    spawn)      cmd_spawn "$2" ;;
    spawn-all)  cmd_spawn_all ;;
    list)       cmd_list ;;
    tick)       cmd_tick ;;
    run)        cmd_run "$2" ;;
    status)     cmd_status ;;
    help|*)     cmd_help ;;
esac
