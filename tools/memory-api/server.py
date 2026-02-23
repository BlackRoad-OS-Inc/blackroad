#!/usr/bin/env python3
# BlackRoad Memory API — stdlib only, port 8011
# Endpoints:
#   GET  /memory/recent   → last 10 journal entries (JSON array)
#   GET  /memory/context  → recent-actions.md contents (plain text)
#   POST /memory/log      → append entry to master-journal.jsonl

from http.server import HTTPServer, BaseHTTPRequestHandler
import json, os, datetime

JOURNAL = os.path.expanduser("~/blackroad/memory/journals/master-journal.jsonl")
CONTEXT = os.path.expanduser("~/blackroad/memory/context/recent-actions.md")
PORT    = 8011


def _ensure_dirs():
    for path in (JOURNAL, CONTEXT):
        os.makedirs(os.path.dirname(path), exist_ok=True)


class MemoryHandler(BaseHTTPRequestHandler):

    def log_message(self, fmt, *args):
        print(f"[memory-api] {self.address_string()} {fmt % args}")

    # ── helpers ──────────────────────────────────────────────────────────────

    def _send(self, code: int, body: str, content_type: str = "application/json"):
        encoded = body.encode()
        self.send_response(code)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(encoded)))
        self.end_headers()
        self.wfile.write(encoded)

    def _read_body(self) -> bytes:
        length = int(self.headers.get("Content-Length", 0))
        return self.rfile.read(length) if length else b""

    # ── routing ───────────────────────────────────────────────────────────────

    def do_GET(self):
        if self.path == "/memory/recent":
            self._get_recent()
        elif self.path == "/memory/context":
            self._get_context()
        elif self.path in ("/", "/health"):
            self._send(200, json.dumps({"status": "ok", "service": "memory-api", "port": PORT}))
        else:
            self._send(404, json.dumps({"error": "not found"}))

    def do_POST(self):
        if self.path == "/memory/log":
            self._post_log()
        else:
            self._send(404, json.dumps({"error": "not found"}))

    # ── handlers ──────────────────────────────────────────────────────────────

    def _get_recent(self):
        _ensure_dirs()
        entries = []
        if os.path.exists(JOURNAL):
            with open(JOURNAL) as f:
                lines = [l.strip() for l in f if l.strip()]
            for line in lines[-10:]:
                try:
                    entries.append(json.loads(line))
                except json.JSONDecodeError:
                    entries.append({"raw": line})
        self._send(200, json.dumps(entries, indent=2))

    def _get_context(self):
        _ensure_dirs()
        if os.path.exists(CONTEXT):
            with open(CONTEXT) as f:
                body = f.read()
            self._send(200, body, content_type="text/plain; charset=utf-8")
        else:
            self._send(200, "(no context file yet)", content_type="text/plain")

    def _post_log(self):
        _ensure_dirs()
        raw = self._read_body()
        try:
            payload = json.loads(raw) if raw else {}
        except json.JSONDecodeError:
            self._send(400, json.dumps({"error": "invalid JSON"}))
            return

        # Inject timestamp if missing
        if "ts" not in payload:
            payload["ts"] = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

        line = json.dumps(payload)
        with open(JOURNAL, "a") as f:
            f.write(line + "\n")

        self._send(201, json.dumps({"ok": True, "entry": payload}))


if __name__ == "__main__":
    _ensure_dirs()
    print(f"[memory-api] starting on http://0.0.0.0:{PORT}")
    print(f"  journal : {JOURNAL}")
    print(f"  context : {CONTEXT}")
    server = HTTPServer(("0.0.0.0", PORT), MemoryHandler)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n[memory-api] stopped")
