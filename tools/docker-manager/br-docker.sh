#!/usr/bin/env zsh

AMBER='\033[38;5;214m'; PINK='\033[38;5;205m'; VIOLET='\033[38;5;135m'; BBLUE='\033[38;5;69m'
GREEN='\033[0;32m'; RED='\033[0;31m'; BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'
CYAN="$AMBER"; YELLOW="$PINK"; BLUE="$BBLUE"; MAGENTA="$VIOLET"; PURPLE="$VIOLET"

DB_FILE="$HOME/.blackroad/docker-manager.db"

init_db() {
    mkdir -p "$(dirname "$DB_FILE")"
    sqlite3 "$DB_FILE" <<EOF
CREATE TABLE IF NOT EXISTS containers (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    container_id TEXT UNIQUE,
    name TEXT,
    image TEXT,
    status TEXT,
    ports TEXT,
    created_at INTEGER
);

CREATE TABLE IF NOT EXISTS images (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    image_id TEXT UNIQUE,
    repository TEXT,
    tag TEXT,
    size TEXT,
    created_at INTEGER
);
EOF
}

check_docker() {
    if ! command -v docker &> /dev/null; then
        echo "${RED}❌ Docker not found${NC}"
        echo "Install: https://docs.docker.com/get-docker/"
        exit 1
    fi
}

cmd_ps() {
    check_docker
    init_db
    
    local show_all=false
    [[ "$1" == "-a" || "$1" == "--all" ]] && show_all=true
    
    echo -e "${CYAN}🐳 Docker Containers:${NC}\n"
    
    local cmd="docker ps --format '{{.ID}}|{{.Names}}|{{.Image}}|{{.Status}}|{{.Ports}}'"
    [[ "$show_all" == true ]] && cmd="$cmd -a"
    
    eval "$cmd" | while IFS='|' read -r id name image status ports; do
        if [[ "$status" == *"Up"* ]]; then
            echo -e "${GREEN}●${NC} $name ($id)"
        else
            echo -e "${RED}●${NC} $name ($id)"
        fi
        echo "  Image: $image"
        echo "  Status: $status"
        [[ -n "$ports" ]] && echo "  Ports: $ports"
        echo ""
    done
}

cmd_start() {
    check_docker
    local container="$1"
    
    if [[ -z "$container" ]]; then
        echo -e "${RED}❌ Specify container name or ID${NC}"
        exit 1
    fi
    
    echo -e "${CYAN}🚀 Starting $container...${NC}"
    docker start "$container"
    echo -e "${GREEN}✓ Started${NC}"
}

cmd_stop() {
    check_docker
    local container="$1"
    
    if [[ -z "$container" ]]; then
        echo -e "${RED}❌ Specify container name or ID${NC}"
        exit 1
    fi
    
    echo -e "${CYAN}🛑 Stopping $container...${NC}"
    docker stop "$container"
    echo -e "${GREEN}✓ Stopped${NC}"
}

cmd_logs() {
    check_docker
    local container="$1"
    local lines="${2:-50}"
    
    if [[ -z "$container" ]]; then
        echo -e "${RED}❌ Specify container name or ID${NC}"
        exit 1
    fi
    
    echo -e "${CYAN}📋 Logs for $container:${NC}\n"
    docker logs --tail "$lines" -f "$container"
}

cmd_exec() {
    check_docker
    local container="$1"
    shift
    local command="${@:-/bin/sh}"
    
    if [[ -z "$container" ]]; then
        echo -e "${RED}❌ Specify container name or ID${NC}"
        exit 1
    fi
    
    echo -e "${CYAN}💻 Executing in $container...${NC}"
    docker exec -it "$container" $command
}

cmd_images() {
    check_docker
    init_db
    
    echo -e "${CYAN}🖼️  Docker Images:${NC}\n"
    
    docker images --format '{{.ID}}|{{.Repository}}|{{.Tag}}|{{.Size}}' | while IFS='|' read -r id repo tag size; do
        echo -e "${BLUE}▸${NC} $repo:$tag"
        echo "  ID: $id"
        echo "  Size: $size"
        echo ""
    done
}

cmd_clean() {
    check_docker
    echo -e "${YELLOW}🧹 Cleaning Docker resources...${NC}\n"
    
    echo "Removing stopped containers..."
    docker container prune -f
    
    echo "Removing dangling images..."
    docker image prune -f
    
    echo "Removing unused volumes..."
    docker volume prune -f
    
    echo -e "\n${GREEN}✓ Cleanup complete${NC}"
}

cmd_compose() {
    check_docker
    local action="$1"
    shift
    
    local compose_cmd="docker compose"
    ! docker compose version &> /dev/null 2>&1 && compose_cmd="docker-compose"
    
    case "$action" in
        up)
            echo -e "${CYAN}🚀 Starting compose stack...${NC}"
            $compose_cmd up -d "$@"
            echo -e "${GREEN}✓ Stack started${NC}"
            ;;
        down)
            echo -e "${CYAN}🛑 Stopping compose stack...${NC}"
            $compose_cmd down "$@"
            echo -e "${GREEN}✓ Stack stopped${NC}"
            ;;
        logs)
            $compose_cmd logs -f "$@"
            ;;
        ps)
            echo -e "${CYAN}�� Compose Services:${NC}\n"
            $compose_cmd ps
            ;;
        *)
            echo -e "${RED}❌ Unknown compose action: $action${NC}"
            echo "Use: up, down, logs, ps"
            exit 1
            ;;
    esac
}

cmd_stats() {
    check_docker
    local interval="${1:-3}"
    local containers; containers=$(docker ps --format '{{.Names}}' 2>/dev/null)
    if [[ -z "$containers" ]]; then
        echo -e "  ${DIM}No running containers${NC}"; return 0
    fi

    echo -e "  ${AMBER}${BOLD}◆ BR DOCKER STATS${NC}  ${DIM}Live · Ctrl-C to exit · refresh ${interval}s${NC}\n"

    while true; do
        # Move cursor up to redraw (skip on first run)
        local raw; raw=$(docker stats --no-stream --format \
            "{{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}\t{{.NetIO}}" 2>/dev/null)

        # Clear previous rows
        tput cuu1 2>/dev/null
        printf "\033[2K"

        echo -e "  ${BOLD}$(printf '%-20s' 'CONTAINER')  $(printf '%-7s' 'CPU')  $(printf '%-20s' 'MEM USAGE')  $(printf '%-6s' 'MEM%')  NET I/O${NC}"
        echo -e "  ${DIM}$(printf '%.0s─' {1..68})${NC}"

        echo "$raw" | while IFS=$'\t' read -r name cpu mem memp net; do
            # CPU bar (max 20 chars)
            local cpu_n; cpu_n=$(echo "$cpu" | tr -d '%' | python3 -c "import sys; v=float(sys.stdin.read().strip() or 0); print(min(int(v/5),20))" 2>/dev/null || echo 0)
            local mem_n; mem_n=$(echo "$memp" | tr -d '%' | python3 -c "import sys; v=float(sys.stdin.read().strip() or 0); print(min(int(v/5),20))" 2>/dev/null || echo 0)
            local cpu_bar; cpu_bar=$(python3 -c "print('█'*${cpu_n} + '░'*(10-min(${cpu_n},10)))" 2>/dev/null || echo "")
            local mem_bar; mem_bar=$(python3 -c "print('█'*${mem_n} + '░'*(10-min(${mem_n},10)))" 2>/dev/null || echo "")

            # Color CPU by load
            local cpu_color="$GREEN"
            (( cpu_n >= 12 )) && cpu_color="$PINK"
            (( cpu_n >= 16 )) && cpu_color="$RED"

            printf "  ${AMBER}%-20s${NC}  ${cpu_color}%-6s${NC}  ${DIM}%s${NC}  %-20s  ${VIOLET}%-5s${NC}  ${DIM}%s${NC}  %s\n" \
                "${name:0:19}" "$cpu" "$cpu_bar" "${mem:0:19}" "$memp" "$mem_bar" "${net:0:20}"
        done

        echo -e "\n  ${DIM}$(date '+%H:%M:%S') · next in ${interval}s${NC}"

        sleep "$interval"

        # Move up past the table for redraw (count lines)
        local row_count; row_count=$(echo "$raw" | wc -l | tr -d ' ')
        local total_rows=$(( row_count + 4 ))
        tput cuu "$total_rows" 2>/dev/null
    done
}

cmd_help() {
    echo -e ""
    echo -e "  ${AMBER}${BOLD}◆ BR DOCKER${NC}  ${DIM}Container control. Zero-friction ops, live stats.${NC}"
    echo -e "  ${DIM}Ship faster. Debug quicker. One command to rule the daemon.${NC}"
    echo -e "  ${DIM}────────────────────────────────────────────────${NC}"
    echo -e "  ${BOLD}CONTAINERS${NC}"
    echo -e "  ${AMBER}  ps [-a]                  ${NC} List running (or all) containers"
    echo -e "  ${AMBER}  start|stop|restart <n>   ${NC} Container lifecycle"
    echo -e "  ${AMBER}  logs <name> [lines]      ${NC} Tail container logs"
    echo -e "  ${AMBER}  exec <name> [cmd]        ${NC} Exec into container"
    echo -e "  ${AMBER}  stats [interval]         ${NC} ${BOLD}Live stats${NC} with CPU/MEM bars (default 3s)"
    echo -e ""
    echo -e "  ${BOLD}IMAGES${NC}"
    echo -e "  ${AMBER}  images                   ${NC} List images"
    echo -e "  ${AMBER}  pull <image>             ${NC} Pull image"
    echo -e "  ${AMBER}  build [path]             ${NC} Build from Dockerfile"
    echo -e ""
    echo -e "  ${BOLD}COMPOSE${NC}"
    echo -e "  ${AMBER}  compose up|down|ps|logs  ${NC} Docker Compose control"
    echo -e ""
    echo -e "  ${BOLD}MAINTENANCE${NC}"
    echo -e "  ${AMBER}  clean                    ${NC} Remove unused containers/images"
    echo -e "  ${AMBER}  prune                    ${RED}DANGER${NC} Full system cleanup"
    echo -e ""
}

# Main dispatch
init_db

case "${1:-help}" in
    ps) cmd_ps "${@:2}" ;;
    start) cmd_start "${@:2}" ;;
    stop) cmd_stop "${@:2}" ;;
    restart) 
        check_docker
        docker restart "${2}"
        echo -e "${GREEN}✓ Restarted${NC}"
        ;;
    logs) cmd_logs "${@:2}" ;;
    exec) cmd_exec "${@:2}" ;;
    images) cmd_images ;;
    pull)
        check_docker
        docker pull "${2}"
        ;;
    build)
        check_docker
        docker build "${@:2}"
        ;;
    compose) cmd_compose "${@:2}" ;;
    stats) cmd_stats "${2:-3}" ;;
    clean) cmd_clean ;;
    prune)
        check_docker
        echo -e "${YELLOW}⚠️  Full system cleanup${NC}"
        docker system prune -a -f --volumes
        echo -e "${GREEN}✓ Done${NC}"
        ;;
    help|--help|-h) cmd_help ;;
    *)
        echo -e "${RED}❌ Unknown command: $1${NC}"
        cmd_help
        exit 1
        ;;
esac
