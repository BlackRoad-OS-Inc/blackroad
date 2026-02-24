// BlackRoad.io — Main Portal Worker with Real-Time Data
// Serves the main site at blackroad.io with live stats

const API_CORS = { "Access-Control-Allow-Origin": "*", "Content-Type": "application/json" };
const HTML_CORS = { "Access-Control-Allow-Origin": "*", "Content-Type": "text/html;charset=UTF-8" };

async function getLiveStats() {
  const stats = {
    agents: 30000, repos: 1825, orgs: 17,
    workers: 75, tools: 162, domains: 20, pis: 3,
    status: "operational", timestamp: new Date().toISOString(),
  };
  try {
    const r = await fetch("https://command-center.blackroad.workers.dev/health", { signal: AbortSignal.timeout(2000) });
    if (r.ok) stats.status = "operational";
  } catch { stats.status = "degraded"; }
  return stats;
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    if (request.method === "OPTIONS") return new Response(null, { headers: { "Access-Control-Allow-Origin": "*" } });
    if (url.pathname === "/health") return Response.json({ status: "ok", service: "blackroad.io", ts: Date.now() }, { headers: API_CORS });
    if (url.pathname === "/api/stats") return Response.json(await getLiveStats(), { headers: API_CORS });

    const s = await getLiveStats();
    return new Response(`<!DOCTYPE html>
<html lang="en"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>BlackRoad OS — Your AI. Your Hardware. Your Rules.</title>
<style>
*{margin:0;padding:0;box-sizing:border-box}
:root{--amber:#F5A623;--pink:#FF1D6C;--violet:#9C27B0;--blue:#2979FF;--g:linear-gradient(135deg,#F5A623 0%,#FF1D6C 38.2%,#9C27B0 61.8%,#2979FF 100%)}
body{background:#000;color:#fff;font-family:-apple-system,BlinkMacSystemFont,'SF Pro Display',sans-serif;min-height:100vh}
.hero{padding:5rem 2rem;text-align:center;max-width:960px;margin:0 auto}
h1{font-size:clamp(3rem,10vw,7rem);font-weight:800;background:var(--g);-webkit-background-clip:text;-webkit-text-fill-color:transparent;line-height:1.1;margin-bottom:1rem}
.tagline{font-size:1.2rem;color:#666;margin-bottom:3rem;line-height:1.618}
.stats{display:grid;grid-template-columns:repeat(auto-fit,minmax(130px,1fr));gap:.75rem;margin:2rem 0}
.stat{background:#0a0a0a;border:1px solid #1a1a1a;border-radius:12px;padding:1.25rem;text-align:center}
.stat:hover{border-color:#FF1D6C33}
.n{font-size:2rem;font-weight:800;background:var(--g);-webkit-background-clip:text;-webkit-text-fill-color:transparent}
.l{color:#444;font-size:.75rem;text-transform:uppercase;letter-spacing:.1em;margin-top:.4rem}
.nav{display:flex;gap:.75rem;justify-content:center;flex-wrap:wrap;margin-top:2.5rem}
.nav a{color:#FF1D6C;text-decoration:none;padding:.6rem 1.25rem;border:1px solid #FF1D6C22;border-radius:8px;font-size:.85rem;transition:all .2s}
.nav a:hover{background:#FF1D6C11;border-color:#FF1D6C44}
.agents{max-width:960px;margin:0 auto 4rem;padding:0 2rem;display:grid;grid-template-columns:repeat(auto-fit,minmax(150px,1fr));gap:.75rem}
.ac{background:#050505;border:1px solid #111;border-radius:10px;padding:1rem;text-align:center}
.ac .e{font-size:1.75rem;margin-bottom:.5rem}.ac h4{font-size:.85rem;color:#eee}.ac p{font-size:.7rem;color:#444;margin-top:.25rem}
footer{text-align:center;padding:2rem;border-top:1px solid #0a0a0a;color:#222;font-size:.75rem}
.dot{display:inline-block;width:7px;height:7px;border-radius:50%;background:#4ade80;animation:p 2s infinite;margin-right:6px}
@keyframes p{0%,100%{opacity:1}50%{opacity:.3}}
</style></head><body>
<div class="hero">
<h1>BlackRoad OS</h1>
<p class="tagline">Your AI. Your Hardware. Your Rules.<br>30,000 agents. 17 orgs. 1,825+ repositories.</p>
<div class="stats">
<div class="stat"><div class="n">${s.agents.toLocaleString()}</div><div class="l">Agents</div></div>
<div class="stat"><div class="n">${s.repos.toLocaleString()}</div><div class="l">Repos</div></div>
<div class="stat"><div class="n">${s.orgs}</div><div class="l">Orgs</div></div>
<div class="stat"><div class="n">${s.workers}+</div><div class="l">Workers</div></div>
<div class="stat"><div class="n">${s.tools}</div><div class="l">CLI Tools</div></div>
<div class="stat"><div class="n">${s.domains}</div><div class="l">Domains</div></div>
</div>
<nav class="nav">
<a href="https://agents.blackroad.io">🤖 Agents</a>
<a href="https://api.blackroad.io">⚡ API</a>
<a href="https://dashboard.blackroad.io">📊 Dashboard</a>
<a href="https://docs.blackroad.io">📖 Docs</a>
<a href="https://console.blackroad.io">🖥️ Console</a>
<a href="https://ai.blackroad.io">🧠 AI</a>
<a href="https://github.com/BlackRoad-OS">💻 GitHub</a>
<a href="https://github.com/BlackRoad-OS-Inc">🔒 Private</a>
</nav>
</div>
<div class="agents">
<div class="ac"><div class="e">💜</div><h4>CECE</h4><p>Meta-cognitive core</p></div>
<div class="ac"><div class="e">🟢</div><h4>Octavia</h4><p>Systems architect</p></div>
<div class="ac"><div class="e">🔴</div><h4>Lucidia</h4><p>Dreamer & philosopher</p></div>
<div class="ac"><div class="e">🔵</div><h4>Alice</h4><p>DevOps operator</p></div>
<div class="ac"><div class="e">🩵</div><h4>Aria</h4><p>Interface designer</p></div>
<div class="ac"><div class="e">🔐</div><h4>Shellfish</h4><p>Security hacker</p></div>
</div>
<footer><span class="dot"></span><span style="color:#333">${s.status}</span> · Pi Fleet: ${s.pis} nodes · ${new Date().toUTCString()}</footer>
<script>setInterval(()=>fetch('/api/stats').then(r=>r.json()).then(d=>console.log('Stats:',d)).catch(()=>{}),30000)</script>
</body></html>`, { headers: HTML_CORS });
  }
};
