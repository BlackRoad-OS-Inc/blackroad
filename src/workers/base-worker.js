// base-worker.js — BlackRoad OS Reusable Worker Template
// All workers extend this pattern.
// BlackRoad OS, Inc. © 2025 — All Rights Reserved

export const BRAND = {
  hotPink: '#FF1D6C',
  electricBlue: '#2979FF',
  amber: '#F5A623',
  violet: '#9C27B0',
  black: '#000000',
  white: '#FFFFFF',
  gradient: 'linear-gradient(135deg, #F5A623 0%, #FF1D6C 38.2%, #9C27B0 61.8%, #2979FF 100%)',
};

export const GH_ORG = 'BlackRoad-OS-Inc';
export const AGENTS_API = 'https://blackroad-os-api.amundsonalexa.workers.dev';
export const CACHE_TTL = 60;

/**
 * fetchWithCache — fetch with Cloudflare Cache API, 60s TTL
 */
export async function fetchWithCache(request, url, ttl = CACHE_TTL) {
  const cacheKey = new Request(url, { method: 'GET' });
  const cache = caches.default;
  let res = await cache.match(cacheKey);
  if (res) return res;
  try {
    res = await fetch(url, {
      headers: { 'User-Agent': 'BlackRoad-OS/2.0', Accept: 'application/json' },
      cf: { cacheTtl: ttl },
    });
    if (res.ok) {
      const cloned = new Response(res.body, res);
      cloned.headers.set('Cache-Control', `public, max-age=${ttl}`);
      await cache.put(cacheKey, cloned.clone());
      return cloned;
    }
  } catch (_) {}
  return res;
}

/**
 * getGitHubOrg — fetch org stats (no auth needed for public data)
 */
export async function getGitHubOrg(org = GH_ORG) {
  try {
    const r = await fetch(`https://api.github.com/orgs/${org}`, {
      headers: { 'User-Agent': 'BlackRoad-OS/2.0' },
      cf: { cacheTtl: 300 },
    });
    if (r.ok) return r.json();
  } catch (_) {}
  return { public_repos: 21, followers: 0, login: org };
}

/**
 * getGitHubRepos — list org repos
 */
export async function getGitHubRepos(org = GH_ORG, perPage = 10) {
  try {
    const r = await fetch(`https://api.github.com/orgs/${org}/repos?per_page=${perPage}&sort=pushed`, {
      headers: { 'User-Agent': 'BlackRoad-OS/2.0' },
      cf: { cacheTtl: 120 },
    });
    if (r.ok) return r.json();
  } catch (_) {}
  return [];
}

/**
 * navHTML — shared navigation bar
 */
export function navHTML() {
  return `<nav>
    <span class="logo">◆ BlackRoad OS</span>
    <a href="https://blackroad.io">Home</a>
    <a href="https://agents.blackroad.io">Agents</a>
    <a href="https://dashboard.blackroad.io">Dashboard</a>
    <a href="https://api.blackroad.io">API</a>
    <a href="https://docs.blackroad.io">Docs</a>
    <a href="https://console.blackroad.io">Console</a>
    <a href="https://ai.blackroad.io">AI</a>
    <a href="https://status.blackroad.io">Status</a>
  </nav>`;
}

/**
 * baseCSS — shared CSS variables and resets
 */
export function baseCSS() {
  return `
    * { margin: 0; padding: 0; box-sizing: border-box; }
    :root {
      --hot-pink: #FF1D6C; --electric-blue: #2979FF;
      --amber: #F5A623; --violet: #9C27B0;
      --bg: #000; --surface: #0a0a0a; --border: #1a1a1a;
      --text: #fff; --muted: #888; --subtle: #444;
      --gradient: linear-gradient(135deg, var(--amber) 0%, var(--hot-pink) 38.2%, var(--violet) 61.8%, var(--electric-blue) 100%);
    }
    body { font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Display', sans-serif; background: var(--bg); color: var(--text); min-height: 100vh; }
    nav { display: flex; align-items: center; gap: 1.5rem; padding: 1rem 2rem; border-bottom: 1px solid var(--border); background: #000; position: sticky; top: 0; z-index: 100; flex-wrap: wrap; }
    nav .logo { font-weight: 800; font-size: 1rem; background: var(--gradient); -webkit-background-clip: text; -webkit-text-fill-color: transparent; margin-right: 0.5rem; }
    nav a { color: var(--muted); text-decoration: none; font-size: 0.82rem; transition: color 0.2s; }
    nav a:hover { color: var(--text); }
    .hero { padding: 4rem 2rem 2rem; text-align: center; }
    .hero h1 { font-size: clamp(2rem, 5vw, 3.5rem); font-weight: 800; background: var(--gradient); -webkit-background-clip: text; -webkit-text-fill-color: transparent; margin-bottom: 0.5rem; }
    .hero .subtitle { color: var(--muted); font-size: 1.05rem; }
    .live-badge { display: inline-flex; align-items: center; gap: 0.4rem; background: #0f2010; color: #4ade80; font-size: 0.75rem; padding: 0.25rem 0.75rem; border-radius: 20px; margin-bottom: 1rem; }
    .live-badge::before { content: ''; width: 6px; height: 6px; background: #4ade80; border-radius: 50%; animation: pulse 2s infinite; }
    @keyframes pulse { 0%,100%{opacity:1}50%{opacity:0.3} }
    .stats-bar { display: flex; justify-content: center; gap: 3rem; padding: 1.5rem; background: var(--surface); border-top: 1px solid var(--border); border-bottom: 1px solid var(--border); margin-bottom: 3rem; flex-wrap: wrap; }
    .stat-item { text-align: center; }
    .stat-item .val { font-size: 2rem; font-weight: 700; color: var(--hot-pink); }
    .stat-item .lbl { font-size: 0.72rem; color: var(--subtle); text-transform: uppercase; letter-spacing: 0.1em; }
    .card { background: var(--surface); border: 1px solid var(--border); border-radius: 12px; padding: 1.5rem; }
    .card:hover { border-color: var(--hot-pink); }
    .footer { text-align: center; padding: 2rem; color: #333; font-size: 0.8rem; border-top: 1px solid var(--border); }
    .tag { display: inline-block; padding: 0.2rem 0.6rem; border-radius: 4px; font-size: 0.7rem; font-weight: 600; text-transform: uppercase; letter-spacing: 0.05em; }
    .tag-green { background: #0f2010; color: #4ade80; }
    .tag-blue { background: #0a1628; color: #60a5fa; }
    .tag-pink { background: #1a0510; color: #f472b6; }
    .tag-amber { background: #1a1000; color: #fbbf24; }
    a { color: var(--electric-blue); }
  `;
}

/**
 * htmlResponse — wrap content in full HTML doc
 */
export function htmlResponse(title, content, extraHead = '') {
  return new Response(`<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>${title} — BlackRoad OS</title>
  <style>${baseCSS()}</style>
  ${extraHead}
</head>
<body>
  ${navHTML()}
  ${content}
  <div class="footer">BlackRoad OS, Inc. © ${new Date().getFullYear()} — All Rights Reserved</div>
</body>
</html>`, {
    headers: {
      'Content-Type': 'text/html;charset=UTF-8',
      'Cache-Control': 'public, max-age=30',
      'X-BlackRoad-Version': '2.0.0',
    },
  });
}
