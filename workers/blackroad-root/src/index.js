/**
 * BlackRoad OS — Root Worker
 * Serves: blackroad.io, www.blackroad.io
 * Pulls live data from: GitHub API, Railway GraphQL, Cloudflare API
 */

const CF_ACCOUNT_ID = "848cf0b18d51e0170e0d1537aec3505a";

const BRAND = {
  gradient: "linear-gradient(135deg, #F5A623 0%, #FF1D6C 38.2%, #9C27B0 61.8%, #2979FF 100%)",
};

const AGENTS = [
  { id: "lucidia",  name: "Lucidia",  role: "The Dreamer",   color: "#38bdf8", emoji: "🌀", status: "online",  model: "qwen2.5:7b"  },
  { id: "alice",    name: "Alice",    role: "The Operator",  color: "#4ade80", emoji: "🚪", status: "online",  model: "llama3.2:3b" },
  { id: "octavia",  name: "Octavia",  role: "The Architect", color: "#a78bfa", emoji: "⚡", status: "online",  model: "deepseek-r1" },
  { id: "aria",     name: "Aria",     role: "The Interface", color: "#fb923c", emoji: "🎨", status: "online",  model: "qwen2.5:7b"  },
  { id: "cipher",   name: "Cipher",   role: "The Guardian",  color: "#f43f5e", emoji: "🔐", status: "standby", model: "llama3.2:3b" },
  { id: "cece",     name: "CECE",     role: "The Core",      color: "#c084fc", emoji: "💜", status: "online",  model: "claude-3-5"  },
  { id: "prism",    name: "Prism",    role: "The Analyst",   color: "#fbbf24", emoji: "🔮", status: "standby", model: "qwen2.5:7b"  },
  { id: "echo",     name: "Echo",     role: "The Librarian", color: "#34d399", emoji: "📡", status: "online",  model: "llama3.2:3b" },
];

const SERVICES = [
  { name: "Gateway",   url: "api.blackroad.io",       desc: "Tokenless AI proxy"      },
  { name: "Agents",    url: "agents.blackroad.io",    desc: "30K agent mesh"          },
  { name: "Dashboard", url: "dashboard.blackroad.io", desc: "CI/CD & deployments"    },
  { name: "Docs",      url: "docs.blackroad.io",      desc: "Documentation hub"       },
  { name: "Console",   url: "console.blackroad.io",   desc: "BR CLI reference"        },
  { name: "AI",        url: "ai.blackroad.io",        desc: "Model registry"          },
  { name: "Dev",       url: "dev.blackroad.io",       desc: "Developer hub"           },
  { name: "Analytics", url: "analytics.blackroad.io", desc: "Platform metrics"        },
  { name: "Security",  url: "security.blackroad.io",  desc: "Security posture"        },
  { name: "Network",   url: "network.blackroad.io",   desc: "Infrastructure topology" },
  { name: "Edge",      url: "edge.blackroad.io",      desc: "Edge computing layer"    },
  { name: "CDN",       url: "cdn.blackroad.io",       desc: "Content delivery"        },
];

function json(data, status = 200) {
  return new Response(JSON.stringify(data, null, 2), {
    status, headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
  });
}

async function ghFetch(env, endpoint) {
  if (!env.GITHUB_TOKEN) return null;
  try {
    const r = await fetch(`https://api.github.com${endpoint}`, {
      headers: {
        "Authorization": `Bearer ${env.GITHUB_TOKEN}`,
        "Accept": "application/vnd.github+json",
        "X-GitHub-Api-Version": "2022-11-28",
        "User-Agent": "BlackRoad-OS-Worker/2.0",
      },
    });
    return r.ok ? r.json() : null;
  } catch { return null; }
}

async function railwayGql(env, query) {
  if (!env.RAILWAY_TOKEN) return null;
  try {
    const r = await fetch("https://backboard.railway.app/graphql/v2", {
      method: "POST",
      headers: { "Authorization": `Bearer ${env.RAILWAY_TOKEN}`, "Content-Type": "application/json" },
      body: JSON.stringify({ query }),
    });
    return r.ok ? r.json() : null;
  } catch { return null; }
}

async function cfApi(env, path) {
  if (!env.CF_API_TOKEN) return null;
  try {
    const r = await fetch(`https://api.cloudflare.com/client/v4/accounts/${CF_ACCOUNT_ID}${path}`, {
      headers: { "Authorization": `Bearer ${env.CF_API_TOKEN}`, "Content-Type": "application/json" },
    });
    return r.ok ? r.json() : null;
  } catch { return null; }
}

function timeAgo(iso) {
  if (!iso) return "";
  const diff = Date.now() - new Date(iso).getTime();
  const m = Math.floor(diff / 60000);
  if (m < 1) return "just now";
  if (m < 60) return `${m}m ago`;
  const h = Math.floor(m / 60);
  if (h < 24) return `${h}h ago`;
  return `${Math.floor(h / 24)}d ago`;
}

function renderPage(stats, runs, projects, workerCount) {
  const onlineAgents = AGENTS.filter(a => a.status === "online").length;
  const latestRun = runs?.[0];
  const ciStatus = latestRun?.conclusion === "success" ? "passing" : latestRun?.conclusion || "unknown";
  const ciColor = ciStatus === "passing" ? "#4ade80" : ciStatus === "failure" ? "#f43f5e" : "#fbbf24";

  const agentCards = AGENTS.map(a => `
    <div class="agent-card">
      <div class="agent-top">
        <span class="agent-emoji">${a.emoji}</span>
        <span class="badge ${a.status === "online" ? "green" : "yellow"}">${a.status}</span>
      </div>
      <div class="agent-name" style="color:${a.color}">${a.name}</div>
      <div class="agent-role">${a.role}</div>
      <div class="agent-model">${a.model}</div>
    </div>`).join("");

  const serviceLinks = SERVICES.map(s => `
    <a class="service-card" href="https://${s.url}">
      <div class="service-name">${s.name}</div>
      <div class="service-url">${s.url}</div>
      <div class="service-desc">${s.desc}</div>
    </a>`).join("");

  const runRows = (runs || []).slice(0, 5).map(r => `
    <tr>
      <td>${(r.name || "").slice(0, 40)}</td>
      <td><span style="color:${r.conclusion === "success" ? "#4ade80" : r.conclusion === "failure" ? "#f43f5e" : "#fbbf24"};font-size:11px;font-weight:600;">${r.conclusion || r.status}</span></td>
      <td style="color:#555;font-size:12px;">${r.head_branch}</td>
      <td style="color:#555;font-size:12px;">${timeAgo(r.updated_at)}</td>
    </tr>`).join("");

  const ts = new Date().toISOString();

  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta http-equiv="refresh" content="120">
  <title>BlackRoad OS — Your AI. Your Hardware. Your Rules.</title>
  <style>
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
    :root {
      --amber: #F5A623; --pink: #FF1D6C; --violet: #9C27B0; --blue: #2979FF;
      --bg: #000; --surface: #0a0a0a; --border: #1a1a1a; --surface2: #111;
      --text: #fff; --muted: #555; --dim: #333;
      --gradient: linear-gradient(135deg, var(--amber) 0%, var(--pink) 38.2%, var(--violet) 61.8%, var(--blue) 100%);
      --radius: 12px; --font: -apple-system, BlinkMacSystemFont, 'SF Pro Display', sans-serif;
    }
    body { background: var(--bg); color: var(--text); font-family: var(--font); min-height: 100vh; }

    /* Gradient bar */
    .gradient-bar { height: 3px; background: var(--gradient); }

    /* Hero */
    .hero { padding: 60px 48px 48px; border-bottom: 1px solid var(--border); }
    .eyebrow { font-size: 11px; font-weight: 600; letter-spacing: 0.2em; text-transform: uppercase; color: var(--muted); margin-bottom: 16px; }
    .hero-title { font-size: clamp(36px, 6vw, 72px); font-weight: 800; line-height: 1.0;
      background: var(--gradient); -webkit-background-clip: text; -webkit-text-fill-color: transparent; background-clip: text; }
    .hero-sub { margin-top: 16px; font-size: 18px; color: var(--muted); line-height: 1.618; max-width: 600px; }
    .hero-nav { display: flex; gap: 12px; flex-wrap: wrap; margin-top: 24px; }
    .btn { padding: 10px 20px; border-radius: 8px; font-size: 13px; font-weight: 600; text-decoration: none; transition: all 0.15s; }
    .btn-primary { background: var(--pink); color: #fff; }
    .btn-primary:hover { opacity: 0.85; }
    .btn-secondary { background: transparent; color: var(--text); border: 1px solid var(--border); }
    .btn-secondary:hover { border-color: var(--dim); }

    /* Stats */
    .stats { display: grid; grid-template-columns: repeat(auto-fit, minmax(160px, 1fr)); gap: 1px; background: var(--border); border-top: 1px solid var(--border); border-bottom: 1px solid var(--border); }
    .stat { background: var(--bg); padding: 24px 32px; }
    .stat-value { font-size: 28px; font-weight: 700; }
    .stat-label { font-size: 11px; font-weight: 600; letter-spacing: 0.1em; text-transform: uppercase; color: var(--muted); margin-top: 4px; }

    /* Content */
    .content { padding: 48px; }
    .section { margin-bottom: 56px; }
    .section-title { font-size: 12px; font-weight: 600; letter-spacing: 0.12em; text-transform: uppercase; color: var(--muted); margin-bottom: 20px; padding-bottom: 10px; border-bottom: 1px solid var(--border); }

    /* Service grid */
    .service-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(220px, 1fr)); gap: 12px; }
    .service-card { display: block; text-decoration: none; background: var(--surface); border: 1px solid var(--border); border-radius: var(--radius); padding: 16px 18px; transition: all 0.15s; }
    .service-card:hover { border-color: var(--dim); transform: translateY(-1px); }
    .service-name { font-size: 14px; font-weight: 600; color: var(--text); }
    .service-url { font-size: 11px; color: var(--pink); margin: 2px 0 6px; }
    .service-desc { font-size: 12px; color: var(--muted); }

    /* Agents */
    .agent-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(160px, 1fr)); gap: 12px; }
    .agent-card { background: var(--surface); border: 1px solid var(--border); border-radius: var(--radius); padding: 16px; }
    .agent-top { display: flex; align-items: center; justify-content: space-between; margin-bottom: 10px; }
    .agent-emoji { font-size: 24px; }
    .agent-name { font-size: 15px; font-weight: 700; margin-bottom: 2px; }
    .agent-role { font-size: 11px; color: var(--muted); }
    .agent-model { font-size: 11px; color: var(--dim); margin-top: 6px; font-family: 'SF Mono', monospace; }
    .badge { display: inline-flex; align-items: center; gap: 4px; padding: 2px 8px; border-radius: 12px; font-size: 10px; font-weight: 600; }
    .badge::before { content:''; width:5px; height:5px; border-radius:50%; background:currentColor; }
    .badge.green { background:rgba(74,222,128,.1); color:#4ade80; border:1px solid rgba(74,222,128,.2); }
    .badge.yellow { background:rgba(251,191,36,.1); color:#fbbf24; border:1px solid rgba(251,191,36,.2); }

    /* CI Table */
    .table { width: 100%; border-collapse: collapse; }
    .table th { font-size: 11px; font-weight: 600; letter-spacing: 0.1em; text-transform: uppercase; color: var(--muted); padding: 8px 12px; text-align: left; border-bottom: 1px solid var(--border); }
    .table td { padding: 10px 12px; border-bottom: 1px solid var(--surface2); font-size: 13px; }

    /* CI status indicator */
    .ci-status { display: inline-flex; align-items: center; gap: 8px; padding: 6px 14px; border-radius: 8px; font-size: 13px; font-weight: 600; background: var(--surface); border: 1px solid; }

    .footer { padding: 24px 48px; border-top: 1px solid var(--border); display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 12px; }
    .footer-links { display: flex; gap: 20px; }
    .footer-link { font-size: 12px; color: var(--muted); text-decoration: none; }
    .footer-link:hover { color: var(--text); }
    @media(max-width:600px){ .hero,.content{ padding:24px; } .stats .stat { padding: 16px 24px; } }
  </style>
</head>
<body>
  <div class="gradient-bar"></div>
  <div class="hero">
    <div class="eyebrow">BlackRoad OS · Sovereign AI Infrastructure</div>
    <h1 class="hero-title">Your AI.<br>Your Hardware.<br>Your Rules.</h1>
    <p class="hero-sub">30,000-agent orchestration platform. 17 GitHub orgs. 1,825+ repositories. Built for digital sovereignty.</p>
    <nav class="hero-nav">
      <a class="btn btn-primary" href="https://agents.blackroad.io">View Agents</a>
      <a class="btn btn-secondary" href="https://docs.blackroad.io">Documentation</a>
      <a class="btn btn-secondary" href="https://dashboard.blackroad.io">Dashboard</a>
      <a class="btn btn-secondary" href="https://console.blackroad.io">CLI Reference</a>
    </nav>
  </div>

  <div class="stats">
    <div class="stat">
      <div class="stat-value" style="background:${BRAND.gradient};-webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text">${stats.repos ?? "1,825+"}</div>
      <div class="stat-label">Repositories</div>
    </div>
    <div class="stat">
      <div class="stat-value">${workerCount ?? "75+"}</div>
      <div class="stat-label">Edge Workers</div>
    </div>
    <div class="stat">
      <div class="stat-value">${projects?.length ?? "14"}</div>
      <div class="stat-label">Railway Projects</div>
    </div>
    <div class="stat">
      <div class="stat-value">${onlineAgents}/${AGENTS.length}</div>
      <div class="stat-label">Agents Online</div>
    </div>
    <div class="stat">
      <div class="stat-value" style="color:${ciColor}">${ciStatus}</div>
      <div class="stat-label">CI Status</div>
    </div>
  </div>

  <div class="content">
    <div class="section">
      <div class="section-title">Platform Services</div>
      <div class="service-grid">${serviceLinks}</div>
    </div>

    <div class="section">
      <div class="section-title">Agent Mesh · ${onlineAgents} online · 30,000 capacity</div>
      <div class="agent-grid">${agentCards}</div>
    </div>

    ${runs?.length ? `<div class="section">
      <div class="section-title">Recent CI Runs</div>
      <table class="table">
        <thead><tr><th>Workflow</th><th>Status</th><th>Branch</th><th>Updated</th></tr></thead>
        <tbody>${runRows}</tbody>
      </table>
    </div>` : ""}

    ${projects?.length ? `<div class="section">
      <div class="section-title">Railway Projects (${projects.length})</div>
      <div style="display:flex;gap:10px;flex-wrap:wrap;">
        ${projects.map(p => `<span style="background:var(--surface);border:1px solid var(--border);border-radius:8px;padding:6px 12px;font-size:12px;">⚡ ${p.name}</span>`).join("")}
      </div>
    </div>` : ""}
  </div>

  <div class="footer">
    <span style="font-size:12px;color:var(--muted)">© BlackRoad OS, Inc. · ${ts.slice(0,10)}</span>
    <div class="footer-links">
      <a class="footer-link" href="https://github.com/BlackRoad-OS-Inc">GitHub</a>
      <a class="footer-link" href="https://api.blackroad.io">API</a>
      <a class="footer-link" href="https://docs.blackroad.io">Docs</a>
      <a class="footer-link" href="https://console.blackroad.io">CLI</a>
    </div>
  </div>
</body>
</html>`;
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const path = url.pathname;

    // CORS preflight
    if (request.method === "OPTIONS") {
      return new Response(null, { headers: { "Access-Control-Allow-Origin": "*", "Access-Control-Allow-Methods": "GET", "Access-Control-Max-Age": "86400" } });
    }

    if (path === "/health") {
      return json({ status: "ok", worker: "blackroad-root", ts: new Date().toISOString() });
    }

    if (path === "/api" || path === "/api/status") {
      const [runs, workers] = await Promise.allSettled([
        ghFetch(env, "/repos/BlackRoad-OS-Inc/blackroad/actions/runs?per_page=5"),
        cfApi(env, "/workers/scripts?per_page=100"),
      ]);
      const r = runs.status === "fulfilled" ? runs.value : null;
      const w = workers.status === "fulfilled" ? workers.value : null;
      return json({
        status: "operational",
        version: "2.0.0",
        agents: { total: AGENTS.length, online: AGENTS.filter(a => a.status === "online").length, capacity: 30000 },
        workers: { count: w?.result?.length ?? null },
        ci: r?.workflow_runs?.[0]?.conclusion ?? "unknown",
        ts: new Date().toISOString(),
      });
    }

    if (path === "/api/agents") {
      return json({ total: AGENTS.length, online: AGENTS.filter(a => a.status === "online").length, capacity: 30000, agents: AGENTS });
    }

    // Main HTML dashboard
    const [ghRuns, railway, cfWorkers, ghOrg] = await Promise.allSettled([
      ghFetch(env, "/repos/BlackRoad-OS-Inc/blackroad/actions/runs?per_page=10"),
      railwayGql(env, `query{me{projects{edges{node{id name updatedAt services{edges{node{id name}}}}}}}}}`),
      cfApi(env, "/workers/scripts?per_page=100"),
      ghFetch(env, "/orgs/BlackRoad-OS"),
    ]);

    const runs = ghRuns.status === "fulfilled" ? (ghRuns.value?.workflow_runs ?? []) : [];
    const projects = railway.status === "fulfilled"
      ? (railway.value?.data?.me?.projects?.edges?.map(e => ({ id: e.node.id, name: e.node.name })) ?? [])
      : [];
    const workerCount = cfWorkers.status === "fulfilled" ? (cfWorkers.value?.result?.length ?? null) : null;
    const orgStats = ghOrg.status === "fulfilled" ? ghOrg.value : null;
    const stats = { repos: orgStats?.public_repos ?? "1,825+" };

    return new Response(renderPage(stats, runs, projects, workerCount), {
      headers: { "Content-Type": "text/html; charset=utf-8", "Cache-Control": "public, max-age=60" },
    });
  },
};
