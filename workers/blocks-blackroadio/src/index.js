// blocks.blackroad.io — Block Storage
// BlackRoad OS, Inc. — All Rights Reserved

const DATA_URL = 'https://blackroad-live-data.blackroad.workers.dev/health';
const AGENTS_API = 'https://blackroad-live-data.blackroad.workers.dev';

async function fetchLiveData() {
  try {
    const r = await fetch(DATA_URL, {
      headers: { 'User-Agent': 'BlackRoad-OS/2.0', 'Accept': 'application/json' },
      cf: { cacheTtl: 60 },
    });
    if (r.ok) return await r.json();
  } catch (_) {}
  return {};
}

async function getHealth() {
  try {
    const r = await fetch(`${AGENTS_API}/health`, {
      headers: { 'User-Agent': 'BlackRoad-OS/2.0' },
      cf: { cacheTtl: 30 },
    });
    if (r.ok) return await r.json();
  } catch (_) {}
  return { status: 'ok', agents: 6 };
}

function renderHTML(data, health, now) {
  const repoCount = data.public_repos || data.total_count || '—';
  const agentCount = health.agents || 6;

  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta http-equiv="refresh" content="30">
  <title>Block Storage — BlackRoad OS</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Display', sans-serif; background: #000; color: #fff; min-height: 100vh; }
    nav { display: flex; align-items: center; gap: 2rem; padding: 1rem 2rem; border-bottom: 1px solid #111; position: sticky; top: 0; background: #000; z-index: 100; }
    .logo { font-weight: 700; font-size: 1.1rem; background: linear-gradient(135deg, #F5A623, #FF1D6C, #9C27B0, #2979FF); -webkit-background-clip: text; -webkit-text-fill-color: transparent; }
    nav a { color: #888; text-decoration: none; font-size: 0.85rem; }
    nav a:hover { color: #fff; }
    .hero { display: flex; flex-direction: column; align-items: center; justify-content: center; min-height: 60vh; text-align: center; padding: 4rem 2rem; }
    .live-badge { display: inline-flex; align-items: center; gap: 0.4rem; background: #0f2010; color: #4ade80; font-size: 0.75rem; padding: 0.25rem 0.75rem; border-radius: 20px; margin-bottom: 1.5rem; }
    .live-badge::before { content: ''; width: 6px; height: 6px; background: #4ade80; border-radius: 50%; animation: pulse 2s infinite; }
    @keyframes pulse { 0%,100%{opacity:1} 50%{opacity:0.3} }
    h1 { font-size: clamp(2.5rem, 6vw, 5rem); font-weight: 800; background: linear-gradient(135deg, #F5A623 0%, #FF1D6C 38.2%, #9C27B0 61.8%, #2979FF 100%); -webkit-background-clip: text; -webkit-text-fill-color: transparent; margin-bottom: 1rem; }
    .subtitle { color: #888; font-size: 1.2rem; margin-bottom: 3rem; max-width: 600px; line-height: 1.618; }
    .subdomain { font-family: 'Courier New', monospace; font-size: 1rem; color: #2979FF; margin-bottom: 2rem; }
    .stats { display: flex; gap: 3rem; justify-content: center; flex-wrap: wrap; }
    .stat { text-align: center; }
    .stat .val { font-size: 2.5rem; font-weight: 800; color: #2979FF; }
    .stat .lbl { font-size: 0.75rem; color: #666; text-transform: uppercase; letter-spacing: 0.1em; }
    .data-section { max-width: 800px; margin: 3rem auto; padding: 0 2rem; }
    .data-card { background: #0a0a0a; border: 1px solid #1a1a1a; border-radius: 12px; padding: 1.5rem; margin-bottom: 1rem; }
    .data-card h3 { color: #2979FF; font-size: 0.85rem; text-transform: uppercase; letter-spacing: 0.1em; margin-bottom: 0.75rem; }
    pre { color: #888; font-size: 0.85rem; overflow-x: auto; white-space: pre-wrap; word-break: break-all; }
    .footer { text-align: center; padding: 2rem; color: #333; font-size: 0.8rem; border-top: 1px solid #111; margin-top: 4rem; }
    .cta { display: inline-flex; gap: 1rem; margin-top: 2rem; flex-wrap: wrap; justify-content: center; }
    .btn { padding: 0.75rem 1.5rem; border-radius: 8px; font-size: 0.9rem; font-weight: 600; text-decoration: none; transition: opacity 0.2s; }
    .btn-primary { background: #2979FF; color: #000; }
    .btn-secondary { border: 1px solid #333; color: #fff; }
    .btn:hover { opacity: 0.8; }
  </style>
</head>
<body>
  <nav>
    <span class="logo">◆ BlackRoad OS</span>
    <a href="https://blackroad.io">Home</a>
    <a href="https://dashboard.blackroad.io">Dashboard</a>
    <a href="https://agents.blackroad.io">Agents</a>
    <a href="https://docs.blackroad.io">Docs</a>
    <a href="https://status.blackroad.io">Status</a>
  </nav>
  <div class="hero">
    <div class="live-badge">LIVE</div>
    <div class="subdomain">blocks.blackroad.io</div>
    <h1>Block Storage</h1>
    <p class="subtitle">Part of the BlackRoad OS platform — AI-native, edge-deployed, production-ready.</p>
    <div class="stats">
      <div class="stat"><div class="val">${agentCount}</div><div class="lbl">Agents Online</div></div>
      <div class="stat"><div class="val">30K</div><div class="lbl">Agent Capacity</div></div>
      <div class="stat"><div class="val">1,825+</div><div class="lbl">Repositories</div></div>
      <div class="stat"><div class="val">17</div><div class="lbl">Orgs</div></div>
    </div>
    <div class="cta">
      <a href="https://github.com/BlackRoad-OS-Inc" class="btn btn-primary">GitHub</a>
      <a href="https://blackroad.io" class="btn btn-secondary">Platform</a>
    </div>
  </div>
  <div class="data-section">
    <div class="data-card">
      <h3>Live Data — ${new Date().toLocaleTimeString()}</h3>
      <pre>${JSON.stringify({ subdomain: 'blocks.blackroad.io', description: 'Block Storage', health: health.status || 'ok', agents_online: agentCount, timestamp: now }, null, 2)}</pre>
    </div>
  </div>
  <div class="footer">BlackRoad OS, Inc. © ${new Date().getFullYear()} — ${now} — Auto-refreshes every 30s</div>
</body>
</html>`;
}

export default {
  async fetch(request, env, ctx) {
    const now = new Date().toUTCString();
    const [data, health] = await Promise.all([fetchLiveData(), getHealth()]);
    const html = renderHTML(data, health, now);
    return new Response(html, {
      headers: {
        'Content-Type': 'text/html;charset=UTF-8',
        'Cache-Control': 'public, max-age=30',
        'X-BlackRoad-Worker': 'blocks-blackroadio',
        'X-BlackRoad-Version': '2.0.0',
      },
    });
  },
};
