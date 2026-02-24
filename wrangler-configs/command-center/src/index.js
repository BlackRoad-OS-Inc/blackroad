// BlackRoad Command Center Worker v2 — Master Orchestration Hub
// Real-time status, routing, and coordination for all BlackRoad services

const SERVICES = {
  agents: { url: "https://agents-api.blackroad.workers.dev", name: "Agents API", desc: "30K agent fleet" },
  tools:  { url: "https://tools-api.blackroad.workers.dev",  name: "Tools API",  desc: "162 br tools" },
  core:   { url: "https://blackroad-os-core.blackroad.workers.dev", name: "OS Core", desc: "Identity hub" },
  api:    { url: "https://api.blackroad.io",   name: "Pi API",    desc: "Primary Pi fleet" },
  ai:     { url: "https://ai.blackroad.io",    name: "AI Hub",    desc: "Ollama + LLMs" },
  docs:   { url: "https://docs.blackroad.io",  name: "Docs",      desc: "Documentation" },
};

const DOMAINS = {
  "blackroad.network":  "Core OS network",
  "blackroad.systems":  "Systems infrastructure",
  "blackroad.ai":       "AI platform",
  "blackroad.io":       "Main site",
  "lucidia.earth":      "Earth metaverse",
  "aliceqi.com":        "Alice interface",
};

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
  "Content-Type": "application/json",
};

async function checkService(name, svc) {
  const start = Date.now();
  try {
    const r = await fetch(svc.url + "/health", { signal: AbortSignal.timeout(4000) });
    return { name, ...svc, status: r.ok ? "operational" : "degraded", latency_ms: Date.now() - start, code: r.status };
  } catch (e) {
    return { name, ...svc, status: "offline", latency_ms: Date.now() - start, error: e.message };
  }
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const path = url.pathname;

    if (request.method === "OPTIONS") return new Response(null, { headers: CORS });

    // Root — OS overview with live data
    if (path === "/" || path === "/status") {
      const serviceChecks = await Promise.allSettled(
        Object.entries(SERVICES).map(([k, v]) => checkService(k, v))
      );
      const services = serviceChecks.map(r => r.value || r.reason);
      const operational = services.filter(s => s.status === "operational").length;

      return Response.json({
        name: "BlackRoad Command Center",
        tagline: "Your AI. Your Hardware. Your Rules.",
        version: "2.0.0",
        system: {
          status: operational >= 3 ? "operational" : operational >= 1 ? "degraded" : "offline",
          services_up: operational,
          services_total: services.length,
          agents: 30000,
          domains: Object.keys(DOMAINS).length,
          tools: 162,
          runners: 7,
        },
        services,
        domains: DOMAINS,
        fleet: {
          primary: { host: "192.168.4.64", name: "blackroad-pi", role: "PRIMARY" },
          secondary: { host: "192.168.4.38", name: "aria64", role: "SECONDARY" },
          cloud: { host: "159.65.43.12", name: "droplet", role: "FAILOVER" },
        },
        timestamp: new Date().toISOString(),
      }, { headers: CORS });
    }

    // /health — quick health check
    if (path === "/health") {
      return Response.json({ status: "ok", service: "command-center", ts: Date.now() }, { headers: CORS });
    }

    // /dispatch — route command to appropriate service
    if (path === "/dispatch" && request.method === "POST") {
      const { command, target, payload } = await request.json().catch(() => ({}));
      if (!command) return Response.json({ error: "command required" }, { status: 400, headers: CORS });
      
      const svc = SERVICES[target] || SERVICES.api;
      try {
        const resp = await fetch(`${svc.url}/${command}`, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(payload || {}),
          signal: AbortSignal.timeout(15000),
        });
        const data = await resp.json().catch(() => ({}));
        return Response.json({ dispatched: command, target, response: data }, { headers: CORS });
      } catch (e) {
        return Response.json({ error: "Dispatch failed", detail: e.message }, { status: 502, headers: CORS });
      }
    }

    // /dashboard — HTML dashboard
    if (path === "/dashboard") {
      return new Response(`<!DOCTYPE html>
<html lang="en"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>BlackRoad Command Center</title>
<style>
*{margin:0;padding:0;box-sizing:border-box}
body{background:#000;color:#fff;font-family:-apple-system,BlinkMacSystemFont,'SF Pro Display',sans-serif;padding:2rem}
h1{font-size:2.5rem;background:linear-gradient(135deg,#F5A623,#FF1D6C,#9C27B0,#2979FF);-webkit-background-clip:text;-webkit-text-fill-color:transparent;margin-bottom:.5rem}
.status{color:#F5A623;margin-bottom:2rem}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(200px,1fr));gap:1rem}
.card{background:#111;border:1px solid #222;border-radius:12px;padding:1.5rem}
.card h3{color:#FF1D6C;margin-bottom:.5rem}.card p{color:#666;font-size:.85rem}
.online{color:#4ade80}.offline{color:#f87171}.degraded{color:#fbbf24}
#data{color:#888;font-size:.8rem;margin-top:2rem;white-space:pre}
</style></head><body>
<h1>BlackRoad Command Center</h1>
<p class="status">🟢 Loading system status...</p>
<div class="grid" id="grid"></div>
<pre id="data">Fetching live data...</pre>
<script>
async function load() {
  const r = await fetch('/');
  const d = await r.json();
  document.querySelector('.status').textContent = '🟢 ' + d.system.services_up + '/' + d.system.services_total + ' services operational • ' + d.system.agents.toLocaleString() + ' agents • ' + d.system.tools + ' tools';
  const grid = document.getElementById('grid');
  d.services.forEach(s => {
    const cls = s.status === 'operational' ? 'online' : s.status === 'degraded' ? 'degraded' : 'offline';
    const dot = s.status === 'operational' ? '🟢' : s.status === 'degraded' ? '🟡' : '🔴';
    grid.innerHTML += '<div class="card"><h3>' + dot + ' ' + s.name + '</h3><p>' + s.desc + '</p><p class="' + cls + '">' + s.status + (s.latency_ms ? ' (' + s.latency_ms + 'ms)' : '') + '</p></div>';
  });
  document.getElementById('data').textContent = JSON.stringify(d.fleet, null, 2);
}
load();
</script></body></html>`, { headers: { "Content-Type": "text/html;charset=UTF-8" } });
    }

    return Response.json({ error: "Not found", available: ["/", "/health", "/dispatch", "/dashboard"] }, { status: 404, headers: CORS });
  }
};
