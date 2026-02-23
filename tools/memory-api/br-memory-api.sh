#!/bin/zsh
# BR Memory API — start / stop / status / test
# Usage: br memory-api [start|stop|status|test|logs]

GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="${0:A:h}"
SERVER="$SCRIPT_DIR/server.py"
PID_FILE="$HOME/.blackroad/memory-api.pid"
LOG_FILE="$HOME/.blackroad/logs/memory-api.log"
PORT=8011

mkdir -p "$(dirname "$PID_FILE")" "$(dirname "$LOG_FILE")"

_is_running() {
    [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null
}

cmd_start() {
    if _is_running; then
        echo -e "${YELLOW}⚠ memory-api already running (PID $(cat $PID_FILE))${NC}"
        return 0
    fi
    echo -e "${CYAN}▶ starting memory-api on port $PORT…${NC}"
    nohup python3 "$SERVER" >> "$LOG_FILE" 2>&1 &
    echo $! > "$PID_FILE"
    sleep 1
    if _is_running; then
        echo -e "${GREEN}✓ memory-api started (PID $(cat $PID_FILE))${NC}"
        echo -e "  ${CYAN}http://localhost:$PORT/memory/recent${NC}"
    else
        echo -e "${RED}✗ failed to start — check $LOG_FILE${NC}"
        return 1
    fi
}

cmd_stop() {
    if _is_running; then
        kill "$(cat "$PID_FILE")" && rm -f "$PID_FILE"
        echo -e "${GREEN}✓ memory-api stopped${NC}"
    else
        echo -e "${YELLOW}⚠ not running${NC}"
    fi
}

cmd_status() {
    if _is_running; then
        echo -e "${GREEN}● memory-api running${NC} (PID $(cat $PID_FILE), port $PORT)"
    else
        echo -e "${RED}○ memory-api not running${NC}"
    fi
}

cmd_test() {
    echo -e "${CYAN}Testing memory-api endpoints…${NC}"
    echo -e "\n${YELLOW}GET /health${NC}"
    curl -s http://localhost:$PORT/health | python3 -m json.tool 2>/dev/null || echo "(server not running?)"

    echo -e "\n${YELLOW}GET /memory/recent${NC}"
    curl -s http://localhost:$PORT/memory/recent | python3 -m json.tool 2>/dev/null

    echo -e "\n${YELLOW}POST /memory/log${NC}"
    curl -s -X POST http://localhost:$PORT/memory/log \
        -H "Content-Type: application/json" \
        -d '{"action":"test","details":"br memory-api test call"}' | python3 -m json.tool 2>/dev/null

    echo -e "\n${YELLOW}GET /memory/context${NC}"
    curl -s http://localhost:$PORT/memory/context | head -5
}

cmd_logs() {
    tail -f "$LOG_FILE"
}

case "${1:-status}" in
    start)  cmd_start  ;;
    stop)   cmd_stop   ;;
    status) cmd_status ;;
    test)   cmd_test   ;;
    logs)   cmd_logs   ;;
    restart) cmd_stop; sleep 1; cmd_start ;;
    *)
        echo "Usage: br memory-api [start|stop|status|restart|test|logs]"
        echo "  start   — launch server on port $PORT"
        echo "  stop    — stop server"
        echo "  status  — check if running"
        echo "  restart — stop + start"
        echo "  test    — hit all endpoints"
        echo "  logs    — tail log file"
        ;;
esac
