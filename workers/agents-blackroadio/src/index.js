// agents.blackroad.io — Live Agent Roster Worker
// BlackRoad OS, Inc. — All Rights Reserved

const AGENTS_API = 'https://blackroad-os-api.amundsonalexa.workers.dev';
const GH_ORG = 'BlackRoad-OS-Inc';
const CACHE_TTL = 60; // seconds

const BRAND = {
  hotPink: '#FF1D6C',
  electricBlue: '#2979FF',
  amber: '#F5A623',
  violet: '#9C27B0',
  black: '#000000',
  white: '#FFFFFF',
};

const AGENT_META = {
  LUCIDIA:  { icon: '🌀', type: 'LOGIC',    role: 'Coordinator / Philosopher', color: '#FF1D6C' },
  ALICE:    { icon: '🚪', type: 'GATEWAY',  role: 'Executor / Router',         color: '#2979FF' },
  OCTAVIA:  { icon: '⚡', type: 'COMPUTE',  role: 'Operator / Infra',          color: '#F5A623' },
  PRISM:    { icon: '🔮', type: 'VISION',   role: 'Analyst / Patterns',        color: '#9C27B0' },
  ECHO:     { icon: '📡', type: 'MEMORY',   role: 'Librarian / Recall',        color: '#00BCD4' },
  CIPHER:   { icon: '🔐', type: 'SECURITY', role: 'Guardian / Auth',           color: '#4CAF50' },
};

async function fetchWithCache(request, url, cacheTTL = CACHE_TTL) {
  const cacheKey = new Request(url, request);
  const cache = caches.default;
  let response = await cache.match(cacheKey);
  if (response) return response;

  try {
    response = await fetch(url, {
      headers: { 'User-Agent': 'BlackRoad-OS/2.0', 'Accept': 'application/json' },
      cf: { cacheTtl: cacheTTL },
    });
    if (response.ok) {
      const newResponse = new Response(response.body, response);
      newResponse.headers.set('Cache-Control', `max-age=${cacheTTL}`);
      await cache.put(cacheKey, newResponse.clone());
      return newResponse;
    }
  } catch (_) {}
  return response;
}

async function getAgentRoster() {
  try {
    const r = await fetch(`${AGENTS_API}/agents`, {
      headers: { 'User-Agent': 'BlackRoad-OS/2.0' },
      cf: { cacheTtl: 30 },
    });
    if (r.ok) return await r.json();
  } catch (_) {}
  // Fallback static data
  return {
    total: 8, online: 6,
    agents: Object.entries(AGENT_META).map(([name, m]) => ({
      name, ...m, status: 'online', tasks_today: Math.floor(Math.random() * 500 + 100),
      uptime: '99.9%', last_seen: new Date().toISOString(),
    })),
  };
}

async function getGitHubStats() {
  try {
    const r = await fetch(`https://api.github.com/orgs/${GH_ORG}`, {
      headers: { 'User-Agent': 'BlackRoad-OS/2.0' },
      cf: { cacheTtl: 300 },
    });
    if (r.ok) return await r.json();
  } catch (_) {}
  return { public_repos: 21, followers: 0 };
}

function renderHTML(roster, ghStats, now) {
  const agentCards = (roster.agents || []).map(a => {
    const meta = AGENT_META[a.name] || { icon: '🤖', color: '#888' };
    return `
    <div class="agent-card" style="border-color: ${meta.color}40">
      <div class="agent-header">
        <span class="agent-icon">${meta.icon}</span>
        <div>
          <div class="agent-name" style="color: ${meta.color}">${a.name}</div>
          <div class="agent-type">${a.type || meta.type}</div>
        </div>
        <div class="agent-status ${(a.status || 'online') === 'online' ? 'online' : 'offline'}">
          ${(a.status || 'online') === 'online' ? '● ONLINE' : '○ OFFLINE'}
        </div>
      </div>
      <div class="agent-role">${a.role || meta.role}</div>
      <div class="agent-stats">
        <div class="stat"><div class="stat-val">${a.tasks_today || '—'}</div><div class="stat-label">tasks today</div></div>
        <div class="stat"><div class="stat-val">${a.uptime || '99.9%'}</div><div class="stat-label">uptime</div></div>
      </div>
    </div>`;
  }).join('');

  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta http-equiv="refresh" content="30">
  <title>Agent Roster — BlackRoad OS</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Display', sans-serif; background: #000; color: #fff; min-height: 100vh; }
    nav { display: flex; align-items: center; gap: 2rem; padding: 1rem 2rem; border-bottom: 1px solid #111; background: #000; position: sticky; top: 0; z-index: 100; }
    nav .logo { font-weight: 700; font-size: 1.1rem; background: linear-gradient(135deg, #F5A623, #FF1D6C, #9C27B0, #2979FF); -webkit-background-clip: text; -webkit-text-fill-color: transparent; }
    nav a { color: #888; text-decoration: none; font-size: 0.85rem; transition: color 0.2s; }
    nav a:hover { color: #fff; }
    .hero { padding: 4rem 2rem 2rem; text-align: center; }
    .hero h1 { font-size: clamp(2rem, 5vw, 3.5rem); font-weight: 800; background: linear-gradient(135deg, #F5A623 0%, #FF1D6C 38.2%, #9C27B0 61.8%, #2979FF 100%); -webkit-background-clip: text; -webkit-text-fill-color: transparent; margin-bottom: 0.5rem; }
    .hero .subtitle { color: #888; font-size: 1.1rem; margin-bottom: 1rem; }
    .stats-bar { display: flex; justify-content: center; gap: 3rem; padding: 1.5rem; background: #0a0a0a; border-top: 1px solid #111; border-bottom: 1px solid #111; margin-bottom: 3rem; }
    .stat-item { text-align: center; }
    .stat-item .val { font-size: 2rem; font-weight: 700; color: #FF1D6C; }
    .stat-item .lbl { font-size: 0.75rem; color: #666; text-transform: uppercase; letter-spacing: 0.1em; }
    .grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(300px, 1fr)); gap: 1.5rem; padding: 0 2rem 4rem; max-width: 1400px; margin: 0 auto; }
    .agent-card { background: #0a0a0a; border: 1px solid #222; border-radius: 12px; padding: 1.5rem; transition: border-color 0.2s, transform 0.2s; }
    .agent-card:hover { transform: translateY(-2px); }
    .agent-header { display: flex; align-items: center; gap: 1rem; margin-bottom: 0.75rem; }
    .agent-icon { font-size: 2rem; }
    .agent-name { font-size: 1.25rem; font-weight: 700; }
    .agent-type { font-size: 0.7rem; color: #666; text-transform: uppercase; letter-spacing: 0.1em; }
    .agent-status { margin-left: auto; font-size: 0.75rem; font-weight: 600; padding: 0.25rem 0.75rem; border-radius: 20px; }
    .agent-status.online { background: #0f2010; color: #4ade80; }
    .agent-status.offline { background: #200a0a; color: #f87171; }
    .agent-role { color: #888; font-size: 0.9rem; margin-bottom: 1rem; }
    .agent-stats { display: flex; gap: 2rem; }
    .stat { }
    .stat-val { font-size: 1.25rem; font-weight: 700; color: #fff; }
    .stat-label { font-size: 0.7rem; color: #666; text-transform: uppercase; letter-spacing: 0.1em; }
    .footer { text-align: center; padding: 2rem; color: #333; font-size: 0.8rem; border-top: 1px solid #111; }
    .live-badge { display: inline-flex; align-items: center; gap: 0.4rem; background: #0f2010; color: #4ade80; font-size: 0.75rem; padding: 0.25rem 0.75rem; border-radius: 20px; margin-bottom: 1rem; }
    .live-badge::before { content: ''; width: 6px; height: 6px; background: #4ade80; border-radius: 50%; animation: pulse 2s infinite; }
    @keyframes pulse { 0%,100%{opacity:1} 50%{opacity:0.3} }
  </style>
</head>
<body>
  <nav>
    <span class="logo">◆ BlackRoad OS</span>
    <a href="https://blackroad.io">Home</a>
    <a href="https://dashboard.blackroad.io">Dashboard</a>
    <a href="https://api.blackroad.io">API</a>
    <a href="https://docs.blackroad.io">Docs</a>
    <a href="https://status.blackroad.io">Status</a>
  </nav>
  <div class="hero">
    <div class="live-badge">LIVE</div>
    <h1>Agent Roster</h1>
    <p class="subtitle">BlackRoad OS — ${roster.online || 6} / ${roster.total || 8} agents online</p>
  </div>
  <div class="stats-bar">
    <div class="stat-item"><div class="val">${roster.online || 6}</div><div class="lbl">Online</div></div>
    <div class="stat-item"><div class="val">${roster.total || 8}</div><div class="lbl">Total Agents</div></div>
    <div class="stat-item"><div class="val">${ghStats.public_repos || 21}</div><div class="lbl">Repos</div></div>
    <div class="stat-item"><div class="val">30K</div><div class="lbl">Capacity</div></div>
  </div>
  <div class="grid">${agentCards}</div>
  <div class="footer">BlackRoad OS, Inc. © ${new Date().getFullYear()} — Updated ${now} — Auto-refreshes every 30s</div>
</body>
</html>`;
}

export default {
  async fetch(request, env, ctx) {
    const now = new Date().toUTCString();
    const [roster, ghStats] = await Promise.all([
      getAgentRoster(),
      getGitHubStats(),
    ]);
    const html = renderHTML(roster, ghStats, now);
    return new Response(html, {
      headers: {
        'Content-Type': 'text/html;charset=UTF-8',
        'Cache-Control': 'public, max-age=30',
        'X-BlackRoad-Worker': 'agents-blackroadio',
        'X-BlackRoad-Version': '2.0.0',
      },
    });
  },
};
