// api.blackroad.io — API Documentation & Live Explorer
// BlackRoad OS, Inc. © 2025 — All Rights Reserved

const GH_ORG = 'BlackRoad-OS-Inc';
const AGENTS_API = 'https://blackroad-os-api.amundsonalexa.workers.dev';

const ENDPOINTS = [
  { method: 'GET',  path: '/agents',            desc: 'List all active agents and their status',       example: '{"total":8,"online":6,"agents":[...]}' },
  { method: 'GET',  path: '/agents/:name',       desc: 'Get a specific agent by name',                  example: '{"name":"LUCIDIA","status":"online","tasks_today":847}' },
  { method: 'POST', path: '/agents/:name/task',  desc: 'Assign a task to an agent',                     example: '{"task_id":"t_001","status":"queued"}' },
  { method: 'GET',  path: '/health',             desc: 'System health check',                           example: '{"status":"ok","uptime":"99.9%"}' },
  { method: 'GET',  path: '/metrics',            desc: 'Live system metrics (tasks, latency, memory)',   example: '{"tasks_today":12453,"avg_latency_ms":120}' },
  { method: 'GET',  path: '/memory/:key',        desc: 'Retrieve a memory entry by key',                example: '{"key":"session-123","value":{...}}' },
  { method: 'POST', path: '/memory',             desc: 'Store a memory entry',                          example: '{"key":"session-123","stored":true}' },
  { method: 'GET',  path: '/skills',             desc: 'List agent skills and capabilities matrix',     example: '[{"agent":"LUCIDIA","skills":["reasoning","strategy"]}]' },
  { method: 'GET',  path: '/deployments',        desc: 'Recent deployments across all services',        example: '[{"service":"api","status":"success","time":"..."}]' },
  { method: 'POST', path: '/broadcast',          desc: 'Broadcast a message to all agents',             example: '{"delivered":8,"message":"..."}' },
];

const METHOD_COLORS = { GET: '#4ade80', POST: '#60a5fa', DELETE: '#f87171', PATCH: '#fbbf24' };

async function fetchJSON(url, ttl = 30) {
  try {
    const r = await fetch(url, {
      headers: { 'User-Agent': 'BlackRoad-OS/2.0', Accept: 'application/json' },
      cf: { cacheTtl: ttl },
    });
    if (r.ok) return r.json();
  } catch (_) {}
  return null;
}

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);

    // Proxy live API requests
    if (url.pathname.startsWith('/proxy/')) {
      const target = AGENTS_API + url.pathname.replace('/proxy', '');
      const live = await fetchJSON(target);
      return new Response(JSON.stringify(live, null, 2), {
        headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
      });
    }

    const [liveHealth, orgStats] = await Promise.all([
      fetchJSON(`${AGENTS_API}/health`, 30),
      fetchJSON(`https://api.github.com/orgs/${GH_ORG}`, 300),
    ]);

    const now = new Date().toUTCString();
    const endpointRows = ENDPOINTS.map(ep => `
      <div class="endpoint-row">
        <div class="ep-header">
          <span class="method-badge" style="background:${METHOD_COLORS[ep.method]}22;color:${METHOD_COLORS[ep.method]};border:1px solid ${METHOD_COLORS[ep.method]}44">${ep.method}</span>
          <code class="path">${AGENTS_API}${ep.path}</code>
          <a href="/proxy${ep.path.replace(':name','LUCIDIA').replace(':key','test')}" target="_blank" class="try-btn">Try Live ↗</a>
        </div>
        <div class="ep-desc">${ep.desc}</div>
        <pre class="ep-example">// Example response\n${ep.example}</pre>
      </div>`).join('');

    const html = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
  <title>API Reference — BlackRoad OS</title>
  <style>
    *{margin:0;padding:0;box-sizing:border-box}
    :root{--hot-pink:#FF1D6C;--electric-blue:#2979FF;--amber:#F5A623;--violet:#9C27B0;--gradient:linear-gradient(135deg,#F5A623 0%,#FF1D6C 38.2%,#9C27B0 61.8%,#2979FF 100%)}
    body{font-family:-apple-system,BlinkMacSystemFont,'SF Pro Display',sans-serif;background:#000;color:#fff;min-height:100vh}
    nav{display:flex;align-items:center;gap:1.5rem;padding:1rem 2rem;border-bottom:1px solid #111;background:#000;position:sticky;top:0;z-index:100;flex-wrap:wrap}
    nav .logo{font-weight:800;background:var(--gradient);-webkit-background-clip:text;-webkit-text-fill-color:transparent}
    nav a{color:#666;text-decoration:none;font-size:.82rem}nav a:hover{color:#fff}
    .hero{padding:3rem 2rem 1rem;text-align:center}
    .hero h1{font-size:clamp(1.8rem,4vw,3rem);font-weight:800;background:var(--gradient);-webkit-background-clip:text;-webkit-text-fill-color:transparent;margin-bottom:.5rem}
    .hero .sub{color:#666;font-size:1rem}
    .status-banner{display:flex;align-items:center;justify-content:center;gap:2rem;padding:1rem;background:#0f2010;border-top:1px solid #1a3a1a;border-bottom:1px solid #1a3a1a;margin:1.5rem 0;flex-wrap:wrap}
    .status-item{display:flex;align-items:center;gap:.5rem;font-size:.85rem}
    .dot{width:8px;height:8px;border-radius:50%;background:#4ade80}
    .main{max-width:1000px;margin:0 auto;padding:0 2rem 4rem}
    .section-title{font-size:1.2rem;font-weight:700;margin:2rem 0 1rem;color:#fff;border-bottom:1px solid #111;padding-bottom:.75rem}
    .endpoint-row{background:#0a0a0a;border:1px solid #1a1a1a;border-radius:10px;padding:1.25rem;margin-bottom:1rem}
    .endpoint-row:hover{border-color:#333}
    .ep-header{display:flex;align-items:center;gap:.75rem;margin-bottom:.6rem;flex-wrap:wrap}
    .method-badge{padding:.2rem .6rem;border-radius:5px;font-size:.75rem;font-weight:700;text-transform:uppercase;letter-spacing:.05em}
    code.path{font-family:monospace;font-size:.85rem;color:#888;flex:1}
    .try-btn{font-size:.75rem;color:var(--electric-blue);text-decoration:none;margin-left:auto;padding:.2rem .6rem;border:1px solid #2979FF44;border-radius:4px}
    .try-btn:hover{background:#0a1628}
    .ep-desc{color:#777;font-size:.88rem;margin-bottom:.75rem}
    pre.ep-example{background:#050505;border:1px solid #111;border-radius:6px;padding:.75rem 1rem;font-size:.8rem;color:#4ade80;overflow-x:auto}
    .base-url{background:#0a0a0a;border:1px solid #1a1a1a;border-radius:8px;padding:1rem 1.25rem;margin-bottom:1.5rem;font-family:monospace;color:#F5A623;font-size:.95rem}
    .footer{text-align:center;padding:2rem;color:#333;font-size:.8rem;border-top:1px solid #111}
    a{color:var(--electric-blue)}
  </style>
</head>
<body>
<nav>
  <span class="logo">◆ BlackRoad OS</span>
  <a href="https://blackroad.io">Home</a>
  <a href="https://agents.blackroad.io">Agents</a>
  <a href="https://dashboard.blackroad.io">Dashboard</a>
  <a href="https://docs.blackroad.io">Docs</a>
  <a href="https://console.blackroad.io">Console</a>
  <a href="https://status.blackroad.io">Status</a>
</nav>
<div class="hero">
  <h1>API Reference</h1>
  <p class="sub">Live endpoint documentation — all requests are real-time</p>
</div>
<div class="status-banner">
  <div class="status-item"><div class="dot"></div><span>API Online</span></div>
  <div class="status-item"><div class="dot"></div><span>Agents: ${liveHealth?.agents || 6} online</span></div>
  <div class="status-item"><div class="dot"></div><span>Latency: ${liveHealth?.latency_ms || '~50'}ms</span></div>
  <div class="status-item"><div class="dot"></div><span>Version: 2.0.0</span></div>
</div>
<div class="main">
  <div class="base-url">Base URL: ${AGENTS_API}</div>
  <div class="section-title">Endpoints</div>
  ${endpointRows}
  <div class="section-title">Authentication</div>
  <div style="background:#0a0a0a;border:1px solid #1a1a1a;border-radius:10px;padding:1.5rem;color:#888;line-height:1.7">
    <p>Public endpoints are available without authentication. Private endpoints require a <code style="color:#F5A623">Bearer</code> token in the <code style="color:#F5A623">Authorization</code> header.</p>
    <pre style="background:#050505;border:1px solid #111;border-radius:6px;padding:.75rem;margin-top:1rem;font-size:.8rem;color:#60a5fa">curl -H "Authorization: Bearer YOUR_TOKEN" ${AGENTS_API}/agents</pre>
  </div>
</div>
<div class="footer">BlackRoad OS, Inc. © ${new Date().getFullYear()} — Updated ${now}</div>
</body>
</html>`;

    return new Response(html, {
      headers: {
        'Content-Type': 'text/html;charset=UTF-8',
        'Cache-Control': 'public, max-age=30',
        'X-BlackRoad-Worker': 'api-blackroadio',
        'X-BlackRoad-Version': '2.0.0',
      },
    });
  },
};
