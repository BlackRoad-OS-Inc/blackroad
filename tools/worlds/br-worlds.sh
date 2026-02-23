#!/bin/zsh
# BR Worlds — Browse and manage world artifacts

GREEN='\033[0;32m'; RED='\033[0;31m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; PURPLE='\033[0;35m'; NC='\033[0m'

WORLDS_API="https://worlds.blackroad.io"
LOCAL_DIR="$HOME/.blackroad/worlds"

cmd_list() {
    local limit="${1:-20}"
    echo -e "${CYAN}🌍 World Artifacts (live feed)${NC}\n"
    local data
    data=$(curl -sf "${WORLDS_API}/?format=json" 2>/dev/null)
    if [[ -z "$data" ]]; then
        echo -e "${RED}✗ worlds.blackroad.io unreachable — using local${NC}"
        ls -lt "$LOCAL_DIR"/*.md 2>/dev/null | head -$limit | while read -r line; do
            echo "  $line"
        done
        return
    fi
    echo "$data" | python3 -c "
import json,sys
d = json.load(sys.stdin)
worlds = d.get('worlds',[])[:$limit]
types = {}
for w in worlds:
    t = w.get('type','?')
    types[t] = types.get(t,0)+1
print(f'  Total: {d.get(\"total\",len(worlds))} worlds | Types: {dict(sorted(types.items(),key=lambda x:-x[1]))}')
print()
for w in worlds:
    node = w.get(\"node\",\"?\")
    wtype = w.get(\"type\",\"?\")
    name = w.get(\"title\",w.get(\"name\",\"?\"))
    print(f'  [{wtype:<12}] {name[:50]:<50}  📍{node}')
" 2>/dev/null || echo "$data" | python3 -c "import json,sys; d=json.load(sys.stdin); [print('  '+w.get('name','?')) for w in d.get('worlds',[])[:$limit]]"
    echo ""
}

cmd_stats() {
    echo -e "${CYAN}📊 World Statistics${NC}\n"
    local data
    data=$(curl -sf "${WORLDS_API}/?format=json" 2>/dev/null)
    [[ -z "$data" ]] && { echo -e "${RED}✗ unreachable${NC}"; return; }
    echo "$data" | python3 -c "
import json,sys,datetime
d = json.load(sys.stdin)
worlds = d.get('worlds',[])
types = {}; nodes = {}
for w in worlds:
    t = w.get('type','unknown'); types[t] = types.get(t,0)+1
    n = w.get('node','unknown'); nodes[n] = nodes.get(n,0)+1
print(f'  Total worlds: {d.get(\"total\",len(worlds))}')
print(f'  Live feed: {d.get(\"feed_url\",\"worlds.blackroad.io\")}')
print()
print('  By type:')
for k,v in sorted(types.items(),key=lambda x:-x[1]):
    bar = '█'*min(v,30)
    print(f'    {k:<20} {bar} {v}')
print()
print('  By node:')
for k,v in sorted(nodes.items(),key=lambda x:-x[1]):
    print(f'    {k:<20} {v}')
" 2>/dev/null
}

cmd_watch() {
    echo -e "${CYAN}👁  Watching for new worlds (Ctrl+C to stop)...${NC}\n"
    local prev_count=0
    while true; do
        local count
        count=$(curl -sf "${WORLDS_API}/?format=json" 2>/dev/null | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('total',0))" 2>/dev/null || echo "0")
        if [[ "$count" -gt "$prev_count" ]]; then
            local new=$((count - prev_count))
            echo -e "  ${GREEN}+$new worlds${NC} — total: $count  $(date '+%H:%M:%S')"
            prev_count=$count
        else
            printf "\r  ${CYAN}%s${NC} worlds — checking...  $(date '+%H:%M:%S')" "$count"
        fi
        sleep 15
    done
}

cmd_rss() {
    echo -e "${CYAN}📡 RSS Feed${NC}: ${WORLDS_API}/rss\n"
    curl -sf "${WORLDS_API}/rss" 2>/dev/null | head -40
}

show_help() {
    echo -e "${CYAN}BR Worlds — World artifact browser${NC}"
    echo ""
    echo "  br worlds              - List recent worlds (default: 20)"
    echo "  br worlds list [N]     - List N worlds"
    echo "  br worlds stats        - Show statistics by type/node"
    echo "  br worlds watch        - Watch for new worlds live"
    echo "  br worlds rss          - Show RSS feed"
}

case "${1:-list}" in
    list|ls|"")     cmd_list "${2:-20}" ;;
    stats|stat)     cmd_stats ;;
    watch)          cmd_watch ;;
    rss)            cmd_rss ;;
    help|-h)        show_help ;;
    [0-9]*)         cmd_list "$1" ;;
    *) echo -e "${RED}Unknown: $1${NC}"; show_help ;;
esac
