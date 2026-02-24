// analytics.blackroad.io — Analytics Dashboard Worker
// BlackRoad OS, Inc. © 2026 — All Rights Reserved

const GH_ORG = 'BlackRoad-OS-Inc';
const KEY_REPOS = ['blackroad', 'blackroad-core', 'blackroad-agents', 'blackroad-web', 'blackroad-docs'];

async function fetchJSON(url, ttl = 120) {
  try {
    const r = await fetch(url, {
      headers: { 'User-Agent': 'BlackRoad-OS/2.0', Accept: 'application/json' },
      cf: { cacheTtl: ttl },
    });
    if (r.ok) return r.json();
  } catch (_) {}
  return null;
}

function miniBar(value, max, color = '#FF1D6C') {
  const pct = max > 0 ? Math.min(100, (value / max) * 100) : 0;
  return `<div style="background:#111;border-radius:4px;height:6px;width:100%;margin-top:.4rem">
    <div style="background:${color};height:6px;border-radius:4px;width:${pct}%;transition:width .3s"></div>
  </div>`;
}

export default {
  async fetch(request, env, ctx) {
    const now = new Date().toUTCString();

    const [org, ...repos] = await Promise.all([
      fetchJSON(`https://api.github.com/orgs/${GH_ORG}`, 300),
      ...KEY_REPOS.map(r => fetchJSON(`https://api.github.com/repos/${GH_ORG}/${r}`, 120)),
    ]);

    const validRepos = repos.filter(Boolean);
    const totalStars = validRepos.reduce((s, r) => s + (r.stargazers_count || 0), 0);
    const totalForks = validRepos.reduce((s, r) => s + (r.forks_count || 0), 0);
    const totalWatchers = validRepos.reduce((s, r) => s + (r.watchers_count || 0), 0);
    const maxStars = Math.max(...validRepos.map(r => r.stargazers_count || 0), 1);

    const repoRows = validRepos.map(r => `
      <div class="repo-row">
        <div class="repo-name">
          <a href="${r.html_url}" target="_blank">${r.name}</a>
          ${r.language ? `<span class="lang-badge">${r.language}</span>` : ''}
        </div>
        <div class="repo-metrics">
          <div class="metric"><span class="m-val">${r.stargazers_count}</span><span class="m-lbl">⭐ stars</span></div>
          <div class="metric"><span class="m-val">${r.forks_count}</span><span class="m-lbl">🍴 forks</span></div>
          <div class="metric"><span class="m-val">${r.open_issues_count}</span><span class="m-lbl">🔴 issues</span></div>
          <div class="metric"><span class="m-val">${new Date(r.pushed_at).toLocaleDateString()}</span><span class="m-lbl">last push</span></div>
        </div>
        ${miniBar(r.stargazers_count, maxStars, '#FF1D6C')}
      </div>`).join('');

    const html = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
  <title>Analytics — BlackRoad OS</title>
  <meta http-equiv="refresh" content="60">
  <style>
    *{margin:0;padding:0;box-sizing:border-box}
    :root{--hot-pink:#FF1D6C;--electric-blue:#2979FF;--amber:#F5A623;--violet:#9C27B0;--gradient:linear-gradient(135deg,#F5A623 0%,#FF1D6C 38.2%,#9C27B0 61.8%,#2979FF 100%)}
    body{font-family:-apple-system,BlinkMacSystemFont,'SF Pro Display',sans-serif;background:#000;color:#fff;min-height:100vh}
    nav{display:flex;align-items:center;gap:1.5rem;padding:1rem 2rem;border-bottom:1px solid #111;background:#000;position:sticky;top:0;z-index:100;flex-wrap:wrap}
    nav .logo{font-weight:800;background:var(--gradient);-webkit-background-clip:text;-webkit-text-fill-color:transparent}
    nav a{color:#666;text-decoration:none;font-size:.82rem}nav a:hover{color:#fff}
    .hero{padding:3rem 2rem 2rem;text-align:center}
    .hero h1{font-size:clamp(1.8rem,4vw,3rem);font-weight:800;background:var(--gradient);-webkit-background-clip:text;-webkit-text-fill-color:transparent;margin-bottom:.5rem}
    .hero .sub{color:#666}
    .kpis{display:grid;grid-template-columns:repeat(auto-fit,minmax(160px,1fr));gap:1rem;padding:1.5rem 2rem;max-width:1200px;margin:0 auto 2rem}
    .kpi{background:#0a0a0a;border:1px solid #1a1a1a;border-radius:10px;padding:1.25rem;text-align:center}
    .kpi .kv{font-size:2.2rem;font-weight:800;background:var(--gradient);-webkit-background-clip:text;-webkit-text-fill-color:transparent}
    .kpi .kl{font-size:.72rem;color:#555;text-transform:uppercase;letter-spacing:.08em;margin-top:.2rem}
    .main{padding:0 2rem 4rem;max-width:1200px;margin:0 auto}
    .section-title{font-size:1rem;font-weight:700;text-transform:uppercase;letter-spacing:.08em;color:#888;margin:2rem 0 1rem;display:flex;align-items:center;gap:.5rem}
    .repo-row{background:#0a0a0a;border:1px solid #1a1a1a;border-radius:10px;padding:1.25rem;margin-bottom:.75rem}
    .repo-name{display:flex;align-items:center;gap:.5rem;margin-bottom:.75rem}
    .repo-name a{color:#FF1D6C;font-weight:600;text-decoration:none;font-size:1rem}
    .repo-name a:hover{text-decoration:underline}
    .lang-badge{background:#0a1628;border:1px solid #2979FF33;color:#60a5fa;padding:.15rem .5rem;border-radius:4px;font-size:.7rem}
    .repo-metrics{display:flex;gap:2rem;flex-wrap:wrap}
    .metric{text-align:center}.m-val{display:block;font-weight:700;font-size:1.1rem}.m-lbl{font-size:.72rem;color:#555}
    .org-card{background:#0a0a0a;border:1px solid #1a1a1a;border-radius:10px;padding:1.5rem;display:flex;align-items:center;gap:2rem;flex-wrap:wrap}
    .org-stat{text-align:center;flex:1}
    .org-stat .v{font-size:1.5rem;font-weight:700;color:#FF1D6C}
    .org-stat .l{font-size:.72rem;color:#555;text-transform:uppercase;letter-spacing:.08em}
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
  <a href="https://api.blackroad.io">API</a>
  <a href="https://docs.blackroad.io">Docs</a>
  <a href="https://status.blackroad.io">Status</a>
</nav>
<div class="hero">
  <h1>Analytics</h1>
  <p class="sub">Live GitHub metrics — updated every 60 seconds</p>
</div>
<div class="kpis">
  <div class="kpi"><div class="kv">${org?.public_repos || 21}</div><div class="kl">Public Repos</div></div>
  <div class="kpi"><div class="kv">${totalStars}</div><div class="kl">Total Stars</div></div>
  <div class="kpi"><div class="kv">${totalForks}</div><div class="kl">Total Forks</div></div>
  <div class="kpi"><div class="kv">${totalWatchers}</div><div class="kl">Watchers</div></div>
  <div class="kpi"><div class="kv">${org?.followers || 0}</div><div class="kl">Followers</div></div>
  <div class="kpi"><div class="kv">17</div><div class="kl">Organizations</div></div>
</div>
<div class="main">
  <div class="section-title">📦 Key Repository Metrics</div>
  ${repoRows || '<div style="color:#555;padding:1rem">Loading repository data...</div>'}
  <div class="section-title">🏢 Organization Overview</div>
  <div class="org-card">
    <div class="org-stat"><div class="v">${org?.public_repos || 21}</div><div class="l">Repos</div></div>
    <div class="org-stat"><div class="v">${org?.public_members || 0}</div><div class="l">Members</div></div>
    <div class="org-stat"><div class="v">${org?.followers || 0}</div><div class="l">Followers</div></div>
    <div style="flex:2;color:#666;font-size:.88rem">${org?.description || 'BlackRoad OS, Inc. — Your AI. Your Hardware. Your Rules.'}<br><a href="https://github.com/${GH_ORG}" target="_blank">github.com/${GH_ORG}</a></div>
  </div>
</div>
<div class="footer">BlackRoad OS, Inc. © ${new Date().getFullYear()} — Updated ${now} — Auto-refreshes every 60s</div>
</body>
</html>`;

    return new Response(html, {
      headers: {
        'Content-Type': 'text/html;charset=UTF-8',
        'Cache-Control': 'public, max-age=60',
        'X-BlackRoad-Worker': 'analytics-blackroadio',
        'X-BlackRoad-Version': '2.0.0',
      },
    });
  },
};
