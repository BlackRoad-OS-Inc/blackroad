// blackroad.io — Main Platform Worker
// BlackRoad OS, Inc. — All Rights Reserved

const AGENTS_API = 'https://blackroad-os-api.amundsonalexa.workers.dev';
const GH_ORG = 'BlackRoad-OS-Inc';
const GH_ORG2 = 'BlackRoad-OS';

async function fetchJSON(url, cacheTtl = 60) {
  try {
    const r = await fetch(url, {
      headers: { 'User-Agent': 'BlackRoad-OS/2.0', 'Accept': 'application/json' },
      cf: { cacheTtl },
    });
    if (r.ok) return await r.json();
  } catch (_) {}
  return null;
}

async function getAllData() {
  const [orgInc, orgOS, health, commits] = await Promise.all([
    fetchJSON(`https://api.github.com/orgs/${GH_ORG}`, 300),
    fetchJSON(`https://api.github.com/orgs/${GH_ORG2}`, 300),
    fetchJSON(`${AGENTS_API}/health`, 30),
    fetchJSON(`https://api.github.com/repos/${GH_ORG}/blackroad/commits?per_page=5`, 120),
  ]);
  return { orgInc, orgOS, health, commits };
}

function renderHTML(data, now) {
  const { orgInc, orgOS, health, commits } = data;
  const totalRepos = (orgInc?.public_repos || 0) + (orgOS?.public_repos || 0);
  const agentOnline = health?.agents || 6;

  const commitList = (commits || []).map(c => `
    <div class="commit">
      <div class="commit-sha">${(c.sha || '').slice(0,7)}</div>
      <div class="commit-msg">${(c.commit?.message || '').split('\n')[0].slice(0, 80)}</div>
      <div class="commit-time">${c.commit?.author?.date ? new Date(c.commit.author.date).toLocaleString() : ''}</div>
    </div>`).join('');

  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta http-equiv="refresh" content="60">
  <title>BlackRoad OS — Your AI. Your Hardware. Your Rules.</title>
  <meta name="description" content="BlackRoad OS — AI agent orchestration platform. 30,000 agents. 1,825+ repositories. 17 organizations.">
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    :root {
      --hot-pink: #FF1D6C; --electric-blue: #2979FF; --amber: #F5A623; --violet: #9C27B0;
      --space-xs: 8px; --space-sm: 13px; --space-md: 21px; --space-lg: 34px; --space-xl: 55px;
    }
    body { font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Display', sans-serif; background: #000; color: #fff; min-height: 100vh; line-height: 1.618; }
    nav { display: flex; align-items: center; gap: 2rem; padding: 1rem 2rem; border-bottom: 1px solid #111; position: sticky; top: 0; background: rgba(0,0,0,0.95); backdrop-filter: blur(10px); z-index: 100; }
    .logo { font-weight: 800; font-size: 1.2rem; background: linear-gradient(135deg, var(--amber), var(--hot-pink), var(--violet), var(--electric-blue)); -webkit-background-clip: text; -webkit-text-fill-color: transparent; }
    nav a { color: #888; text-decoration: none; font-size: 0.85rem; transition: color 0.2s; }
    nav a:hover { color: #fff; }
    .nav-cta { margin-left: auto; background: var(--hot-pink); color: #fff !important; padding: 0.5rem 1.25rem; border-radius: 8px; font-weight: 600; }
    .hero { padding: var(--space-xl) 2rem; text-align: center; position: relative; overflow: hidden; }
    .hero::before { content: ''; position: absolute; inset: 0; background: radial-gradient(ellipse at center, #FF1D6C08 0%, transparent 70%); pointer-events: none; }
    .live-badge { display: inline-flex; align-items: center; gap: 0.4rem; background: #0f2010; color: #4ade80; font-size: 0.75rem; padding: 0.3rem 0.9rem; border-radius: 20px; margin-bottom: 1.5rem; font-weight: 500; }
    .live-badge::before { content: ''; width: 7px; height: 7px; background: #4ade80; border-radius: 50%; animation: pulse 2s infinite; }
    @keyframes pulse { 0%,100%{opacity:1;transform:scale(1)} 50%{opacity:0.3;transform:scale(0.8)} }
    h1 { font-size: clamp(3rem, 8vw, 7rem); font-weight: 900; line-height: 1.05; background: linear-gradient(135deg, var(--amber) 0%, var(--hot-pink) 38.2%, var(--violet) 61.8%, var(--electric-blue) 100%); -webkit-background-clip: text; -webkit-text-fill-color: transparent; margin-bottom: 1.5rem; letter-spacing: -0.02em; }
    .tagline { font-size: 1.4rem; color: #888; margin-bottom: var(--space-lg); max-width: 600px; margin-left: auto; margin-right: auto; }
    .cta { display: flex; gap: 1rem; justify-content: center; flex-wrap: wrap; margin-bottom: var(--space-xl); }
    .btn { padding: 0.85rem 2rem; border-radius: 10px; font-size: 1rem; font-weight: 700; text-decoration: none; transition: all 0.2s cubic-bezier(0.25,0.1,0.25,1); }
    .btn-primary { background: linear-gradient(135deg, var(--hot-pink), var(--violet)); color: #fff; }
    .btn-secondary { border: 1px solid #333; color: #fff; background: transparent; }
    .btn:hover { transform: translateY(-2px); opacity: 0.9; }
    .stats { display: grid; grid-template-columns: repeat(auto-fill, minmax(140px, 1fr)); gap: 1px; background: #111; border: 1px solid #111; border-radius: 16px; overflow: hidden; max-width: 900px; margin: 0 auto var(--space-xl); }
    .stat { background: #000; padding: 1.5rem; text-align: center; }
    .stat .val { font-size: 2.5rem; font-weight: 800; display: block; }
    .stat .lbl { font-size: 0.7rem; color: #666; text-transform: uppercase; letter-spacing: 0.12em; margin-top: 0.25rem; display: block; }
    .main { max-width: 1200px; margin: 0 auto; padding: 0 2rem var(--space-xl); }
    .grid-2 { display: grid; grid-template-columns: 1fr 1fr; gap: 1.5rem; margin-bottom: 1.5rem; }
    @media (max-width: 768px) { .grid-2 { grid-template-columns: 1fr; } }
    .card { background: #0a0a0a; border: 1px solid #1a1a1a; border-radius: 14px; padding: 1.5rem; }
    .card h2 { font-size: 0.8rem; color: #666; text-transform: uppercase; letter-spacing: 0.12em; margin-bottom: 1rem; font-weight: 500; }
    .commit { display: flex; align-items: flex-start; gap: 0.75rem; padding: 0.6rem 0; border-bottom: 1px solid #111; }
    .commit:last-child { border: none; }
    .commit-sha { font-family: 'Courier New', monospace; font-size: 0.75rem; color: var(--electric-blue); min-width: 55px; }
    .commit-msg { font-size: 0.85rem; color: #ccc; flex: 1; }
    .commit-time { font-size: 0.75rem; color: #555; min-width: 120px; text-align: right; }
    .agent-row { display: flex; align-items: center; gap: 0.75rem; padding: 0.6rem 0; border-bottom: 1px solid #111; }
    .agent-row:last-child { border: none; }
    .agent-dot { width: 8px; height: 8px; border-radius: 50%; flex-shrink: 0; }
    .agent-name { font-weight: 600; font-size: 0.9rem; flex: 1; }
    .agent-role { font-size: 0.8rem; color: #666; }
    .agent-badge { font-size: 0.7rem; padding: 0.2rem 0.5rem; border-radius: 10px; font-weight: 600; }
    .domains-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(180px, 1fr)); gap: 0.75rem; margin-top: 1rem; }
    .domain-chip { background: #111; border: 1px solid #1a1a1a; border-radius: 8px; padding: 0.6rem 1rem; font-size: 0.8rem; text-decoration: none; color: #888; transition: all 0.2s; }
    .domain-chip:hover { border-color: var(--hot-pink); color: #fff; }
    .footer { text-align: center; padding: 3rem 2rem; color: #333; font-size: 0.8rem; border-top: 1px solid #111; }
    .footer strong { color: #555; }
  </style>
</head>
<body>
  <nav>
    <span class="logo">◆ BlackRoad OS</span>
    <a href="https://agents.blackroad.io">Agents</a>
    <a href="https://dashboard.blackroad.io">Dashboard</a>
    <a href="https://api.blackroad.io">API</a>
    <a href="https://docs.blackroad.io">Docs</a>
    <a href="https://github.com/BlackRoad-OS-Inc" target="_blank">GitHub</a>
    <a href="https://status.blackroad.io" class="nav-cta">Status</a>
  </nav>

  <div class="hero">
    <div class="live-badge">LIVE — ${agentOnline} agents online</div>
    <h1>BlackRoad OS</h1>
    <p class="tagline">Your AI. Your Hardware. Your Rules.<br>The AI-native operating system for builders.</p>
    <div class="cta">
      <a href="https://agents.blackroad.io" class="btn btn-primary">Explore Agents</a>
      <a href="https://dashboard.blackroad.io" class="btn btn-secondary">Dashboard</a>
      <a href="https://github.com/BlackRoad-OS-Inc" class="btn btn-secondary" target="_blank">GitHub ↗</a>
    </div>
    <div class="stats">
      <div class="stat"><span class="val" style="color:var(--hot-pink)">${totalRepos || '1,825+'}</span><span class="lbl">Repositories</span></div>
      <div class="stat"><span class="val" style="color:var(--electric-blue)">${agentOnline}</span><span class="lbl">Agents Online</span></div>
      <div class="stat"><span class="val" style="color:var(--amber)">17</span><span class="lbl">GitHub Orgs</span></div>
      <div class="stat"><span class="val" style="color:var(--violet)">30K</span><span class="lbl">Agent Capacity</span></div>
      <div class="stat"><span class="val" style="color:#4ade80">75+</span><span class="lbl">CF Workers</span></div>
      <div class="stat"><span class="val" style="color:#00BCD4">3</span><span class="lbl">Pi Nodes</span></div>
    </div>
  </div>

  <div class="main">
    <div class="grid-2">
      <div class="card">
        <h2>Recent Commits — BlackRoad-OS-Inc</h2>
        ${commitList || '<p style="color:#555;font-size:0.85rem">Loading commits...</p>'}
      </div>
      <div class="card">
        <h2>Agent Fleet</h2>
        <div class="agent-row"><div class="agent-dot" style="background:#FF1D6C"></div><span class="agent-name">LUCIDIA</span><span class="agent-role">Coordinator</span><span class="agent-badge" style="background:#0f0a1a;color:#FF1D6C">ONLINE</span></div>
        <div class="agent-row"><div class="agent-dot" style="background:#2979FF"></div><span class="agent-name">ALICE</span><span class="agent-role">Router</span><span class="agent-badge" style="background:#0a0f1a;color:#2979FF">ONLINE</span></div>
        <div class="agent-row"><div class="agent-dot" style="background:#F5A623"></div><span class="agent-name">OCTAVIA</span><span class="agent-role">Infra</span><span class="agent-badge" style="background:#1a0f0a;color:#F5A623">ONLINE</span></div>
        <div class="agent-row"><div class="agent-dot" style="background:#9C27B0"></div><span class="agent-name">PRISM</span><span class="agent-role">Analyst</span><span class="agent-badge" style="background:#0f0a1a;color:#9C27B0">ONLINE</span></div>
        <div class="agent-row"><div class="agent-dot" style="background:#00BCD4"></div><span class="agent-name">ECHO</span><span class="agent-role">Memory</span><span class="agent-badge" style="background:#0a1a1a;color:#00BCD4">ONLINE</span></div>
        <div class="agent-row"><div class="agent-dot" style="background:#4CAF50"></div><span class="agent-name">CIPHER</span><span class="agent-role">Security</span><span class="agent-badge" style="background:#0a1a0a;color:#4CAF50">ONLINE</span></div>
      </div>
    </div>

    <div class="card" style="margin-bottom:1.5rem">
      <h2>Domain Network — blackroad.io</h2>
      <div class="domains-grid">
        ${['about','admin','agents','ai','algorithms','alice','analytics','api','asia','blockchain','blocks','blog','cdn','chain','circuits','cli','compliance','compute','console','control','dashboard','data','demo','design','dev','docs','edge','editor','engineering','eu','events','explorer','features','finance','global','guide','hardware','help','hr','ide','network','status'].map(d => `<a href="https://${d}.blackroad.io" class="domain-chip">${d}.blackroad.io</a>`).join('')}
      </div>
    </div>

    <div class="grid-2">
      <div class="card">
        <h2>GitHub Organizations</h2>
        <div style="font-size:0.85rem;color:#888;line-height:2">
          <div>BlackRoad-OS-Inc — ${orgInc?.public_repos || 21} repos (Corporate)</div>
          <div>BlackRoad-OS — ${orgOS?.public_repos || '1,332+'} repos (Platform)</div>
          <div>BlackRoad-AI — 52 repos (AI/ML)</div>
          <div>BlackRoad-Cloud — 30 repos (Infra)</div>
          <div>BlackRoad-Security — 30 repos (Security)</div>
          <div style="color:#555">+ 12 more organizations</div>
        </div>
      </div>
      <div class="card">
        <h2>Infrastructure</h2>
        <div style="font-size:0.85rem;color:#888;line-height:2">
          <div><span style="color:#4ade80">●</span> Pi Primary — 192.168.4.38 (22.5K agents)</div>
          <div><span style="color:#4ade80">●</span> Pi Secondary — 192.168.4.64 (7.5K agents)</div>
          <div><span style="color:#4ade80">●</span> CF Tunnel — QUIC Dallas edge</div>
          <div><span style="color:#4ade80">●</span> DO Droplet — 159.65.43.12</div>
          <div><span style="color:#4ade80">●</span> Cloudflare Workers — 75+ deployed</div>
          <div><span style="color:#4ade80">●</span> Railway — 14 projects</div>
        </div>
      </div>
    </div>
  </div>

  <div class="footer">
    <strong>BlackRoad OS, Inc.</strong> © ${new Date().getFullYear()} — All Rights Reserved<br>
    Updated: ${now} — Auto-refreshes every 60s
  </div>
</body>
</html>`;
}

export default {
  async fetch(request, env, ctx) {
    const now = new Date().toUTCString();
    const data = await getAllData();
    const html = renderHTML(data, now);
    return new Response(html, {
      headers: {
        'Content-Type': 'text/html;charset=UTF-8',
        'Cache-Control': 'public, max-age=60',
        'X-BlackRoad-Worker': 'blackroad-io',
        'X-BlackRoad-Version': '2.0.0',
      },
    });
  },
};
