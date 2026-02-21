#!/bin/bash
# br-model — BlackRoad Model Fleet CLI
# Query 108 models across 6 nodes from one command

PINK='\033[38;5;205m'
AMBER='\033[38;5;214m'
BLUE='\033[38;5;69m'
GREEN='\033[38;5;82m'
VIOLET='\033[38;5;135m'
DIM='\033[2m'
BOLD='\033[1m'
RESET='\033[0m'

NODES=(
    "cecilia:192.168.4.89:8787"
    "lucidia:192.168.4.81:8787"
    "octavia:192.168.4.38:8787"
    "alice:192.168.4.49:8790"
    "anastasia:174.138.44.45:8787"
    "gematria:159.65.43.12:8787"
)

pick_node() {
    # Try local nodes first, then cloud
    for entry in "${NODES[@]}"; do
        IFS=: read -r name ip port <<< "$entry"
        if curl -s --connect-timeout 1 "http://${ip}:${port}/health" &>/dev/null; then
            echo "${ip}:${port}"
            return 0
        fi
    done
    echo ""
    return 1
}

cmd_status() {
    echo -e "${PINK}${BOLD}BlackRoad Model Fleet${RESET}"
    echo -e "${DIM}──────────────────────────────────────${RESET}"
    for entry in "${NODES[@]}"; do
        IFS=: read -r name ip port <<< "$entry"
        health=$(curl -s --connect-timeout 2 "http://${ip}:${port}/health" 2>/dev/null)
        if [ -n "$health" ] && echo "$health" | python3 -c "import sys,json; json.load(sys.stdin)" 2>/dev/null; then
            models=$(echo "$health" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('models','?'))" 2>/dev/null)
            live=$(echo "$health" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('live','?'))" 2>/dev/null)
            echo -e "  ${GREEN}●${RESET} ${BOLD}${name}${RESET}  ${DIM}${ip}:${port}${RESET}  ${models} models  ${GREEN}${live} live${RESET}"
        else
            echo -e "  ${PINK}●${RESET} ${BOLD}${name}${RESET}  ${DIM}${ip}:${port}${RESET}  ${PINK}offline${RESET}"
        fi
    done
    echo ""
}

cmd_list() {
    local filter="$1"
    local node
    node=$(pick_node)
    if [ -z "$node" ]; then
        echo -e "${PINK}No nodes reachable${RESET}" >&2
        exit 1
    fi

    data=$(curl -s "http://${node}/models" 2>/dev/null)
    if [ -z "$data" ]; then
        echo -e "${PINK}Failed to fetch models${RESET}" >&2
        exit 1
    fi

    if [ -n "$filter" ]; then
        echo "$data" | python3 -c "
import sys, json
d = json.load(sys.stdin)
f = '${filter}'.lower()
for cat, info in sorted(d['categories'].items()):
    if f and f not in cat.lower():
        matches = [m for m in info['models'] if f in m.lower()]
        if not matches:
            continue
        info = dict(info)
        info['models'] = matches
        info['count'] = len(matches)
    print(f\"  {cat} ({info['count']} models, {info['live']} live)\")
    for m in sorted(info['models']):
        print(f'    {m}')
"
    else
        echo "$data" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print(f\"  {d['total_models']} models | {d['live']} live | {d['available']} available\")
print()
for cat, info in sorted(d['categories'].items()):
    live_tag = f' ({info[\"live\"]} live)' if info['live'] > 0 else ''
    print(f'  {cat}: {info[\"count\"]}{live_tag}')
    for m in sorted(info['models']):
        print(f'    {m}')
    print()
"
    fi
}

cmd_query() {
    local model="$1"
    if [ -z "$model" ]; then
        echo "Usage: br-model query <ModelName>" >&2
        exit 1
    fi

    # Try all nodes, show first result
    for entry in "${NODES[@]}"; do
        IFS=: read -r name ip port <<< "$entry"
        result=$(curl -s --connect-timeout 2 "http://${ip}:${port}/model/${model}" 2>/dev/null)
        if [ -n "$result" ] && echo "$result" | grep -q '"callable"'; then
            echo "$result" | python3 -c "
import sys, json
d = json.load(sys.stdin)
status_color = '\033[38;5;82m' if d.get('status') == 'live' else '\033[38;5;214m'
print(f\"\033[1m{d['name']}\033[0m\")
print(f\"  status:     {status_color}{d['status']}\033[0m\")
print(f\"  capability: {d['capability']}\")
print(f\"  engine:     {d['engine']}\")
print(f\"  category:   {d['category']}\")
print(f\"  node:       {d['node']}\")
print(f\"  owner:      {d['owner']}\")
formerly = d.get('formerly', '')
if formerly and not formerly.startswith('n/a'):
    print(f\"  formerly:   \033[2m{formerly}\033[0m\")
" 2>/dev/null
            return 0
        fi
        # Check for redirect (old Apple name)
        if [ -n "$result" ] && echo "$result" | grep -q '"renamed"'; then
            new_name=$(echo "$result" | python3 -c "import sys,json; print(json.load(sys.stdin)['new_name'])" 2>/dev/null)
            echo -e "${AMBER}Renamed:${RESET} ${model} → ${BOLD}${new_name}${RESET}"
            cmd_query "$new_name"
            return $?
        fi
    done
    echo -e "${PINK}Model not found:${RESET} ${model}" >&2
    exit 1
}

cmd_live() {
    local node
    node=$(pick_node)
    if [ -z "$node" ]; then
        echo -e "${PINK}No nodes reachable${RESET}" >&2
        exit 1
    fi

    echo -e "${GREEN}${BOLD}Live Models${RESET} ${DIM}(running on hardware now)${RESET}"
    echo ""
    curl -s "http://${node}/models" 2>/dev/null | python3 -c "
import sys, json
d = json.load(sys.stdin)
for cat, info in sorted(d['categories'].items()):
    if info['live'] == 0:
        continue
    print(f'  {cat}:')
    # Fetch each model to check status
    for m in sorted(info['models']):
        pass
    for m in sorted(info['models']):
        print(f'    {m}')
    print()
" 2>/dev/null

    # Get actual live models with details
    curl -s "http://${node}/models" 2>/dev/null | python3 -c "
import sys, json, urllib.request
d = json.load(sys.stdin)
node = '${node}'
for cat, info in sorted(d['categories'].items()):
    for m in sorted(info['models']):
        try:
            r = urllib.request.urlopen(f'http://{node}/model/{m}', timeout=2)
            md = json.loads(r.read())
            if md.get('status') == 'live':
                engine = md.get('engine', '?')
                extra = ''
                if 'hailo_model' in md:
                    extra = f' [{md[\"hailo_model\"]}]'
                elif 'ollama_model' in md:
                    extra = f' [{md[\"ollama_model\"]}]'
                print(f'  \033[38;5;82m●\033[0m {m}  \033[2m{engine}{extra}\033[0m')
        except:
            pass
" 2>/dev/null
}

cmd_search() {
    local term="$1"
    if [ -z "$term" ]; then
        echo "Usage: br-model search <term>" >&2
        exit 1
    fi

    local node
    node=$(pick_node)
    if [ -z "$node" ]; then
        echo -e "${PINK}No nodes reachable${RESET}" >&2
        exit 1
    fi

    curl -s "http://${node}/models" 2>/dev/null | python3 -c "
import sys, json, urllib.request
d = json.load(sys.stdin)
term = '${term}'.lower()
node = '${node}'
found = 0
for cat, info in d['categories'].items():
    for m in info['models']:
        if term in m.lower():
            try:
                r = urllib.request.urlopen(f'http://{node}/model/{m}', timeout=2)
                md = json.loads(r.read())
                status = md.get('status', '?')
                cap = md.get('capability', '?')
                sc = '\033[38;5;82m' if status == 'live' else '\033[38;5;214m'
                print(f'  {sc}●\033[0m \033[1m{m}\033[0m  {cap}')
                found += 1
            except:
                print(f'  \033[1m{m}\033[0m')
                found += 1
        else:
            try:
                r = urllib.request.urlopen(f'http://{node}/model/{m}', timeout=2)
                md = json.loads(r.read())
                cap = md.get('capability', '')
                if term in cap.lower() or term in md.get('engine','').lower() or term in md.get('category','').lower():
                    status = md.get('status', '?')
                    sc = '\033[38;5;82m' if status == 'live' else '\033[38;5;214m'
                    print(f'  {sc}●\033[0m \033[1m{m}\033[0m  {cap}')
                    found += 1
            except:
                pass
if found == 0:
    print(f'  No models matching \"{term}\"')
" 2>/dev/null
}

case "${1:-help}" in
    status|s)
        cmd_status
        ;;
    list|ls|l)
        cmd_list "$2"
        ;;
    query|q|get)
        cmd_query "$2"
        ;;
    live)
        cmd_live
        ;;
    search|find|f)
        cmd_search "$2"
        ;;
    help|--help|-h|"")
        echo -e "${PINK}${BOLD}br-model${RESET} — BlackRoad Model Fleet CLI"
        echo ""
        echo -e "  ${BOLD}br-model status${RESET}          Fleet health across all nodes"
        echo -e "  ${BOLD}br-model list${RESET}            All 108 models by category"
        echo -e "  ${BOLD}br-model list ${DIM}vision${RESET}     Filter by category"
        echo -e "  ${BOLD}br-model live${RESET}            Only models running on hardware"
        echo -e "  ${BOLD}br-model query ${DIM}Name${RESET}     Full details on a model"
        echo -e "  ${BOLD}br-model search ${DIM}term${RESET}   Search by name/capability/engine"
        echo ""
        echo -e "  ${DIM}6 nodes | 108 models | 20 live${RESET}"
        ;;
    *)
        # Treat as a model name query
        cmd_query "$1"
        ;;
esac
