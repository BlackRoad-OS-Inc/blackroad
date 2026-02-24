// console.blackroad.io — Admin Console Worker
// BlackRoad OS, Inc. © 2025 — All Rights Reserved

const GH_ORG = 'BlackRoad-OS-Inc';
const AGENTS_API = 'https://blackroad-os-api.amundsonalexa.workers.dev';

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

const SERVICES = [
  { name: 'API Gateway',     url: AGENTS_API + '/health',                          key: 'api' },
  { name: 'GitHub',          url: 'https://api.github.com/orgs/' + GH_ORG,         key: 'github' },
  { name: 'Cloudflare',      url: 'https://blackroad.io',                           key: 'cf' },
  { name: 'Agents',          url: AGENTS_API + '/agents',                           key: 'agents' },
];

async function checkServices() {
  const results = await Promise.allSettled(SERVICES.map(async (svc) => {
    const start = Date.now();
    try {
      const r = await fetch(svc.url, {
        headers: { 'User-Agent': 'BlackRoad-OS/2.0' },
        cf: { cacheTtl: 30 },
      });
      return { ...svc, status: r.ok ? 'operational' : 'degraded', latency: Date.now() - start };
    } catch (_) {
      return { ...svc, status: 'down', latency: Date.now() - start };
    }
  }));
  return results.map(r => r.value || r.reason);
}

export default {
  async fetch(request, env, ctx) {
    const now = new Date().toUTCString();
    const [services, deployments, agents] = await Promise.all([
      checkServices(),
      fetchJSON(`https://api.github.com/repos/${GH_ORG}/blackroad/actions/runs?per_page=8`, 60),
      fetchJSON(`${AGENTS_API}/agents`, 30),
    ]);

    const runs = deployments?.workflow_runs || [];
    const allOk = services.every(s => s.status === 'operational');
    const overallStatus = allOk ? 'All Systems Operational' : 'Degraded Performance';
    const overallColor = allOk ? '#4ade80' : '#fbbf24';

    const serviceRows = services.map(s => {
      const c = s.status === 'operational' ? '#4ade80' : s.status === 'degraded' ? '#fbbf24' : '#f87171';
      return `<div class="svc-row">
        <span class="svc-dot" style="background:${c}"></span>
        <span class="svc-name">${s.name}</span>
        <span class="svc-status" style="color:${c}">${s.status}</span>
        <span class="svc-latency">${s.latency}ms</span>
      </div>`;
    }).join('');

    const deployRows = runs.map(r => {
      const c = r.conclusion === 'success' ? '#4ade80' : r.conclusion === 'failure' ? '#f87171' : '#fbbf24';
      const icon = r.conclusion === 'success' ? '✓' : r.conclusion === 'failure' ? '✗' : '○';
      return `<div class="deploy-row">
        <span class="deploy-icon" style="color:${c}">${icon}</span>
        <div class="deploy-info">
          <div class="deploy-name">${r.name}</div>
          <div class="deploy-meta">${r.head_branch} · ${new Date(r.created_at).toLocaleString()}</div>
        </div>
        <span class="deploy-status" style="color:${c}">${r.conclusion || r.status}</span>
      </div>`;
    }).join('') || '<div style="color:#555;padding:1rem">No recent deployments</div>';

    const agentList = (agents?.agents || []).slice(0, 6).map(a => `
      <div class="agent-row">
        <span class="agent-dot" style="background:${a.status === 'online' ? '#4ade80' : '#f87171'}"></span>
        <span class="agent-name">${a.name || '—'}</span>
        <span class="agent-tasks">${a.tasks_today || '—'} tasks</span>
      </div>`).join('');

    const html = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
  <title>Console — BlackRoad OS</title>
  <meta http-equiv="refresh" content="30">
  <style>
    *{margin:0;padding:0;box-sizing:border-box}
    :root{--hot-pink:#FF1D6C;--electric-blue:#2979FF;--amber:#F5A623;--violet:#9C27B0;--gradient:linear-gradient(135deg,#F5A623 0%,#FF1D6C 38.2%,#9C27B0 61.8%,#2979FF 100%)}
    body{font-family:-apple-system,BlinkMacSystemFont,'SF Pro Display',sans-serif;background:#000;color:#fff;min-height:100vh}
    nav{display:flex;align-items:center;gap:1.5rem;padding:1rem 2rem;border-bottom:1px solid #111;background:#000;position:sticky;top:0;z-index:100;flex-wrap:wrap}
    nav .logo{font-weight:800;background:var(--gradient);-webkit-background-clip:text;-webkit-text-fill-color:transparent}
    nav a{color:#666;text-decoration:none;font-size:.82rem}nav a:hover{color:#fff}
    .hero{padding:2.5rem 2rem 1.5rem;text-align:center}
    .hero h1{font-size:clamp(1.8rem,4vw,2.8rem);font-weight:800;background:var(--gradient);-webkit-background-clip:text;-webkit-text-fill-color:transparent;margin-bottom:.5rem}
    .overall-status{display:inline-flex;align-items:center;gap:.5rem;padding:.4rem 1rem;border-radius:20px;font-size:.9rem;font-weight:600;border:1px solid ${overallColor}44;color:${overallColor};background:${overallColor}11;margin-top:.5rem}
    .overall-status::before{content:'';width:8px;height:8px;background:${overallColor};border-radius:50%;animation:pulse 2s infinite}
    @keyframes pulse{0%,100%{opacity:1}50%{opacity:.3}}
    .main{display:grid;grid-template-columns:1fr 1fr 1fr;gap:1.5rem;padding:1.5rem 2rem 4rem;max-width:1400px;margin:0 auto}
    @media(max-width:1024px){.main{grid-template-columns:1fr 1fr}}
    @media(max-width:640px){.main{grid-template-columns:1fr}}
    .panel{background:#0a0a0a;border:1px solid #1a1a1a;border-radius:12px;padding:1.25rem;height:fit-content}
    .panel-title{font-size:.9rem;font-weight:700;text-transform:uppercase;letter-spacing:.08em;color:#888;margin-bottom:1rem;display:flex;align-items:center;gap:.5rem}
    .svc-row{display:flex;align-items:center;gap:.75rem;padding:.6rem 0;border-bottom:1px solid #111;font-size:.88rem}
    .svc-row:last-child{border-bottom:none}
    .svc-dot{width:8px;height:8px;border-radius:50%;flex-shrink:0}
    .svc-name{flex:1;color:#ccc}
    .svc-status{font-size:.78rem;font-weight:600;text-transform:uppercase}
    .svc-latency{font-size:.75rem;color:#555;margin-left:.5rem}
    .deploy-row{display:flex;align-items:center;gap:.75rem;padding:.6rem 0;border-bottom:1px solid #111;font-size:.85rem}
    .deploy-row:last-child{border-bottom:none}
    .deploy-icon{font-weight:700;width:16px;flex-shrink:0}
    .deploy-info{flex:1}.deploy-name{color:#ccc;font-weight:500}.deploy-meta{font-size:.75rem;color:#555;margin-top:.15rem}
    .deploy-status{font-size:.75rem;font-weight:600;text-transform:uppercase}
    .agent-row{display:flex;align-items:center;gap:.75rem;padding:.6rem 0;border-bottom:1px solid #111;font-size:.88rem}
    .agent-row:last-child{border-bottom:none}
    .agent-dot{width:8px;height:8px;border-radius:50%;flex-shrink:0}
    .agent-name{flex:1;color:#ccc;font-weight:500}
    .agent-tasks{font-size:.78rem;color:#555}
    .span-2{grid-column:span 2}
    @media(max-width:1024px){.span-2{grid-column:span 1}}
    .footer{text-align:center;padding:2rem;color:#333;font-size:.8rem;border-top:1px solid #111}
  </style>
</head>
<body>
<nav>
  <span class="logo">◆ BlackRoad OS</span>
  <a href="https://blackroad.io">Home</a>
  <a href="https://agents.blackroad.io">Agents</a>
  <a href="https://dashboard.blackroad.io">Dashboard</a>
  <a href="https://api.blackroad.io">API</a>
  <a href="https://docs.blackroad.io">Docs</a>
  <a href="https://status.blackroad.io">Status</a>
</nav>
<div class="hero">
  <h1>Admin Console</h1>
  <div class="overall-status">${overallStatus}</div>
</div>
<div class="main">
  <div class="panel">
    <div class="panel-title">🔌 Service Health</div>
    ${serviceRows}
  </div>
  <div class="panel span-2">
    <div class="panel-title">🚀 Recent Deployments</div>
    ${deployRows}
  </div>
  <div class="panel">
    <div class="panel-title">🤖 Agent Status</div>
    ${agentList || '<div style="color:#555">Loading agents...</div>'}
  </div>
  <div class="panel">
    <div class="panel-title">📊 Quick Stats</div>
    <div style="display:grid;grid-template-columns:1fr 1fr;gap:1rem">
      <div style="text-align:center;padding:1rem;background:#050505;border-radius:8px;border:1px solid #111">
        <div style="font-size:1.8rem;font-weight:700;color:#FF1D6C">${agents?.online || 6}</div>
        <div style="font-size:.72rem;color:#555;text-transform:uppercase;letter-spacing:.08em">Agents Online</div>
      </div>
      <div style="text-align:center;padding:1rem;background:#050505;border-radius:8px;border:1px solid #111">
        <div style="font-size:1.8rem;font-weight:700;color:#2979FF">${runs.filter(r => r.conclusion === 'success').length}</div>
        <div style="font-size:.72rem;color:#555;text-transform:uppercase;letter-spacing:.08em">CI Passing</div>
      </div>
      <div style="text-align:center;padding:1rem;background:#050505;border-radius:8px;border:1px solid #111">
        <div style="font-size:1.8rem;font-weight:700;color:#F5A623">${services.filter(s => s.status === 'operational').length}/${services.length}</div>
        <div style="font-size:.72rem;color:#555;text-transform:uppercase;letter-spacing:.08em">Services Up</div>
      </div>
      <div style="text-align:center;padding:1rem;background:#050505;border-radius:8px;border:1px solid #111">
        <div style="font-size:1.8rem;font-weight:700;color:#9C27B0">30K</div>
        <div style="font-size:.72rem;color:#555;text-transform:uppercase;letter-spacing:.08em">Agent Capacity</div>
      </div>
    </div>
  </div>
</div>
<div class="footer">BlackRoad OS, Inc. © ${new Date().getFullYear()} — Updated ${now} — Auto-refreshes every 30s</div>
</body>
</html>`;

    return new Response(html, {
      headers: {
        'Content-Type': 'text/html;charset=UTF-8',
        'Cache-Control': 'public, max-age=30',
        'X-BlackRoad-Worker': 'console-blackroadio',
        'X-BlackRoad-Version': '2.0.0',
      },
    });
  },
};
