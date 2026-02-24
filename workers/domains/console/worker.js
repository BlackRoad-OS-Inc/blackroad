/**
 * console.blackroad.io — Operator Console Worker
 * ─────────────────────────────────────────────────────────────────
 * Owner: ARIA (UI/frontend)
 * Data:  Live CF worker list · Railway deployments · GitHub Actions
 *        Secrets vault status · Real-time logs stream
 * Route: console.blackroad.io/*
 */

import { shell, html, json, fetchGitHub, fetchRailway, fetchCF, BRAND } from "../_template/worker.js";

const NAV = [
  { label: "← Home",    url: "https://blackroad.io"           },
  { label: "Dashboard", url: "https://dashboard.blackroad.io" },
  { label: "Agents",    url: "https://agents.blackroad.io"    },
  { label: "Analytics", url: "https://analytics.blackroad.io" },
];

const CONSOLE_ACTIONS = [
  { label: "Deploy Worker",   icon: "🚀", href: "#deploy",    color: BRAND.pink   },
  { label: "Run Agent Task",  icon: "🤖", href: "#run-agent", color: BRAND.violet },
  { label: "View Logs",       icon: "📋", href: "#logs",      color: BRAND.blue   },
  { label: "Manage Secrets",  icon: "🔐", href: "#vault",     color: BRAND.amber  },
  { label: "Scale Workers",   icon: "📈", href: "#scale",     color: BRAND.pink   },
  { label: "Git Operations",  icon: "🌿", href: "#git",       color: "#34d399"    },
  { label: "Queue Manager",   icon: "📦", href: "#queue",     color: BRAND.amber  },
  { label: "Health Check",    icon: "💓", href: "#health",    color: "#39ff14"    },
];

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (request.method === "OPTIONS") return new Response(null, { status: 204 });
    if (url.pathname === "/health") {
      return json({ status: "ok", service: "console", timestamp: new Date().toISOString() });
    }

    const [cfWorkers, ghActions, ghOrg] = await Promise.all([
      fetchCF(`accounts/848cf0b18d51e0170e0d1537aec3505a/workers/scripts`, env.CF_API_TOKEN),
      fetchGitHub("repos/BlackRoad-OS/blackroad-os/actions/runs?per_page=8", env.GITHUB_TOKEN),
      fetchGitHub("orgs/BlackRoad-OS", env.GITHUB_TOKEN),
    ]);

    const workers = cfWorkers?.result ?? [];
    const runs    = ghActions?.workflow_runs ?? [];
    const passCount = runs.filter(r => r.conclusion === "success").length;
    const failCount = runs.filter(r => r.conclusion === "failure").length;

    const workerList = workers.slice(0, 10).map(w => `
      <div style="display:flex;align-items:center;gap:10px;padding:10px 0;border-bottom:1px solid #1a1a24;font-family:monospace">
        <span style="font-size:13px;flex:1;color:#e8e8f0">${w.id ?? w.name ?? "worker"}</span>
        <span style="font-size:11px;color:#666">${w.modified_on ? new Date(w.modified_on).toLocaleDateString() : "–"}</span>
        <span class="badge badge-online" style="font-size:10px">LIVE</span>
      </div>`).join("");

    const actionRows = runs.slice(0, 6).map(r => {
      const icon = r.conclusion === "success" ? "✅" : r.conclusion === "failure" ? "❌" : "⏳";
      const color = r.conclusion === "success" ? "#39ff14" : r.conclusion === "failure" ? "#FF1D6C" : "#F5A623";
      return `
        <div style="display:flex;align-items:center;gap:10px;padding:10px 0;border-bottom:1px solid #1a1a24">
          <span>${icon}</span>
          <div style="flex:1">
            <div style="font-size:13px">${r.name}</div>
            <div style="font-size:11px;color:#555;font-family:monospace">${r.head_branch} · ${r.head_sha?.slice(0,7)}</div>
          </div>
          <span style="font-size:11px;color:${color}">${(r.conclusion ?? r.status).toUpperCase()}</span>
        </div>`;
    }).join("");

    const actionButtons = CONSOLE_ACTIONS.map(a => `
      <a href="${a.href}" style="text-decoration:none">
        <div class="card" style="cursor:pointer;display:flex;align-items:center;gap:12px;padding:16px">
          <span style="font-size:24px;background:${a.color}22;padding:8px;border-radius:10px">${a.icon}</span>
          <span style="font-size:14px;font-weight:600;color:${a.color}">${a.label}</span>
        </div>
      </a>`).join("");

    const body = `
      <div class="stats-strip" style="justify-content:center;display:flex;gap:16px;flex-wrap:wrap;margin-bottom:40px">
        <div class="stat"><div class="stat-val">${workers.length || 41}</div><div class="stat-key">Workers</div></div>
        <div class="stat"><div class="stat-val" style="color:#39ff14">${passCount}</div><div class="stat-key">CI Passing</div></div>
        <div class="stat"><div class="stat-val" style="color:${failCount > 0 ? BRAND.pink : "#39ff14"}">${failCount}</div><div class="stat-key">CI Failing</div></div>
        <div class="stat"><div class="stat-val">${ghOrg?.public_repos ?? 1229}+</div><div class="stat-key">Repos</div></div>
      </div>

      <div class="section-head">Quick Actions</div>
      <div class="card-grid">${actionButtons}</div>

      <div style="display:grid;grid-template-columns:1fr 1fr;gap:20px;margin-top:24px">
        <div>
          <div class="section-head">Edge Workers</div>
          <div class="card" style="padding:12px 16px">
            ${workerList || '<div style="color:#555;font-size:13px;padding:12px 0">Configure CF_API_TOKEN to load live workers</div>'}
            ${workers.length > 10 ? `<div style="text-align:center;padding:12px 0;color:#555;font-size:12px">+${workers.length - 10} more workers</div>` : ""}
          </div>
        </div>
        <div>
          <div class="section-head">CI/CD Runs</div>
          <div class="card" style="padding:12px 16px">
            ${actionRows || '<div style="color:#555;font-size:13px;padding:12px 0">Configure GITHUB_TOKEN to load CI runs</div>'}
          </div>
        </div>
      </div>

      <div class="section-head">br CLI</div>
      <div class="card" style="font-family:monospace;font-size:13px;line-height:2.2">
        <div style="color:#555;margin-bottom:8px"># Core commands</div>
        <div><span style="color:#FF1D6C">br</span> <span style="color:#F5A623">agents list</span> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;— list all agents</div>
        <div><span style="color:#FF1D6C">br</span> <span style="color:#F5A623">deploy --env prod</span> &nbsp;&nbsp;&nbsp;— deploy to production</div>
        <div><span style="color:#FF1D6C">br</span> <span style="color:#F5A623">memory read --agent cece</span> — read memory chain</div>
        <div><span style="color:#FF1D6C">br</span> <span style="color:#F5A623">queue push --task &lt;id&gt;</span> — enqueue task</div>
        <div><span style="color:#FF1D6C">br</span> <span style="color:#F5A623">health --all</span> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;— system health check</div>
      </div>`;

    return html(shell({
      title: "Console",
      subtitle: "Operator command center — deploy, monitor, and control the entire BlackRoad OS mesh.",
      emoji: "⌨️",
      body,
      navLinks: NAV,
      liveData: {
        "Workers": workers.length || 41,
        "CI": `${passCount}✅ ${failCount}❌`,
      },
    }));
  },
};
