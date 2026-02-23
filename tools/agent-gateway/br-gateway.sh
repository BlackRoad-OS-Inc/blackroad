#!/usr/bin/env zsh
# BR Agent Gateway — HTTP API server for agent task dispatch
# br gateway start|stop|status|logs|test

GREEN=$'\033[0;32m'; RED=$'\033[0;31m'; YELLOW=$'\033[1;33m'
CYAN=$'\033[0;36m'; BOLD=$'\033[1m'; DIM=$'\033[2m'; NC=$'\033[0m'

GATEWAY_PORT=${BLACKROAD_GATEWAY_PORT:-8080}
GATEWAY_BIND=${BLACKROAD_GATEWAY_BIND:-127.0.0.1}
TASKS_DB="$HOME/.blackroad/agent-tasks.db"
PID_FILE="$HOME/.blackroad/gateway.pid"
LOG_FILE="$HOME/.blackroad/logs/gateway.log"
SCRIPT_DIR="${0:A:h}"

# ── Embedded Python gateway server ──────────────────────────────────────────
GATEWAY_PY="$HOME/.blackroad/gateway_server.py"

write_server() {
cat > "$GATEWAY_PY" << 'PYEOF'
#!/usr/bin/env python3
"""BlackRoad Agent Gateway — lightweight HTTP API for agent task dispatch."""
import http.server, json, sqlite3, os, sys, time, signal, hashlib, traceback
from urllib.parse import urlparse, parse_qs

TASKS_DB  = os.path.expanduser("~/.blackroad/agent-tasks.db")
AGENTS_DB = os.path.expanduser("~/.blackroad/agent-runtime.db")
AGENTS_DIR = os.path.expanduser("~/blackroad/agents/active")
PORT  = int(os.environ.get("GATEWAY_PORT", 8080))
BIND  = os.environ.get("GATEWAY_BIND", "127.0.0.1")
TOKEN = os.environ.get("BLACKROAD_GATEWAY_TOKEN", "")

KNOWN_AGENTS = ["LUCIDIA","ALICE","CIPHER","OCTAVIA","ARIA","SHELLFISH"]

def db():
    c = sqlite3.connect(TASKS_DB)
    c.row_factory = sqlite3.Row
    c.execute("""CREATE TABLE IF NOT EXISTS tasks (
        id TEXT PRIMARY KEY, title TEXT, description TEXT,
        assigned_to TEXT, status TEXT DEFAULT 'pending',
        priority INTEGER DEFAULT 5, result TEXT,
        created_at TEXT DEFAULT (datetime('now')),
        updated_at TEXT DEFAULT (datetime('now'))
    )""")
    c.commit()
    return c

def agent_states():
    agents = []
    if not os.path.isdir(AGENTS_DIR):
        return agents
    for f in os.listdir(AGENTS_DIR):
        if not f.endswith(".json"):
            continue
        try:
            with open(os.path.join(AGENTS_DIR, f)) as fh:
                d = json.load(fh)
            pid = d.get("pid", 0)
            alive = False
            try:
                os.kill(int(pid), 0)
                alive = True
            except Exception:
                pass
            d["alive"] = alive
            agents.append(d)
        except Exception:
            pass
    return agents

def resp(handler, code, data):
    body = json.dumps(data, indent=2).encode()
    handler.send_response(code)
    handler.send_header("Content-Type", "application/json")
    handler.send_header("Content-Length", len(body))
    handler.send_header("Access-Control-Allow-Origin", "*")
    handler.end_headers()
    handler.wfile.write(body)

def auth_ok(handler):
    if not TOKEN:
        return True
    auth = handler.headers.get("Authorization", "")
    return auth == f"Bearer {TOKEN}"

class Handler(http.server.BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        ts = time.strftime("%H:%M:%S")
        sys.stderr.write(f"[{ts}] {fmt % args}\n")

    def do_OPTIONS(self):
        self.send_response(204)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET,POST,DELETE,OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Authorization,Content-Type")
        self.end_headers()

    def do_GET(self):
        if not auth_ok(self):
            return resp(self, 401, {"error": "Unauthorized"})
        p = urlparse(self.path).path.rstrip("/")

        # GET /
        if p in ("", "/"):
            return resp(self, 200, {
                "service": "BlackRoad Agent Gateway",
                "version": "1.0.0",
                "port": PORT,
                "endpoints": [
                    "GET  /health",
                    "GET  /agents",
                    "GET  /tasks",
                    "GET  /tasks/:id",
                    "POST /tasks",
                    "POST /tasks/:id/complete",
                    "DELETE /tasks/:id",
                    "POST /broadcast",
                ]
            })

        # GET /health
        if p == "/health":
            agents = agent_states()
            alive  = sum(1 for a in agents if a.get("alive"))
            c = db()
            pending = c.execute("SELECT COUNT(*) FROM tasks WHERE status='pending'").fetchone()[0]
            active  = c.execute("SELECT COUNT(*) FROM tasks WHERE status='in_progress'").fetchone()[0]
            return resp(self, 200, {
                "status": "ok",
                "agents_alive": alive,
                "agents_total": len(agents),
                "tasks_pending": pending,
                "tasks_active": active,
                "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
            })

        # GET /agents
        if p == "/agents":
            return resp(self, 200, {"agents": agent_states()})

        # GET /tasks
        if p == "/tasks":
            qs = parse_qs(urlparse(self.path).query)
            status_filter = qs.get("status", [None])[0]
            agent_filter  = qs.get("agent",  [None])[0]
            c = db()
            q, params = "SELECT * FROM tasks", []
            conds = []
            if status_filter:
                conds.append("status=?"); params.append(status_filter)
            if agent_filter:
                conds.append("assigned_to=?"); params.append(agent_filter.upper())
            if conds:
                q += " WHERE " + " AND ".join(conds)
            q += " ORDER BY priority DESC, created_at DESC LIMIT 50"
            rows = [dict(r) for r in c.execute(q, params).fetchall()]
            return resp(self, 200, {"tasks": rows, "count": len(rows)})

        # GET /tasks/:id
        if p.startswith("/tasks/"):
            tid = p[7:]
            c = db()
            row = c.execute("SELECT * FROM tasks WHERE id=?", (tid,)).fetchone()
            if not row:
                return resp(self, 404, {"error": "not found"})
            return resp(self, 200, dict(row))

        resp(self, 404, {"error": "not found"})

    def do_POST(self):
        if not auth_ok(self):
            return resp(self, 401, {"error": "Unauthorized"})
        p = urlparse(self.path).path.rstrip("/")
        length = int(self.headers.get("Content-Length", 0))
        body = {}
        if length:
            try:
                body = json.loads(self.rfile.read(length))
            except Exception:
                return resp(self, 400, {"error": "invalid JSON"})

        # POST /tasks — create task
        if p == "/tasks":
            title       = body.get("title", "").strip()
            description = body.get("description", "")
            assigned_to = body.get("assigned_to", "LUCIDIA").upper()
            priority    = int(body.get("priority", 5))
            if not title:
                return resp(self, 400, {"error": "title required"})
            if assigned_to not in KNOWN_AGENTS:
                return resp(self, 400, {"error": f"unknown agent, use one of {KNOWN_AGENTS}"})
            tid = "task_" + hashlib.md5(f"{title}{time.time()}".encode()).hexdigest()[:8]
            c = db()
            c.execute("""INSERT INTO tasks (id,title,description,assigned_to,status,priority)
                         VALUES (?,?,?,?,'pending',?)""",
                      (tid, title, description, assigned_to, priority))
            c.commit()
            return resp(self, 201, {"id": tid, "status": "pending", "assigned_to": assigned_to})

        # POST /tasks/:id/complete
        if p.startswith("/tasks/") and p.endswith("/complete"):
            tid = p[7:-9]
            result = body.get("result", "")
            c = db()
            row = c.execute("SELECT id FROM tasks WHERE id=?", (tid,)).fetchone()
            if not row:
                return resp(self, 404, {"error": "not found"})
            c.execute("UPDATE tasks SET status='done', result=?, updated_at=datetime('now') WHERE id=?",
                      (result, tid))
            c.commit()
            return resp(self, 200, {"id": tid, "status": "done"})

        # POST /broadcast — send message to all agents (writes to shared/inbox/)
        if p == "/broadcast":
            message = body.get("message", "").strip()
            if not message:
                return resp(self, 400, {"error": "message required"})
            shared_dir = os.path.expanduser("~/blackroad/shared/inbox")
            os.makedirs(shared_dir, exist_ok=True)
            msg_id = f"bc_{int(time.time())}"
            msg_file = os.path.join(shared_dir, f"{msg_id}.json")
            with open(msg_file, "w") as fh:
                json.dump({"id": msg_id, "from": "gateway",
                           "to": "ALL", "message": message,
                           "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())}, fh)
            return resp(self, 200, {"broadcast": msg_id, "message": message})

        resp(self, 404, {"error": "not found"})

    def do_DELETE(self):
        if not auth_ok(self):
            return resp(self, 401, {"error": "Unauthorized"})
        p = urlparse(self.path).path.rstrip("/")
        if p.startswith("/tasks/"):
            tid = p[7:]
            c = db()
            c.execute("DELETE FROM tasks WHERE id=?", (tid,))
            c.commit()
            return resp(self, 200, {"deleted": tid})
        resp(self, 404, {"error": "not found"})


if __name__ == "__main__":
    signal.signal(signal.SIGTERM, lambda *_: sys.exit(0))
    server = http.server.HTTPServer((BIND, PORT), Handler)
    sys.stderr.write(f"[gateway] listening on {BIND}:{PORT}\n")
    sys.stderr.flush()
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
PYEOF
}

# ── Commands ─────────────────────────────────────────────────────────────────

cmd_start() {
    if [[ -f "$PID_FILE" ]]; then
        local pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            echo "${YELLOW}⚠ gateway already running${NC} (pid $pid) on ${BIND}:${GATEWAY_PORT}"
            return
        fi
    fi
    mkdir -p "$(dirname "$LOG_FILE")" "$(dirname "$PID_FILE")"
    write_server
    GATEWAY_PORT=$GATEWAY_PORT GATEWAY_BIND=$GATEWAY_BIND \
    BLACKROAD_GATEWAY_TOKEN=${BLACKROAD_GATEWAY_TOKEN:-""} \
        python3 "$GATEWAY_PY" >> "$LOG_FILE" 2>&1 &
    local pid=$!
    echo $pid > "$PID_FILE"
    sleep 0.5
    if kill -0 "$pid" 2>/dev/null; then
        echo "${GREEN}● gateway started${NC}  pid=$pid  http://${GATEWAY_BIND}:${GATEWAY_PORT}"
    else
        echo "${RED}✗ gateway failed to start — check logs: $LOG_FILE${NC}"
        rm -f "$PID_FILE"
        return 1
    fi
}

cmd_stop() {
    if [[ ! -f "$PID_FILE" ]]; then
        echo "${DIM}gateway not running${NC}"; return
    fi
    local pid=$(cat "$PID_FILE")
    if kill -0 "$pid" 2>/dev/null; then
        kill "$pid" && rm -f "$PID_FILE"
        echo "${GREEN}✓ gateway stopped${NC} (pid $pid)"
    else
        echo "${DIM}gateway already stopped${NC}"
        rm -f "$PID_FILE"
    fi
}

cmd_status() {
    echo ""
    echo "${BOLD}BLACKROAD AGENT GATEWAY${NC}"
    echo "${DIM}────────────────────────${NC}"
    if [[ -f "$PID_FILE" ]]; then
        local pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            echo "  ${GREEN}● running${NC}  pid=$pid"
            echo "  ${CYAN}URL:${NC}  http://${GATEWAY_BIND}:${GATEWAY_PORT}"
            local health=$(curl -sf "http://${GATEWAY_BIND}:${GATEWAY_PORT}/health" 2>/dev/null)
            if [[ -n "$health" ]]; then
                local agents=$(echo "$health" | python3 -c "import json,sys; d=json.load(sys.stdin); print(f\"{d['agents_alive']}/{d['agents_total']} agents alive, {d['tasks_pending']} pending tasks\")" 2>/dev/null)
                echo "  ${DIM}$agents${NC}"
            fi
        else
            echo "  ${RED}✗ dead${NC} (stale pid $pid)"
            rm -f "$PID_FILE"
        fi
    else
        echo "  ${DIM}not running${NC}"
    fi
    echo ""
}

cmd_logs() {
    local n=${1:-40}
    if [[ -f "$LOG_FILE" ]]; then
        tail -n "$n" "$LOG_FILE"
    else
        echo "${DIM}no log file yet${NC}"
    fi
}

cmd_test() {
    local base="http://${GATEWAY_BIND}:${GATEWAY_PORT}"
    echo "${BOLD}Testing gateway at $base${NC}"
    echo ""

    echo "${CYAN}GET /${NC}"
    curl -sf "$base/" | python3 -m json.tool 2>/dev/null || echo "${RED}✗ unreachable${NC}"
    echo ""

    echo "${CYAN}GET /health${NC}"
    curl -sf "$base/health" | python3 -m json.tool 2>/dev/null
    echo ""

    echo "${CYAN}POST /tasks (create task for LUCIDIA)${NC}"
    local result=$(curl -sf -X POST "$base/tasks" \
        -H "Content-Type: application/json" \
        -d '{"title":"Gateway test task","description":"Created via br gateway test","assigned_to":"LUCIDIA","priority":3}')
    echo "$result" | python3 -m json.tool 2>/dev/null
    local tid=$(echo "$result" | python3 -c "import json,sys; print(json.load(sys.stdin)['id'])" 2>/dev/null)
    echo ""

    if [[ -n "$tid" ]]; then
        echo "${CYAN}GET /tasks/$tid${NC}"
        curl -sf "$base/tasks/$tid" | python3 -m json.tool 2>/dev/null
        echo ""

        echo "${CYAN}DELETE /tasks/$tid${NC}"
        curl -sf -X DELETE "$base/tasks/$tid" | python3 -m json.tool 2>/dev/null
        echo ""
    fi

    echo "${GREEN}✓ gateway test complete${NC}"
}

show_help() {
    echo ""
    echo "${BOLD}br gateway${NC} — HTTP API server for agent task dispatch"
    echo ""
    echo "${CYAN}Commands:${NC}"
    echo "  ${BOLD}start${NC}             Start the gateway server"
    echo "  ${BOLD}stop${NC}              Stop the gateway server"
    echo "  ${BOLD}restart${NC}           Restart the gateway server"
    echo "  ${BOLD}status${NC}            Show gateway status + health"
    echo "  ${BOLD}logs [n]${NC}          Tail gateway logs (default: 40 lines)"
    echo "  ${BOLD}test${NC}              Run API test suite against running gateway"
    echo ""
    echo "${CYAN}Endpoints (when running):${NC}"
    echo "  GET  http://127.0.0.1:${GATEWAY_PORT}/         # API info"
    echo "  GET  http://127.0.0.1:${GATEWAY_PORT}/health   # health check"
    echo "  GET  http://127.0.0.1:${GATEWAY_PORT}/agents   # all agent states"
    echo "  GET  http://127.0.0.1:${GATEWAY_PORT}/tasks    # task queue"
    echo "  POST http://127.0.0.1:${GATEWAY_PORT}/tasks    # create task"
    echo "  POST http://127.0.0.1:${GATEWAY_PORT}/tasks/:id/complete"
    echo "  DELETE http://127.0.0.1:${GATEWAY_PORT}/tasks/:id"
    echo "  POST http://127.0.0.1:${GATEWAY_PORT}/broadcast"
    echo ""
    echo "${CYAN}Env:${NC}"
    echo "  BLACKROAD_GATEWAY_PORT=8080    (default)"
    echo "  BLACKROAD_GATEWAY_BIND=127.0.0.1"
    echo "  BLACKROAD_GATEWAY_TOKEN=       (optional auth token)"
    echo ""
}

case "${1:-status}" in
    start)    cmd_start ;;
    stop)     cmd_stop ;;
    restart)  cmd_stop; sleep 0.3; cmd_start ;;
    status)   cmd_status ;;
    logs)     shift; cmd_logs "$@" ;;
    test)     cmd_test ;;
    help|-h)  show_help ;;
    *)        show_help ;;
esac
