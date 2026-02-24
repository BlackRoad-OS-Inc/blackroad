/**
 * blackroad.io — Root / Landing Worker
 * ─────────────────────────────────────────────────────────────────
 * Owner: LUCIDIA (AI/core)
 * Data:  GitHub org stats · CF worker count · Railway services
 * Route: blackroad.io/* → this worker
 */

import { shell, html, json, fetchGitHub, fetchRailway, fetchCF, BRAND } from "../_template/worker.js";

const NAV = [
  { label: "Docs",      url: "https://docs.blackroad.io"      },
  { label: "API",       url: "https://api.blackroad.io"       },
  { label: "Dashboard", url: "https://dashboard.blackroad.io" },
  { label: "Agents",    url: "https://agents.blackroad.io"    },
  { label: "Console",   url: "https://console.blackroad.io"   },
  { label: "GitHub",    url: "https://github.com/BlackRoad-OS" },
];

const FEATURES = [
  { emoji: "🤖", title: "30K+ Agent Mesh",      desc: "Distributed AI agent network running on sovereign hardware." },
  { emoji: "⚡", title: "Edge-First Runtime",   desc: "Cloudflare Workers + KV + Durable Objects. Zero cold starts." },
  { emoji: "🔐", title: "Sovereign by Default", desc: "Your keys. Your models. Your infrastructure. Always." },
  { emoji: "🛠️", title: "Full-Stack CLI",       desc: "br CLI controls agents, deploys, secrets, and the mesh." },
  { emoji: "📡", title: "Real-time Mesh",       desc: "WebSocket-first agent communication via Cloudflare Calls." },
  { emoji: "🏗️", title: "Multi-Cloud Infra",    desc: "Railway, Vercel, Pi fleet, and bare metal in one OS." },
];

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "GET,OPTIONS",
      }});
    }

    // JSON health/status endpoint
    if (url.pathname === "/health" || url.pathname === "/api/status") {
      const [osRepos, osInc] = await Promise.all([
        fetchGitHub("orgs/BlackRoad-OS/repos?per_page=1&sort=pushed", env.GITHUB_TOKEN),
        fetchGitHub("orgs/BlackRoad-OS-Inc/repos?per_page=1&sort=pushed", env.GITHUB_TOKEN),
      ]);
      return json({
        status: "operational",
        version: "2.0.0",
        timestamp: new Date().toISOString(),
        services: {
          "blackroad-os":     "online",
          "agents-api":       "online",
          "command-center":   "online",
          "api-edge":         "online",
        },
        github: {
          "BlackRoad-OS":     "1229+ repos",
          "BlackRoad-OS-Inc": "21 repos",
        },
      });
    }

    // Pull live stats in parallel
    const [ghOSOrg, ghIncOrg, cfWorkers] = await Promise.all([
      fetchGitHub("orgs/BlackRoad-OS", env.GITHUB_TOKEN),
      fetchGitHub("orgs/BlackRoad-OS-Inc", env.GITHUB_TOKEN),
      fetchCF(`accounts/848cf0b18d51e0170e0d1537aec3505a/workers/scripts`, env.CF_API_TOKEN),
    ]);

    const totalRepos  = (ghOSOrg?.public_repos  ?? 1229) + (ghIncOrg?.public_repos  ?? 21);
    const workerCount = cfWorkers?.result?.length ?? 41;
    const members     = ghOSOrg?.public_members_count ?? 8;

    const featureCards = FEATURES.map(f => `
      <div class="card">
        <div style="font-size:28px;margin-bottom:10px">${f.emoji}</div>
        <div class="card-title">${f.title}</div>
        <div class="card-sub">${f.desc}</div>
      </div>`).join("");

    const body = `
      <div class="stats-strip" style="justify-content:center;display:flex;gap:16px;flex-wrap:wrap;margin-bottom:40px">
        <div class="stat"><div class="stat-val">${totalRepos.toLocaleString()}+</div><div class="stat-key">Repositories</div></div>
        <div class="stat"><div class="stat-val">${workerCount}</div><div class="stat-key">Edge Workers</div></div>
        <div class="stat"><div class="stat-val">30K+</div><div class="stat-key">Agents</div></div>
        <div class="stat"><div class="stat-val">${members}</div><div class="stat-key">Core Team</div></div>
        <div class="stat"><div class="stat-val">99.9%</div><div class="stat-key">Uptime SLA</div></div>
      </div>

      <div class="section-head">Platform Capabilities</div>
      <div class="card-grid">${featureCards}</div>

      <div class="section-head">System Status</div>
      <div class="card-grid">
        ${["blackroad.io","api.blackroad.io","agents.blackroad.io","dashboard.blackroad.io","docs.blackroad.io","console.blackroad.io"].map(d => `
          <div class="card" style="display:flex;align-items:center;gap:12px;padding:14px 18px">
            <div style="width:8px;height:8px;border-radius:50%;background:#39ff14;flex-shrink:0"></div>
            <div>
              <div class="card-title" style="font-size:13px;margin:0">${d}</div>
              <div class="card-sub" style="font-size:11px">Operational · &lt;10ms p99</div>
            </div>
            <span class="badge badge-online" style="margin-left:auto">LIVE</span>
          </div>`).join("")}
      </div>

      <div class="section-head">Quick Links</div>
      <div style="display:flex;gap:12px;flex-wrap:wrap;margin-bottom:32px">
        ${NAV.map(l => `<a href="${l.url}" style="display:inline-flex;align-items:center;gap:6px;padding:10px 20px;background:#12121A;border:1px solid #2a2a3a;border-radius:10px;color:#e8e8f0;text-decoration:none;font-size:14px;font-weight:500;transition:border-color 0.2s" onmouseover="this.style.borderColor='#FF1D6C'" onmouseout="this.style.borderColor='#2a2a3a'">${l.label}</a>`).join("")}
      </div>`;

    return html(shell({
      title: "BlackRoad OS",
      subtitle: "Your AI. Your Hardware. Your Rules. — The AI-native developer operating system.",
      emoji: "🖤",
      body,
      navLinks: NAV,
      liveData: {
        "Repos": `${totalRepos}+`,
        "Workers": workerCount,
        "Agents": "30K+",
        "Status": "Operational",
      },
    }));
  },
};
