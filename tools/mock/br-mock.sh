#!/bin/zsh
# BR Mock — Local Mock HTTP API Server
# Spin up a mock REST API in seconds for testing

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BLUE='\033[0;34m'; NC='\033[0m'; BOLD='\033[1m'

MOCK_DB="$HOME/.blackroad/mock.db"
MOCK_PID_DIR="$HOME/.blackroad/mock-servers"

init_db() {
  mkdir -p "$(dirname "$MOCK_DB")" "$MOCK_PID_DIR"
  sqlite3 "$MOCK_DB" <<'SQL'
CREATE TABLE IF NOT EXISTS servers (
  id TEXT PRIMARY KEY,
  port INTEGER NOT NULL,
  description TEXT,
  pid INTEGER,
  status TEXT DEFAULT 'stopped',
  created_at INTEGER DEFAULT (strftime('%s','now'))
);
CREATE TABLE IF NOT EXISTS routes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  server_id TEXT NOT NULL,
  method TEXT DEFAULT 'GET',
  path TEXT NOT NULL,
  status_code INTEGER DEFAULT 200,
  response_body TEXT DEFAULT '{"ok":true}',
  response_headers TEXT DEFAULT '{}',
  delay_ms INTEGER DEFAULT 0,
  call_count INTEGER DEFAULT 0,
  created_at INTEGER DEFAULT (strftime('%s','now'))
);
CREATE TABLE IF NOT EXISTS request_log (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  server_id TEXT,
  method TEXT,
  path TEXT,
  status_code INTEGER,
  body TEXT,
  headers TEXT,
  logged_at INTEGER DEFAULT (strftime('%s','now'))
);
SQL
}

cmd_list() {
  echo -e "\n${BOLD}${CYAN}🔧 Mock Servers${NC}\n"
  python3 - "$MOCK_DB" "$MOCK_PID_DIR" <<'PY'
import sqlite3, sys, os
db, pid_dir = sys.argv[1], sys.argv[2]
conn = sqlite3.connect(db)
servers = conn.execute("SELECT id, port, description, pid, status FROM servers ORDER BY id").fetchall()
if not servers:
    print("  No servers. Create: br mock new <id> <port>")
else:
    for id_, port, desc, pid, status in servers:
        # Check if actually running
        alive = False
        pid_file = os.path.join(pid_dir, f"{id_}.pid")
        if os.path.exists(pid_file):
            with open(pid_file) as f:
                stored_pid = f.read().strip()
            try:
                os.kill(int(stored_pid), 0)
                alive = True
            except:
                pass
        
        st_icon = '\033[32m●\033[0m' if alive else '\033[90m○\033[0m'
        route_count = conn.execute("SELECT COUNT(*) FROM routes WHERE server_id=?", (id_,)).fetchone()[0]
        print(f"  {st_icon} \033[1m{id_:<16}\033[0m  :{port}  {route_count} routes  {desc or ''}")

conn.close()
print()
PY
}

cmd_new() {
  local sid="$1" port="${2:-3099}" desc="${3:-Mock API}"
  [[ -z "$sid" ]] && {
    echo -e "${CYAN}Usage: br mock new <id> [port] [description]${NC}"
    return 1
  }
  sqlite3 "$MOCK_DB" "INSERT OR REPLACE INTO servers (id, port, description) VALUES ('$sid',$port,'$desc');"
  echo -e "${GREEN}✓${NC} Server created: ${BOLD}$sid${NC} on port $port"
  echo -e "  Add routes: br mock route $sid GET /api/users '[{\"id\":1}]'"
  echo -e "  Start:      br mock start $sid"
}

cmd_route() {
  local sid="$1" method="${2:-GET}" path="$3" body="${4:-{\"ok\":true}}" status="${5:-200}"
  [[ -z "$sid" || -z "$path" ]] && {
    echo -e "${CYAN}Usage: br mock route <server> <METHOD> <path> <body> [status]${NC}"
    echo -e "Example: br mock route myapi GET /api/users '[{\"id\":1,\"name\":\"Alice\"}]' 200"
    return 1
  }
  sqlite3 "$MOCK_DB" "INSERT INTO routes (server_id, method, path, response_body, status_code) VALUES ('$sid','$method','$path','$(echo "$body" | sed "s/'/''/g")',$status);"
  echo -e "${GREEN}✓${NC} Route: ${BOLD}$method $path${NC} → $status"
}

cmd_routes() {
  local sid="$1"
  [[ -z "$sid" ]] && { echo -e "${RED}✗${NC} Usage: br mock routes <server>"; return 1; }
  echo -e "\n${BOLD}${CYAN}Routes: $sid${NC}\n"
  python3 - "$MOCK_DB" "$sid" <<'PY'
import sqlite3, sys
db, sid = sys.argv[1], sys.argv[2]
conn = sqlite3.connect(db)
rows = conn.execute("SELECT method, path, status_code, call_count, response_body FROM routes WHERE server_id=? ORDER BY path", (sid,)).fetchall()
for method, path, code, calls, body in rows:
    method_color = {'GET':'\033[32m','POST':'\033[34m','PUT':'\033[33m','DELETE':'\033[31m','PATCH':'\033[35m'}.get(method, '\033[0m')
    snippet = body[:60].replace('\n', ' ') if body else ''
    print(f"  {method_color}{method:<7}\033[0m  {path:<35}  {code}  \033[90m×{calls}  {snippet}\033[0m")
print()
conn.close()
PY
}

cmd_start() {
  local sid="$1"
  [[ -z "$sid" ]] && { echo -e "${RED}✗${NC} Usage: br mock start <server>"; return 1; }

  local port
  port=$(sqlite3 "$MOCK_DB" "SELECT port FROM servers WHERE id='$sid';")
  [[ -z "$port" ]] && { echo -e "${RED}✗${NC} Server not found: $sid"; return 1; }

  local pid_file="$MOCK_PID_DIR/$sid.pid"
  if [[ -f "$pid_file" ]]; then
    local existing_pid=$(cat "$pid_file")
    if kill -0 "$existing_pid" 2>/dev/null; then
      echo -e "${YELLOW}⚠${NC} Server $sid already running (PID $existing_pid) on port $port"
      return
    fi
  fi

  echo -e "${CYAN}▶ Starting mock server:${NC} ${BOLD}$sid${NC} on http://localhost:$port"

  # Export routes as JSON for the Python server
  local routes_json
  routes_json=$(python3 - "$MOCK_DB" "$sid" <<'PY'
import sqlite3, sys, json
db, sid = sys.argv[1], sys.argv[2]
conn = sqlite3.connect(db)
rows = conn.execute("SELECT method, path, status_code, response_body, response_headers, delay_ms FROM routes WHERE server_id=?", (sid,)).fetchall()
routes = []
for method, path, code, body, headers, delay in rows:
    try:
        body_parsed = json.loads(body)
    except:
        body_parsed = body
    try:
        headers_parsed = json.loads(headers) if headers else {}
    except:
        headers_parsed = {}
    routes.append({"method": method, "path": path, "status": code, "body": body_parsed, "headers": headers_parsed, "delay": delay or 0})
print(json.dumps(routes))
conn.close()
PY
)

  local server_script
  server_script=$(cat <<PYSERVER
import json, time, sys
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse

ROUTES = json.loads('''$routes_json''')
SERVER_ID = '$sid'
LOG_DB = '$MOCK_DB'

class MockHandler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        ts = time.strftime('[%H:%M:%S]')
        print(f"\033[36m{ts}\033[0m \033[1m{self.command}\033[0m {self.path} → ", end='', flush=True)

    def do_request(self):
        parsed = urlparse(self.path)
        for route in ROUTES:
            if route['method'] == self.command and (route['path'] == parsed.path or route['path'] == self.path):
                delay = route.get('delay', 0)
                if delay:
                    time.sleep(delay / 1000.0)
                
                body = json.dumps(route['body']).encode()
                headers = route.get('headers', {})
                
                self.send_response(route['status'])
                self.send_header('Content-Type', 'application/json')
                self.send_header('Access-Control-Allow-Origin', '*')
                for k, v in headers.items():
                    self.send_header(k, v)
                self.end_headers()
                self.wfile.write(body)
                print(f"\033[32m{route['status']}\033[0m  ({len(body)} bytes)")
                return
        
        self.send_response(404)
        self.send_header('Content-Type', 'application/json')
        self.end_headers()
        self.wfile.write(json.dumps({"error": "Not found", "path": self.path}).encode())
        print(f"\033[31m404\033[0m")

    def do_GET(self): self.do_request()
    def do_POST(self): self.do_request()
    def do_PUT(self): self.do_request()
    def do_DELETE(self): self.do_request()
    def do_PATCH(self): self.do_request()
    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET,POST,PUT,DELETE,PATCH,OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type,Authorization')
        self.end_headers()

server = HTTPServer(('0.0.0.0', $port), MockHandler)
print(f"\033[32m✓\033[0m Mock server '$sid' running on http://localhost:$port")
print(f"  Routes: {len(ROUTES)}  |  Press Ctrl+C to stop")
try:
    server.serve_forever()
except KeyboardInterrupt:
    print("\n\033[33m⚠\033[0m Server stopped")
PYSERVER
)

  # Start in background
  python3 -c "$server_script" &
  local srv_pid=$!
  echo "$srv_pid" > "$pid_file"
  sqlite3 "$MOCK_DB" "UPDATE servers SET pid=$srv_pid, status='running' WHERE id='$sid';"

  sleep 0.5
  if kill -0 "$srv_pid" 2>/dev/null; then
    echo -e "${GREEN}✓${NC} Running  (PID $srv_pid)"
    echo -e "  Test: curl http://localhost:$port/health"
    echo -e "  Logs: br mock logs $sid"
    echo -e "  Stop: br mock stop $sid"
  else
    echo -e "${RED}✗${NC} Server failed to start"
  fi
}

cmd_stop() {
  local sid="$1"
  [[ -z "$sid" ]] && { echo -e "${RED}✗${NC} Usage: br mock stop <server>"; return 1; }
  local pid_file="$MOCK_PID_DIR/$sid.pid"
  if [[ -f "$pid_file" ]]; then
    local pid=$(cat "$pid_file")
    if kill -0 "$pid" 2>/dev/null; then
      kill "$pid"
      rm -f "$pid_file"
      sqlite3 "$MOCK_DB" "UPDATE servers SET status='stopped', pid=NULL WHERE id='$sid';"
      echo -e "${GREEN}✓${NC} Stopped: $sid (PID $pid)"
    else
      echo -e "${YELLOW}⚠${NC} Process not found, cleaning up"
      rm -f "$pid_file"
    fi
  else
    echo -e "${YELLOW}⚠${NC} No PID file for $sid"
  fi
}

cmd_seed() {
  # Seed a complete mock REST API
  local sid="${1:-demo}" port="${2:-3099}"
  cmd_new "$sid" "$port" "Demo REST API"
  cmd_route "$sid" GET  /health '{"status":"ok","service":"mock"}' 200
  cmd_route "$sid" GET  /api/users '[{"id":1,"name":"Alice","email":"alice@example.com"},{"id":2,"name":"Bob","email":"bob@example.com"}]' 200
  cmd_route "$sid" GET  /api/users/1 '{"id":1,"name":"Alice","email":"alice@example.com","role":"admin"}' 200
  cmd_route "$sid" POST /api/users '{"id":3,"name":"New User","created":true}' 201
  cmd_route "$sid" GET  /api/products '[{"id":1,"name":"Widget","price":9.99},{"id":2,"name":"Gadget","price":29.99}]' 200
  cmd_route "$sid" GET  /api/error '{"error":"Something went wrong","code":"INTERNAL_ERROR"}' 500
  echo -e "\n${GREEN}✓${NC} Seeded demo API: $sid"
  echo -e "  Start: br mock start $sid"
}

cmd_logs() {
  local sid="$1"
  [[ -z "$sid" ]] && { echo -e "${RED}✗${NC} Usage: br mock logs <server>"; return 1; }
  local pid_file="$MOCK_PID_DIR/$sid.pid"
  if [[ -f "$pid_file" ]]; then
    local pid=$(cat "$pid_file")
    echo -e "${CYAN}Attaching to server logs (Ctrl+C to detach)...${NC}"
    # Can't easily attach - just tail the process's output
    echo -e "${YELLOW}Tip: Start the server in foreground for live logs${NC}"
  fi
  # Show from DB log
  echo -e "\n${BOLD}${CYAN}Recent Requests: $sid${NC}\n"
  sqlite3 "$MOCK_DB" "SELECT datetime(logged_at,'unixepoch'), method, path, status_code FROM request_log WHERE server_id='$sid' ORDER BY logged_at DESC LIMIT 20;"
}

cmd_delete() {
  local sid="$1"
  [[ -z "$sid" ]] && { echo -e "${RED}✗${NC} Usage: br mock delete <server>"; return 1; }
  cmd_stop "$sid" 2>/dev/null
  sqlite3 "$MOCK_DB" "DELETE FROM servers WHERE id='$sid'; DELETE FROM routes WHERE server_id='$sid';"
  echo -e "${GREEN}✓${NC} Deleted: $sid"
}

show_help() {
  echo -e "\n${BOLD}${CYAN}🔧 BR Mock — Local Mock API Server${NC}\n"
  echo -e "  ${CYAN}br mock list${NC}                          — list servers"
  echo -e "  ${CYAN}br mock new <id> [port] [desc]${NC}        — create server"
  echo -e "  ${CYAN}br mock route <id> METHOD /path <body>${NC} — add route"
  echo -e "  ${CYAN}br mock routes <id>${NC}                   — list routes"
  echo -e "  ${CYAN}br mock start <id>${NC}                    — start server"
  echo -e "  ${CYAN}br mock stop <id>${NC}                     — stop server"
  echo -e "  ${CYAN}br mock seed [id] [port]${NC}              — seed demo API"
  echo -e "  ${CYAN}br mock delete <id>${NC}                   — delete server"
  echo -e "\n  ${YELLOW}Quick start:${NC}"
  echo -e "    br mock seed myapi 8080"
  echo -e "    br mock start myapi"
  echo -e "    curl http://localhost:8080/api/users\n"
}

init_db
case "${1:-help}" in
  list|ls)          cmd_list ;;
  new|create)       cmd_new "$2" "$3" "$4" ;;
  route|add-route)  cmd_route "$2" "$3" "$4" "$5" "$6" ;;
  routes|endpoints) cmd_routes "$2" ;;
  start|up|serve)   cmd_start "$2" ;;
  stop|down|kill)   cmd_stop "$2" ;;
  seed|demo)        cmd_seed "$2" "$3" ;;
  logs|log)         cmd_logs "$2" ;;
  delete|rm)        cmd_delete "$2" ;;
  help|--help|-h)   show_help ;;
  *) show_help ;;
esac
