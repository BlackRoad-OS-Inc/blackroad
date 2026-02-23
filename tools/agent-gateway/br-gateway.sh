#!/usr/bin/env zsh
# BR Agent Gateway — HTTP API + SSE event stream + agent chaining
# br gateway start|stop|restart|status|logs|test|stream

GREEN=$'\033[0;32m'; RED=$'\033[0;31m'; YELLOW=$'\033[1;33m'
CYAN=$'\033[0;36m'; BOLD=$'\033[1m'; DIM=$'\033[2m'; NC=$'\033[0m'

GATEWAY_PORT=${BLACKROAD_GATEWAY_PORT:-8080}
GATEWAY_BIND=${BLACKROAD_GATEWAY_BIND:-127.0.0.1}
PID_FILE="$HOME/.blackroad/gateway.pid"
LOG_FILE="$HOME/.blackroad/logs/gateway.log"
GATEWAY_PY="$HOME/.blackroad/gateway_server.py"

# ── Embedded Python server ───────────────────────────────────────────────────
write_server() {
cat > "$GATEWAY_PY" << 'PYEOF'
#!/usr/bin/env python3
"""BlackRoad Agent Gateway v1.1 — HTTP API + SSE events + task chaining."""
import http.server, json, sqlite3, os, sys, time, signal, hashlib, threading
from urllib.parse import urlparse, parse_qs

TASKS_DB   = os.path.expanduser("~/.blackroad/agent-tasks.db")
AGENTS_DIR = os.path.expanduser("~/blackroad/agents/active")
PORT  = int(os.environ.get("GATEWAY_PORT", 8080))
BIND  = os.environ.get("GATEWAY_BIND", "127.0.0.1")
TOKEN = os.environ.get("BLACKROAD_GATEWAY_TOKEN", "")
KNOWN_AGENTS = ["LUCIDIA","ALICE","CIPHER","OCTAVIA","ARIA","SHELLFISH"]

# SSE broadcast — push events to all connected /events clients
_sse_clients = []
_sse_lock    = threading.Lock()

def sse_broadcast(event_type, data):
    msg = f"event: {event_type}\ndata: {json.dumps(data)}\n\n"
    with _sse_lock:
        dead = [q for q in _sse_clients if q is None]
        for d in dead:
            _sse_clients.remove(d)
        for q in list(_sse_clients):
            try:
                q.append(msg)
            except Exception:
                pass

def db():
    c = sqlite3.connect(TASKS_DB, timeout=10, check_same_thread=False)
    c.row_factory = sqlite3.Row
    c.execute("PRAGMA journal_mode=WAL")
    c.execute("""CREATE TABLE IF NOT EXISTS tasks (
        id TEXT PRIMARY KEY, title TEXT, description TEXT,
        assigned_to TEXT, chain_to TEXT,
        status TEXT DEFAULT 'pending', priority INTEGER DEFAULT 5,
        result TEXT, created_at INTEGER DEFAULT (strftime('%s','now')),
        claimed_at INTEGER, completed_at INTEGER
    )""")
    c.execute("""CREATE TABLE IF NOT EXISTS agent_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        agent TEXT, event TEXT, detail TEXT,
        ts INTEGER DEFAULT (strftime('%s','now'))
    )""")
    c.commit()
    return c

def agent_states():
    agents = []
    if not os.path.isdir(AGENTS_DIR):
        return agents
    for f in sorted(os.listdir(AGENTS_DIR)):
        if not f.endswith(".json"):
            continue
        try:
            with open(os.path.join(AGENTS_DIR, f)) as fh:
                d = json.load(fh)
            try:
                os.kill(int(d.get("pid",0)), 0)
                d["alive"] = True
            except Exception:
                d["alive"] = False
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
    return handler.headers.get("Authorization","") == f"Bearer {TOKEN}"

# Background: watch agent_log for new entries and broadcast SSE
_last_log_id = [0]
def log_watcher():
    while True:
        try:
            c = db()
            rows = c.execute(
                "SELECT id,agent,event,detail,ts FROM agent_log WHERE id>? ORDER BY id LIMIT 20",
                (_last_log_id[0],)
            ).fetchall()
            for row in rows:
                _last_log_id[0] = row["id"]
                sse_broadcast("agent_event", {
                    "agent": row["agent"], "event": row["event"],
                    "detail": row["detail"], "ts": row["ts"]
                })
        except Exception:
            pass
        time.sleep(1)


class Handler(http.server.BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        sys.stderr.write(f"[{time.strftime('%H:%M:%S')}] {fmt % args}\n")

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

        if p in ("", "/"):
            return resp(self, 200, {
                "service": "BlackRoad Agent Gateway", "version": "1.1.0", "port": PORT,
                "endpoints": [
                    "GET  /health", "GET  /agents", "GET  /tasks", "GET  /tasks/:id",
                    "GET  /log", "GET  /events  (SSE stream)",
                    "POST /tasks  {title,assigned_to,chain_to?,priority?}",
                    "POST /tasks/:id/complete  {result}",
                    "POST /broadcast  {message}",
                    "DELETE /tasks/:id"
                ]
            })

        if p == "/health":
            agents = agent_states()
            alive  = sum(1 for a in agents if a.get("alive"))
            c = db()
            pending = c.execute("SELECT COUNT(*) FROM tasks WHERE status='pending'").fetchone()[0]
            active  = c.execute("SELECT COUNT(*) FROM tasks WHERE status='in_progress'").fetchone()[0]
            done    = c.execute("SELECT COUNT(*) FROM tasks WHERE status='done'").fetchone()[0]
            return resp(self, 200, {
                "status": "ok", "agents_alive": alive, "agents_total": len(agents),
                "tasks_pending": pending, "tasks_active": active, "tasks_done": done,
                "sse_clients": len(_sse_clients),
                "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
            })

        if p == "/agents":
            return resp(self, 200, {"agents": agent_states()})

        if p == "/log":
            c = db()
            rows = [dict(r) for r in c.execute(
                "SELECT * FROM agent_log ORDER BY id DESC LIMIT 50"
            ).fetchall()]
            return resp(self, 200, {"log": rows, "count": len(rows)})

        # SSE event stream
        if p == "/events":
            queue = []
            with _sse_lock:
                _sse_clients.append(queue)
            self.send_response(200)
            self.send_header("Content-Type", "text/event-stream")
            self.send_header("Cache-Control", "no-cache")
            self.send_header("Connection", "keep-alive")
            self.send_header("Access-Control-Allow-Origin", "*")
            self.send_header("X-Accel-Buffering", "no")
            self.end_headers()
            try:
                # Initial snapshot
                snap = {"agents": agent_states()}
                c = db()
                snap["tasks"] = [dict(r) for r in c.execute(
                    "SELECT id,title,assigned_to,status,priority FROM tasks "
                    "WHERE status!='done' ORDER BY priority DESC LIMIT 10"
                ).fetchall()]
                self.wfile.write(f"event: snapshot\ndata: {json.dumps(snap)}\n\n".encode())
                self.wfile.flush()
            except Exception:
                pass
            last_hb = time.time()
            try:
                while True:
                    while queue:
                        self.wfile.write(queue.pop(0).encode())
                        self.wfile.flush()
                    if time.time() - last_hb > 15:
                        self.wfile.write(b": heartbeat\n\n")
                        self.wfile.flush()
                        last_hb = time.time()
                    time.sleep(0.1)
            except Exception:
                pass
            finally:
                with _sse_lock:
                    if queue in _sse_clients:
                        _sse_clients.remove(queue)
            return

        if p == "/tasks":
            qs = parse_qs(urlparse(self.path).query)
            sf = qs.get("status",[None])[0]
            af = qs.get("agent",[None])[0]
            c  = db()
            q, params = "SELECT * FROM tasks", []
            conds = []
            if sf:
                conds.append("status=?"); params.append(sf)
            if af:
                conds.append("assigned_to=?"); params.append(af.upper())
            if conds:
                q += " WHERE " + " AND ".join(conds)
            q += " ORDER BY priority DESC, created_at DESC LIMIT 50"
            rows = [dict(r) for r in c.execute(q, params).fetchall()]
            return resp(self, 200, {"tasks": rows, "count": len(rows)})

        if p.startswith("/tasks/"):
            tid = p[7:]
            row = db().execute("SELECT * FROM tasks WHERE id=?", (tid,)).fetchone()
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

        if p == "/tasks":
            title       = body.get("title","").strip()
            description = body.get("description","")
            assigned_to = body.get("assigned_to","LUCIDIA").upper()
            chain_to    = body.get("chain_to","")
            priority    = int(body.get("priority", 5))
            if not title:
                return resp(self, 400, {"error": "title required"})
            if assigned_to not in KNOWN_AGENTS:
                return resp(self, 400, {"error": f"unknown agent — use: {KNOWN_AGENTS}"})
            tid = "task_" + hashlib.md5(f"{title}{time.time()}".encode()).hexdigest()[:8]
            c = db()
            c.execute("""INSERT INTO tasks (id,title,description,assigned_to,chain_to,status,priority)
                         VALUES (?,?,?,?,?,'pending',?)""",
                      (tid, title, description, assigned_to, chain_to, priority))
            c.commit()
            sse_broadcast("task_created", {"id": tid, "title": title,
                                            "assigned_to": assigned_to, "priority": priority})
            return resp(self, 201, {"id": tid, "status": "pending",
                                     "assigned_to": assigned_to, "chain_to": chain_to})

        if p.startswith("/tasks/") and p.endswith("/complete"):
            tid    = p[7:-9]
            result = body.get("result","")
            c = db()
            row = c.execute("SELECT * FROM tasks WHERE id=?", (tid,)).fetchone()
            if not row:
                return resp(self, 404, {"error": "not found"})
            c.execute("UPDATE tasks SET status='done', result=?, completed_at=strftime('%s','now') WHERE id=?",
                      (result, tid))
            c.commit()
            sse_broadcast("task_done", {"id": tid, "agent": row["assigned_to"], "result": result[:200]})
            # Agent chaining
            chain_to = (row["chain_to"] or "").strip().upper()
            if chain_to and chain_to in KNOWN_AGENTS:
                ntid = "task_" + hashlib.md5(f"chain{tid}{time.time()}".encode()).hexdigest()[:8]
                c.execute("""INSERT INTO tasks (id,title,description,assigned_to,status,priority)
                             VALUES (?,?,?,?,'pending',?)""",
                          (ntid,
                           f"[Chain] {row['title']}",
                           f"Context from {row['assigned_to']}: {result[:400]}",
                           chain_to, row["priority"]))
                c.commit()
                sse_broadcast("task_chained", {
                    "from_task": tid, "new_task": ntid,
                    "from_agent": row["assigned_to"], "to_agent": chain_to
                })
            return resp(self, 200, {"id": tid, "status": "done", "chained_to": chain_to or None})

        if p == "/broadcast":
            message = body.get("message","").strip()
            if not message:
                return resp(self, 400, {"error": "message required"})
            shared = os.path.expanduser("~/blackroad/shared/inbox")
            os.makedirs(shared, exist_ok=True)
            mid = f"bc_{int(time.time())}"
            with open(os.path.join(shared, f"{mid}.json"), "w") as fh:
                json.dump({"id": mid, "from": "gateway", "to": "ALL",
                           "message": message,
                           "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ",time.gmtime())}, fh)
            sse_broadcast("broadcast", {"id": mid, "message": message})
            return resp(self, 200, {"broadcast": mid, "message": message})

        resp(self, 404, {"error": "not found"})

    def do_DELETE(self):
        if not auth_ok(self):
            return resp(self, 401, {"error": "Unauthorized"})
        p = urlparse(self.path).path.rstrip("/")
        if p.startswith("/tasks/"):
            tid = p[7:]
            db().execute("DELETE FROM tasks WHERE id=?", (tid,))
            return resp(self, 200, {"deleted": tid})
        resp(self, 404, {"error": "not found"})


if __name__ == "__main__":
    signal.signal(signal.SIGTERM, lambda *_: sys.exit(0))
    try:
        row = db().execute("SELECT MAX(id) FROM agent_log").fetchone()
        _last_log_id[0] = row[0] or 0
    except Exception:
        pass
    threading.Thread(target=log_watcher, daemon=True).start()
    server = http.server.HTTPServer((BIND, PORT), Handler)
    server.socket.setsockopt(__import__('socket').SOL_SOCKET,
                              __import__('socket').SO_REUSEADDR, 1)
    sys.stderr.write(f"[gateway] v1.1 listening on {BIND}:{PORT}\n")
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
            echo "${YELLOW}⚠ gateway already running${NC} (pid $pid) on ${GATEWAY_BIND}:${GATEWAY_PORT}"
            return
        fi
    fi
    mkdir -p "$(dirname "$LOG_FILE")"
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
        echo "${RED}✗ gateway failed — check: $LOG_FILE${NC}"
        rm -f "$PID_FILE"; return 1
    fi
}

cmd_stop() {
    if [[ ! -f "$PID_FILE" ]]; then echo "${DIM}gateway not running${NC}"; return; fi
    local pid=$(cat "$PID_FILE")
    if kill -0 "$pid" 2>/dev/null; then
        kill "$pid" && rm -f "$PID_FILE"
        echo "${GREEN}✓ gateway stopped${NC} (pid $pid)"
    else
        echo "${DIM}already stopped${NC}"; rm -f "$PID_FILE"
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
                echo "$health" | python3 -c "
import json,sys
d=json.load(sys.stdin)
print(f\"  agents: {d['agents_alive']}/{d['agents_total']} alive\")
print(f\"  tasks:  {d['tasks_pending']} pending  {d['tasks_active']} active  {d['tasks_done']} done\")
print(f\"  sse:    {d['sse_clients']} connected client(s)\")
" 2>/dev/null
            fi
        else
            echo "  ${RED}✗ dead${NC} (stale pid)"; rm -f "$PID_FILE"
        fi
    else
        echo "  ${DIM}not running — br gateway start${NC}"
    fi
    echo ""
}

cmd_logs() {
    [[ -f "$LOG_FILE" ]] && tail -n "${1:-40}" "$LOG_FILE" || echo "${DIM}no logs yet${NC}"
}

cmd_stream() {
    local base="http://${GATEWAY_BIND}:${GATEWAY_PORT}"
    echo "${BOLD}${CYAN}◆ BLACKROAD LIVE EVENT STREAM${NC}  ${DIM}${base}/events${NC}"
    echo "${DIM}(Ctrl+C to stop)${NC}"
    echo ""
    curl -sN "$base/events" 2>/dev/null | while IFS= read -r line; do
        if [[ "$line" == event:* ]]; then
            local etype="${line#event: }"
            case "$etype" in
                agent_event)  printf "${CYAN}[EVENT]${NC} " ;;
                task_created) printf "${GREEN}[NEW TASK]${NC} " ;;
                task_done)    printf "${GREEN}[DONE]${NC} " ;;
                task_chained) printf "${YELLOW}[CHAIN]${NC} " ;;
                broadcast)    printf "${MAGENTA}[BROADCAST]${NC} " ;;
                snapshot)     printf "${DIM}[SNAPSHOT]${NC} " ;;
                *)            printf "${DIM}[${etype}]${NC} " ;;
            esac
        elif [[ "$line" == data:* ]]; then
            local data="${line#data: }"
            echo "$data" | python3 -c "
import json,sys
try:
    d=json.load(sys.stdin)
    # Format nicely per event type
    if 'agent' in d and 'event' in d:
        print(f\"{d['agent']:10s} {d['event']:12s} {d.get('detail','')}\" )
    elif 'title' in d:
        print(f\"{d.get('assigned_to','?'):10s} ← {d['title'][:50]}\")
    elif 'from_agent' in d:
        print(f\"{d['from_agent']} → {d['to_agent']}  task={d.get('new_task','?')[:16]}\")
    else:
        print(json.dumps(d, separators=(',',':')))
except: print(sys.stdin.read())
" 2>/dev/null || echo "$data"
        fi
    done
}

cmd_test() {
    local base="http://${GATEWAY_BIND}:${GATEWAY_PORT}"
    echo "${BOLD}Testing gateway at $base${NC}"
    echo ""
    echo "${CYAN}GET /health${NC}"
    curl -sf "$base/health" | python3 -m json.tool 2>/dev/null
    echo ""
    echo "${CYAN}POST /tasks (chain: ARIA → CIPHER)${NC}"
    local r=$(curl -sf -X POST "$base/tasks" \
        -H "Content-Type: application/json" \
        -d '{"title":"Test chain task","description":"Say hello","assigned_to":"ARIA","chain_to":"CIPHER","priority":1}')
    echo "$r" | python3 -m json.tool 2>/dev/null
    local tid=$(echo "$r" | python3 -c "import json,sys; print(json.load(sys.stdin).get('id',''))" 2>/dev/null)
    if [[ -n "$tid" ]]; then
        echo ""
        echo "${CYAN}DELETE /tasks/$tid (cleanup)${NC}"
        curl -sf -X DELETE "$base/tasks/$tid" | python3 -m json.tool 2>/dev/null
    fi
    echo ""
    echo "${GREEN}✓ gateway test complete${NC}"
}

show_help() {
    echo ""
    echo "${BOLD}br gateway${NC} — HTTP API + SSE event stream for agent tasks"
    echo ""
    echo "${CYAN}Commands:${NC}"
    echo "  ${BOLD}start${NC}          Start gateway server (port ${GATEWAY_PORT})"
    echo "  ${BOLD}stop${NC}           Stop gateway server"
    echo "  ${BOLD}restart${NC}        Restart gateway"
    echo "  ${BOLD}status${NC}         Show status + health metrics"
    echo "  ${BOLD}logs [n]${NC}       Tail logs (default 40 lines)"
    echo "  ${BOLD}stream${NC}         Watch live SSE event stream"
    echo "  ${BOLD}test${NC}           Run API test suite"
    echo ""
    echo "${CYAN}Key endpoints:${NC}"
    echo "  GET  /health                     # agents alive, task counts, SSE clients"
    echo "  GET  /events                     # SSE stream — agent_event, task_created, task_done, task_chained"
    echo "  GET  /agents                     # live agent states"
    echo "  GET  /log                        # recent agent activity log"
    echo "  GET  /tasks?status=pending       # task queue"
    echo "  POST /tasks                      # {title, assigned_to, chain_to?, priority?}"
    echo "  POST /tasks/:id/complete         # {result}"
    echo ""
    echo "${CYAN}Task chaining:${NC}"
    echo "  POST /tasks -d '{...\"chain_to\":\"CIPHER\"}'"
    echo "  → when ARIA completes, a follow-up task is auto-created for CIPHER"
    echo ""
}

case "${1:-status}" in
    start)    cmd_start ;;
    stop)     cmd_stop ;;
    restart)  cmd_stop; sleep 0.3; cmd_start ;;
    status)   cmd_status ;;
    logs)     shift; cmd_logs "$@" ;;
    stream)   cmd_stream ;;
    test)     cmd_test ;;
    help|-h)  show_help ;;
    *)        show_help ;;
esac
