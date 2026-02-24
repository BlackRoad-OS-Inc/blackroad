/**
 * BlackRoad OS — Domain Worker Template
 * ────────────────────────────────────────────────────────────────────
 * Every subdomain worker extends this base. Override WORKER_CONFIG and
 * renderBody() to customize per domain.
 *
 * Account: 848cf0b18d51e0170e0d1537aec3505a
 * Brand:   #FF1D6C (pink) · #F5A623 (amber) · #9C27B0 (violet) · #2979FF (blue)
 *
 * Secrets required (set via: wrangler secret put <NAME>):
 *   GITHUB_TOKEN    — GitHub PAT (read:org, read:repo)
 *   CF_API_TOKEN    — Cloudflare API token (read workers/zones)
 *   RAILWAY_TOKEN   — Railway API token
 *   INTERNAL_SECRET — Shared secret for agent-to-agent calls
 */

// ── Brand ─────────────────────────────────────────────────────────────────────
export const BRAND = {
  pink:     "#FF1D6C",
  amber:    "#F5A623",
  violet:   "#9C27B0",
  blue:     "#2979FF",
  gradient: "linear-gradient(135deg, #F5A623 0%, #FF1D6C 38.2%, #9C27B0 61.8%, #2979FF 100%)",
  dark:     "#0A0A0F",
  surface:  "#12121A",
  border:   "rgba(255,29,108,0.2)",
};

// ── CORS ──────────────────────────────────────────────────────────────────────
const CORS = {
  "Access-Control-Allow-Origin":  "*",
  "Access-Control-Allow-Methods": "GET,POST,OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type,Authorization,X-BlackRoad-Agent",
  "Access-Control-Max-Age":       "86400",
};

// ── Helpers ───────────────────────────────────────────────────────────────────
export function html(body, status = 200) {
  return new Response(body, {
    status,
    headers: { "Content-Type": "text/html;charset=UTF-8", "Cache-Control": "no-store", ...CORS },
  });
}

export function json(data, status = 200) {
  return new Response(JSON.stringify(data, null, 2), {
    status,
    headers: { "Content-Type": "application/json", ...CORS },
  });
}

// ── Live data fetchers ────────────────────────────────────────────────────────
export async function fetchGitHub(path, token) {
  if (!token) return null;
  try {
    const r = await fetch(`https://api.github.com/${path}`, {
      headers: {
        Authorization: `Bearer ${token}`,
        Accept: "application/vnd.github+json",
        "X-GitHub-Api-Version": "2022-11-28",
        "User-Agent": "blackroad-worker/2.0",
      },
    });
    return r.ok ? r.json() : null;
  } catch { return null; }
}

export async function fetchRailway(query, token) {
  if (!token) return null;
  try {
    const r = await fetch("https://backboard.railway.app/graphql/v2", {
      method: "POST",
      headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" },
      body: JSON.stringify({ query }),
    });
    return r.ok ? r.json() : null;
  } catch { return null; }
}

export async function fetchCF(path, token) {
  if (!token) return null;
  try {
    const r = await fetch(`https://api.cloudflare.com/client/v4/${path}`, {
      headers: { Authorization: `Bearer ${token}` },
    });
    return r.ok ? r.json() : null;
  } catch { return null; }
}

// ── Shared HTML shell ─────────────────────────────────────────────────────────
export function shell({ title, subtitle, emoji, body, navLinks = [], liveData = {} }) {
  const nav = navLinks.map(l =>
    `<a href="${l.url}" style="color:#aaa;text-decoration:none;font-size:13px;padding:4px 12px;border:1px solid #333;border-radius:20px;">${l.label}</a>`
  ).join("");

  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width,initial-scale=1"/>
  <title>${title} — BlackRoad OS</title>
  <style>
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
    :root {
      --pink: ${BRAND.pink}; --amber: ${BRAND.amber};
      --violet: ${BRAND.violet}; --blue: ${BRAND.blue};
      --dark: ${BRAND.dark}; --surface: ${BRAND.surface};
      --border: ${BRAND.border};
    }
    body {
      background: var(--dark); color: #e8e8f0;
      font-family: -apple-system, 'SF Pro Display', 'Inter', sans-serif;
      min-height: 100vh; line-height: 1.6;
    }
    .topbar {
      background: var(--surface);
      border-bottom: 1px solid var(--border);
      padding: 12px 24px;
      display: flex; align-items: center; gap: 16px;
      position: sticky; top: 0; z-index: 100;
      backdrop-filter: blur(12px);
    }
    .logo {
      background: ${BRAND.gradient};
      -webkit-background-clip: text; -webkit-text-fill-color: transparent;
      font-weight: 800; font-size: 18px; letter-spacing: -0.5px;
      text-decoration: none;
    }
    .domain-badge {
      font-size: 12px; color: #666; font-family: monospace;
      background: #1a1a24; padding: 2px 8px; border-radius: 4px;
      border: 1px solid #2a2a3a;
    }
    .nav-links { display: flex; gap: 8px; margin-left: auto; flex-wrap: wrap; }
    .pulse-dot {
      width: 8px; height: 8px; border-radius: 50%;
      background: ${BRAND.pink}; display: inline-block;
      animation: pulse 2s infinite;
    }
    @keyframes pulse {
      0%, 100% { opacity: 1; transform: scale(1); }
      50% { opacity: 0.5; transform: scale(0.8); }
    }
    .hero {
      padding: 60px 24px 40px;
      text-align: center;
      background: radial-gradient(ellipse at top, rgba(255,29,108,0.08) 0%, transparent 60%);
    }
    .hero-emoji { font-size: 48px; margin-bottom: 16px; }
    .hero-title {
      font-size: clamp(28px, 5vw, 52px);
      font-weight: 800; letter-spacing: -1.5px;
      background: ${BRAND.gradient};
      -webkit-background-clip: text; -webkit-text-fill-color: transparent;
      margin-bottom: 12px;
    }
    .hero-sub { color: #888; font-size: 16px; max-width: 540px; margin: 0 auto 24px; }
    .stats-strip {
      display: flex; gap: 16px; justify-content: center;
      flex-wrap: wrap; padding: 0 24px 32px;
    }
    .stat {
      background: var(--surface); border: 1px solid var(--border);
      border-radius: 12px; padding: 16px 24px; text-align: center;
      min-width: 120px;
    }
    .stat-val { font-size: 28px; font-weight: 700; color: ${BRAND.pink}; }
    .stat-key { font-size: 11px; color: #555; text-transform: uppercase; letter-spacing: 1px; }
    .content { max-width: 1100px; margin: 0 auto; padding: 0 24px 60px; }
    .card-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(280px, 1fr)); gap: 16px; margin: 24px 0; }
    .card {
      background: var(--surface); border: 1px solid #1e1e2e;
      border-radius: 14px; padding: 20px;
      transition: border-color 0.2s, transform 0.2s;
    }
    .card:hover { border-color: var(--pink); transform: translateY(-2px); }
    .card-title { font-size: 15px; font-weight: 600; margin-bottom: 6px; }
    .card-sub { font-size: 13px; color: #666; }
    .badge {
      display: inline-block; padding: 2px 8px; border-radius: 20px;
      font-size: 11px; font-weight: 600; letter-spacing: 0.5px;
    }
    .badge-online  { background: rgba(57,255,20,0.15); color: #39ff14; }
    .badge-standby { background: rgba(245,166,35,0.15); color: ${BRAND.amber}; }
    .badge-offline { background: rgba(255,29,108,0.15); color: ${BRAND.pink}; }
    .section-head {
      font-size: 11px; font-weight: 700; color: #444;
      text-transform: uppercase; letter-spacing: 2px;
      margin: 32px 0 12px; padding-bottom: 8px;
      border-bottom: 1px solid #1a1a24;
    }
    footer {
      text-align: center; padding: 24px;
      color: #333; font-size: 12px;
      border-top: 1px solid #1a1a24;
    }
    footer span { background: ${BRAND.gradient}; -webkit-background-clip: text; -webkit-text-fill-color: transparent; }
    .ticker {
      background: #0d0d14; border-top: 1px solid #1a1a24;
      padding: 8px 0; overflow: hidden; font-size: 12px; color: #555;
      font-family: monospace;
    }
    .ticker-inner { white-space: nowrap; animation: scroll 30s linear infinite; display: inline-block; }
    @keyframes scroll { from { transform: translateX(100vw); } to { transform: translateX(-100%); } }
  </style>
</head>
<body>
  <div class="topbar">
    <a class="logo" href="https://blackroad.io">BlackRoad OS</a>
    <span class="domain-badge">${title.toLowerCase().replace(/\s+/g, '.')}.blackroad.io</span>
    <span class="pulse-dot"></span>
    <nav class="nav-links">${nav}</nav>
  </div>
  <div class="hero">
    <div class="hero-emoji">${emoji}</div>
    <div class="hero-title">${title}</div>
    <p class="hero-sub">${subtitle}</p>
  </div>
  <div class="content">
    ${body}
  </div>
  <footer>
    <span>BlackRoad OS</span> — Your AI. Your Hardware. Your Rules. &nbsp;·&nbsp;
    Built on Cloudflare Edge &nbsp;·&nbsp; Worker v2.0
  </footer>
  <div class="ticker">
    <span class="ticker-inner">
      🖤 BlackRoad OS &nbsp;·&nbsp;
      ${Object.entries(liveData).map(([k,v]) => `${k}: ${v}`).join(" &nbsp;·&nbsp; ")}
      &nbsp;·&nbsp; Edge: ${new Date().toISOString()} &nbsp;·&nbsp;
      Agent Mesh: ONLINE &nbsp;·&nbsp; 🌐 Global CDN Active
    </span>
  </div>
</body>
</html>`;
}
