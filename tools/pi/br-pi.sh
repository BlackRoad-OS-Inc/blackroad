#!/bin/zsh
# BR Pi — Raspberry Pi fleet management

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BLUE='\033[0;34m'; NC='\033[0m'

PI_NODES=(
  "aria64:alexa@192.168.4.38:8182:Primary:qwen2.5:3b"
  "alice:alice@192.168.4.49:8183:Secondary:llama3.2:1b"
)

status_node() {
  local label="$1" user_host="$2" port="$3"
  local ip="${user_host##*@}"
  if ping -c 1 -W 2 "$ip" &>/dev/null; then
    data=$(curl -s --max-time 3 "http://$ip:$port/status" 2>/dev/null)
    if [ -n "$data" ]; then
      host=$(echo "$data" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('host','?'))" 2>/dev/null)
      cpu=$(echo "$data" | python3 -c "import json,sys; d=json.load(sys.stdin); print(f\"{d.get('cpu_pct',0):.0f}%\")" 2>/dev/null)
      ram=$(echo "$data" | python3 -c "import json,sys; d=json.load(sys.stdin); print(f\"{d.get('ram_free_gb',0):.1f}GB free\")" 2>/dev/null)
      worlds=$(echo "$data" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('worlds_created',0))" 2>/dev/null)
      echo -e "  ${GREEN}●${NC} ${CYAN}$label${NC} ($host) — cpu=$cpu ram=$ram worlds=$worlds"
    else
      echo -e "  ${YELLOW}●${NC} ${CYAN}$label${NC} — online but status server not ready"
    fi
  else
    echo -e "  ${RED}●${NC} ${CYAN}$label${NC} — offline"
  fi
}

cmd_status() {
  echo -e "\n${BLUE}🍓 Pi Fleet Status${NC}"
  echo "══════════════════════════════"
  for node in "${PI_NODES[@]}"; do
    IFS=: read label user_host port role model <<< "$node"
    status_node "$label" "$user_host" "$port"
  done
  echo ""
}

cmd_worlds() {
  local node="${1:-aria64}"
  echo -e "\n${BLUE}🌍 Worlds on $node${NC}"
  for n in "${PI_NODES[@]}"; do
    IFS=: read label user_host port role model <<< "$n"
    if [[ "$label" == "$node" ]]; then
      local ip="${user_host##*@}"
      curl -s "http://$ip:$port/worlds" | python3 -c "
import json, sys
d = json.load(sys.stdin)
for w in d.get('worlds', []):
    import time
    ts = time.strftime('%m/%d %H:%M', time.localtime(w['ts']))
    print(f'  {ts}  {w[\"name\"]}  ({w[\"size\"]} bytes)')
" 2>/dev/null
      return
    fi
  done
  echo "Node not found: $node"
}

cmd_read() {
  local node="${1:-aria64}" name="$2"
  if [ -z "$name" ]; then echo "Usage: br pi read <node> <world-name>"; return; fi
  for n in "${PI_NODES[@]}"; do
    IFS=: read label user_host port role model <<< "$n"
    if [[ "$label" == "$node" ]]; then
      local ip="${user_host##*@}"
      curl -s "http://$ip:$port/worlds/$name" | python3 -c "
import json, sys
d = json.load(sys.stdin)
print(d.get('content', 'not found'))
" 2>/dev/null
      return
    fi
  done
}

cmd_task() {
  local node="${1:-aria64}" title="$2" description="${3:-$2}" agent="${4:-LUCIDIA}"
  if [ -z "$title" ]; then echo "Usage: br pi task <node> <title> [description] [agent]"; return; fi
  
  # Find node's ssh user
  for n in "${PI_NODES[@]}"; do
    IFS=: read label user_host port role model <<< "$n"
    if [[ "$label" == "$node" ]]; then
      local task_id="t-$(date +%s)"
      local task_json="{\"task_id\":\"$task_id\",\"title\":\"$title\",\"description\":\"$description\",\"agent\":\"$agent\",\"posted_at\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}"
      local task_file="/tmp/$task_id.json"
      echo "$task_json" > "$task_file"
      scp -o ConnectTimeout=5 -o StrictHostKeyChecking=no "$task_file" "${user_host}:.blackroad/tasks/available/$task_id.json" 2>/dev/null \
        && echo -e "${GREEN}✓${NC} Task queued on $node: $title" \
        || echo -e "${RED}✗${NC} Failed to queue task"
      rm -f "$task_file"
      return
    fi
  done
}

cmd_ssh() {
  local node="${1:-aria64}"
  for n in "${PI_NODES[@]}"; do
    IFS=: read label user_host port role model <<< "$n"
    if [[ "$label" == "$node" ]]; then
      echo -e "${CYAN}→${NC} SSH to $label ($user_host)"
      ssh -o StrictHostKeyChecking=no "$user_host"
      return
    fi
  done
  echo "Node not found: $node"
}

cmd_logs() {
  local node="${1:-aria64}" service="${2:-world}"
  for n in "${PI_NODES[@]}"; do
    IFS=: read label user_host port role model <<< "$n"
    if [[ "$label" == "$node" ]]; then
      ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no "$user_host" \
        "journalctl --user -u blackroad-$service -n 30 --no-pager 2>/dev/null" 2>/dev/null
      return
    fi
  done
}

show_help() {
  echo -e "\n${BLUE}BR Pi — Raspberry Pi Fleet Manager${NC}"
  echo "Usage: br pi <command> [args]"
  echo ""
  echo "Commands:"
  echo "  status              Show all nodes status"
  echo "  worlds [node]       List generated worlds (default: aria64)"
  echo "  read <node> <name>  Read a world artifact"
  echo "  task <node> <title> [desc] [agent]  Queue a task"
  echo "  ssh <node>          SSH into a Pi node"
  echo "  logs <node> [svc]   View service logs"
  echo ""
  echo "Nodes: aria64, alice"
  echo "Services: world, status, git-worker"
}

case "$1" in
  status)  cmd_status ;;
  worlds)  cmd_worlds "$2" ;;
  read)    cmd_read "$2" "$3" ;;
  task)    cmd_task "$2" "$3" "$4" "$5" ;;
  ssh)     cmd_ssh "$2" ;;
  logs)    cmd_logs "$2" "$3" ;;
  *)       show_help ;;
esac
