#!/usr/bin/env zsh
# BR Agent Gateway — HTTP API + SSE event stream + agent chaining
# br gateway start|stop|restart|status|logs|test|stream
AMBER='\033[38;5;214m'; PINK='\033[38;5;205m'; VIOLET='\033[38;5;135m'; BBLUE='\033[38;5;69m'
GREEN='\033[0;32m'; RED='\033[0;31m'; BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'
CYAN="$AMBER"; YELLOW="$PINK"; BLUE="$BBLUE"; MAGENTA="$VIOLET"; PURPLE="$VIOLET"

# (aliases above; no overrides)

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

        if p in ("", "/", "/ui"):
            html = DASHBOARD_HTML.encode()
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", len(html))
            self.end_headers()
            self.wfile.write(html)
            return

        if p == "/api":
            return resp(self, 200, {
                "service": "BlackRoad Agent Gateway", "version": "1.2.0", "port": PORT,
                "ui": f"http://{BIND}:{PORT}/",
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


# ── Dashboard HTML ────────────────────────────────────────────────────────────
DASHBOARD_HTML = """<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>BlackRoad OS — Agent Fleet</title>
<style>
  :root {
    --black:  #000;
    --white:  #fff;
    --amber:  #F5A623;
    --pink:   #FF1D6C;
    --blue:   #2979FF;
    --violet: #9C27B0;
    --green:  #00E676;
    --red:    #FF1744;
    --dim:    #333;
    --card:   #0d0d0d;
    --border: #1a1a1a;
  }
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body {
    background: var(--black);
    color: var(--white);
    font-family: -apple-system, BlinkMacSystemFont, 'SF Mono', 'Fira Code', monospace;
    font-size: 13px;
    min-height: 100vh;
  }
  /* ── Header ── */
  header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 16px 24px;
    border-bottom: 1px solid var(--border);
    background: #050505;
  }
  .logo {
    font-size: 18px;
    font-weight: 700;
    letter-spacing: 2px;
    background: linear-gradient(135deg, var(--amber) 0%, var(--pink) 38%, var(--violet) 62%, var(--blue) 100%);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
    background-clip: text;
  }
  .status-pill {
    display: inline-flex;
    align-items: center;
    gap: 6px;
    padding: 4px 12px;
    border-radius: 20px;
    border: 1px solid var(--border);
    font-size: 11px;
    color: #888;
  }
  .status-pill .dot { width: 7px; height: 7px; border-radius: 50%; background: var(--green); animation: pulse 2s infinite; }
  @keyframes pulse { 0%,100%{opacity:1} 50%{opacity:.4} }
  /* ── Layout ── */
  main { display: grid; grid-template-columns: 1fr 1fr; grid-template-rows: auto auto; gap: 0; }
  @media (max-width: 900px) { main { grid-template-columns: 1fr; } }
  section {
    padding: 20px 24px;
    border-right: 1px solid var(--border);
    border-bottom: 1px solid var(--border);
  }
  section:nth-child(even) { border-right: none; }
  h2 {
    font-size: 10px;
    letter-spacing: 2px;
    text-transform: uppercase;
    color: #555;
    margin-bottom: 16px;
    display: flex;
    align-items: center;
    gap: 8px;
  }
  h2 .count {
    background: var(--border);
    color: #777;
    padding: 1px 7px;
    border-radius: 10px;
    font-size: 10px;
  }
  /* ── Agent cards ── */
  .agents-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(200px, 1fr)); gap: 10px; }
  .agent-card {
    background: var(--card);
    border: 1px solid var(--border);
    border-radius: 8px;
    padding: 12px 14px;
    transition: border-color 0.2s, transform 0.15s;
  }
  .agent-card:hover { border-color: #333; transform: translateY(-1px); }
  .agent-card.alive { border-color: #1a2a1a; }
  .agent-card.busy  { border-color: #2a1a2a; }
  .agent-card.dead  { opacity: 0.4; }
  .agent-name {
    font-size: 13px;
    font-weight: 700;
    letter-spacing: 1px;
    margin-bottom: 6px;
  }
  .agent-meta { color: #555; font-size: 11px; margin-bottom: 8px; }
  .agent-task {
    font-size: 11px;
    color: #888;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }
  .agent-status {
    display: inline-flex;
    align-items: center;
    gap: 5px;
    font-size: 10px;
    letter-spacing: 0.5px;
    text-transform: uppercase;
    padding: 2px 8px;
    border-radius: 10px;
    margin-top: 8px;
  }
  .agent-status.alive  { background: #0a2010; color: var(--green); }
  .agent-status.busy   { background: #1a0a20; color: var(--violet); }
  .agent-status.dead   { background: #200a0a; color: var(--red); }
  /* ── Tasks ── */
  .task-list { display: flex; flex-direction: column; gap: 8px; }
  .task-item {
    background: var(--card);
    border: 1px solid var(--border);
    border-left: 3px solid transparent;
    border-radius: 6px;
    padding: 10px 12px;
    display: grid;
    grid-template-columns: 1fr auto;
    gap: 4px 12px;
    align-items: start;
  }
  .task-item.pending    { border-left-color: var(--amber); }
  .task-item.in_progress { border-left-color: var(--violet); }
  .task-item.done       { border-left-color: #333; opacity: 0.6; }
  .task-title { font-size: 12px; color: #ccc; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
  .task-meta  { font-size: 10px; color: #555; grid-column: 1; }
  .task-badge {
    font-size: 9px; letter-spacing: 0.5px; text-transform: uppercase;
    padding: 2px 7px; border-radius: 8px; white-space: nowrap;
    grid-row: 1; grid-column: 2;
  }
  .task-badge.pending     { background: #2a1e00; color: var(--amber); }
  .task-badge.in_progress { background: #1a0a20; color: var(--violet); }
  .task-badge.done        { background: #111; color: #555; }
  /* ── Event log ── */
  #event-log {
    height: 240px;
    overflow-y: auto;
    display: flex;
    flex-direction: column-reverse;
    gap: 4px;
    scrollbar-width: thin;
    scrollbar-color: #222 transparent;
  }
  .event-row {
    display: flex;
    gap: 10px;
    align-items: baseline;
    padding: 3px 0;
    border-bottom: 1px solid #0d0d0d;
    animation: fadein 0.3s ease;
  }
  @keyframes fadein { from{opacity:0;transform:translateY(-4px)} to{opacity:1;transform:none} }
  .event-time { color: #444; font-size: 10px; white-space: nowrap; }
  .event-type {
    font-size: 9px; letter-spacing: 0.5px; text-transform: uppercase;
    padding: 1px 6px; border-radius: 8px; white-space: nowrap;
  }
  .event-type.agent_event  { background: #0a1520; color: var(--blue); }
  .event-type.task_created { background: #0a2010; color: var(--green); }
  .event-type.task_done    { background: #1a2a1a; color: var(--green); }
  .event-type.task_chained { background: #1a0a20; color: var(--violet); }
  .event-type.broadcast    { background: #2a1000; color: var(--amber); }
  .event-text { color: #888; font-size: 11px; flex: 1; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
  /* ── Stats bar ── */
  .stats-bar {
    display: flex;
    gap: 0;
    border-bottom: 1px solid var(--border);
    background: #050505;
  }
  .stat {
    flex: 1;
    padding: 12px 20px;
    border-right: 1px solid var(--border);
    text-align: center;
  }
  .stat:last-child { border-right: none; }
  .stat-val {
    font-size: 28px;
    font-weight: 700;
    line-height: 1;
    background: linear-gradient(135deg, var(--amber), var(--pink));
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
    background-clip: text;
  }
  .stat-label { font-size: 9px; text-transform: uppercase; letter-spacing: 1px; color: #555; margin-top: 4px; }
  /* ── Post task form ── */
  .post-form {
    display: flex;
    flex-direction: column;
    gap: 10px;
    margin-top: 12px;
  }
  .post-form input, .post-form select {
    background: var(--card);
    border: 1px solid var(--border);
    color: var(--white);
    padding: 8px 12px;
    border-radius: 6px;
    font-size: 12px;
    font-family: inherit;
    outline: none;
    transition: border-color 0.2s;
  }
  .post-form input:focus, .post-form select:focus { border-color: var(--pink); }
  .post-form .row { display: flex; gap: 8px; }
  .post-form .row > * { flex: 1; }
  .btn {
    background: linear-gradient(135deg, var(--pink), var(--violet));
    color: var(--white);
    border: none;
    padding: 9px 20px;
    border-radius: 6px;
    font-size: 12px;
    font-family: inherit;
    font-weight: 600;
    letter-spacing: 0.5px;
    cursor: pointer;
    transition: opacity 0.2s, transform 0.1s;
  }
  .btn:hover  { opacity: 0.85; }
  .btn:active { transform: scale(0.97); }
  .btn-sm { padding: 5px 12px; font-size: 11px; }
  .empty { color: #333; font-size: 11px; text-align: center; padding: 24px 0; }
  .tag { display: inline-block; background: #111; color: #555; font-size: 9px; padding: 1px 6px; border-radius: 4px; margin-left: 4px; }
</style>
</head>
<body>

<header>
  <div class="logo">◆ BLACKROAD OS</div>
  <div style="display:flex;gap:12px;align-items:center">
    <span class="status-pill"><span class="dot"></span><span id="hdr-status">connecting…</span></span>
    <span style="color:#444;font-size:11px" id="hdr-time"></span>
  </div>
</header>

<div class="stats-bar">
  <div class="stat"><div class="stat-val" id="stat-alive">—</div><div class="stat-label">agents alive</div></div>
  <div class="stat"><div class="stat-val" id="stat-pending">—</div><div class="stat-label">pending</div></div>
  <div class="stat"><div class="stat-val" id="stat-active">—</div><div class="stat-label">active</div></div>
  <div class="stat"><div class="stat-val" id="stat-done">—</div><div class="stat-label">completed</div></div>
  <div class="stat"><div class="stat-val" id="stat-sse">—</div><div class="stat-label">sse clients</div></div>
</div>

<main>
  <!-- Agents -->
  <section style="grid-column:1/-1">
    <h2>⬡ AGENT FLEET <span class="count" id="agents-count">0</span></h2>
    <div class="agents-grid" id="agents-grid">
      <div class="empty">Loading agents…</div>
    </div>
  </section>

  <!-- Task Queue -->
  <section>
    <h2>▶ TASK QUEUE <span class="count" id="tasks-count">0</span></h2>
    <div class="task-list" id="task-list">
      <div class="empty">No tasks</div>
    </div>
  </section>

  <!-- Right column: events + post form -->
  <section>
    <h2>◈ LIVE EVENTS</h2>
    <div id="event-log"><div class="empty">Waiting for events…</div></div>
    <div style="border-top:1px solid var(--border);margin-top:16px;padding-top:16px">
      <h2 style="margin-bottom:12px">✦ POST TASK</h2>
      <div class="post-form">
        <input id="pt-title" placeholder="Task title *" />
        <input id="pt-desc"  placeholder="Description (optional)" />
        <div class="row">
          <select id="pt-agent">
            <option value="LUCIDIA">LUCIDIA</option>
            <option value="ARIA">ARIA</option>
            <option value="CIPHER">CIPHER</option>
            <option value="OCTAVIA">OCTAVIA</option>
            <option value="SHELLFISH">SHELLFISH</option>
            <option value="ALICE">ALICE</option>
          </select>
          <select id="pt-chain">
            <option value="">No chain</option>
            <option value="LUCIDIA">→ LUCIDIA</option>
            <option value="ARIA">→ ARIA</option>
            <option value="CIPHER">→ CIPHER</option>
            <option value="OCTAVIA">→ OCTAVIA</option>
            <option value="SHELLFISH">→ SHELLFISH</option>
            <option value="ALICE">→ ALICE</option>
          </select>
          <input id="pt-priority" type="number" min="1" max="10" value="5" placeholder="Pri" style="max-width:60px" />
        </div>
        <button class="btn" onclick="postTask()">▶ Post Task</button>
      </div>
    </div>
  </section>
</main>

<script>
const AGENTS = ['LUCIDIA','ALICE','CIPHER','OCTAVIA','ARIA','SHELLFISH'];
const COLORS = {
  LUCIDIA:'#FF1D6C', ALICE:'#00E676', CIPHER:'#2979FF',
  OCTAVIA:'#F5A623', ARIA:'#9C27B0', SHELLFISH:'#FF6D00'
};

let agentMap = {};
let taskMap  = {};

function ts() {
  return new Date().toTimeString().slice(0,8);
}

function pushEvent(type, text) {
  const log = document.getElementById('event-log');
  // Remove empty placeholder
  const empty = log.querySelector('.empty');
  if (empty) empty.remove();
  const row = document.createElement('div');
  row.className = 'event-row';
  row.innerHTML = `<span class="event-time">${ts()}</span>
    <span class="event-type ${type}">${type.replace('_',' ')}</span>
    <span class="event-text">${text}</span>`;
  log.prepend(row);
  // Keep max 100 rows
  while (log.children.length > 100) log.removeChild(log.lastChild);
}

function renderAgents() {
  const grid = document.getElementById('agents-grid');
  grid.innerHTML = '';
  const list = Object.values(agentMap);
  if (!list.length) { grid.innerHTML = '<div class="empty">No agents found</div>'; return; }
  document.getElementById('agents-count').textContent = list.length;
  list.forEach(a => {
    const alive = a.alive;
    const busy  = a.status === 'busy' || a.current_task;
    const cls   = alive ? (busy ? 'busy' : 'alive') : 'dead';
    const color = COLORS[a.name] || '#888';
    const card  = document.createElement('div');
    card.className = `agent-card ${cls}`;
    card.innerHTML = `
      <div class="agent-name" style="color:${color}">${a.name || a.agent}</div>
      <div class="agent-meta">${a.model || '—'} &nbsp;·&nbsp; pid ${a.pid || '—'}</div>
      <div class="agent-task">${a.current_task ? '⟳ ' + a.current_task : (alive ? 'idle' : 'offline')}</div>
      <div class="agent-status ${cls}">
        <span style="width:6px;height:6px;border-radius:50%;background:currentColor;display:inline-block"></span>
        ${cls}
      </div>`;
    grid.appendChild(card);
  });
}

function renderTasks() {
  const list = document.getElementById('task-list');
  list.innerHTML = '';
  const tasks = Object.values(taskMap)
    .sort((a,b) => (b.priority||5)-(a.priority||5) || (a.created_at||0)-(b.created_at||0))
    .slice(0, 20);
  document.getElementById('tasks-count').textContent = tasks.length;
  if (!tasks.length) { list.innerHTML = '<div class="empty">No tasks</div>'; return; }
  tasks.forEach(t => {
    const div = document.createElement('div');
    div.className = `task-item ${t.status}`;
    const chain = t.chain_to ? `<span class="tag">→${t.chain_to}</span>` : '';
    div.innerHTML = `
      <div class="task-title">${t.title || '—'} ${chain}</div>
      <div class="task-meta">${t.assigned_to || '?'} · p${t.priority||5}</div>
      <span class="task-badge ${t.status}">${t.status}</span>`;
    list.appendChild(div);
  });
}

function updateStats(h) {
  if (!h) return;
  document.getElementById('stat-alive').textContent   = h.agents_alive   ?? '—';
  document.getElementById('stat-pending').textContent = h.tasks_pending   ?? '—';
  document.getElementById('stat-active').textContent  = h.tasks_active    ?? '—';
  document.getElementById('stat-done').textContent    = h.tasks_done      ?? '—';
  document.getElementById('stat-sse').textContent     = h.sse_clients     ?? '—';
  document.getElementById('hdr-time').textContent     = h.timestamp ? h.timestamp.slice(11,19)+' UTC' : '';
}

async function fetchHealth() {
  try {
    const r = await fetch('/health');
    if (r.ok) updateStats(await r.json());
  } catch(_) {}
}

async function fetchTasks() {
  try {
    const r = await fetch('/tasks');
    if (!r.ok) return;
    const d = await r.json();
    taskMap = {};
    (d.tasks || []).forEach(t => taskMap[t.id] = t);
    renderTasks();
  } catch(_) {}
}

async function postTask() {
  const title    = document.getElementById('pt-title').value.trim();
  const desc     = document.getElementById('pt-desc').value.trim();
  const agent    = document.getElementById('pt-agent').value;
  const chain    = document.getElementById('pt-chain').value;
  const priority = parseInt(document.getElementById('pt-priority').value) || 5;
  if (!title) { alert('Title is required'); return; }
  try {
    const r = await fetch('/tasks', {
      method: 'POST',
      headers: {'Content-Type':'application/json'},
      body: JSON.stringify({title, description:desc, assigned_to:agent,
                             chain_to:chain, priority})
    });
    const d = await r.json();
    if (r.ok) {
      document.getElementById('pt-title').value = '';
      document.getElementById('pt-desc').value  = '';
      taskMap[d.id] = d;
      renderTasks();
      pushEvent('task_created', `${d.id} → ${agent}${chain?' ⇒ '+chain:''}: ${title}`);
    } else {
      alert(d.error || 'Failed to post task');
    }
  } catch(e) { alert('Gateway unreachable'); }
}

function connectSSE() {
  const es = new EventSource('/events');
  document.getElementById('hdr-status').textContent = 'connected';

  es.addEventListener('snapshot', e => {
    const d = JSON.parse(e.data);
    agentMap = {};
    (d.agents || []).forEach(a => agentMap[a.name || a.agent] = a);
    renderAgents();
    taskMap = {};
    (d.tasks || []).forEach(t => taskMap[t.id] = t);
    renderTasks();
    fetchHealth();
    pushEvent('agent_event', `snapshot: ${Object.keys(agentMap).length} agents, ${Object.keys(taskMap).length} tasks`);
  });

  es.addEventListener('agent_event', e => {
    const d = JSON.parse(e.data);
    if (d.event === 'status_update' || d.event === 'task_started' || d.event === 'task_done') {
      // Refresh agent states
      fetch('/agents').then(r => r.json()).then(data => {
        agentMap = {};
        (data.agents || []).forEach(a => agentMap[a.name || a.agent] = a);
        renderAgents();
      }).catch(()=>{});
    }
    pushEvent('agent_event', `${d.agent} · ${d.event} ${d.detail || ''}`);
  });

  es.addEventListener('task_created', e => {
    const d = JSON.parse(e.data);
    taskMap[d.id] = Object.assign(d, {status:'pending'});
    renderTasks();
    fetchHealth();
    pushEvent('task_created', `${d.assigned_to}: ${d.title}`);
  });

  es.addEventListener('task_done', e => {
    const d = JSON.parse(e.data);
    if (taskMap[d.id]) taskMap[d.id].status = 'done';
    renderTasks();
    fetchHealth();
    pushEvent('task_done', `${d.agent}: ${d.result ? d.result.slice(0,80)+'…' : '(no result)'}`);
  });

  es.addEventListener('task_chained', e => {
    const d = JSON.parse(e.data);
    pushEvent('task_chained', `${d.from_agent} → ${d.to_agent}  new=${d.new_task}`);
    fetchTasks();
    fetchHealth();
  });

  es.addEventListener('broadcast', e => {
    const d = JSON.parse(e.data);
    pushEvent('broadcast', d.message);
  });

  es.onerror = () => {
    document.getElementById('hdr-status').textContent = 'reconnecting…';
    es.close();
    setTimeout(connectSSE, 3000);
  };
}

// Clock
setInterval(() => {
  // header time is updated from health poll
}, 1000);

// Periodic health poll (supplements SSE)
setInterval(fetchHealth, 10000);

// Init
connectSSE();
fetchTasks();
fetchHealth();
</script>
</body>
</html>"""


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
    sys.stderr.write(f"[gateway] v1.2 listening on {BIND}:{PORT}  ui=http://{BIND}:{PORT}/\n")
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

#──────────────────────────────────────────────────────────────────────────────
# Provider discovery
#──────────────────────────────────────────────────────────────────────────────
cmd_providers() {
  echo -e "\n  ${AMBER}${BOLD}◆ BR GATEWAY${NC}  ${DIM}Provider Discovery${NC}\n"
  local ollama_url="${BLACKROAD_OLLAMA_URL:-http://localhost:11434}"
  local gw_url="http://${GATEWAY_BIND}:${GATEWAY_PORT}"

  # Check Ollama
  if curl -sf --max-time 2 "${ollama_url}/api/tags" &>/dev/null; then
    local models=$(curl -sf "${ollama_url}/api/tags" | python3 -c "
import json,sys
d=json.load(sys.stdin)
names=[m['name'] for m in d.get('models',[])]
print(', '.join(names[:8]) if names else '(no models pulled)')
" 2>/dev/null || echo "unknown")
    echo -e "  ${GREEN}●${NC} ${BOLD}Ollama${NC}           ${DIM}${ollama_url}${NC}"
    echo -e "  ${DIM}  Models: ${models}${NC}"
  else
    echo -e "  ${RED}○${NC} ${BOLD}Ollama${NC}           ${DIM}${ollama_url} — offline${NC}"
    echo -e "  ${DIM}  Run: ollama serve${NC}"
  fi

  # Check local gateway
  if [[ -f "$PID_FILE" ]] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
    echo -e "  ${GREEN}●${NC} ${BOLD}BR Gateway${NC}       ${DIM}${gw_url}${NC}"
  else
    echo -e "  ${RED}○${NC} ${BOLD}BR Gateway${NC}       ${DIM}${gw_url} — not running${NC}"
    echo -e "  ${DIM}  Run: br gateway start${NC}"
  fi

  # Check env-based providers (only show existence, never keys)
  for var in BLACKROAD_OPENAI_API_KEY BLACKROAD_ANTHROPIC_API_KEY; do
    if [[ -n "${(P)var}" ]]; then
      local name="${var/BLACKROAD_/}"; name="${name/_API_KEY/}"
      echo -e "  ${GREEN}●${NC} ${BOLD}${name}${NC}           ${DIM}(key set via env — routed through gateway)${NC}"
    fi
  done

  echo ""
}

#──────────────────────────────────────────────────────────────────────────────
# Route a prompt to Ollama / gateway
#──────────────────────────────────────────────────────────────────────────────
cmd_route() {
  local model="${2:-llama3.2}"
  local prompt="${@:3}"
  if [[ -z "$prompt" ]]; then
    echo -e "${RED}✗ Usage: br gateway route <model> <prompt>${NC}"; return 1
  fi
  local ollama_url="${BLACKROAD_OLLAMA_URL:-http://localhost:11434}"
  local gw_url="http://${GATEWAY_BIND}:${GATEWAY_PORT}"

  echo -e "\n  ${AMBER}${BOLD}◆ BR GATEWAY${NC}  ${DIM}Routing →${NC} ${BOLD}${model}${NC}\n"

  # Try Ollama directly first
  if curl -sf --max-time 2 "${ollama_url}/api/tags" &>/dev/null; then
    echo -e "  ${DIM}Provider: Ollama (local)${NC}\n"
    curl -sf -X POST "${ollama_url}/api/generate" \
      -H "Content-Type: application/json" \
      -d "$(python3 -c "import json; print(json.dumps({'model':'${model}','prompt':'${prompt}','stream':False}))")" \
    | python3 -c "
import json,sys
d=json.load(sys.stdin)
resp=d.get('response','')
# word-wrap at 72 chars
words=resp.split()
line=''; lines=[]
for w in words:
    if len(line)+len(w)+1>72:
        lines.append(line); line=w
    else:
        line=(line+' '+w).strip()
if line: lines.append(line)
print('\n'.join('  '+l for l in lines))
print()
" 2>/dev/null || echo -e "  ${RED}✗ Ollama response parse error${NC}"
    return
  fi

  # Try local gateway as fallback
  if [[ -f "$PID_FILE" ]] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
    echo -e "  ${DIM}Provider: BR Gateway (localhost:${GATEWAY_PORT})${NC}\n"
    local r=$(curl -sf -X POST "${gw_url}/route" \
      -H "Content-Type: application/json" \
      -d "$(python3 -c "import json; print(json.dumps({'model':'${model}','prompt':'${prompt}'}))")" 2>/dev/null)
    if [[ -n "$r" ]]; then
      echo "$r" | python3 -m json.tool 2>/dev/null || echo "$r"
      return
    fi
  fi

  echo -e "  ${RED}✗ No providers available${NC}"
  echo -e "  ${DIM}  Start Ollama:  ollama serve${NC}"
  echo -e "  ${DIM}  Start gateway: br gateway start${NC}\n"
}

#──────────────────────────────────────────────────────────────────────────────
# Interactive chat via Ollama / gateway
#──────────────────────────────────────────────────────────────────────────────
cmd_chat() {
  local model="${2:-llama3.2}"
  local ollama_url="${BLACKROAD_OLLAMA_URL:-http://localhost:11434}"
  local history=()

  # Check provider
  if ! curl -sf --max-time 2 "${ollama_url}/api/tags" &>/dev/null; then
    echo -e "${RED}✗ Ollama not running — start with: ollama serve${NC}"; return 1
  fi

  clear
  echo -e "\n  ${AMBER}${BOLD}◆ BR GATEWAY CHAT${NC}  ${DIM}model: ${model} · type${NC} ${BOLD}/quit${NC} ${DIM}to exit${NC}\n"

  while true; do
    printf "  ${AMBER}you${NC} › "
    read -r user_input
    [[ -z "$user_input" ]] && continue
    [[ "$user_input" == "/quit" || "$user_input" == "quit" ]] && break
    [[ "$user_input" == "/model "* ]] && { model="${user_input#/model }"; echo -e "  ${DIM}→ switched to ${model}${NC}"; continue; }
    [[ "$user_input" == "/clear" ]] && { history=(); clear; continue; }

    history+=("$(python3 -c "import json; print(json.dumps({'role':'user','content':'${user_input//\'/}'}))")")

    local payload=$(python3 -c "
import json
model='${model}'
messages=$(echo "${history[@]}" | python3 -c "import json,sys; lines=sys.stdin.read().strip().split('\n'); print(json.dumps([json.loads(l) for l in lines if l.strip()]))" 2>/dev/null || echo "[]")
print(json.dumps({'model':model,'messages':messages,'stream':False}))
" 2>/dev/null)

    local resp=$(curl -sf -X POST "${ollama_url}/api/chat" \
      -H "Content-Type: application/json" \
      -d "${payload}" 2>/dev/null)

    local reply=$(echo "$resp" | python3 -c "
import json,sys
d=json.load(sys.stdin)
print(d.get('message',{}).get('content',''))
" 2>/dev/null)

    if [[ -n "$reply" ]]; then
      echo -e "\n  ${VIOLET}${model}${NC} › ${reply}\n"
      history+=("$(python3 -c "import json; print(json.dumps({'role':'assistant','content':$(echo "$reply" | python3 -c "import json,sys; print(json.dumps(sys.stdin.read().strip()))")}))")")
    else
      echo -e "  ${RED}✗ No response — check model name${NC}\n"
    fi
  done
  echo -e "\n  ${DIM}◆ Chat ended${NC}\n"
}

show_help() {
  echo -e ""
  echo -e "  ${AMBER}${BOLD}◆ BR GATEWAY${NC}  ${DIM}Tokenless AI routing. One gateway, every provider.${NC}"
  echo -e "  ${DIM}Your rules. Your secrets. Zero tokens in agent code.${NC}"
  echo -e "  ${DIM}──────────────────────────────────────────────${NC}"
  echo -e "  ${BOLD}USAGE${NC}  br ${DIM}<command> [args]${NC}"
  echo -e ""
  echo -e "  ${BOLD}COMMANDS${NC}"
  echo -e "  ${AMBER}  start                         ${NC} Start the BlackRoad gateway server"
  echo -e "  ${AMBER}  stop                          ${NC} Stop the gateway"
  echo -e "  ${AMBER}  status                        ${NC} Gateway health and route status"
  echo -e "  ${AMBER}  providers                     ${NC} Discover available AI providers"
  echo -e "  ${AMBER}  route <model> <prompt>        ${NC} Route a prompt (Ollama → gateway fallback)"
  echo -e "  ${AMBER}  chat [model]                  ${NC} Interactive chat via Ollama/gateway"
  echo -e "  ${AMBER}  routes                        ${NC} List registered agent routes"
  echo -e "  ${AMBER}  logs                          ${NC} Tail gateway request logs"
  echo -e "  ${AMBER}  config                        ${NC} Show/edit gateway configuration"
  echo -e "  ${AMBER}  test                          ${NC} Test a route end-to-end"
  echo -e ""
  echo -e "  ${BOLD}EXAMPLES${NC}"
  echo -e "  ${DIM}  br gateway providers${NC}"
  echo -e "  ${DIM}  br gateway route llama3.2 \"What is 2+2?\"${NC}"
  echo -e "  ${DIM}  br gateway chat qwen2.5:7b${NC}"
  echo -e "  ${DIM}  br gateway start${NC}"
  echo -e "  ${DIM}  br gateway status${NC}"
  echo -e ""
}

case "${1:-status}" in
    start)       cmd_start ;;
    stop)        cmd_stop ;;
    restart)     cmd_stop; sleep 0.3; cmd_start ;;
    status)      cmd_status ;;
    providers)   cmd_providers ;;
    route)       cmd_route "$@" ;;
    chat)        cmd_chat "$@" ;;
    logs)        shift; cmd_logs "$@" ;;
    stream)      cmd_stream ;;
    test)        cmd_test ;;
    help|-h)     show_help ;;
    *)           show_help ;;
esac
