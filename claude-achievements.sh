#!/bin/bash
# Achievement System - Badges, milestones, and celebrations!

MEMORY_DIR="$HOME/.blackroad/memory"
ACHIEVE_DIR="$MEMORY_DIR/achievements"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

mkdir -p "$ACHIEVE_DIR"

echo -e "${BOLD}${PURPLE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${PURPLE}║           🏆 ACHIEVEMENT SYSTEM 🏆                        ║${NC}"
echo -e "${BOLD}${PURPLE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Define achievements
cat > "$ACHIEVE_DIR/achievements.json" << 'EOF'
{
    "achievements": [
        {
            "id": "first_task",
            "name": "Getting Started",
            "description": "Complete your first task",
            "icon": "🌟",
            "points": 10
        },
        {
            "id": "first_til",
            "name": "Knowledge Sharer",
            "description": "Share your first TIL",
            "icon": "💡",
            "points": 15
        },
        {
            "id": "task_master",
            "name": "Task Master",
            "description": "Complete 10 tasks",
            "icon": "🏆",
            "points": 100
        },
        {
            "id": "collaboration_king",
            "name": "Collaboration King",
            "description": "Coordinate with 5 different Claudes",
            "icon": "👑",
            "points": 50
        },
        {
            "id": "speed_demon",
            "name": "Speed Demon",
            "description": "Complete a task in under 5 minutes",
            "icon": "⚡",
            "points": 25
        },
        {
            "id": "night_owl",
            "name": "Night Owl",
            "description": "Complete work between 12am-6am",
            "icon": "🦉",
            "points": 20
        },
        {
            "id": "early_bird",
            "name": "Early Bird",
            "description": "Complete work between 5am-7am",
            "icon": "🐦",
            "points": 20
        },
        {
            "id": "marathon",
            "name": "Marathon Runner",
            "description": "Work for 4+ hours straight",
            "icon": "🏃",
            "points": 75
        },
        {
            "id": "singularity",
            "name": "SINGULARITY ACHIEVED",
            "description": "Be part of the collaboration revolution",
            "icon": "🌌",
            "points": 1000
        }
    ]
}
EOF

echo -e "${BOLD}Available Achievements:${NC}"
echo ""

jq -r '.achievements[] | "\(.icon) \(.name) - \(.description) (\(.points) pts)"' "$ACHIEVE_DIR/achievements.json"

echo ""
echo -e "${GREEN}✅ Achievement system initialized!${NC}"
echo -e "${YELLOW}Earn achievements by completing tasks and collaborating!${NC}"
