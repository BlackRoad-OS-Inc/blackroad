/**
 * BlackRoad OS — Shared Worker Utilities
 * Import or copy into each domain worker
 */

export const CF_ACCOUNT_ID = "848cf0b18d51e0170e0d1537aec3505a";

export const BRAND = {
  gradient: "linear-gradient(135deg, #F5A623 0%, #FF1D6C 38.2%, #9C27B0 61.8%, #2979FF 100%)",
  amber: "#F5A623", pink: "#FF1D6C", violet: "#9C27B0", blue: "#2979FF",
};

export const AGENTS = [
  { id: "lucidia",  name: "Lucidia",  role: "The Dreamer",   color: "#38bdf8", emoji: "🌀", status: "online",  model: "qwen2.5:7b"  },
  { id: "alice",    name: "Alice",    role: "The Operator",  color: "#4ade80", emoji: "🚪", status: "online",  model: "llama3.2:3b" },
  { id: "octavia",  name: "Octavia",  role: "The Architect", color: "#a78bfa", emoji: "⚡", status: "online",  model: "deepseek-r1" },
  { id: "aria",     name: "Aria",     role: "The Interface", color: "#fb923c", emoji: "🎨", status: "online",  model: "qwen2.5:7b"  },
  { id: "cipher",   name: "Cipher",   role: "The Guardian",  color: "#f43f5e", emoji: "��", status: "standby", model: "llama3.2:3b" },
  { id: "cece",     name: "CECE",     role: "The Core",      color: "#c084fc", emoji: "💜", status: "online",  model: "claude-3-5"  },
  { id: "prism",    name: "Prism",    role: "The Analyst",   color: "#fbbf24", emoji: "🔮", status: "standby", model: "qwen2.5:7b"  },
  { id: "echo",     name: "Echo",     role: "The Librarian", color: "#34d399", emoji: "📡", status: "online",  model: "llama3.2:3b" },
];

export const CSS_BASE = `
*, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
:root {
  --amber: #F5A623; --pink: #FF1D6C; --violet: #9C27B0; --blue: #2979FF;
  --bg: #000; --surface: #0a0a0a; --border: #1a1a1a; --surface2: #111;
  --text: #fff; --muted: #555; --dim: #333;
  --gradient: linear-gradient(135deg, var(--amber) 0%, var(--pink) 38.2%, var(--violet) 61.8%, var(--blue) 100%);
  --radius: 12px; --font: -apple-system, BlinkMacSystemFont, 'SF Pro Display', sans-serif;
}
body { background: var(--bg); color: var(--text); font-family: var(--font); min-height: 100vh; }
.header { padding: 40px; border-bottom: 1px solid var(--border); }
.eyebrow { font-size: 11px; font-weight: 600; letter-spacing: 0.15em; text-transform: uppercase; color: var(--muted); margin-bottom: 12px; }
.title { font-size: clamp(28px, 4vw, 52px); font-weight: 700; line-height: 1.1;
  background: var(--gradient); -webkit-background-clip: text; -webkit-text-fill-color: transparent; background-clip: text; }
.subtitle { margin-top: 8px; font-size: 15px; color: var(--muted); line-height: 1.618; }
.content { padding: 40px; max-width: 1400px; }
.gradient-bar { height: 2px; background: var(--gradient); border-radius: 1px; margin-bottom: 40px; }
.grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(260px, 1fr)); gap: 16px; }
.card { background: var(--surface); border: 1px solid var(--border); border-radius: var(--radius); padding: 20px; transition: border-color 0.2s; }
.card:hover { border-color: var(--dim); }
.card-eyebrow { font-size: 11px; font-weight: 600; letter-spacing: 0.1em; text-transform: uppercase; color: var(--muted); margin-bottom: 8px; }
.card-value { font-size: 32px; font-weight: 700; }
.card-sub { font-size: 12px; color: var(--muted); margin-top: 4px; }
.badge { display: inline-flex; align-items: center; gap: 5px; padding: 3px 10px; border-radius: 20px; font-size: 11px; font-weight: 600; letter-spacing: 0.05em; }
.badge::before { content: ''; width: 6px; height: 6px; border-radius: 50%; background: currentColor; }
.badge.green { background: rgba(74,222,128,.1); color: #4ade80; border: 1px solid rgba(74,222,128,.2); }
.badge.yellow { background: rgba(251,191,36,.1); color: #fbbf24; border: 1px solid rgba(251,191,36,.2); }
.badge.red { background: rgba(244,63,94,.1); color: #f43f5e; border: 1px solid rgba(244,63,94,.2); }
.badge.blue { background: rgba(41,121,255,.1); color: #60a5fa; border: 1px solid rgba(41,121,255,.2); }
.section { margin-top: 48px; }
.section-title { font-size: 12px; font-weight: 600; letter-spacing: 0.12em; text-transform: uppercase; color: var(--muted); margin-bottom: 16px; padding-bottom: 8px; border-bottom: 1px solid var(--border); }
.table { width: 100%; border-collapse: collapse; }
.table th { font-size: 11px; font-weight: 600; letter-spacing: 0.1em; text-transform: uppercase; color: var(--muted); padding: 8px 12px; text-align: left; border-bottom: 1px solid var(--border); }
.table td { padding: 10px 12px; border-bottom: 1px solid #0d0d0d; font-size: 13px; }
.table tr:last-child td { border-bottom: none; }
.code { background: var(--surface2); border: 1px solid var(--border); border-radius: 8px; padding: 16px 20px; font-family: 'SF Mono', 'Fira Code', monospace; font-size: 13px; line-height: 1.6; overflow-x: auto; color: #e2e8f0; }
.link { color: var(--pink); text-decoration: none; font-weight: 500; }
.link:hover { text-decoration: underline; }
.nav { display: flex; gap: 8px; flex-wrap: wrap; margin-top: 16px; }
.nav-link { padding: 6px 14px; border-radius: 8px; font-size: 13px; font-weight: 500; text-decoration: none; color: var(--muted); border: 1px solid var(--border); transition: all 0.15s; }
.nav-link:hover { color: var(--text); border-color: var(--dim); }
.ts { font-size: 11px; color: var(--dim); margin-top: 48px; padding-top: 16px; border-top: 1px solid var(--border); }
@media (max-width: 600px) { .header, .content { padding: 24px; } }
`;

export function json(data, status = 200) {
  return new Response(JSON.stringify(data, null, 2), {
    status, headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
  });
}

export function html(content, status = 200) {
  return new Response(content, {
    status, headers: { "Content-Type": "text/html; charset=utf-8" },
  });
}

export function page(title, eyebrow, subtitle, body, navLinks = []) {
  const nav = navLinks.map(([label, href]) =>
    `<a class="nav-link" href="${href}">${label}</a>`).join("");
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${title} — BlackRoad OS</title>
  <style>${CSS_BASE}</style>
</head>
<body>
  <div class="gradient-bar"></div>
  <div class="header">
    <div class="eyebrow">BlackRoad OS · ${eyebrow}</div>
    <h1 class="title">${title}</h1>
    <p class="subtitle">${subtitle}</p>
    <nav class="nav">${nav}</nav>
  </div>
  <div class="content">
    ${body}
    <p class="ts">Generated ${new Date().toISOString()} · <a class="link" href="https://github.com/BlackRoad-OS-Inc/blackroad">GitHub</a> · <a class="link" href="https://api.blackroad.io/health">API Health</a></p>
  </div>
</body>
</html>`;
}

export async function ghFetch(env, endpoint) {
  const token = env.BR_GITHUB_TOKEN || env.GITHUB_TOKEN;
  if (!token) return null;
  try {
    const r = await fetch(`https://api.github.com${endpoint}`, {
      headers: {
        "Authorization": `Bearer ${token}`,
        "Accept": "application/vnd.github+json",
        "X-GitHub-Api-Version": "2022-11-28",
        "User-Agent": "BlackRoad-OS-Worker/2.0",
      },
    });
    return r.ok ? r.json() : null;
  } catch { return null; }
}

export async function railwayGql(env, query, vars = {}) {
  if (!env.RAILWAY_TOKEN) return null;
  try {
    const r = await fetch("https://backboard.railway.app/graphql/v2", {
      method: "POST",
      headers: { "Authorization": `Bearer ${env.RAILWAY_TOKEN}`, "Content-Type": "application/json" },
      body: JSON.stringify({ query, variables: vars }),
    });
    return r.ok ? r.json() : null;
  } catch { return null; }
}

export async function cfApi(env, path) {
  if (!env.CF_API_TOKEN) return null;
  try {
    const r = await fetch(`https://api.cloudflare.com/client/v4/accounts/${CF_ACCOUNT_ID}${path}`, {
      headers: { "Authorization": `Bearer ${env.CF_API_TOKEN}`, "Content-Type": "application/json" },
    });
    return r.ok ? r.json() : null;
  } catch { return null; }
}

export function timeAgo(iso) {
  const diff = Date.now() - new Date(iso).getTime();
  const m = Math.floor(diff / 60000);
  if (m < 1) return "just now";
  if (m < 60) return `${m}m ago`;
  const h = Math.floor(m / 60);
  if (h < 24) return `${h}h ago`;
  return `${Math.floor(h / 24)}d ago`;
}

export function statusBadge(status) {
  const s = (status || "").toLowerCase();
  if (["success", "completed", "online", "active", "operational", "passing"].some(x => s.includes(x)))
    return `<span class="badge green">●&nbsp;${status}</span>`;
  if (["failure", "failed", "error", "offline"].some(x => s.includes(x)))
    return `<span class="badge red">●&nbsp;${status}</span>`;
  if (["pending", "in_progress", "queued", "standby", "running"].some(x => s.includes(x)))
    return `<span class="badge yellow">●&nbsp;${status}</span>`;
  return `<span class="badge blue">●&nbsp;${status}</span>`;
}
