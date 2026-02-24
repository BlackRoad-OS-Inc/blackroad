// status.blackroad.io — System Status Page Worker
// BlackRoad OS, Inc. © 2025 — All Rights Reserved

const MONITORED_SERVICES = [
  { name: 'BlackRoad.io',          url: 'https://blackroad.io',                    category: 'Frontend' },
  { name: 'Agents API',            url: 'https://agents.blackroad.io',             category: 'Agents' },
  { name: 'API Reference',         url: 'https://api.blackroad.io',                category: 'API' },
  { name: 'Dashboard',             url: 'https://dashboard.blackroad.io',          category: 'Frontend' },
  { name: 'Documentation',         url: 'https://docs.blackroad.io',               category: 'Docs' },
  { name: 'Console',               url: 'https://console.blackroad.io',            category: 'Admin' },
  { name: 'AI Platform',           url: 'https://ai.blackroad.io',                 category: 'AI' },
  { name: 'Analytics',             url: 'https://analytics.blackroad.io',          category: 'Analytics' },
  { name: 'BlackRoad.ai',          url: 'https://blackroad.ai',                    category: 'Frontend' },
  { name: 'GitHub API',            url: 'https://api.github.com/orgs/BlackRoad-OS-Inc', category: 'External' },
  { name: 'Cloudflare Workers',    url: 'https://blackroad-live-hub.amundsonalexa.workers.dev/health', category: 'Infrastructure' },
];

async function checkService(svc) {
  const start = Date.now();
  try {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 5000);
    const r = await fetch(svc.url, {
      method: 'HEAD',
      headers: { 'User-Agent': 'BlackRoad-Status/2.0' },
      signal: controller.signal,
      cf: { cacheTtl: 0 },
    });
    clearTimeout(timeout);
    const latency = Date.now() - start;
    return {
      ...svc,
      status: r.ok || r.status < 500 ? 'operational' : 'degraded',
      statusCode: r.status,
      latency,
    };
  } catch (e) {
    return { ...svc, status: e.name === 'AbortError' ? 'timeout' : 'down', statusCode: 0, latency: Date.now() - start };
  }
}

const STATUS_CONFIG = {
  operational: { color: '#4ade80', bg: '#0f2010', icon: '●', label: 'Operational' },
  degraded:    { color: '#fbbf24', bg: '#1a1000', icon: '●', label: 'Degraded' },
  down:        { color: '#f87171', bg: '#1a0505', icon: '●', label: 'Down' },
  timeout:     { color: '#f87171', bg: '#1a0505', icon: '◌', label: 'Timeout' },
};

export default {
  async fetch(request, env, ctx) {
    const now = new Date().toUTCString();

    // Check all services in parallel
    const results = await Promise.all(MONITORED_SERVICES.map(checkService));

    const operational = results.filter(r => r.status === 'operational').length;
    const total = results.length;
    const allOk = operational === total;
    const majorOutage = operational < total * 0.5;
    const overallStatus = allOk ? 'All Systems Operational' : majorOutage ? 'Major Outage' : 'Partial Outage';
    const overallColor = allOk ? '#4ade80' : majorOutage ? '#f87171' : '#fbbf24';
    const uptimePct = ((operational / total) * 100).toFixed(1);

    const categories = [...new Set(results.map(r => r.category))];

    const servicesByCategory = categories.map(cat => {
      const catServices = results.filter(r => r.category === cat);
      const rows = catServices.map(s => {
        const cfg = STATUS_CONFIG[s.status] || STATUS_CONFIG.down;
        return `<div class="svc-row">
          <span class="svc-indicator" style="color:${cfg.color}">${cfg.icon}</span>
          <span class="svc-name">${s.name}</span>
          <span class="svc-latency">${s.latency < 9999 ? s.latency + 'ms' : '—'}</span>
          <span class="svc-status" style="background:${cfg.bg};color:${cfg.color}">${cfg.label}</span>
        </div>`;
      }).join('');
      return `<div class="category-group">
        <div class="cat-title">${cat}</div>
        ${rows}
      </div>`;
    }).join('');

    const html = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
  <title>System Status — BlackRoad OS</title>
  <meta http-equiv="refresh" content="60">
  <style>
    *{margin:0;padding:0;box-sizing:border-box}
    :root{--hot-pink:#FF1D6C;--electric-blue:#2979FF;--amber:#F5A623;--violet:#9C27B0;--gradient:linear-gradient(135deg,#F5A623 0%,#FF1D6C 38.2%,#9C27B0 61.8%,#2979FF 100%)}
    body{font-family:-apple-system,BlinkMacSystemFont,'SF Pro Display',sans-serif;background:#000;color:#fff;min-height:100vh}
    nav{display:flex;align-items:center;gap:1.5rem;padding:1rem 2rem;border-bottom:1px solid #111;background:#000;position:sticky;top:0;z-index:100;flex-wrap:wrap}
    nav .logo{font-weight:800;background:var(--gradient);-webkit-background-clip:text;-webkit-text-fill-color:transparent}
    nav a{color:#666;text-decoration:none;font-size:.82rem}nav a:hover{color:#fff}
    .hero{padding:3.5rem 2rem 2rem;text-align:center}
    .overall-badge{display:inline-flex;align-items:center;gap:.6rem;padding:.75rem 2rem;border-radius:30px;font-size:1.1rem;font-weight:700;border:1px solid ${overallColor}44;color:${overallColor};background:${overallColor}0f;margin-bottom:1rem}
    .overall-badge::before{content:'';width:10px;height:10px;background:${overallColor};border-radius:50%;animation:pulse 2s infinite}
    @keyframes pulse{0%,100%{opacity:1}50%{opacity:.3}}
    .last-check{color:#444;font-size:.82rem;margin-top:.5rem}
    .kpis{display:flex;justify-content:center;gap:3rem;padding:1.5rem;background:#0a0a0a;border-top:1px solid #111;border-bottom:1px solid #111;margin-bottom:2.5rem;flex-wrap:wrap}
    .kpi{text-align:center}.kpi .v{font-size:1.8rem;font-weight:700;color:var(--hot-pink)}.kpi .l{font-size:.72rem;color:#555;text-transform:uppercase;letter-spacing:.08em}
    .main{max-width:800px;margin:0 auto;padding:0 2rem 4rem}
    .category-group{margin-bottom:2rem}
    .cat-title{font-size:.72rem;text-transform:uppercase;letter-spacing:.12em;color:#555;margin-bottom:.75rem;padding-bottom:.5rem;border-bottom:1px solid #111}
    .svc-row{display:flex;align-items:center;gap:1rem;padding:.75rem 1rem;background:#0a0a0a;border:1px solid #111;border-radius:8px;margin-bottom:.4rem}
    .svc-row:hover{border-color:#222}
    .svc-indicator{font-size:1rem;width:16px;flex-shrink:0}
    .svc-name{flex:1;font-size:.92rem;color:#ccc}
    .svc-latency{font-size:.8rem;color:#444;width:60px;text-align:right}
    .svc-status{padding:.2rem .6rem;border-radius:20px;font-size:.72rem;font-weight:600;text-transform:uppercase;letter-spacing:.04em;white-space:nowrap}
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
  <a href="https://console.blackroad.io">Console</a>
  <a href="https://ai.blackroad.io">AI</a>
</nav>
<div class="hero">
  <div class="overall-badge">${overallStatus}</div>
  <div class="last-check">Last checked: ${now}</div>
</div>
<div class="kpis">
  <div class="kpi"><div class="v">${uptimePct}%</div><div class="l">Uptime</div></div>
  <div class="kpi"><div class="v">${operational}/${total}</div><div class="l">Services Up</div></div>
  <div class="kpi"><div class="v">${results.filter(r => r.status === 'operational' && r.latency < 500).length}</div><div class="l">Fast (&lt;500ms)</div></div>
  <div class="kpi"><div class="v">${Math.round(results.filter(r => r.latency).reduce((s, r) => s + r.latency, 0) / results.length)}ms</div><div class="l">Avg Latency</div></div>
</div>
<div class="main">
  ${servicesByCategory}
</div>
<div class="footer">BlackRoad OS, Inc. © ${new Date().getFullYear()} — Auto-refreshes every 60s — <a href="https://dashboard.blackroad.io" style="color:#2979FF">Dashboard</a></div>
</body>
</html>`;

    return new Response(html, {
      headers: {
        'Content-Type': 'text/html;charset=UTF-8',
        'Cache-Control': 'no-store',
        'X-BlackRoad-Worker': 'status-blackroadio',
        'X-BlackRoad-Version': '2.0.0',
      },
    });
  },
};
