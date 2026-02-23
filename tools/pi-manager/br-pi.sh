#!/bin/zsh
# BR Pi — Raspberry Pi fleet management + world generation

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BLUE='\033[0;34m'; PURPLE='\033[0;35m'; NC='\033[0m'

# Node config: label:ssh_host_alias:local_port:role:model
# alice uses SSH config alias (user=blackroad, id_ed25519) - slow to connect, use long timeout
PI_NODES=(
  "aria64:alexa@192.168.4.38:8182:Primary(22500 agents):qwen2.5:3b"
  "alice:alice:8184:Secondary(relay→aria64):relay"
)

# Fetch status via SSH tunnel (192.168.4.x unreachable directly from macOS)
# alice is fetched via aria64 relay (much faster - no SSH banner delay)
ssh_status() {
  local user_host="$1" port="$2"
  if [[ "$user_host" == "alice" ]]; then
    # Relay alice status check through aria64 (same subnet, fast)
    ssh -o ConnectTimeout=8 -o StrictHostKeyChecking=no alexa@192.168.4.38 \
      "curl -s --max-time 5 http://192.168.4.49:$port/status 2>/dev/null" 2>/dev/null
  else
    ssh -o ConnectTimeout=8 -o StrictHostKeyChecking=no "$user_host" \
      "curl -s http://localhost:$port/status 2>/dev/null" 2>/dev/null
  fi
}

cmd_status() {
  echo -e "\n${BLUE}🍓 BlackRoad Pi Fleet${NC}"
  echo "══════════════════════════════════════"
  for node in "${PI_NODES[@]}"; do
    IFS=: read label user_host port role model <<< "$node"
    # Resolve IP: if user_host has @, extract IP; otherwise hardcode known IPs
    case "$label" in
      aria64) ip="192.168.4.38" ;;
      alice)  ip="192.168.4.49" ;;
      *)      ip="${user_host##*@}" ;;
    esac
    if ping -c 1 -W 2 "$ip" &>/dev/null; then
      data=$(ssh_status "$user_host" "$port")
      if [ -n "$data" ]; then
        host=$(echo "$data" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('host','?'))" 2>/dev/null)
        cpu=$(echo "$data" | python3 -c "import json,sys; d=json.load(sys.stdin); print(f\"{d.get('cpu_pct',0):.0f}%\")" 2>/dev/null)
        ram=$(echo "$data" | python3 -c "import json,sys; d=json.load(sys.stdin); print(f\"{d.get('ram_free_gb',0):.1f}GB free\")" 2>/dev/null)
        disk=$(echo "$data" | python3 -c "import json,sys; d=json.load(sys.stdin); print(f\"{d.get('disk_free_gb',0):.0f}GB free\")" 2>/dev/null)
        worlds=$(echo "$data" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('worlds_created',0))" 2>/dev/null)
        tasks_done=$(echo "$data" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('tasks_completed',0))" 2>/dev/null)
        echo -e "  ${GREEN}●${NC} ${CYAN}${label}${NC} (${host}) ${PURPLE}${role}${NC}"
        echo -e "    cpu=${cpu}  ram=${ram}  disk=${disk}"
        echo -e "    🌍 worlds=${worlds}  ✅ tasks=${tasks_done}  🤖 model=${model}"
      else
        echo -e "  ${YELLOW}●${NC} ${CYAN}${label}${NC} — online (status server starting...)"
      fi
    else
      echo -e "  ${RED}●${NC} ${CYAN}${label}${NC} — offline"
    fi
    echo ""
  done
}

cmd_worlds() {
  local node="${1:-aria64}" count="${2:-10}"
  echo -e "\n${BLUE}🌍 Worlds on ${node}${NC}"
  for n in "${PI_NODES[@]}"; do
    IFS=: read label user_host port role model <<< "$n"
    if [[ "$label" == "$node" ]]; then
      ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no "$user_host" \
        "ls -lt ~/.blackroad/worlds/*.md 2>/dev/null | head -$count | awk '{print \$6, \$7, \$9}'" 2>/dev/null \
        | while read date time path; do
            name=$(basename "$path")
            echo -e "  ${CYAN}${date} ${time}${NC}  ${name}"
          done
      return
    fi
  done
  echo "Node not found: $node"
}

cmd_read() {
  local node="${1:-aria64}" name="$2"
  if [ -z "$name" ]; then
    # Show latest
    for n in "${PI_NODES[@]}"; do
      IFS=: read label user_host port role model <<< "$n"
      if [[ "$label" == "$node" ]]; then
        ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no "$user_host" \
          "ls -t ~/.blackroad/worlds/*.md 2>/dev/null | head -1 | xargs cat 2>/dev/null" 2>/dev/null
        return
      fi
    done
  else
    for n in "${PI_NODES[@]}"; do
      IFS=: read label user_host port role model <<< "$n"
      if [[ "$label" == "$node" ]]; then
        ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no "$user_host" \
          "cat ~/.blackroad/worlds/$name 2>/dev/null || ls ~/.blackroad/worlds/ | grep '$name'" 2>/dev/null
        return
      fi
    done
  fi
}

cmd_task() {
  local node="${1:-aria64}" title="$2" description="${3:-$2}" agent="${4:-LUCIDIA}"
  if [ -z "$title" ]; then
    echo "Usage: br pi task <node> <title> [description] [agent]"
    echo "Example: br pi task aria64 'Write a haiku about Cloudflare' '' LUCIDIA"
    return 1
  fi
  for n in "${PI_NODES[@]}"; do
    IFS=: read label user_host port role model <<< "$n"
    if [[ "$label" == "$node" ]]; then
      local task_id="t-$(date +%s)"
      local posted=$(date -u +%Y-%m-%dT%H:%M:%SZ)
      ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no "$user_host" \
        "mkdir -p ~/.blackroad/tasks/available && echo '{\"task_id\":\"$task_id\",\"title\":\"$title\",\"description\":\"$description\",\"agent\":\"$agent\",\"posted_at\":\"$posted\"}' > ~/.blackroad/tasks/available/$task_id.json && echo 'queued'" 2>/dev/null \
        | grep -q queued && echo -e "${GREEN}✓${NC} Task queued on $node: '$title' → $agent" \
        || echo -e "${RED}✗${NC} Failed to queue task"
      return
    fi
  done
  echo "Node not found: $node"
}

cmd_generate() {
  local node="${1:-aria64}" prompt="${2:-Create something beautiful}"
  echo -e "${CYAN}→${NC} Generating on $node with Ollama..."
  for n in "${PI_NODES[@]}"; do
    IFS=: read label user_host port role model <<< "$n"
    if [[ "$label" == "$node" ]]; then
      ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no "$user_host" \
        "curl -s -X POST http://localhost:11434/api/chat \
          -d '{\"model\":\"$model\",\"messages\":[{\"role\":\"user\",\"content\":\"$prompt\"}],\"stream\":false}' \
          | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get(\"message\",{}).get(\"content\",\"failed\"))' 2>/dev/null" 2>/dev/null
      return
    fi
  done
}

cmd_ssh() {
  local node="${1:-aria64}"
  for n in "${PI_NODES[@]}"; do
    IFS=: read label user_host port role model <<< "$n"
    if [[ "$label" == "$node" ]]; then
      echo -e "${CYAN}→${NC} Connecting to $label..."
      ssh -o StrictHostKeyChecking=no "$user_host"
      return
    fi
  done
  echo "Node not found: $node (available: aria64, alice)"
}

cmd_logs() {
  local node="${1:-aria64}" service="${2:-world}"
  for n in "${PI_NODES[@]}"; do
    IFS=: read label user_host port role model <<< "$n"
    if [[ "$label" == "$node" ]]; then
      echo -e "${BLUE}📋 Logs: $label / blackroad-$service${NC}"
      ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no "$user_host" \
        "journalctl --user -u blackroad-$service -n 40 --no-pager 2>/dev/null" 2>/dev/null
      return
    fi
  done
}

cmd_models() {
  local node="${1:-aria64}"
  for n in "${PI_NODES[@]}"; do
    IFS=: read label user_host port role model <<< "$n"
    if [[ "$label" == "$node" ]]; then
      echo -e "${BLUE}🤖 Ollama models on $label${NC}"
      ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no "$user_host" \
        "ollama list 2>/dev/null" 2>/dev/null
      return
    fi
  done
}

show_help() {
  echo -e ""
  echo -e "  ${AMBER}${BOLD}◆ BR PI${NC}  ${DIM}Raspberry Pi fleet management.${NC}"
  echo -e "  ${DIM}Your hardware. Your edge. Your agents.${NC}"
  echo -e "  ${DIM}──────────────────────────────────────────────${NC}"
  echo -e "  ${BOLD}USAGE${NC}  br ${DIM}<command> [args]${NC}"
  echo -e ""
  echo -e "  ${BOLD}COMMANDS${NC}"
  echo -e "  ${AMBER}  list                          ${NC} List all registered Pi nodes"
  echo -e "  ${AMBER}  ssh <name>                    ${NC} SSH into a Pi by name"
  echo -e "  ${AMBER}  deploy <name> <script>        ${NC} Deploy script to a Pi"
  echo -e "  ${AMBER}  status                        ${NC} Fleet health overview"
  echo -e "  ${AMBER}  add <name> <ip>               ${NC} Register a new Pi"
  echo -e "  ${AMBER}  logs <name>                   ${NC} Tail Pi logs"
  echo -e "  ${AMBER}  reboot <name>                 ${NC} Reboot a Pi remotely"
  echo -e ""
  echo -e "  ${BOLD}EXAMPLES${NC}"
  echo -e "  ${DIM}  br pi list${NC}"
  echo -e "  ${DIM}  br pi ssh lucidia${NC}"
  echo -e "  ${DIM}  br pi status${NC}"
  echo -e "  ${DIM}  br pi deploy octavia setup.sh${NC}"
  echo -e ""
}

case "$1" in
  status|st)    cmd_status ;;
  worlds|w)     cmd_worlds "$2" "$3" ;;
  read|r)       cmd_read "$2" "$3" ;;
  task|t)       cmd_task "$2" "$3" "$4" "$5" ;;
  generate|gen) cmd_generate "$2" "$3" ;;
  models|m)     cmd_models "$2" ;;
  ssh)          cmd_ssh "$2" ;;
  logs|l)       cmd_logs "$2" "$3" ;;
  *)            show_help ;;
esac
