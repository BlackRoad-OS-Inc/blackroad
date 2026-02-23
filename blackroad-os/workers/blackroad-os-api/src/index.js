/**
 * BlackRoad OS API Worker
 * Public-facing API + branded dashboard + Railway + GitHub integration
 * https://blackroad-os-api.amundsonalexa.workers.dev
 *
 * Secrets (set via: wrangler secret put <NAME>):
 *   RAILWAY_TOKEN   — Railway API token
 *   GITHUB_TOKEN    — GitHub personal access token
 */

const AGENTS = [
  { id: "lucidia",  name: "Lucidia",  role: "The Dreamer",   color: "#38bdf8", emoji: "🌀", status: "online",  model: "qwen2.5:7b"   },
  { id: "alice",    name: "Alice",    role: "The Operator",  color: "#4ade80", emoji: "🚪", status: "online",  model: "llama3.2:3b"  },
  { id: "octavia",  name: "Octavia",  role: "The Architect", color: "#a78bfa", emoji: "⚡", status: "online",  model: "deepseek-r1"  },
  { id: "aria",     name: "Aria",     role: "The Interface", color: "#fb923c", emoji: "🎨", status: "online",  model: "qwen2.5:7b"   },
  { id: "cipher",   name: "Cipher",   role: "The Guardian",  color: "#f43f5e", emoji: "🔐", status: "standby", model: "llama3.2:3b"  },
  { id: "cece",     name: "CECE",     role: "The Core",      color: "#c084fc", emoji: "💜", status: "online",  model: "claude-3-5"   },
  { id: "prism",    name: "Prism",    role: "The Analyst",   color: "#fbbf24", emoji: "🔮", status: "standby", model: "qwen2.5:7b"   },
  { id: "echo",     name: "Echo",     role: "The Librarian", color: "#34d399", emoji: "📡", status: "online",  model: "llama3.2:3b"  },
];

const BRAND = {
  gradient: "linear-gradient(135deg, #F5A623 0%, #FF1D6C 38.2%, #9C27B0 61.8%, #2979FF 100%)",
  amber: "#F5A623",
  pink: "#FF1D6C",
  violet: "#9C27B0",
  blue: "#2979FF",
};

// ── HTML Dashboard ──────────────────────────────────────────
function renderDashboard(req) {
  const online = AGENTS.filter(a => a.status === "online").length;
  const agentCards = AGENTS.map(a => `
    <div class="agent-card ${a.status}">
      <div class="agent-emoji">${a.emoji}</div>
      <div class="agent-info">
        <div class="agent-name">${a.name}</div>
        <div class="agent-role">${a.role}</div>
        <div class="agent-model">${a.model}</div>
      </div>
      <div class="agent-status ${a.status}">${a.status}</div>
    </div>`).join("");

  const ts = new Date().toISOString();

  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>BlackRoad OS — Agent Dashboard</title>
  <style>
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
    :root {
      --amber: #F5A623; --pink: #FF1D6C; --violet: #9C27B0; --blue: #2979FF;
      --bg: #000; --surface: #0a0a0a; --border: #1a1a1a;
      --text: #fff; --muted: #666;
      --gradient: linear-gradient(135deg, var(--amber) 0%, var(--pink) 38.2%, var(--violet) 61.8%, var(--blue) 100%);
      --radius: 12px; --font: -apple-system, BlinkMacSystemFont, 'SF Pro Display', sans-serif;
    }
    body { background: var(--bg); color: var(--text); font-family: var(--font); min-height: 100vh; }

    /* Header */
    .header {
      padding: 40px 40px 0;
      border-bottom: 1px solid var(--border);
      padding-bottom: 32px;
    }
    .logo {
      font-size: 13px; font-weight: 600; letter-spacing: 0.15em;
      text-transform: uppercase; color: var(--muted);
      margin-bottom: 16px;
    }
    .title {
      font-size: clamp(28px, 4vw, 48px);
      font-weight: 700; line-height: 1.1;
      background: var(--gradient);
      -webkit-background-clip: text; -webkit-text-fill-color: transparent;
      background-clip: text;
    }
    .subtitle { color: var(--muted); margin-top: 8px; font-size: 15px; }

    /* Stats bar */
    .stats {
      display: flex; gap: 32px; padding: 24px 40px;
      border-bottom: 1px solid var(--border);
    }
    .stat { display: flex; flex-direction: column; gap: 4px; }
    .stat-val { font-size: 24px; font-weight: 700; }
    .stat-label { font-size: 11px; text-transform: uppercase; letter-spacing: 0.1em; color: var(--muted); }
    .stat-val.green { color: #4ade80; }
    .stat-val.amber { color: var(--amber); }
    .stat-val.pink  { color: var(--pink); }

    /* Agents grid */
    .section { padding: 32px 40px; }
    .section-title {
      font-size: 11px; text-transform: uppercase; letter-spacing: 0.15em;
      color: var(--muted); margin-bottom: 20px;
    }
    .agents { display: grid; grid-template-columns: repeat(auto-fill, minmax(280px, 1fr)); gap: 12px; }
    .agent-card {
      background: var(--surface); border: 1px solid var(--border);
      border-radius: var(--radius); padding: 16px 20px;
      display: flex; align-items: center; gap: 16px;
      transition: border-color 0.2s;
    }
    .agent-card:hover { border-color: #333; }
    .agent-card.online { border-left: 3px solid #4ade80; }
    .agent-card.standby { border-left: 3px solid #444; }
    .agent-emoji { font-size: 24px; flex-shrink: 0; }
    .agent-info { flex: 1; min-width: 0; }
    .agent-name { font-weight: 600; font-size: 15px; }
    .agent-role { color: var(--muted); font-size: 12px; margin-top: 2px; }
    .agent-model { color: #444; font-size: 11px; margin-top: 4px; font-family: monospace; }
    .agent-status { font-size: 10px; text-transform: uppercase; letter-spacing: 0.1em; padding: 3px 8px; border-radius: 20px; }
    .agent-status.online  { background: rgba(74,222,128,0.1); color: #4ade80; }
    .agent-status.standby { background: rgba(100,100,100,0.1); color: #666; }

    /* API reference */
    .api { display: flex; flex-direction: column; gap: 8px; }
    .endpoint {
      display: flex; align-items: center; gap: 12px;
      background: var(--surface); border: 1px solid var(--border);
      border-radius: 8px; padding: 12px 16px; font-family: monospace; font-size: 13px;
    }
    .method { color: var(--amber); font-weight: 700; min-width: 36px; }
    .path { color: var(--text); }
    .desc { color: var(--muted); margin-left: auto; font-size: 11px; font-family: var(--font); }

    /* Footer */
    .footer {
      padding: 24px 40px; border-top: 1px solid var(--border);
      display: flex; justify-content: space-between; align-items: center;
      color: var(--muted); font-size: 12px;
    }
    .dot { display: inline-block; width: 6px; height: 6px; border-radius: 50%; background: #4ade80; margin-right: 6px; animation: pulse 2s infinite; }
    @keyframes pulse { 0%,100%{opacity:1} 50%{opacity:0.4} }
    .gradient-bar { height: 3px; background: var(--gradient); }
  </style>
</head>
<body>
  <div class="gradient-bar"></div>

  <div class="header">
    <div class="logo">◆ BlackRoad OS</div>
    <div class="title">Agent Dashboard</div>
    <div class="subtitle">30,000 AI agents. One platform. Your rules.</div>
  </div>

  <div class="stats">
    <div class="stat">
      <div class="stat-val green">${online}</div>
      <div class="stat-label">Online</div>
    </div>
    <div class="stat">
      <div class="stat-val amber">${AGENTS.length}</div>
      <div class="stat-label">Agents</div>
    </div>
    <div class="stat">
      <div class="stat-val pink">30,000</div>
      <div class="stat-label">Capacity</div>
    </div>
    <div class="stat">
      <div class="stat-val" style="color:var(--blue)">v2.0</div>
      <div class="stat-label">Version</div>
    </div>
  </div>

  <div class="section">
    <div class="section-title"><span class="dot"></span>Active Agents</div>
    <div class="agents">${agentCards}</div>
  </div>

  <div class="section">
    <div class="section-title">API Reference</div>
    <div class="api">
      <div class="endpoint"><span class="method">GET</span><span class="path">/</span><span class="desc">This dashboard</span></div>
      <div class="endpoint"><span class="method">GET</span><span class="path">/health</span><span class="desc">Health check</span></div>
      <div class="endpoint"><span class="method">GET</span><span class="path">/agents</span><span class="desc">Agent registry JSON</span></div>
      <div class="endpoint"><span class="method">GET</span><span class="path">/agents/:id</span><span class="desc">Single agent</span></div>
      <div class="endpoint"><span class="method">GET</span><span class="path">/status</span><span class="desc">Platform status</span></div>
      <div class="endpoint"><span class="method">GET</span><span class="path">/railway</span><span class="desc">Railway projects live status</span></div>
      <div class="endpoint"><span class="method">GET</span><span class="path">/railway/deployments?project=ID</span><span class="desc">Railway deployments</span></div>
      <div class="endpoint"><span class="method">GET</span><span class="path">/github/runs</span><span class="desc">GitHub Actions runs</span></div>
      <div class="endpoint"><span class="method">GET</span><span class="path">/github/repo</span><span class="desc">Repo stats</span></div>
    </div>
  </div>

  <div class="footer">
    <span>© BlackRoad OS, Inc. All rights reserved.</span>
    <span>Last refreshed: ${ts}</span>
  </div>
</body>
</html>`;
}

// ── Request Handler ─────────────────────────────────────────
export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const path = url.pathname;

    const json = (data, status = 200) => new Response(JSON.stringify(data, null, 2), {
      status,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
        "X-Powered-By": "BlackRoad OS",
      },
    });

    const html = (body) => new Response(body, {
      headers: {
        "Content-Type": "text/html;charset=UTF-8",
        "X-Powered-By": "BlackRoad OS",
      },
    });

    // Route
    if (path === "/" || path === "/dashboard") {
      return html(renderDashboard(request));
    }

    if (path === "/health") {
      return json({
        status: "ok",
        service: "blackroad-os-api",
        version: env.VERSION || "2.0.0",
        timestamp: new Date().toISOString(),
        agents_online: AGENTS.filter(a => a.status === "online").length,
        agents_total: AGENTS.length,
      });
    }

    if (path === "/agents") {
      return json({
        org: env.ORG || "BlackRoad OS",
        total: AGENTS.length,
        online: AGENTS.filter(a => a.status === "online").length,
        agents: AGENTS,
      });
    }

    if (path.startsWith("/agents/")) {
      const id = path.split("/")[2];
      const agent = AGENTS.find(a => a.id === id);
      if (!agent) return json({ error: "agent not found", id }, 404);
      return json({
        ...agent,
        email: `${agent.id}@blackroad.io`,
        endpoint: `https://blackroad-os-api.blackroad.workers.dev/agents/${agent.id}`,
      });
    }

    if (path === "/status") {
      return json({
        status: "operational",
        version: env.VERSION || "2.0.0",
        org: env.ORG || "BlackRoad OS",
        capacity: 30000,
        agents: {
          total: AGENTS.length,
          online: AGENTS.filter(a => a.status === "online").length,
          standby: AGENTS.filter(a => a.status === "standby").length,
        },
        services: {
          gateway: "operational",
          email_router: "operational",
          agent_mesh: "operational",
          kv_store: "operational",
          railway: env.RAILWAY_TOKEN ? "connected" : "no_token",
          github: env.GITHUB_TOKEN ? "connected" : "no_token",
        },
        timestamp: new Date().toISOString(),
      });
    }

    // ── Railway ──────────────────────────────────────────────
    if (path === "/railway" || path.startsWith("/railway/")) {
      if (!env.RAILWAY_TOKEN) {
        return json({ error: "RAILWAY_TOKEN not set", hint: "wrangler secret put RAILWAY_TOKEN" }, 503);
      }
      const sub = path.split("/")[2] || "projects";

      // Railway GraphQL API
      const gql = async (query, vars = {}) => {
        const r = await fetch("https://backboard.railway.app/graphql/v2", {
          method: "POST",
          headers: {
            "Authorization": `Bearer ${env.RAILWAY_TOKEN}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({ query, variables: vars }),
        });
        return r.json();
      };

      if (sub === "projects" || sub === "") {
        const data = await gql(`query {
          me {
            projects {
              edges {
                node {
                  id name createdAt updatedAt
                  services { edges { node { id name } } }
                  environments { edges { node { id name } } }
                }
              }
            }
          }
        }`);
        const projects = data?.data?.me?.projects?.edges?.map(e => ({
          id: e.node.id,
          name: e.node.name,
          services: e.node.services?.edges?.length || 0,
          environments: e.node.environments?.edges?.length || 0,
          updated: e.node.updatedAt,
        })) || [];
        return json({ source: "railway", total: projects.length, projects });
      }

      if (sub === "deployments") {
        const projectId = url.searchParams.get("project");
        const data = await gql(`query($projectId: String) {
          deployments(input: { projectId: $projectId }) {
            edges {
              node {
                id status createdAt
                meta { branch commitMessage author }
                service { id name }
              }
            }
          }
        }`, { projectId });
        const deploys = data?.data?.deployments?.edges?.map(e => ({
          id: e.node.id,
          status: e.node.status,
          service: e.node.service?.name,
          branch: e.node.meta?.branch,
          message: e.node.meta?.commitMessage,
          author: e.node.meta?.author,
          created: e.node.createdAt,
        })) || [];
        return json({ source: "railway", total: deploys.length, deployments: deploys });
      }

      return json({ error: "unknown railway path", available: ["/railway", "/railway/deployments?project=ID"] }, 404);
    }

    // ── GitHub ────────────────────────────────────────────────
    if (path === "/github" || path.startsWith("/github/")) {
      if (!env.GITHUB_TOKEN) {
        return json({ error: "GITHUB_TOKEN not set", hint: "wrangler secret put GITHUB_TOKEN" }, 503);
      }
      const sub = path.split("/")[2] || "runs";
      const org  = url.searchParams.get("org")  || env.GITHUB_ORG  || "BlackRoad-OS-Inc";
      const repo = url.searchParams.get("repo") || env.GITHUB_REPO || "blackroad";

      const ghFetch = async (endpoint) => {
        const r = await fetch(`https://api.github.com${endpoint}`, {
          headers: {
            "Authorization": `Bearer ${env.GITHUB_TOKEN}`,
            "Accept": "application/vnd.github+json",
            "X-GitHub-Api-Version": "2022-11-28",
            "User-Agent": "BlackRoad-OS-Worker/2.0",
          },
        });
        return r.json();
      };

      if (sub === "runs" || sub === "") {
        const data = await ghFetch(`/repos/${org}/${repo}/actions/runs?per_page=10`);
        const runs = (data.workflow_runs || []).map(r => ({
          id: r.id,
          name: r.name,
          status: r.status,
          conclusion: r.conclusion,
          branch: r.head_branch,
          commit: r.head_sha?.slice(0, 8),
          actor: r.actor?.login,
          created: r.created_at,
          updated: r.updated_at,
          url: r.html_url,
        }));
        return json({ source: "github", repo: `${org}/${repo}`, total: runs.length, runs });
      }

      if (sub === "repo") {
        const data = await ghFetch(`/repos/${org}/${repo}`);
        return json({
          source: "github",
          name: data.full_name,
          description: data.description,
          stars: data.stargazers_count,
          forks: data.forks_count,
          open_issues: data.open_issues_count,
          default_branch: data.default_branch,
          updated: data.updated_at,
          url: data.html_url,
        });
      }

      if (sub === "orgs") {
        const data = await ghFetch(`/users/${org}/repos?type=owner&per_page=10&sort=updated`);
        const repos = (Array.isArray(data) ? data : []).map(r => ({
          name: r.name,
          description: r.description,
          stars: r.stargazers_count,
          updated: r.updated_at,
          url: r.html_url,
        }));
        return json({ source: "github", org, total: repos.length, repos });
      }

      return json({ error: "unknown github path", available: ["/github/runs", "/github/repo", "/github/orgs"] }, 404);
    }

    // 404
    return json({ error: "not found", path }, 404);
  },
};
