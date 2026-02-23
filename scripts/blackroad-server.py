#!/usr/bin/env python3
"""BlackRoad OS - Pi Fleet Web Server"""
import http.server, socketserver, os, json, socket

PORT = int(os.environ.get("PORT", 3000))
HOSTNAME = socket.gethostname()

HTML = b"""<!DOCTYPE html><html>
<head><title>BlackRoad OS</title>
<style>body{background:#000;color:#fff;font-family:sans-serif;display:flex;align-items:center;justify-content:center;min-height:100vh;margin:0}
.card{text-align:center;max-width:600px;padding:40px}
h1{background:linear-gradient(135deg,#F5A623,#FF1D6C,#9C27B0,#2979FF);-webkit-background-clip:text;-webkit-text-fill-color:transparent;font-size:3rem;margin:0}
p{color:#888;font-size:1.1rem;margin-top:1rem}
.badge{display:inline-block;background:#111;border:1px solid #333;padding:6px 16px;border-radius:20px;font-size:0.8rem;margin:4px;color:#aaa}
</style></head>
<body><div class="card"><h1>BlackRoad OS</h1><p>Pi Fleet Node &mdash; Self-Hosted via Cloudflare Tunnel</p>
<div><span class="badge">&#x1F7E2; Online</span><span class="badge">&#x1F512; Self-Hosted</span><span class="badge">&#x26A1; $0 Infra</span></div>
</div></body></html>"""

class H(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path=="/health":
            self.send_response(200); self.send_header("Content-Type","application/json"); self.end_headers()
            self.wfile.write(json.dumps({"status":"ok","host":HOSTNAME}).encode())
        else:
            self.send_response(200); self.send_header("Content-Type","text/html"); self.end_headers()
            self.wfile.write(HTML)
    def log_message(self,*a): pass

socketserver.TCPServer.allow_reuse_address = True
with socketserver.TCPServer(("",PORT),H) as s:
    print(f"listening:{PORT}")
    s.serve_forever()
