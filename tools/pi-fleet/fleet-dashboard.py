#!/usr/bin/env python3
"""BlackRoad Ops API — alice node + Pi Fleet Dashboard"""
import json, os, glob, socket, urllib.request, subprocess
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse
from datetime import datetime

WORLDS_DIR = "/home/blackroad/.blackroad/worlds"
NODE_NAME = "alice"
NODE_IP = "192.168.4.49"

def get_world_count():
    if os.path.exists(WORLDS_DIR):
        return len(glob.glob(f"{WORLDS_DIR}/*.json"))
    return 0

def fetch_url(url, timeout=2):
    try:
        req = urllib.request.urlopen(url, timeout=timeout)
        return json.loads(req.read())
    except:
        return None

def get_alice_stats():
    try:
        import psutil
        return {
            "cpu": round(psutil.cpu_percent(interval=0.5), 1),
            "mem": round(psutil.virtual_memory().percent, 1),
            "disk": round(psutil.disk_usage('/').percent, 1),
            "uptime": int(datetime.now().timestamp() - psutil.boot_time())
        }
    except:
        return {"cpu": 0, "mem": 0, "disk": 0, "uptime": 0}

def get_fleet_data():
    nodes = {
        "alice":   {"ip": "192.168.4.49", "role": "Gateway + CI/CD", "emoji": "🔵", "color": "#2979FF"},
        "octavia": {"ip": "192.168.4.81", "role": "Model Server",     "emoji": "🟣", "color": "#9C27B0"},
        "aria":    {"ip": "192.168.4.82", "role": "Agent Services",   "emoji": "🟡", "color": "#F5A623"},
        "lucidia": {"ip": "192.168.4.38", "role": "AI Reasoning",     "emoji": "🔴", "color": "#FF1D6C"},
    }
    result = {}
    for name, info in nodes.items():
        d = {**info, "online": False, "services": [], "models": 0, "agents": 0}
        if name == "alice":
            stats = get_alice_stats()
            d.update({"online": True, **stats})
            d["services"] = [
                "cloudflared", "nginx", "github-runner",
                "qdrant(:6333)", "redis(:6379)", "postgres(:5432)"
            ]
        elif name == "octavia":
            models_data = fetch_url("http://192.168.4.81:8787/models")
            if models_data:
                d["online"] = True
                live = [m for m in models_data.get("models", []) if m.get("status") == "live"]
                d["models"] = len(live)
                d["services"] = ["model-server(:8787)", "ollama(:11434)"]
                d["model_names"] = [m["name"] for m in live[:5]]
        elif name == "aria":
            agents_data = fetch_url("http://192.168.4.82:4010/agents")
            if agents_data:
                d["online"] = True
                d["agents"] = len(agents_data.get("agents", []))
                d["services"] = ["agents-api(:4010)", "blackroad-api(:3001)"]
                d["agent_names"] = [a["name"] for a in agents_data.get("agents", [])[:5]]
        elif name == "lucidia":
            resp = fetch_url("http://192.168.4.38:8080/health")
            d["online"] = resp is not None
        result[name] = d
    return result

FLEET_HTML = '''<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>🖥️ BlackRoad Pi Fleet</title>
<style>
:root{--black:#000;--white:#fff;--amber:#F5A623;--pink:#FF1D6C;--blue:#2979FF;--violet:#9C27B0;--green:#00E676;--red:#FF1744;--bg:#050505;--card:#0e0e0e;--border:#1a1a1a;}
*{margin:0;padding:0;box-sizing:border-box;}
body{background:var(--bg);color:var(--white);font-family:-apple-system,BlinkMacSystemFont,\'SF Pro Display\',sans-serif;min-height:100vh;padding:28px;}
header{display:flex;align-items:center;gap:16px;margin-bottom:36px;padding-bottom:24px;border-bottom:1px solid var(--border);}
h1{font-size:26px;font-weight:800;background:linear-gradient(135deg,var(--amber),var(--pink),var(--violet),var(--blue));-webkit-background-clip:text;-webkit-text-fill-color:transparent;}
.subtitle{color:#555;font-size:13px;margin-top:4px;}
.live{display:flex;align-items:center;gap:6px;margin-left:auto;color:#555;font-size:12px;}
.dot{width:8px;height:8px;background:var(--green);border-radius:50%;animation:pulse 2s infinite;}
@keyframes pulse{0%,100%{opacity:1;transform:scale(1);}50%{opacity:.5;transform:scale(1.4);}}
.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(320px,1fr));gap:20px;margin-bottom:32px;}
.card{background:var(--card);border:1px solid var(--border);border-radius:16px;padding:24px;position:relative;overflow:hidden;transition:border-color .2s;}
.card:hover{border-color:#333;}
.card-accent{position:absolute;top:0;left:0;right:0;height:2px;}
.card-header{display:flex;align-items:flex-start;gap:14px;margin-bottom:20px;}
.emoji{font-size:32px;line-height:1;}
.node-name{font-size:18px;font-weight:700;letter-spacing:-0.3px;}
.role{color:#555;font-size:11px;margin-top:3px;text-transform:uppercase;letter-spacing:.5px;}
.ip{color:#333;font-size:11px;font-family:monospace;margin-top:4px;}
.badge{margin-left:auto;padding:5px 12px;border-radius:20px;font-size:11px;font-weight:600;letter-spacing:.3px;}
.badge.online{background:rgba(0,230,118,.12);color:var(--green);border:1px solid rgba(0,230,118,.2);}
.badge.offline{background:rgba(255,23,68,.12);color:var(--red);border:1px solid rgba(255,23,68,.2);}
.metrics{display:grid;grid-template-columns:repeat(3,1fr);gap:10px;margin-bottom:18px;}
.metric{background:#111;border-radius:10px;padding:12px;text-align:center;}
.metric-val{font-size:22px;font-weight:700;font-variant-numeric:tabular-nums;}
.metric-label{color:#444;font-size:10px;margin-top:3px;text-transform:uppercase;letter-spacing:.5px;}
.services{margin-top:14px;}
.services-title{color:#333;font-size:10px;text-transform:uppercase;letter-spacing:.5px;margin-bottom:8px;}
.service-tags{display:flex;flex-wrap:wrap;gap:6px;}
.tag{background:#111;border:1px solid #1e1e1e;border-radius:6px;padding:3px 8px;font-size:10px;color:#666;font-family:monospace;}
.models-list{margin-top:12px;}
.model-tag{background:rgba(41,121,255,.1);border:1px solid rgba(41,121,255,.2);border-radius:6px;padding:3px 8px;font-size:10px;color:var(--blue);font-family:monospace;}
.summary{background:var(--card);border:1px solid var(--border);border-radius:16px;padding:24px;display:flex;gap:40px;align-items:center;flex-wrap:wrap;}
.stat{text-align:center;}
.stat-val{font-size:36px;font-weight:800;}
.stat-label{color:#555;font-size:11px;text-transform:uppercase;letter-spacing:.5px;margin-top:4px;}
.ts{color:#333;font-size:11px;margin-left:auto;}
.offline-msg{color:#333;font-size:13px;padding:20px 0;text-align:center;}
.bar{height:4px;border-radius:2px;background:#1a1a1a;margin-top:6px;overflow:hidden;}
.bar-fill{height:100%;border-radius:2px;transition:width .5s;}
</style>
</head>
<body>
<header>
  <div>
    <h1>🖥️ BlackRoad Pi Fleet</h1>
    <div class="subtitle">Real-time cluster status across all nodes</div>
  </div>
  <div class="live"><div class="dot"></div> LIVE</div>
</header>
<div class="grid" id="grid">Loading fleet data...</div>
<div class="summary" id="summary"></div>
<div style="color:#333;font-size:11px;margin-top:16px;text-align:center" id="ts"></div>

<script>
async function load() {
  try {
    const r = await fetch('/api/fleet');
    const {data, timestamp} = await r.json();
    renderGrid(data);
    renderSummary(data, timestamp);
  } catch(e) {
    document.getElementById('grid').innerHTML = '<div style="color:#555;padding:40px">Failed to load fleet data</div>';
  }
}

function bar(val, color) {
  return `<div class="bar"><div class="bar-fill" style="width:${val}%;background:${color}"></div></div>`;
}

function renderGrid(data) {
  const nodes = ['alice','octavia','aria','lucidia'];
  const colors = {alice:'#2979FF',octavia:'#9C27B0',aria:'#F5A623',lucidia:'#FF1D6C'};
  const emojis = {alice:'🔵',octavia:'🟣',aria:'🟡',lucidia:'🔴'};
  
  document.getElementById('grid').innerHTML = nodes.map(n => {
    const d = data[n];
    const online = d.online;
    const c = colors[n];
    
    let metrics = '';
    if (online && n === 'alice') {
      metrics = `<div class="metrics">
        <div class="metric"><div class="metric-val" style="color:${d.cpu > 80 ? '#FF1744' : '#00E676'}">${d.cpu}%</div>${bar(d.cpu, d.cpu>80?'#FF1744':'#00E676')}<div class="metric-label">CPU</div></div>
        <div class="metric"><div class="metric-val" style="color:${d.mem > 80 ? '#FF1744' : '#2979FF'}">${d.mem}%</div>${bar(d.mem, d.mem>80?'#FF1744':'#2979FF')}<div class="metric-label">RAM</div></div>
        <div class="metric"><div class="metric-val" style="color:#F5A623">${d.disk}%</div>${bar(d.disk,'#F5A623')}<div class="metric-label">DISK</div></div>
      </div>`;
    } else if (online && n === 'octavia') {
      metrics = `<div class="metrics">
        <div class="metric"><div class="metric-val" style="color:${c}">${d.models}</div><div class="metric-label">Models</div></div>
        <div class="metric"><div class="metric-val" style="color:#00E676">LIVE</div><div class="metric-label">Status</div></div>
        <div class="metric"><div class="metric-val" style="color:#555">GPU</div><div class="metric-label">Hailo</div></div>
      </div>`;
    } else if (online && n === 'aria') {
      metrics = `<div class="metrics">
        <div class="metric"><div class="metric-val" style="color:${c}">${d.agents}</div><div class="metric-label">Agents</div></div>
        <div class="metric"><div class="metric-val" style="color:#00E676">LIVE</div><div class="metric-label">Status</div></div>
        <div class="metric"><div class="metric-val" style="color:#555">API</div><div class="metric-label">Mode</div></div>
      </div>`;
    } else if (!online) {
      metrics = `<div class="offline-msg">⚠️ Node offline — no connection</div>`;
    }
    
    const services = d.services?.length ? `
      <div class="services">
        <div class="services-title">Services</div>
        <div class="service-tags">${d.services.map(s=>`<span class="tag">${s}</span>`).join('')}</div>
      </div>` : '';
    
    const models = d.model_names?.length ? `
      <div class="models-list">
        <div class="services-title" style="margin-top:12px">Models</div>
        <div class="service-tags">${d.model_names.map(m=>`<span class="model-tag">${m}</span>`).join('')}</div>
      </div>` : '';

    return `<div class="card">
      <div class="card-accent" style="background:${c}"></div>
      <div class="card-header">
        <div class="emoji">${emojis[n]}</div>
        <div>
          <div class="node-name">${n.toUpperCase()}</div>
          <div class="role">${d.role}</div>
          <div class="ip">${d.ip}</div>
        </div>
        <span class="badge ${online?'online':'offline'}">${online?'● ONLINE':'○ OFFLINE'}</span>
      </div>
      ${metrics}${services}${models}
    </div>`;
  }).join('');
}

function renderSummary(data, ts) {
  const online = Object.values(data).filter(d=>d.online).length;
  const total = Object.keys(data).length;
  const models = data.octavia?.models || 0;
  const agents = data.aria?.agents || 0;
  document.getElementById('summary').innerHTML = `
    <div class="stat"><div class="stat-val" style="color:#00E676">${online}/${total}</div><div class="stat-label">Nodes Online</div></div>
    <div class="stat"><div class="stat-val" style="color:#2979FF">${models}</div><div class="stat-label">Live Models</div></div>
    <div class="stat"><div class="stat-val" style="color:#F5A623">${agents}</div><div class="stat-label">Active Agents</div></div>
    <div class="stat"><div class="stat-val" style="color:#9C27B0">${Math.round(online/total*100)}%</div><div class="stat-label">Fleet Health</div></div>
    <div class="ts">Last updated: ${new Date(ts).toLocaleTimeString()}</div>
  `;
  document.getElementById('ts').textContent = `Auto-refreshes every 10s • fleet.blackroad.io`;
}

load();
setInterval(load, 10000);
</script>
</body>
</html>'''

class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args): pass

    def send_html(self, html):
        body = html.encode()
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", len(body))
        self.end_headers()
        self.wfile.write(body)

    def send_json(self, data, status=200):
        body = json.dumps(data, indent=2).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Content-Length", len(body))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        path = urlparse(self.path).path
        if path in ["/", "/fleet"]:
            self.send_html(FLEET_HTML)
        elif path == "/api/fleet":
            self.send_json({"data": get_fleet_data(), "timestamp": datetime.utcnow().isoformat() + "Z"})
        elif path in ["/api/node", "/health", "/api/status"]:
            stats = get_alice_stats()
            self.send_json({"node": NODE_NAME, "status": "online", "ip": NODE_IP, "role": "secondary", "worlds_count": get_world_count(), "timestamp": datetime.utcnow().isoformat() + "Z", **stats})
        else:
            self.send_json({"error": "Not found"}, 404)

if __name__ == "__main__":
    print(f"BlackRoad Pi Fleet Dashboard running on :8012")
    HTTPServer(('0.0.0.0', 8012), Handler).serve_forever()
