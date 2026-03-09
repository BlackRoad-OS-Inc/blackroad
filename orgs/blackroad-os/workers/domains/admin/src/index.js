// admin.blackroad.io — BlackRoad OS Control Panel

const CF_ACCOUNT_ID = "848cf0b18d51e0170e0d1537aec3505a";
const BRAND = { gradient: "linear-gradient(135deg, #F5A623 0%, #FF1D6C 38.2%, #9C27B0 61.8%, #2979FF 100%)" };
function json(data, status = 200) { return new Response(JSON.stringify(data, null, 2), { status, headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" } }); }
function html(content) { return new Response(content, { headers: { "Content-Type": "text/html; charset=utf-8" } }); }
async function ghFetch(env, endpoint) { if (!env.GITHUB_TOKEN) return null; const r = await fetch(`https://api.github.com${endpoint}`, { headers: { "Authorization": `Bearer ${env.GITHUB_TOKEN}`, "Accept": "application/vnd.github+json", "X-GitHub-Api-Version": "2022-11-28", "User-Agent": "BlackRoad-OS-Worker/2.0" } }); return r.ok ? r.json() : null; }

const CSS = `*{box-sizing:border-box;margin:0;padding:0}:root{--amber:#F5A623;--pink:#FF1D6C;--violet:#9C27B0;--blue:#2979FF;--bg:#000;--surface:#0a0a0a;--border:#1a1a1a;--text:#fff;--muted:#555;--gradient:linear-gradient(135deg,var(--amber) 0%,var(--pink) 38.2%,var(--violet) 61.8%,var(--blue) 100%);--radius:12px;--font:-apple-system,BlinkMacSystemFont,'SF Pro Display',sans-serif}body{background:var(--bg);color:var(--text);font-family:var(--font);min-height:100vh}.header{padding:40px;border-bottom:1px solid var(--border)}.title{font-size:clamp(24px,3vw,40px);font-weight:700;background:var(--gradient);-webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text}.content{padding:40px}.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(240px,1fr));gap:16px;margin-top:24px}.card{background:var(--surface);border:1px solid var(--border);border-radius:var(--radius);padding:20px}.section-title{font-size:12px;font-weight:600;letter-spacing:.1em;text-transform:uppercase;color:#555;margin-bottom:16px;margin-top:32px}.gradient-bar{height:2px;background:var(--gradient);margin:0 0 32px}`;

function isAuthorized(request, env) {
  const token = env.ADMIN_TOKEN;
  if (!token) return false;
  const headerToken = request.headers.get("X-Admin-Token");
  if (headerToken === token) return true;
  const url = new URL(request.url);
  const queryToken = url.searchParams.get("token");
  return queryToken === token;
}

function loginPage() {
  return html(`<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Admin — BlackRoad OS</title><style>${CSS}
.login-wrap{display:flex;align-items:center;justify-content:center;min-height:100vh;padding:24px}
.login-card{background:var(--surface);border:1px solid var(--border);border-radius:16px;padding:48px;width:100%;max-width:400px}
.login-title{font-size:28px;font-weight:700;background:var(--gradient);-webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text;margin-bottom:8px}
.login-sub{color:var(--muted);font-size:14px;margin-bottom:32px}
label{display:block;font-size:12px;font-weight:600;letter-spacing:.08em;text-transform:uppercase;color:var(--muted);margin-bottom:8px}
input[type=password]{width:100%;background:#111;border:1px solid var(--border);border-radius:8px;color:#fff;font-size:15px;padding:12px 16px;outline:none;transition:border .2s}
input[type=password]:focus{border-color:#333}
.btn{display:block;width:100%;margin-top:20px;padding:13px;background:var(--gradient);border:none;border-radius:8px;color:#fff;font-size:15px;font-weight:600;cursor:pointer;letter-spacing:.02em}
.lock{font-size:40px;margin-bottom:24px}
</style></head><body>
<div class="login-wrap">
  <div class="login-card">
    <div class="lock">🔐</div>
    <div class="login-title">Admin Access</div>
    <div class="login-sub">BlackRoad OS Control Panel</div>
    <form method="GET" action="/">
      <label for="token">Admin Token</label>
      <input type="password" id="token" name="token" placeholder="Enter admin token" autofocus>
      <button class="btn" type="submit">Authenticate</button>
    </form>
  </div>
</div>
</body></html>`);
}

async function adminPanel(env) {
  const [orgData, commits, repos] = await Promise.all([
    ghFetch(env, "/orgs/BlackRoad-OS"),
    ghFetch(env, "/repos/BlackRoad-OS-Inc/blackroad/commits?per_page=5"),
    ghFetch(env, "/orgs/BlackRoad-OS/repos?per_page=1"),
  ]);

  const publicRepos = orgData?.public_repos ?? "1,332+";
  const recentCommits = Array.isArray(commits) ? commits : [];

  const activityHTML = recentCommits.length
    ? recentCommits.map(c => `
      <div class="activity-item">
        <div class="activity-icon">📝</div>
        <div>
          <div class="activity-msg">${c.commit?.message?.split("\n")[0]?.slice(0, 72) ?? "commit"}</div>
          <div class="activity-meta">${c.commit?.author?.name ?? "unknown"} · ${new Date(c.commit?.author?.date).toLocaleDateString()}</div>
        </div>
      </div>`).join("")
    : `<div style="color:var(--muted);font-size:14px;">No GITHUB_TOKEN set — add secret to see live activity.</div>`;

  return html(`<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Admin — BlackRoad OS</title><style>${CSS}
.badge{display:inline-block;padding:3px 10px;border-radius:20px;font-size:11px;font-weight:700;background:#0f2;color:#000}
.stat-num{font-size:32px;font-weight:800;background:var(--gradient);-webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text}
.stat-label{font-size:12px;color:var(--muted);margin-top:4px}
.action-link{display:flex;align-items:center;gap:12px;padding:14px 18px;background:var(--surface);border:1px solid var(--border);border-radius:10px;color:#fff;text-decoration:none;transition:border .2s;font-size:14px;font-weight:500}
.action-link:hover{border-color:#333}
.action-icon{font-size:20px;width:36px;text-align:center}
.actions-grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(280px,1fr));gap:10px;margin-top:16px}
.activity-item{display:flex;gap:12px;padding:14px 0;border-bottom:1px solid var(--border)}
.activity-item:last-child{border-bottom:none}
.activity-icon{font-size:18px;width:28px;flex-shrink:0}
.activity-msg{font-size:14px;margin-bottom:3px}
.activity-meta{font-size:12px;color:var(--muted)}
</style></head><body>
<div class="gradient-bar"></div>
<div class="header" style="display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:16px;">
  <div>
    <div style="font-size:12px;color:var(--muted);font-weight:600;letter-spacing:.1em;text-transform:uppercase;margin-bottom:6px">Admin</div>
    <div class="title">BlackRoad OS Control Panel</div>
  </div>
  <span class="badge">AUTHENTICATED</span>
</div>

<div class="content">
  <div class="section-title">System Overview</div>
  <div class="grid">
    <div class="card">
      <div class="stat-num">${publicRepos}</div>
      <div class="stat-label">GitHub Repositories</div>
    </div>
    <div class="card">
      <div class="stat-num">14</div>
      <div class="stat-label">Railway Projects</div>
    </div>
    <div class="card">
      <div class="stat-num">75+</div>
      <div class="stat-label">Cloudflare Workers</div>
    </div>
    <div class="card">
      <div class="stat-num">30,000</div>
      <div class="stat-label">Agent Capacity</div>
    </div>
    <div class="card">
      <div class="stat-num">17</div>
      <div class="stat-label">GitHub Orgs</div>
    </div>
    <div class="card">
      <div class="stat-num" style="color:#0f0;-webkit-text-fill-color:#0f0">●&nbsp;Live</div>
      <div class="stat-label">System Status</div>
    </div>
  </div>

  <div class="section-title">Quick Actions</div>
  <div class="actions-grid">
    <a class="action-link" href="https://console.blackroad.io" target="_blank"><span class="action-icon">🚀</span>Deploy All Workers</a>
    <a class="action-link" href="https://dashboard.blackroad.io" target="_blank"><span class="action-icon">📊</span>View CI/CD Dashboard</a>
    <a class="action-link" href="https://agents.blackroad.io" target="_blank"><span class="action-icon">🤖</span>Manage Agents</a>
    <a class="action-link" href="https://security.blackroad.io" target="_blank"><span class="action-icon">🛡️</span>Security Scan</a>
    <a class="action-link" href="https://edge.blackroad.io" target="_blank"><span class="action-icon">📡</span>View Edge Logs</a>
    <a class="action-link" href="https://github.com/BlackRoad-OS-Inc" target="_blank"><span class="action-icon">🐙</span>GitHub Org</a>
  </div>

  <div class="section-title">Recent Activity</div>
  <div class="card" style="margin-top:0">
    ${activityHTML}
  </div>
</div>
</body></html>`);
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const { pathname } = url;

    if (pathname === "/health") {
      return json({ status: "ok", worker: "admin-blackroadio", ts: Date.now() });
    }

    if (pathname === "/api/status") {
      if (!isAuthorized(request, env)) return json({ error: "Unauthorized" }, 401);
      const orgData = await ghFetch(env, "/orgs/BlackRoad-OS");
      return json({
        status: "ok",
        github: { repos: orgData?.public_repos ?? null, org: "BlackRoad-OS" },
        railway_projects: 14,
        cf_workers: 75,
        agents: 30000,
      });
    }

    if (pathname === "/") {
      if (!isAuthorized(request, env)) return loginPage();
      return adminPanel(env);
    }

    return json({ error: "Not found" }, 404);
  },
};
