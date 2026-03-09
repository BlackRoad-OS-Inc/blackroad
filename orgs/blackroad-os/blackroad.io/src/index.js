// BlackRoad Platform Worker v3.1.0
// AI Training Opt-Out Headers (EU DSM Article 4 reservation)

const CLOUDFLARE_ACCOUNT_ID = "848cf0b18d51e0170e0d1537aec3505a";

// AI training opt-out headers
const aiOptOutHeaders = {
  "X-Robots-Tag": "noai, noimageai",
  "X-AI-Use-Policy": "no-training, no-indexing, rights-reserved",
  "X-AI-Training": "disallow",
};

// Combined security + AI headers
const securityHeaders = {
  "X-Content-Type-Options": "nosniff",
  "X-Frame-Options": "SAMEORIGIN",
  "X-XSS-Protection": "1; mode=block",
  "Referrer-Policy": "strict-origin-when-cross-origin",
  "Permissions-Policy": "geolocation=(), microphone=(), camera=()",
  "Strict-Transport-Security": "max-age=31536000; includeSubDomains; preload",
  ...aiOptOutHeaders
};

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    const path = url.pathname;
    
    const corsHeaders = {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type, Authorization",
      ...securityHeaders
    };

    if (request.method === "OPTIONS") {
      return new Response(null, { headers: corsHeaders });
    }

    try {
      if (path === "/api/platform/health") {
        return json({ status: "operational", version: "3.1.0", timestamp: new Date().toISOString() }, corsHeaders);
      }

      if (path === "/api/platform/inventory") {
        return json({
          cloudflare: { workers: 83, pages: 0, domains: 19 },
          vercel: { projects: 34, deployments: "active" },
          github: { organizations: 15, primaryOrg: "BlackRoad-OS" },
          agents: { total: 1000, framework: "LangGraph + CrewAI" }
        }, corsHeaders);
      }

      if (path === "/api/platform/workers") {
        const workers = await fetchCloudflareWorkers(env);
        return json(workers, corsHeaders);
      }

      if (path === "/api/platform/vercel") {
        const projects = await fetchVercelProjects(env);
        return json(projects, corsHeaders);
      }

      if (path === "/platform" || path === "/platform/") {
        return new Response(getDashboardHTML(), {
          headers: { ...corsHeaders, "Content-Type": "text/html" }
        });
      }

      // Root path is handled by the main web service (services/web)
      // This worker only handles /platform and API routes

      return json({ error: "Not found" }, corsHeaders, 404);
    } catch (err) {
      return json({ error: err.message }, corsHeaders, 500);
    }
  }
};

function json(data, corsHeaders, status = 200) {
  return new Response(JSON.stringify(data, null, 2), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" }
  });
}

async function fetchCloudflareWorkers(env) {
  if (!env.CLOUDFLARE_API_TOKEN) {
    return { error: "CLOUDFLARE_API_TOKEN not configured", workers: [] };
  }
  try {
    const resp = await fetch(
      `https://api.cloudflare.com/client/v4/accounts/${CLOUDFLARE_ACCOUNT_ID}/workers/scripts`,
      { headers: { "Authorization": `Bearer ${env.CLOUDFLARE_API_TOKEN}` } }
    );
    const data = await resp.json();
    if (!data.success) return { error: data.errors, workers: [] };
    return {
      total: data.result.length,
      workers: data.result.map(w => ({
        name: w.id,
        modified: w.modified_on,
        created: w.created_on
      }))
    };
  } catch (e) {
    return { error: e.message, workers: [] };
  }
}

async function fetchVercelProjects(env) {
  if (!env.VERCEL_TOKEN) {
    return { error: "VERCEL_TOKEN not configured", projects: [] };
  }
  try {
    const resp = await fetch(
      "https://api.vercel.com/v9/projects?teamId=team_TRzkNju2fGETspZKM2AkELHe",
      { headers: { "Authorization": `Bearer ${env.VERCEL_TOKEN}` } }
    );
    const data = await resp.json();
    return {
      total: data.projects?.length || 0,
      projects: (data.projects || []).map(p => ({
        name: p.name,
        framework: p.framework,
        updated: p.updatedAt
      }))
    };
  } catch (e) {
    return { error: e.message, projects: [] };
  }
}

function getDashboardHTML() {
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta name="robots" content="noai, noimageai, noindex, nofollow">
  <title>BlackRoad Platform Hub</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      background: linear-gradient(135deg, #0a0a0a 0%, #1a1a2e 50%, #16213e 100%);
      color: #e4e4e7;
      min-height: 100vh;
      padding: 2rem;
    }
    .container { max-width: 1400px; margin: 0 auto; }
    header {
      text-align: center;
      margin-bottom: 3rem;
      padding: 2rem;
      background: rgba(255,255,255,0.03);
      border-radius: 16px;
      border: 1px solid rgba(255,255,255,0.1);
    }
    h1 {
      font-size: 2.5rem;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
      margin-bottom: 0.5rem;
    }
    .subtitle { color: #a1a1aa; font-size: 1.1rem; }
    .grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
      gap: 1.5rem;
      margin-bottom: 2rem;
    }
    .card {
      background: rgba(255,255,255,0.05);
      border-radius: 12px;
      padding: 1.5rem;
      border: 1px solid rgba(255,255,255,0.1);
      transition: transform 0.2s, border-color 0.2s;
    }
    .card:hover {
      transform: translateY(-2px);
      border-color: rgba(102, 126, 234, 0.5);
    }
    .card-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 1rem;
    }
    .card-title {
      font-size: 1.1rem;
      font-weight: 600;
      display: flex;
      align-items: center;
      gap: 0.5rem;
    }
    .card-icon { font-size: 1.3rem; }
    .stat {
      font-size: 2.5rem;
      font-weight: 700;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
    }
    .stat-label { color: #71717a; font-size: 0.9rem; margin-top: 0.25rem; }
    .status-dot {
      width: 8px;
      height: 8px;
      border-radius: 50%;
      background: #22c55e;
      animation: pulse 2s infinite;
    }
    @keyframes pulse {
      0%, 100% { opacity: 1; }
      50% { opacity: 0.5; }
    }
    .worker-list, .project-list {
      max-height: 300px;
      overflow-y: auto;
      margin-top: 1rem;
    }
    .worker-item, .project-item {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 0.75rem;
      background: rgba(0,0,0,0.2);
      border-radius: 8px;
      margin-bottom: 0.5rem;
      font-size: 0.9rem;
    }
    .worker-name, .project-name {
      font-family: 'Monaco', 'Menlo', monospace;
      color: #a78bfa;
    }
    .worker-date, .project-framework {
      color: #71717a;
      font-size: 0.8rem;
    }
    .section-title {
      font-size: 1.3rem;
      margin: 2rem 0 1rem;
      padding-bottom: 0.5rem;
      border-bottom: 1px solid rgba(255,255,255,0.1);
    }
    .refresh-btn {
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      border: none;
      color: white;
      padding: 0.75rem 1.5rem;
      border-radius: 8px;
      cursor: pointer;
      font-size: 0.9rem;
      transition: opacity 0.2s;
    }
    .refresh-btn:hover { opacity: 0.9; }
    .refresh-btn:disabled { opacity: 0.5; cursor: not-allowed; }
    .loading {
      display: inline-block;
      width: 16px;
      height: 16px;
      border: 2px solid rgba(255,255,255,0.3);
      border-top-color: white;
      border-radius: 50%;
      animation: spin 0.8s linear infinite;
    }
    @keyframes spin { to { transform: rotate(360deg); } }
    .error { color: #f87171; font-size: 0.9rem; }
    .timestamp { text-align: center; color: #52525b; font-size: 0.85rem; margin-top: 2rem; }
    .api-links {
      display: flex;
      gap: 1rem;
      flex-wrap: wrap;
      margin-top: 1rem;
    }
    .api-link {
      color: #a78bfa;
      text-decoration: none;
      font-family: monospace;
      font-size: 0.85rem;
      padding: 0.5rem 1rem;
      background: rgba(167, 139, 250, 0.1);
      border-radius: 6px;
      transition: background 0.2s;
    }
    .api-link:hover { background: rgba(167, 139, 250, 0.2); }
  </style>
</head>
<body>
  <div class="container">
    <header>
      <h1>⬛ BlackRoad Platform Hub</h1>
      <p class="subtitle">Unified Infrastructure Monitoring</p>
      <div class="api-links">
        <a href="/api/platform/health" class="api-link">/api/platform/health</a>
        <a href="/api/platform/inventory" class="api-link">/api/platform/inventory</a>
        <a href="/api/platform/workers" class="api-link">/api/platform/workers</a>
        <a href="/api/platform/vercel" class="api-link">/api/platform/vercel</a>
      </div>
    </header>

    <div class="grid">
      <div class="card">
        <div class="card-header">
          <span class="card-title"><span class="card-icon">☁️</span> Cloudflare Workers</span>
          <div class="status-dot"></div>
        </div>
        <div class="stat" id="worker-count">--</div>
        <div class="stat-label">Active Workers</div>
      </div>

      <div class="card">
        <div class="card-header">
          <span class="card-title"><span class="card-icon">▲</span> Vercel Projects</span>
          <div class="status-dot"></div>
        </div>
        <div class="stat" id="vercel-count">--</div>
        <div class="stat-label">Deployed Projects</div>
      </div>

      <div class="card">
        <div class="card-header">
          <span class="card-title"><span class="card-icon">🤖</span> AI Agents</span>
          <div class="status-dot"></div>
        </div>
        <div class="stat">1,000</div>
        <div class="stat-label">LangGraph + CrewAI</div>
      </div>

      <div class="card">
        <div class="card-header">
          <span class="card-title"><span class="card-icon">🌐</span> Domains</span>
          <div class="status-dot"></div>
        </div>
        <div class="stat">19</div>
        <div class="stat-label">Cloudflare DNS</div>
      </div>
    </div>

    <div style="text-align: center; margin: 2rem 0;">
      <button class="refresh-btn" onclick="refreshAll()">
        <span id="refresh-text">Refresh All</span>
      </button>
    </div>

    <h2 class="section-title">☁️ Cloudflare Workers</h2>
    <div id="workers-container" class="worker-list">
      <div style="text-align: center; padding: 2rem; color: #71717a;">Loading workers...</div>
    </div>

    <h2 class="section-title">▲ Vercel Projects</h2>
    <div id="vercel-container" class="project-list">
      <div style="text-align: center; padding: 2rem; color: #71717a;">Loading projects...</div>
    </div>

    <p class="timestamp">Last updated: <span id="last-update">--</span></p>
  </div>

  <script>
    async function fetchWorkers() {
      try {
        const resp = await fetch('/api/platform/workers');
        const data = await resp.json();
        document.getElementById('worker-count').textContent = data.total || '0';
        const container = document.getElementById('workers-container');
        if (data.error) {
          container.innerHTML = '<div class="error">Error: ' + data.error + '</div>';
          return;
        }
        if (!data.workers || data.workers.length === 0) {
          container.innerHTML = '<div style="padding: 1rem; color: #71717a;">No workers found</div>';
          return;
        }
        container.innerHTML = data.workers.slice(0, 50).map(w => 
          '<div class="worker-item"><span class="worker-name">' + w.name + '</span><span class="worker-date">' + 
          new Date(w.modified).toLocaleDateString() + '</span></div>'
        ).join('');
      } catch (e) {
        document.getElementById('workers-container').innerHTML = '<div class="error">Failed to load workers</div>';
      }
    }

    async function fetchVercel() {
      try {
        const resp = await fetch('/api/platform/vercel');
        const data = await resp.json();
        document.getElementById('vercel-count').textContent = data.total || '0';
        const container = document.getElementById('vercel-container');
        if (data.error) {
          container.innerHTML = '<div class="error">Error: ' + data.error + '</div>';
          return;
        }
        if (!data.projects || data.projects.length === 0) {
          container.innerHTML = '<div style="padding: 1rem; color: #71717a;">No projects found</div>';
          return;
        }
        container.innerHTML = data.projects.map(p => 
          '<div class="project-item"><span class="project-name">' + p.name + '</span><span class="project-framework">' + 
          (p.framework || 'static') + '</span></div>'
        ).join('');
      } catch (e) {
        document.getElementById('vercel-container').innerHTML = '<div class="error">Failed to load projects</div>';
      }
    }

    async function refreshAll() {
      const btn = document.querySelector('.refresh-btn');
      const text = document.getElementById('refresh-text');
      btn.disabled = true;
      text.innerHTML = '<span class="loading"></span> Loading...';
      await Promise.all([fetchWorkers(), fetchVercel()]);
      document.getElementById('last-update').textContent = new Date().toLocaleString();
      btn.disabled = false;
      text.textContent = 'Refresh All';
    }

    // Initial load
    refreshAll();
    // Auto-refresh every 60 seconds
    setInterval(refreshAll, 60000);
  </script>
</body>
</html>`;
}
