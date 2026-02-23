#!/bin/zsh
# BR World - 8-bit ASCII World Generator & Explorer  v2

# Brand palette
AMBER='\033[38;5;214m'
VIOLET='\033[38;5;135m'
GREEN='\033[0;32m'
RED='\033[0;31m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'
# Compat aliases
CYAN="$AMBER"; YELLOW="$AMBER"; BLUE="$VIOLET"; PURPLE="$VIOLET"

DB_FILE="$HOME/.blackroad/world.db"

# 8-bit sprites
SPRITES=(
    "🌲" "🌳" "🏔️" "🏕️" "🏰" "🏠" "🏡" "⛺" 
    "🌊" "🏖️" "🏝️" "🗻" "🌋" "🏜️" "🏞️" "🌄"
    "🐉" "🐺" "🦅" "🐻" "🐗" "🦌" "🐇" "🦊"
    "⚔️" "🛡️" "💎" "👑" "🗝️" "📜" "🎒" "🧭"
)

TERRAIN_CHARS=(
    "." "," "~" ":" ";" "^" "*" "+"
)

init_db() {
    mkdir -p "$(dirname "$DB_FILE")"
    sqlite3 "$DB_FILE" <<EOF
CREATE TABLE IF NOT EXISTS worlds (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE NOT NULL,
    width INTEGER DEFAULT 80,
    height INTEGER DEFAULT 24,
    seed INTEGER,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS player_state (
    world_name TEXT PRIMARY KEY,
    x INTEGER DEFAULT 0,
    y INTEGER DEFAULT 0,
    inventory TEXT DEFAULT '',
    score INTEGER DEFAULT 0,
    last_played DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS world_objects (
    world_name TEXT,
    x INTEGER,
    y INTEGER,
    sprite TEXT,
    type TEXT,
    collected INTEGER DEFAULT 0,
    PRIMARY KEY (world_name, x, y)
);
EOF
}

generate_world() {
    local name="$1"
    local width="${2:-80}"
    local height="${3:-24}"
    local seed="${RANDOM}"
    
    echo -e "  ${AMBER}${BOLD}◆ BR WORLD${NC}  ${DIM}generating: $name${NC}"
    echo -e "  ${DIM}──────────────────────────────────────────────${NC}"
    echo ""
    
    # Create world
    sqlite3 "$DB_FILE" "INSERT OR REPLACE INTO worlds (name, width, height, seed) VALUES ('$name', $width, $height, $seed);"
    
    # Generate terrain and objects
    local terrain=""
    local num_objects=$((width * height / 50))
    
    for ((i=0; i<num_objects; i++)); do
        local x=$((RANDOM % width))
        local y=$((RANDOM % height))
        local sprite_idx=$((RANDOM % ${#SPRITES[@]}))
        local sprite="${SPRITES[$sprite_idx]}"
        
        # Determine type based on sprite
        local type="terrain"
        if [[ "$sprite" == "💎" || "$sprite" == "👑" || "$sprite" == "🗝️" ]]; then
            type="treasure"
        elif [[ "$sprite" =~ [🐉🐺🦅🐻🐗] ]]; then
            type="creature"
        elif [[ "$sprite" =~ [⚔️🛡️🎒🧭] ]]; then
            type="item"
        fi
        
        sqlite3 "$DB_FILE" "INSERT OR IGNORE INTO world_objects (world_name, x, y, sprite, type) VALUES ('$name', $x, $y, '$sprite', '$type');"
    done
    
    # Initialize player at random safe spot
    local px=$((RANDOM % (width - 10) + 5))
    local py=$((RANDOM % (height - 5) + 2))
    sqlite3 "$DB_FILE" "INSERT OR REPLACE INTO player_state (world_name, x, y) VALUES ('$name', $px, $py);"
    
    echo -e "  ${GREEN}✓${NC} World ${BOLD}$name${NC} generated — ${AMBER}$num_objects${NC} objects"
    echo -e "  ${DIM}👤 Player spawned at ($px, $py)${NC}"
    echo -e "  ${DIM}→  br world explore $name${NC}"
    echo ""
}

explore_world() {
    local name="$1"
    
    # Check if world exists
    local exists=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM worlds WHERE name='$name';" 2>/dev/null || echo "0")
    if [[ "$exists" == "0" ]]; then
        echo -e "${RED}✗${NC} World '$name' not found. Create it with: ${YELLOW}br world generate $name${NC}"
        return 1
    fi
    
    # Get world dimensions
    local dims=$(sqlite3 "$DB_FILE" "SELECT width, height FROM worlds WHERE name='$name';")
    local width=$(echo "$dims" | cut -f1)
    local height=$(echo "$dims" | cut -f2)
    
    # Get player position
    local pos=$(sqlite3 "$DB_FILE" "SELECT x, y, score FROM player_state WHERE world_name='$name';")
    local px=$(echo "$pos" | cut -f1)
    local py=$(echo "$pos" | cut -f2)
    local score=$(echo "$pos" | cut -f3)
    
    clear
    
    while true; do
        # Draw world
        echo -e "${PURPLE}╔═══════════════════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${PURPLE}║${NC} ${CYAN}🌍 WORLD:${NC} $name  ${CYAN}📍${NC} ($px,$py)  ${CYAN}⭐${NC} Score: $score  ${YELLOW}[WASD/HJKL to move, Q to quit]${NC}"
        echo -e "${PURPLE}╚═══════════════════════════════════════════════════════════════════════════════╝${NC}"
        
        # Render viewport (40x20 centered on player)
        local view_width=40
        local view_height=18
        local start_x=$((px - view_width/2))
        local start_y=$((py - view_height/2))
        
        for ((y=0; y<view_height; y++)); do
            local world_y=$((start_y + y))
            echo -n "  "
            
            for ((x=0; x<view_width; x++)); do
                local world_x=$((start_x + x))
                
                # Player position
                if [[ $world_x -eq $px && $world_y -eq $py ]]; then
                    echo -n "👤"
                    continue
                fi
                
                # Check for objects at this position
                local obj=$(sqlite3 "$DB_FILE" "SELECT sprite, collected FROM world_objects WHERE world_name='$name' AND x=$world_x AND y=$world_y AND collected=0;" 2>/dev/null)
                
                if [[ -n "$obj" ]]; then
                    local sprite=$(echo "$obj" | cut -f1)
                    echo -n "$sprite"
                else
                    # Random terrain
                    local seed=$((world_x * 1000 + world_y))
                    local terrain_idx=$(( (seed * 1103515245 + 12345) % ${#TERRAIN_CHARS[@]} ))
                    echo -n "${TERRAIN_CHARS[$terrain_idx]}"
                fi
            done
            echo ""
        done
        
        echo ""
        echo -e "${CYAN}🎒 Inventory:${NC} $(sqlite3 "$DB_FILE" "SELECT inventory FROM player_state WHERE world_name='$name';")"
        
        # Check for nearby objects
        local nearby=$(sqlite3 "$DB_FILE" "SELECT x, y, sprite, type FROM world_objects WHERE world_name='$name' AND collected=0 AND ABS(x-$px)<=2 AND ABS(y-$py)<=2;" 2>/dev/null)
        if [[ -n "$nearby" ]]; then
            echo -e "${YELLOW}📍 Nearby:${NC}"
            echo "$nearby" | while IFS=$'\t' read -r ox oy sprite type; do
                echo "  $sprite at ($ox,$oy) - $type"
            done
        fi
        
        # Get input
        echo -ne "\n${CYAN}>${NC} "
        read -k1 key
        
        local new_x=$px
        local new_y=$py
        local collected=0
        
        case "$key" in
            w|W|k) new_y=$((py-1)) ;;
            s|S|j) new_y=$((py+1)) ;;
            a|A|h) new_x=$((px-1)) ;;
            d|D|l) new_x=$((px+1)) ;;
            q|Q) 
                echo -e "\n${GREEN}👋 Saving and exiting...${NC}"
                return 0
                ;;
            *) continue ;;
        esac
        
        # Bounds check
        if [[ $new_x -lt 0 ]]; then new_x=0; fi
        if [[ $new_y -lt 0 ]]; then new_y=0; fi
        if [[ $new_x -ge $width ]]; then new_x=$((width-1)); fi
        if [[ $new_y -ge $height ]]; then new_y=$((height-1)); fi
        
        # Check for object at new position
        local obj_at_pos=$(sqlite3 "$DB_FILE" "SELECT sprite, type FROM world_objects WHERE world_name='$name' AND x=$new_x AND y=$new_y AND collected=0;" 2>/dev/null)
        if [[ -n "$obj_at_pos" ]]; then
            local sprite=$(echo "$obj_at_pos" | cut -f1)
            local type=$(echo "$obj_at_pos" | cut -f2)
            
            # Collect the item
            sqlite3 "$DB_FILE" "UPDATE world_objects SET collected=1 WHERE world_name='$name' AND x=$new_x AND y=$new_y;"
            
            local current_inv=$(sqlite3 "$DB_FILE" "SELECT inventory FROM player_state WHERE world_name='$name';")
            local new_inv="${current_inv}${sprite}"
            
            local points=10
            if [[ "$type" == "treasure" ]]; then points=50; fi
            if [[ "$type" == "item" ]]; then points=25; fi
            
            score=$((score + points))
            
            sqlite3 "$DB_FILE" "UPDATE player_state SET inventory='$new_inv', score=$score WHERE world_name='$name';"
        fi
        
        # Update position
        px=$new_x
        py=$new_y
        sqlite3 "$DB_FILE" "UPDATE player_state SET x=$px, y=$py, last_played=CURRENT_TIMESTAMP WHERE world_name='$name';"
        
        clear
    done
}

list_worlds() {
    echo -e "${CYAN}🌍 Available Worlds${NC}\n"
    
    sqlite3 "$DB_FILE" "SELECT name, width, height, created_at FROM worlds;" 2>/dev/null | while IFS='|' read -r name width height created; do
        local player=$(sqlite3 "$DB_FILE" "SELECT score FROM player_state WHERE world_name='$name';" 2>/dev/null || echo "0")
        echo -e "  ${GREEN}$name${NC} - ${width}x${height} - Score: ${YELLOW}$player${NC}"
    done
}

delete_world() {
    local name="$1"
    echo -e "${YELLOW}⚠️  Deleting world: $name${NC}"
    sqlite3 "$DB_FILE" "DELETE FROM worlds WHERE name='$name';"
    sqlite3 "$DB_FILE" "DELETE FROM player_state WHERE world_name='$name';"
    sqlite3 "$DB_FILE" "DELETE FROM world_objects WHERE world_name='$name';"
    echo -e "${GREEN}✓${NC} World deleted"
}

show_help() {
    echo ""
    echo -e "  ${AMBER}${BOLD}BR WORLD${NC}  ${DIM}8-bit ASCII world generator${NC}"
    echo ""
    echo -e "  ${BOLD}br world generate <name>${NC}     ${DIM}create new world${NC}"
    echo -e "  ${BOLD}br world explore <name>${NC}      ${DIM}explore (WASD/HJKL)${NC}"
    echo -e "  ${BOLD}br world list${NC}                ${DIM}list all worlds${NC}"
    echo -e "  ${BOLD}br world delete <name>${NC}       ${DIM}delete a world${NC}"
    echo ""
    echo -e "  ${DIM}Controls: W/K up  S/J down  A/H left  D/L right  Q quit${NC}"
    echo -e "  ${DIM}Collect 💎 treasures, ⚔️ items, encounter 🐉 creatures!${NC}"
    echo ""
}

# Initialize database
init_db

# Command routing
case "$1" in
    generate|gen|g)
        shift
        generate_world "$@"
        ;;
    explore|e|play)
        explore_world "$2"
        ;;
    list|ls)
        list_worlds
        ;;
    delete|del|rm)
        delete_world "$2"
        ;;
    help|--help|-h|"")
        show_help
        ;;
    *)
        echo -e "${RED}✗${NC} Unknown command: $1"
        echo -e "Use ${YELLOW}br world help${NC} for usage"
        exit 1
        ;;
esac
