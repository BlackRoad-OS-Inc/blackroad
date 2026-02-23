#!/usr/bin/env zsh
# BR Mock Server — Instant JSON/REST API mock server

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; BLUE='\033[0;34m'; NC='\033[0m'
BOLD='\033[1m'
DB="$HOME/.blackroad/mock-server.db"
MOCK_DIR="$HOME/.blackroad/mocks"
REQUESTS_DIR="$HOME/.blackroad/mock-requests"
PID_FILE="$HOME/.blackroad/mock-server.pid"
PORT_FILE="$HOME/.blackroad/mock-server.port"
DEFAULT_PORT=3099

init_db() {
  mkdir -p "$MOCK_DIR" "$REQUESTS_DIR"
  sqlite3 "$DB" <<'SQL'
CREATE TABLE IF NOT EXISTS routes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  server_name TEXT DEFAULT 'default',
  method TEXT NOT NULL,
  path TEXT NOT NULL,
  status_code INTEGER DEFAULT 200,
  response_body TEXT DEFAULT '{"ok":true}',
  content_type TEXT DEFAULT 'application/json',
  delay_ms INTEGER DEFAULT 0,
  hit_count INTEGER DEFAULT 0,
  enabled INTEGER DEFAULT 1,
  created_at TEXT DEFAULT (datetime('now'))
);
CREATE TABLE IF NOT EXISTS requests (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  method TEXT NOT NULL,
  path TEXT NOT NULL,
  headers TEXT DEFAULT '',
  body TEXT DEFAULT '',
  ts TEXT DEFAULT (datetime('now'))
);
CREATE TABLE IF NOT EXISTS servers (
  name TEXT PRIMARY KEY,
  port INTEGER NOT NULL,
  status TEXT DEFAULT 'stopped',
  started_at TEXT DEFAULT NULL
);
SQL
  sqlite3 "$DB" <<'SQL'
INSERT OR IGNORE INTO servers (name, port) VALUES ('default', 3099);
INSERT OR IGNORE INTO routes (server_name, method, path, status_code, response_body) VALUES
  ('default', 'GET', '/health', 200, '{"status":"ok","service":"mock-server"}'),
  ('default', 'GET', '/users', 200, '[{"id":1,"name":"Alice","email":"alice@example.com"},{"id":2,"name":"Bob","email":"bob@example.com"}]'),
  ('default', 'GET', '/users/:id', 200, '{"id":1,"name":"Alice","email":"alice@example.com"}'),
  ('default', 'POST', '/users', 201, '{"id":3,"name":"New User","created":true}'),
  ('default', 'GET', '/todos', 200, '[{"id":1,"title":"Buy milk","done":false},{"id":2,"title":"Code review","done":true}]'),
  ('default', 'GET', '/error', 500, '{"error":"Internal Server Error","code":500}'),
  ('default', 'GET', '/slow', 200, '{"message":"This was slow","delay":"2s"}');
SQL
  sqlite3 "$DB" "UPDATE routes SET delay_ms=2000 WHERE path='/slow' AND delay_ms=0;" 2>/dev/null
}

cmd_start() {
  local name="${1:-default}" port=""
  port=$(sqlite3 "$DB" "SELECT port FROM servers WHERE name='$name';" 2>/dev/null)
  port="${port:-$DEFAULT_PORT}"
  [[ -n "$2" ]] && port="$2"

  if [[ -f "$PID_FILE" ]]; then
    local pid; pid=$(cat "$PID_FILE")
    if kill -0 "$pid" 2>/dev/null; then
      echo -e "${YELLOW}⚠ Mock server already running (PID $pid, port $(cat "$PORT_FILE"))${NC}"
      echo -e "  Stop with: ${CYAN}br mock stop${NC}"
      return
    fi
  fi

  echo ""
  echo -e "${GREEN}${BOLD}🚀 Starting mock server '$name' on :${port}${NC}"

  # Write Python server to temp file
  local tmppy; tmppy=$(mktemp /tmp/br-mock-XXXXX.py)
  cat > "$tmppy" << PYEOF
import sqlite3, json, time, os
from http.server import HTTPServer, BaseHTTPRequestHandler
from datetime import datetime

DB_PATH = "${DB}"
SERVER_NAME = "${name}"
REQUESTS_DIR = "${REQUESTS_DIR}"

def load_routes():
    db = sqlite3.connect(DB_PATH)
    rows = db.execute("SELECT method, path, status_code, response_body, content_type, delay_ms FROM routes WHERE server_name=? AND enabled=1", (SERVER_NAME,)).fetchall()
    db.close()
    return rows

def match_route(routes, method, path):
    for r in routes:
        rm, rp, status, body, ct, delay = r
        if rm.upper() != method.upper():
            continue
        if rp == path:
            return status, body, ct, delay, rp
        rparts = rp.split("/")
        pparts = path.split("/")
        if len(rparts) != len(pparts):
            continue
        match = all(rp.startswith(":") or rp == pp for rp, pp in zip(rparts, pparts))
        if match:
            return status, body, ct, delay, rp
    return None

class MockHandler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args): pass

    def do_request(self):
        routes = load_routes()
        content_len = int(self.headers.get("Content-Length", 0))
        req_body = self.rfile.read(content_len).decode() if content_len else ""
        result = match_route(routes, self.command, self.path)

        ts = datetime.utcnow().strftime("%Y%m%dT%H%M%S")
        safe_path = self.path.replace("/", "_").replace("?", "_")
        req_file = os.path.join(REQUESTS_DIR, f"{ts}-{self.command}-{safe_path}.json")
        with open(req_file, "w") as f:
            json.dump({"method": self.command, "path": self.path, "body": req_body, "ts": ts}, f)

        if result:
            status, resp_body, ct, delay, matched = result
            if delay: time.sleep(delay / 1000)
            db = sqlite3.connect(DB_PATH)
            db.execute("UPDATE routes SET hit_count=hit_count+1 WHERE server_name=? AND path=? AND method=?", (SERVER_NAME, matched, self.command))
            db.commit(); db.close()
        else:
            status, resp_body, ct = 404, json.dumps({"error": "Not found", "path": self.path}), "application/json"

        self.send_response(status)
        self.send_header("Content-Type", ct)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("X-Mock-Server", "br-mock/1.0")
        self.end_headers()
        self.wfile.write(resp_body.encode())
        color = "\\033[0;32m" if status < 400 else "\\033[0;31m"
        print(f"  {color}{self.command:6} {status}\\033[0m {self.path}")

    do_GET = do_POST = do_PUT = do_PATCH = do_DELETE = do_request

    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET,POST,PUT,PATCH,DELETE,OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type,Authorization")
        self.end_headers()

server = HTTPServer(("0.0.0.0", ${port}), MockHandler)
print(f"\\033[0;36m🎭 Mock server running on http://localhost:${port}\\033[0m")
server.serve_forever()
PYEOF

  python3 "$tmppy" &
  local pid=$!
  sleep 0.8
  if kill -0 "$pid" 2>/dev/null; then
    echo "$pid" > "$PID_FILE"
    echo "$port" > "$PORT_FILE"
    sqlite3 "$DB" "UPDATE servers SET status='running', started_at=datetime('now') WHERE name='$name';"
    rm -f "$tmppy"
    echo -e "  PID: $pid"
    echo -e "  ${GREEN}✓ Ready — http://localhost:${port}${NC}"
    echo ""
    echo -e "  ${CYAN}curl http://localhost:${port}/health${NC}"
    echo -e "  ${CYAN}curl http://localhost:${port}/users${NC}"
    echo -e "  ${YELLOW}br mock stop${NC} to shutdown"
    echo ""
  else
    echo -e "${RED}✗ Server failed to start${NC}"
    rm -f "$tmppy" "$PID_FILE"
  fi
}

cmd_stop() {
  [[ ! -f "$PID_FILE" ]] && { echo -e "${YELLOW}⚠ No mock server running${NC}"; return; }
  local pid; pid=$(cat "$PID_FILE")
  kill "$pid" 2>/dev/null && echo -e "${GREEN}✓ Mock server stopped (PID $pid)${NC}" || echo -e "${RED}✗ Failed (PID $pid)${NC}"
  rm -f "$PID_FILE" "$PORT_FILE"
  sqlite3 "$DB" "UPDATE servers SET status='stopped';"
}

cmd_status() {
  echo ""
  echo -e "${CYAN}${BOLD}🎭 Mock Server${NC}"
  echo ""
  if [[ -f "$PID_FILE" ]]; then
    local pid port; pid=$(cat "$PID_FILE"); port=$(cat "$PORT_FILE" 2>/dev/null || echo $DEFAULT_PORT)
    if kill -0 "$pid" 2>/dev/null; then
      echo -e "  ${GREEN}● RUNNING${NC}  PID=$pid  http://localhost:${port}"
    else
      echo -e "  ${RED}● DEAD${NC} (stale PID file)"; rm -f "$PID_FILE"
    fi
  else
    echo -e "  ${YELLOW}○ STOPPED${NC}"
  fi
  echo ""
  local hits; hits=$(sqlite3 "$DB" "SELECT SUM(hit_count) FROM routes;" 2>/dev/null || echo 0)
  echo -e "  Total hits: ${CYAN}${hits:-0}${NC}"
  echo ""
  echo -e "  ${BLUE}Routes:${NC}"
  sqlite3 -separator "|" "$DB" "SELECT method, path, status_code, hit_count, delay_ms FROM routes WHERE enabled=1 ORDER BY path;" | while IFS="|" read -r m p s h d; do
    local delay_str=""; [[ "$d" -gt 0 ]] && delay_str="  ${YELLOW}(${d}ms)${NC}"
    printf "  ${GREEN}%-7s${NC} %-28s ${CYAN}%s${NC}  hits=%-4s%b\n" "$m" "$p" "$s" "$h" "$delay_str"
  done
  echo ""
}

cmd_route_add() {
  local method="${1:-GET}" path="${2:-/test}" status="${3:-200}"
  local body="${4:-{\"ok\":true}}"
  sqlite3 "$DB" "INSERT INTO routes (server_name, method, path, status_code, response_body) VALUES ('default', upper('$method'), '$path', $status, '$body');"
  echo -e "${GREEN}✓ Route: $method $path → $status${NC}"
}

cmd_requests() {
  local limit="${1:-15}"
  echo ""
  echo -e "${CYAN}${BOLD}📋 Recent Requests${NC}"
  echo ""
  local count=0
  for f in $(ls -t "$REQUESTS_DIR"/*.json 2>/dev/null | head -"$limit"); do
    python3 -c "
import json
try:
    d = json.load(open('$f'))
    m = d.get('method','?')
    p = d.get('path','?')
    ts = d.get('ts','?')
    print(f'  \033[0;32m{m:6}\033[0m {p:35} {ts}')
except: pass
"
    count=$((count + 1))
  done
  [[ $count -eq 0 ]] && echo "  No requests yet. Start server and make some calls."
  echo ""
}

cmd_load() {
  local file="$1"
  [[ -z "$file" || ! -f "$file" ]] && { echo "Usage: br mock load <routes.json>"; exit 1; }
  python3 - "$file" "$DB" << 'PY'
import json, sqlite3, sys
file, db_path = sys.argv[1], sys.argv[2]
with open(file) as f:
    data = json.load(f)
db = sqlite3.connect(db_path)
routes = data.get("routes", data) if isinstance(data, dict) else data
count = 0
for route in (routes if isinstance(routes, list) else []):
    method = route.get("method", "GET").upper()
    path = route.get("path", "/")
    status = route.get("status", route.get("statusCode", 200))
    body = json.dumps(route.get("response", route.get("body", {"ok": True})))
    ct = route.get("contentType", "application/json")
    delay = route.get("delay", 0)
    db.execute("INSERT OR REPLACE INTO routes (server_name,method,path,status_code,response_body,content_type,delay_ms) VALUES ('default',?,?,?,?,?,?)", (method, path, status, body, ct, delay))
    count += 1
db.commit()
print(f"✓ {count} routes loaded")
PY
}

show_help() {
  echo ""
  echo -e "${CYAN}${BOLD}br mock${NC} — Instant REST API mock server"
  echo ""
  echo -e "  ${GREEN}br mock start [name] [port]${NC}    Start server (default port 3099)"
  echo -e "  ${GREEN}br mock stop${NC}                   Stop server"
  echo -e "  ${GREEN}br mock status${NC}                 Routes + hit counts"
  echo -e "  ${GREEN}br mock requests [n]${NC}           Recent incoming requests"
  echo -e "  ${GREEN}br mock route add <M> <path> <status> <json>${NC}"
  echo -e "  ${GREEN}br mock load <routes.json>${NC}     Load routes from file"
  echo ""
  echo -e "  Built-in: ${CYAN}/health  /users  /users/:id  /todos  /error  /slow${NC}"
  echo ""
}

init_db
case "${1:-status}" in
  start)          shift; cmd_start "$@" ;;
  stop)           cmd_stop ;;
  status|ls|list) cmd_status ;;
  requests|req)   shift; cmd_requests "$@" ;;
  route)
    shift
    case "${1:-list}" in
      add)  shift; cmd_route_add "$@" ;;
      list) cmd_status ;;
      *)    echo "Usage: br mock route <add|list>" ;;
    esac
    ;;
  load)           shift; cmd_load "$@" ;;
  help|-h)        show_help ;;
  *)              show_help ;;
esac
