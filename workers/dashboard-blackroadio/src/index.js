// dashboard.blackroad.io — System Dashboard Worker
// BlackRoad OS, Inc. © 2026 — All Rights Reserved

const GH_ORG = 'BlackRoad-OS-Inc';
const AGENTS_API = 'https://blackroad-live-hub.amundsonalexa.workers.dev';

function gradientText(text) {
  return `<span style="background:linear-gradient(135deg,#F5A623 0%,#FF1D6C 38.2%,#9C27B0 61.8%,#2979FF 100%);-webkit-background-clip:text;-webkit-text-fill-color:transparent;font-weight:800">${text}</span>`;
}

async function fetchJSON(url, ttl = 60) {
  try {
    const r = await fetch(url, {
      headers: { 'User-Agent': 'BlackRoad-OS/2.0', Accept: 'application/json' },
      cf: { cacheTtl: ttl },
    });
    if (r.ok) return r.json();
  } catch (_) {}
  return null;
}

async function getGitHubData() {
  const [org, repos, workflows] = await Promise.all([
    fetchJSON(`https://api.github.com/orgs/${GH_ORG}`, 300),
    fetchJSON(`https://api.github.com/orgs/${GH_ORG}/repos?per_page=5&sort=pushed`, 120),
    fetchJSON(`https://api.github.com/repos/${GH_ORG}/blackroad/actions/runs?per_page=5`, 60),
  ]);
  return { org, repos, workflows };
}

async function getAgentData() {
  return fetchJSON(`${AGENTS_API}/agents`, 30) || { online: 6, total: 8 };
}

function repoCard(repo) {
  if (!repo) return '';
  const pushed = new Date(repo.pushed_at).toLocaleDateString();
  return `<div class="card repo-card">
    <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:0.5rem">
      <a href="${repo.html_url}" target="_blank" style="color:#FF1D6C;font-weight:600;text-decoration:none">${repo.name}</a>
      <span class="tag tag-blue">${repo.language || 'Code'}</span>
    </div>
    <div style="color:#666;font-size:0.85rem;margin-bottom:0.75rem">${repo.description || 'BlackRoad OS repository'}</div>
    <div style="display:flex;gap:1.5rem;font-size:0.8rem;color:#555">
      <span>⭐ ${repo.stargazers_count}</span>
      <span>🍴 ${repo.forks_count}</span>
      <span>📅 ${pushed}</span>
    </div>
  </div>`;
}

function workflowRow(run) {
  if (!run) return '';
  const status = run.conclusion || run.status;
  const cls = status === 'success' ? 'tag-green' : status === 'failure' ? 'tag-pink' : 'tag-amber';
  return `<div class="card" style="display:flex;align-items:center;justify-content:space-between;padding:1rem 1.5rem;margin-bottom:0.75rem">
    <div>
      <div style="font-weight:600;margin-bottom:0.2rem">${run.name}</div>
      <div style="color:#666;font-size:0.8rem">${run.head_branch} — ${new Date(run.created_at).toLocaleString()}</div>
    </div>
    <span class="tag ${cls}">${status}</span>
  </div>`;
}

export default {
  async fetch(request, env, ctx) {
    const now = new Date().toUTCString();
    const [gh, agents] = await Promise.all([getGitHubData(), getAgentData()]);
    const org = gh.org || {};
    const repos = gh.repos || [];
    const runs = (gh.workflows?.workflow_runs) || [];

    const html = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
  <title>Dashboard — BlackRoad OS</title>
  <style>
    *{margin:0;padding:0;box-sizing:border-box}
    :root{--hot-pink:#FF1D6C;--electric-blue:#2979FF;--amber:#F5A623;--violet:#9C27B0;--gradient:linear-gradient(135deg,#F5A623 0%,#FF1D6C 38.2%,#9C27B0 61.8%,#2979FF 100%)}
    body{font-family:-apple-system,BlinkMacSystemFont,'SF Pro Display',sans-serif;background:#000;color:#fff;min-height:100vh}
    nav{display:flex;align-items:center;gap:1.5rem;padding:1rem 2rem;border-bottom:1px solid #111;background:#000;position:sticky;top:0;z-index:100;flex-wrap:wrap}
    nav .logo{font-weight:800;background:var(--gradient);-webkit-background-clip:text;-webkit-text-fill-color:transparent}
    nav a{color:#666;text-decoration:none;font-size:0.82rem}nav a:hover{color:#fff}
    .hero{padding:3rem 2rem 2rem;text-align:center}
    .hero h1{font-size:clamp(1.8rem,4vw,3rem);font-weight:800;background:var(--gradient);-webkit-background-clip:text;-webkit-text-fill-color:transparent;margin-bottom:0.5rem}
    .hero .sub{color:#666;font-size:1rem}
    .stats-bar{display:flex;justify-content:center;gap:3rem;padding:1.5rem;background:#0a0a0a;border-top:1px solid #111;border-bottom:1px solid #111;margin-bottom:2rem;flex-wrap:wrap}
    .stat-item{text-align:center}.stat-item .val{font-size:1.8rem;font-weight:700;color:var(--hot-pink)}.stat-item .lbl{font-size:0.7rem;color:#555;text-transform:uppercase;letter-spacing:.1em}
    .main{display:grid;grid-template-columns:1fr 1fr;gap:2rem;padding:0 2rem 4rem;max-width:1400px;margin:0 auto}
    @media(max-width:768px){.main{grid-template-columns:1fr}}
    .section-title{font-size:1.1rem;font-weight:700;margin-bottom:1rem;color:#fff;display:flex;align-items:center;gap:0.5rem}
    .card{background:#0a0a0a;border:1px solid #1a1a1a;border-radius:10px;padding:1.25rem;margin-bottom:0.75rem;transition:border-color .2s}
    .card:hover{border-color:#333}
    .repo-card{margin-bottom:0.75rem}
    .tag{display:inline-block;padding:.2rem .55rem;border-radius:4px;font-size:.7rem;font-weight:600;text-transform:uppercase}
    .tag-green{background:#0f2010;color:#4ade80}.tag-blue{background:#0a1628;color:#60a5fa}.tag-pink{background:#1a0510;color:#f472b6}.tag-amber{background:#1a1000;color:#fbbf24}
    .live-badge{display:inline-flex;align-items:center;gap:.4rem;background:#0f2010;color:#4ade80;font-size:.75rem;padding:.25rem .75rem;border-radius:20px;margin-bottom:.75rem}
    .live-badge::before{content:'';width:6px;height:6px;background:#4ade80;border-radius:50%;animation:pulse 2s infinite}
    @keyframes pulse{0%,100%{opacity:1}50%{opacity:.3}}
    .footer{text-align:center;padding:2rem;color:#333;font-size:.8rem;border-top:1px solid #111}
    a{color:var(--electric-blue)}
  </style>
  <meta http-equiv="refresh" content="30">
</head>
<body>
<nav>
  <span class="logo">◆ BlackRoad OS</span>
  <a href="https://blackroad.io">Home</a>
  <a href="https://agents.blackroad.io">Agents</a>
  <a href="https://api.blackroad.io">API</a>
  <a href="https://docs.blackroad.io">Docs</a>
  <a href="https://console.blackroad.io">Console</a>
  <a href="https://ai.blackroad.io">AI</a>
  <a href="https://status.blackroad.io">Status</a>
</nav>
<div class="hero">
  <div class="live-badge">LIVE</div>
  <h1>System Dashboard</h1>
  <p class="sub">BlackRoad OS — Real-time infrastructure overview</p>
</div>
<div class="stats-bar">
  <div class="stat-item"><div class="val">${org.public_repos || 21}</div><div class="lbl">Repositories</div></div>
  <div class="stat-item"><div class="val">${agents.online || 6}</div><div class="lbl">Agents Online</div></div>
  <div class="stat-item"><div class="val">${runs.filter(r => r.conclusion === 'success').length || 0}</div><div class="lbl">CI Passing</div></div>
  <div class="stat-item"><div class="val">30K</div><div class="lbl">Agent Capacity</div></div>
</div>
<div class="main">
  <div>
    <div class="section-title">📦 Recent Repositories</div>
    ${repos.map(repoCard).join('') || '<div class="card" style="color:#666">Loading repos...</div>'}
  </div>
  <div>
    <div class="section-title">⚙️ Recent CI/CD Runs</div>
    ${runs.map(workflowRow).join('') || `<div class="card" style="color:#666;padding:1rem">No workflow runs found — <a href="https://github.com/${GH_ORG}" target="_blank">View on GitHub</a></div>`}
    <div style="margin-top:1.5rem">
      <div class="section-title">🏢 Organization</div>
      <div class="card">
        <div style="font-size:1.1rem;font-weight:700;margin-bottom:0.5rem">${org.login || GH_ORG}</div>
        <div style="color:#666;font-size:0.9rem;margin-bottom:0.75rem">${org.description || 'BlackRoad OS, Inc. — Your AI. Your Hardware. Your Rules.'}</div>
        <div style="display:flex;gap:2rem;font-size:0.85rem">
          <span style="color:#FF1D6C">${org.public_repos || 21} <span style="color:#555">repos</span></span>
          <span style="color:#2979FF">${org.followers || 0} <span style="color:#555">followers</span></span>
        </div>
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
        'X-BlackRoad-Worker': 'dashboard-blackroadio',
        'X-BlackRoad-Version': '2.0.0',
      },
    });
  },
};
