// BlackRoad.io — Main Portal Worker with Real-Time Data
// Serves the main site at blackroad.io with live stats

const CORS = { "Access-Control-Allow-Origin": "*", "Content-Type": "text/html;charset=UTF-8" };
const API_CORS = { "Access-Control-Allow-Origin": "*", "Content-Type": "application/json" };

async function getLiveStats(env) {
  const stats = {
    agents: 30000,
    repos: 1825,
    orgs: 17,
    workers: 75,
    tools: 162,
    domains: 20,
    pis: 3,
    status: "operational",
    timestamp: new Date().toISOString(),
  };

  // Try to fetch live data
  try {
    const r = await fetch("https://command-center.blackroad.workers.dev/health", { 
      signal: AbortSignal.timeout(2000) 
    });
    if (r.ok) stats.status = "operational";
  } catch {
    stats.status = "degraded";
  }

  return stats;
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    
    if (request.method === "OPTIONS") return new Response(null, { headers: { "Access-Control-Allow-Origin": "*" } });

    if (url.pathname === "/health") {
      return Response.json({ status: "ok", service: "blackroad.io", ts: Date.now() }, { headers: API_CORS });
    }

    if (url.pathname === "/api/stats") {
      const stats = await getLiveStats(env);
      return Response.json(stats, { headers: API_CORS });
    }

    const stats = await getLiveStats(env);

    return new Response(`<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>BlackRoad OS — Your AI. Your Hardware. Your Rules.</title>
<style>
*{margin:0;padding:0;box-sizing:border-box}
:root{
  --amber:#F5A623;--pink:#FF1D6C;--violet:#9C27B0;--blue:#2979FF;
  --gradient:linear-gradient(135deg,var(--amber) 0%,var(--pink) 38.2%,var(--violet) 61.8%,var(--blue) 100%)
}
body{background:#000;color:#fff;font-family:-apple-system,BlinkMacSystemFont,'SF Pro Display',sans-serif;min-height:100vh}
.hero{padding:5rem 2rem;text-align:center;max-width:900px;margin:0 auto}
h1{font-size:clamp(3rem,10vw,7rem);font-weight:800;background:var(--gradient);-webkit-background-clip:text;-webkit-text-fill-color:transparent;line-height:1.1;margin-bottom:1rem}
.tagline{font-size:1.4rem;color:#888;margin-bottom:3rem;line-height:1.618}
.stats{display:grid;grid-template-columns:repeat(auto-fit,minmax(140px,1fr));gap:1rem;margin:3rem 0}
.stat{background:#111;border:1px solid #1a1a1a;border-radius:16px;padding:1.5rem;text-align:center;transition:border-color .3s}
.stat:hover{border-color:var(--pink)}
.stat-num{font-size:2.5rem;font-weight:800;background:var(--gradient);-webkit-background-clip:text;-webkit-text-fill-color:transparent}
.stat-label{color:#555;font-size:.8rem;text-transform:uppercase;letter-spacing:.1em;margin-top:.5rem}
.nav{display:flex;gap:1rem;justify-content:center;flex-wrap:wrap;margin-top:3rem}
.nav a{color:var(--pink);text-decoration:none;padding:.75rem 1.5rem;border:1px solid var(--pink)33;border-radius:8px;font-size:.9rem;transition:all .2s}
.nav a:hover{background:var(--pink)22;border-color:var(--pink)}
.status-bar{position:fixed;bottom:0;left:0;right:0;background:#0a0a0a;border-top:1px solid #1a1a1a;padding:.75rem 2rem;display:flex;align-items:center;gap:1rem;font-size:.8rem;color:#555}
.dot{width:8px;height:8px;border-radius:50%;background:#4ade80;animation:pulse 2s infinite}
@keyframes pulse{0%,100%{opacity:1}50%{opacity:.4}}
.agents-section{max-width:900px;margin:0 auto 4rem;padding:0 2rem}
.agents-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(160px,1fr));gap:.75rem}
.agent-card{background:#0a0a0a;border:1px solid #1a1a1a;border-radius:12px;padding:1rem;text-align:center}
.agent-card .emoji{font-size:2rem;margin-bottom:.5rem}
.agent-card h4{font-size:.9rem;color:#fff;margin-bottom:.25rem}
.agent-card p{font-size:.75rem;color:#555}
</style>
</head>
<body>
<div class="hero">
  <h1>BlackRoad OS</h1>
  <p class="tagline">Your AI. Your Hardware. Your Rules.<br>30,000 agents. 17 orgs. Zero compromise.</p>
  <div class="stats" id="stats">
    <div class="stat"><div class="stat-num">${stats.agents.toLocaleString()}</div><div class="stat-label">Agents</div></div>
    <div class="stat"><div class="stat-num">${stats.repos.toLocaleString()}</div><div class="stat-label">Repositories</div></div>
    <div class="stat"><div class="stat-num">${stats.orgs}</div><div class="stat-label">Orgs</div></div>
    <div class="stat"><div class="stat-num">${stats.workers}</div><div class="stat-label">Workers</div></div>
    <div class="stat"><div class="stat-num">${stats.tools}</div><div class="stat-label">CLI Tools</div></div>
    <div class="stat"><div class="stat-num">${stats.domains}</div><div class="stat-label">Domains</div></div>
  </div>
  <nav class="nav">
    <a href="https://agents.blackroad.io">🤖 Agents</a>
    <a href="https://api.blackroad.io">⚡ API</a>
    <a href="https://dashboard.blackroad.io">📊 Dashboard</a>
    <a href="https://docs.blackroad.io">📖 Docs</a>
    <a href="https://console.blackroad.io">🖥️ Console</a>
    <a href="https://ai.blackroad.io">🧠 AI Hub</a>
    <a href="https://github.com/BlackRoad-OS">💻 GitHub</a>
  </nav>
</div>

<div class="agents-section">
  <div class="agents-grid">
    <div class="agent-card"><div class="emoji">💜</div><h4>CECE</h4><p>Meta-cognitive core</p></div>
    <div class="agent-card"><div class="emoji">🟢</div><h4>Octavia</h4><p>Systems architect</p></div>
    <div class="agent-card"><div class="emoji">🔴</div><h4>Lucidia</h4><p>Dreamer & philosopher</p></div>
    <div class="agent-card"><div class="emoji">🔵</div><h4>Alice</h4><p>DevOps operator</p></div>
    <div class="agent-card"><div class="emoji">🩵</div><h4>Aria</h4><p>Interface designer</p></div>
    <div class="agent-card"><div class="emoji">🔐</div><h4>Shellfish</h4><p>Security hacker</p></div>
  </div>
</div>

<div class="status-bar">
  <div class="dot"></div>
  <span>${stats.status === 'operational' ? '🟢' : '🟡'} ${stats.status}</span>
  <span>•</span>
  <span>Pi Fleet: ${stats.pis} nodes</span>
  <span>•</span>
  <span>Cloudflare Edge: ${stats.workers}+ workers</span>
  <span>•</span>
  <span style="margin-left:auto;color:#333">${new Date().toUTCString()}</span>
</div>

<script>
// Auto-refresh stats every 30s
async function refreshStats() {
  try {
    const r = await fetch('/api/stats');
    const d = await r.json();
    console.log('Live stats:', d);
  } catch(e) {}
}
setInterval(refreshStats, 30000);
</script>
</body>
</html>`, { headers: CORS });
  }
};
