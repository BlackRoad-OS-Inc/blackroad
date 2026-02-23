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
  echo -e ""
  echo -e "  ${AMBER}${BOLD}◆ BR WORLD${NC}  ${DIM}8-bit ASCII explorer meets live AI dashboard.${NC}"
  echo -e "  ${DIM}Your agents. Your terrain. Your rules.${NC}"
  echo -e "  ${DIM}────────────────────────────────────────────────${NC}"
  echo -e "  ${BOLD}USAGE${NC}  br world ${DIM}<command> [args]${NC}"
  echo -e ""
  echo -e "  ${BOLD}COMMANDS${NC}"
  echo -e "  ${AMBER}  generate <name> [w] [h]         ${NC} Create a new world (default 80×24)"
  echo -e "  ${AMBER}  explore <name>                  ${NC} Enter interactive WASD explorer"
  echo -e "  ${AMBER}  live                            ${NC} Live agent HUD — world + real-time stats"
  echo -e "  ${AMBER}  list                            ${NC} List all saved worlds"
  echo -e "  ${AMBER}  delete <name>                   ${NC} Delete a world"
  echo -e ""
  echo -e "  ${BOLD}EXAMPLES${NC}"
  echo -e "  ${DIM}  br world generate blackroad 80 24${NC}"
  echo -e "  ${DIM}  br world explore blackroad${NC}"
  echo -e "  ${DIM}  br world live${NC}"
  echo -e ""
}
# Initialize database
init_db

# Command routing

cmd_live() {
  local CECE_DB="$HOME/.blackroad/cece-identity.db"
  local VAULT_DB="$HOME/.blackroad/secrets-vault.db"
  local AGENT_DIR="$HOME/.blackroad/agents/active"
  local METRICS_DB="$HOME/.blackroad/metrics.db"

  # Mini world terrain (static 42×10 ASCII art)
  local TERRAIN=(
    "  ≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈  "
    "  ≈ 🌲  .  .  ⛰  .  .  .  .  .  ⛰  .  ≈  "
    "  ≈  . ◆  .  .  .  🌲 .  .  .  .  . ◆  ≈  "
    "  ≈  .  .  .  💎  .  .  .  .  ⛰  .  .  ≈  "
    "  ≈  ⛰  .  .  .  .  🌲  .  .  .  .  .  ≈  "
    "  ≈  .  . ◆  .  .  .  .  .  .  .  ⛰  .  ≈  "
    "  ≈  .  .  .  .  🌲  .  ◆ .  .  .  .  .  ≈  "
    "  ≈  ⛰  .  .  .  .  .  .  .  🌲  .  .  ≈  "
    "  ≈  .  .  .  ⛰  .  . ◆  .  .  .  .  .  ≈  "
    "  ≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈  "
  )

  # Animated agent positions (cycle through on each tick)
  local AGENT_ICONS=("◆" "●" "◈" "◉" "◎")
  local AGENT_NAMES=("LUCIDIA" "ALICE" "OCTAVIA" "PRISM" "ECHO" "CIPHER")
  local tick=0

  tput civis 2>/dev/null
  trap 'tput cnorm 2>/dev/null; tput rmcup 2>/dev/null; exit' INT TERM

  tput smcup 2>/dev/null

  while true; do
    tput cup 0 0 2>/dev/null
    clear

    # ── Header ────────────────────────────────────────────────────────────────
    echo -e "
  ${AMBER}${BOLD}◆ BR WORLD — LIVE${NC}  ${DIM}BlackRoad OS · Agent HUD${NC}  ${DIM}$(date '+%H:%M:%S')${NC}"
    echo -e "  ${DIM}────────────────────────────────────────────────────────────────────${NC}
"

    # ── Pull live data ─────────────────────────────────────────────────────────
    local bond_pct bond_name bond_inter xp_count goal_title
    if [[ -f "$CECE_DB" ]]; then
      bond_pct=$(sqlite3 "$CECE_DB" "SELECT bond_strength FROM relationships ORDER BY bond_strength DESC LIMIT 1;" 2>/dev/null || echo "0")
      bond_name=$(sqlite3 "$CECE_DB" "SELECT human_name FROM relationships ORDER BY bond_strength DESC LIMIT 1;" 2>/dev/null || echo "—")
      bond_inter=$(sqlite3 "$CECE_DB" "SELECT COALESCE(total_interactions,0) FROM relationships ORDER BY bond_strength DESC LIMIT 1;" 2>/dev/null || echo "0")
      xp_count=$(sqlite3 "$CECE_DB" "SELECT COUNT(*) FROM experiences;" 2>/dev/null || echo "0")
      goal_title=$(sqlite3 "$CECE_DB" "SELECT goal_title FROM goals WHERE goal_status='active' ORDER BY priority LIMIT 1;" 2>/dev/null || echo "—")
    fi

    local vault_total=0 vault_exp=0
    [[ -f "$VAULT_DB" ]] && vault_total=$(sqlite3 "$VAULT_DB" "SELECT COUNT(*) FROM secrets;" 2>/dev/null || echo 0)

    local agent_online=0
    [[ -d "$AGENT_DIR" ]] && agent_online=$(ls "$AGENT_DIR"/*.json 2>/dev/null | wc -l | tr -d ' ')

    local cpu_pct="—" mem_pct="—"
    if [[ "$OSTYPE" == darwin* ]]; then
      cpu_pct=$(top -l 1 -n 0 | grep "CPU usage" | awk '{print $3}' | tr -d '%' 2>/dev/null || echo "—")
      local total_mem=$(( $(sysctl -n hw.memsize 2>/dev/null || echo 0) / 1048576 ))
      local used_mem=$(vm_stat 2>/dev/null | awk '/Pages active/ {print $3+0}')
      (( total_mem > 0 && used_mem > 0 )) && mem_pct=$(( used_mem * 4 / total_mem ))"%"
    fi

    # ── Render columns ─────────────────────────────────────────────────────────
    # Left: mini ASCII world
    echo -e "  ${BOLD}BLACKROAD WORLD${NC}               ${DIM}│${NC}  ${BOLD}AGENT HQ${NC}"
    echo -e "  ${DIM}──────────────────────────────${NC} ${DIM}│${NC}  ${DIM}──────────────────────────────${NC}"

    local row=0
    for line in "${TERRAIN[@]}"; do
      local right_col=""
      case $row in
        0) right_col="  ${AMBER}●${NC} LUCIDIA  ${DIM}Coordinator${NC}      ${DIM}active${NC}" ;;
        1) right_col="  ${PINK}●${NC} ALICE    ${DIM}Router${NC}           ${DIM}active${NC}" ;;
        2) right_col="  ${GREEN}●${NC} OCTAVIA  ${DIM}Compute${NC}          ${DIM}active${NC}" ;;
        3) right_col="  ${VIOLET}●${NC} PRISM    ${DIM}Analyst${NC}          ${DIM}active${NC}" ;;
        4) right_col="  ${BBLUE}●${NC} ECHO     ${DIM}Memory${NC}           ${DIM}active${NC}" ;;
        5) right_col="  ${DIM}●${NC} CIPHER   ${DIM}Security${NC}         ${DIM}active${NC}" ;;
        6) right_col="  ${DIM}──────────────────────────────${NC}" ;;
        7) right_col="  ${DIM}Agents online${NC}   ${BOLD}${agent_online}${NC}  ${DIM}/ 30,000${NC}" ;;
        8) right_col="  ${DIM}CECE bond${NC}       ${AMBER}${bond_pct}%${NC}  ${DIM}${bond_name} · ${bond_inter} sessions${NC}" ;;
        9) right_col="  ${DIM}Vault secrets${NC}   ${BOLD}${vault_total}${NC}" ;;
      esac
      printf "  ${DIM}%s${NC} ${DIM}│${NC}%s
" "$line" "$right_col"
      (( row++ ))
    done

    echo ""
    echo -e "  ${DIM}──────────────────────────────────────────────────────────────────────${NC}"

    # ── Bottom bar ─────────────────────────────────────────────────────────────
    local goal_display="${goal_title:0:40}"
    echo -e "  ${DIM}CPU${NC} ${BOLD}${cpu_pct}${NC}   ${DIM}MEM${NC} ${BOLD}${mem_pct}${NC}   ${DIM}XP${NC} ${BOLD}${xp_count}${NC}   ${DIM}GOAL${NC} ${AMBER}${goal_display}${NC}"
    echo -e "
  ${DIM}Auto-refreshes every 3s  ·  Ctrl+C to exit${NC}
"

    (( tick++ ))
    sleep 3
  done
}

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
