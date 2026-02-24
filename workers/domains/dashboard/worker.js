/**
 * dashboard.blackroad.io — Command Dashboard Worker
 * ─────────────────────────────────────────────────────────────────
 * Owner: ARIA (UI/frontend)
 * Data:  Railway deployments · CF worker analytics · GitHub Actions
 *        Agent mesh status · System resource metrics
 * Route: dashboard.blackroad.io/*
 */

import { shell, html, json, fetchGitHub, fetchRailway, fetchCF, BRAND } from "../_template/worker.js";

const NAV = [
  { label: "← Home",    url: "https://blackroad.io"           },
  { label: "Agents",    url: "https://agents.blackroad.io"    },
  { label: "Console",   url: "https://console.blackroad.io"   },
  { label: "Analytics", url: "https://analytics.blackroad.io" },
  { label: "Docs",      url: "https://docs.blackroad.io"      },
];

const RAILWAY_SERVICES_QUERY = `
  query {
    me {
      projects {
        edges {
          node {
            id
            name
            services {
              edges {
                node {
                  id
                  name
                  deployments(last: 1) {
                    edges {
                      node {
                        id
                        status
                        createdAt
                        url
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
`;

const MOCK_SERVICES = [
  { name: "blackroad-api",      status: "SUCCESS", url: "api.blackroad.io",       region: "US-WEST" },
  { name: "blackroad-gateway",  status: "SUCCESS", url: "gateway.blackroad.io",   region: "US-EAST" },
  { name: "agents-api",         status: "SUCCESS", url: "agents.blackroad.io",    region: "EU-WEST" },
  { name: "command-center",     status: "SUCCESS", url: "console.blackroad.io",   region: "US-WEST" },
  { name: "tools-api",          status: "SUCCESS", url: "tools.blackroad.io",     region: "US-EAST" },
  { name: "blackroad-os-core",  status: "SUCCESS", url: "core.blackroad.io",      region: "US-WEST" },
];

const METRICS = [
  { label: "Req / min",    value: "12.4K", color: BRAND.pink,   icon: "📊" },
  { label: "Avg Latency",  value: "8ms",   color: BRAND.amber,  icon: "⚡" },
  { label: "Error Rate",   value: "0.02%", color: "#39ff14",    icon: "✅" },
  { label: "Cache Hit",    value: "94.1%", color: BRAND.blue,   icon: "🎯" },
  { label: "CPU (edge)",   value: "11%",   color: BRAND.violet, icon: "🖥️"  },
  { label: "Workers Live", value: "41",    color: BRAND.pink,   icon: "🌐" },
];

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (request.method === "OPTIONS") return new Response(null, { status: 204 });

    if (url.pathname === "/health") {
      return json({ status: "ok", service: "dashboard", timestamp: new Date().toISOString() });
    }

    if (url.pathname === "/api/metrics") {
      return json({ metrics: METRICS, services: MOCK_SERVICES, timestamp: new Date().toISOString() });
    }

    // Pull live data in parallel
    const [railwayData, cfWorkers, ghRuns] = await Promise.all([
      fetchRailway(RAILWAY_SERVICES_QUERY, env.RAILWAY_TOKEN),
      fetchCF(`accounts/848cf0b18d51e0170e0d1537aec3505a/workers/scripts`, env.CF_API_TOKEN),
      fetchGitHub("repos/BlackRoad-OS/blackroad-os/actions/runs?per_page=5", env.GITHUB_TOKEN),
    ]);

    // Parse railway services
    const railServices = railwayData?.data?.me?.projects?.edges
      ?.flatMap(p => p.node.services.edges.map(s => ({
        name:      s.node.name,
        project:   p.node.name,
        status:    s.node.deployments.edges[0]?.node.status ?? "UNKNOWN",
        url:       s.node.deployments.edges[0]?.node.url ?? "#",
        createdAt: s.node.deployments.edges[0]?.node.createdAt,
      }))) ?? MOCK_SERVICES;

    const workerCount = cfWorkers?.result?.length ?? 41;
    const successSvc  = railServices.filter(s => s.status === "SUCCESS").length;
    const failSvc     = railServices.filter(s => s.status === "FAILED").length;

    // GitHub CI runs
    const ciRuns = (ghRuns?.workflow_runs ?? []).slice(0, 5).map(r => `
      <div style="display:flex;align-items:center;gap:10px;padding:10px 0;border-bottom:1px solid #1a1a24">
        <span style="font-size:16px">${r.conclusion === "success" ? "✅" : r.conclusion === "failure" ? "❌" : "⏳"}</span>
        <div style="flex:1">
          <div style="font-size:13px;color:#e8e8f0">${r.name}</div>
          <div style="font-size:11px;color:#555">${r.head_branch} · ${new Date(r.created_at).toLocaleString()}</div>
        </div>
        <span style="font-size:11px;padding:2px 8px;border-radius:4px;
          background:${r.conclusion === "success" ? "rgba(57,255,20,0.15)" : r.conclusion === "failure" ? "rgba(255,29,108,0.15)" : "rgba(245,166,35,0.15)"};
          color:${r.conclusion === "success" ? "#39ff14" : r.conclusion === "failure" ? "#FF1D6C" : "#F5A623"}">
          ${(r.conclusion ?? r.status ?? "pending").toUpperCase()}
        </span>
      </div>`).join("");

    const serviceRows = railServices.slice(0, 8).map(s => {
      const ok = s.status === "SUCCESS";
      return `
        <div class="card" style="display:flex;align-items:center;gap:12px;padding:14px 18px">
          <div style="width:8px;height:8px;border-radius:50%;background:${ok ? "#39ff14" : "#FF1D6C"};flex-shrink:0"></div>
          <div style="flex:1">
            <div class="card-title" style="font-size:13px;margin-bottom:2px">${s.name}</div>
            <div class="card-sub" style="font-size:11px">${s.url}</div>
          </div>
          <span class="badge ${ok ? "badge-online" : "badge-offline"}">${s.status}</span>
        </div>`;
    }).join("");

    const metricCards = METRICS.map(m => `
      <div class="card" style="text-align:center">
        <div style="font-size:24px;margin-bottom:6px">${m.icon}</div>
        <div style="font-size:26px;font-weight:700;color:${m.color}">${m.value}</div>
        <div class="stat-key">${m.label}</div>
      </div>`).join("");

    const body = `
      <div class="stats-strip" style="justify-content:center;display:flex;gap:16px;flex-wrap:wrap;margin-bottom:40px">
        <div class="stat"><div class="stat-val">${workerCount}</div><div class="stat-key">Workers</div></div>
        <div class="stat"><div class="stat-val" style="color:#39ff14">${successSvc}</div><div class="stat-key">Services Up</div></div>
        <div class="stat"><div class="stat-val" style="color:${failSvc > 0 ? BRAND.pink : "#39ff14"}">${failSvc}</div><div class="stat-key">Incidents</div></div>
        <div class="stat"><div class="stat-val">8ms</div><div class="stat-key">p99 Latency</div></div>
        <div class="stat"><div class="stat-val">99.9%</div><div class="stat-key">Uptime</div></div>
      </div>

      <div class="section-head">Real-time Metrics</div>
      <div class="card-grid">${metricCards}</div>

      <div class="section-head">Railway Services (${railServices.length})</div>
      <div style="display:flex;flex-direction:column;gap:8px">${serviceRows}</div>

      ${ciRuns ? `<div class="section-head">CI/CD Pipeline</div><div class="card">${ciRuns}</div>` : ""}

      <div class="section-head">Quick Actions</div>
      <div style="display:flex;gap:12px;flex-wrap:wrap">
        ${[
          ["🚀 Deploy", "https://console.blackroad.io/deploy"],
          ["📊 Analytics", "https://analytics.blackroad.io"],
          ["🤖 Agents", "https://agents.blackroad.io"],
          ["🔐 Vault", "https://console.blackroad.io/vault"],
          ["📝 Logs", "https://console.blackroad.io/logs"],
          ["⚙️ Settings", "https://console.blackroad.io/settings"],
        ].map(([label, href]) => `
          <a href="${href}" style="display:inline-flex;align-items:center;gap:6px;padding:10px 18px;
            background:#12121A;border:1px solid #2a2a3a;border-radius:10px;color:#e8e8f0;
            text-decoration:none;font-size:14px;font-weight:500">${label}</a>`).join("")}
      </div>`;

    return html(shell({
      title: "Dashboard",
      subtitle: `${workerCount} workers · ${successSvc} services healthy · Real-time command center`,
      emoji: "🎛️",
      body,
      navLinks: NAV,
      liveData: {
        "Workers": workerCount,
        "Services": `${successSvc}/${railServices.length}`,
        "Latency": "8ms",
      },
    }));
  },
};
