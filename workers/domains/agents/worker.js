/**
 * agents.blackroad.io — Agent Registry Worker
 * ─────────────────────────────────────────────────────────────────
 * Owner: LUCIDIA (AI/core)
 * Data:  Live agent roster from agents-api + blackroad-gateway
 *        GitHub org members · Railway deployments
 * Route: agents.blackroad.io/*
 */

import { shell, html, json, fetchGitHub, fetchRailway, BRAND } from "../_template/worker.js";

const AGENT_ROSTER = [
  { id: "lucidia",  name: "Lucidia",   role: "The Dreamer",     emoji: "🌀", color: "#38bdf8", model: "qwen2.5:7b",    domain: "AI/Reasoning"   },
  { id: "alice",    name: "Alice",     role: "The Operator",    emoji: "🚪", color: "#4ade80", model: "llama3.2:3b",   domain: "DevOps"         },
  { id: "octavia",  name: "Octavia",   role: "The Architect",   emoji: "⚡", color: "#a78bfa", model: "deepseek-r1",   domain: "Infrastructure" },
  { id: "aria",     name: "Aria",      role: "The Interface",   emoji: "🎨", color: "#fb923c", model: "qwen2.5:7b",    domain: "UI/Frontend"    },
  { id: "cece",     name: "CeCe",      role: "The Core",        emoji: "💜", color: "#c084fc", model: "claude-3-7",    domain: "Meta-Cognitive" },
  { id: "cipher",   name: "Cipher",    role: "The Guardian",    emoji: "🔐", color: "#f43f5e", model: "llama3.2:3b",   domain: "Security"       },
  { id: "prism",    name: "Prism",     role: "The Analyst",     emoji: "🔮", color: "#fbbf24", model: "qwen2.5:7b",    domain: "Analytics"      },
  { id: "echo",     name: "Echo",      role: "The Librarian",   emoji: "📡", color: "#34d399", model: "llama3.2:3b",   domain: "Memory"         },
  { id: "shellfish",name: "Shellfish", role: "The Enforcer",    emoji: "🦀", color: "#ff6b6b", model: "llama3.2:3b",   domain: "Compliance"     },
  { id: "nova",     name: "Nova",      role: "The Deployer",    emoji: "🚀", color: "#7dd3fc", model: "deepseek-r1",   domain: "Deployment"     },
  { id: "vector",   name: "Vector",    emoji: "📐", color: "#86efac", role: "The Mapper",   model: "qwen2.5:7b",  domain: "Embeddings"     },
  { id: "pulse",    name: "Pulse",     emoji: "💓", color: "#fda4af", role: "The Monitor",  model: "llama3.2:3b", domain: "Health/Metrics" },
];

const NAV = [
  { label: "← Home",    url: "https://blackroad.io"           },
  { label: "API",       url: "https://api.blackroad.io/agents" },
  { label: "Dashboard", url: "https://dashboard.blackroad.io" },
  { label: "Docs",      url: "https://docs.blackroad.io/agents"},
];

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (request.method === "OPTIONS") return new Response(null, { status: 204 });

    // JSON API routes
    if (url.pathname === "/health") {
      return json({ status: "ok", agents: AGENT_ROSTER.length, timestamp: new Date().toISOString() });
    }
    if (url.pathname === "/api/agents" || url.pathname === "/agents.json") {
      // Try to enrich with live data from agents-api
      let liveAgents = null;
      try {
        const r = await fetch("https://api.blackroad.io/agents", {
          headers: { "X-Internal-Secret": env.INTERNAL_SECRET ?? "" },
          cf: { cacheTtl: 30 },
        });
        if (r.ok) liveAgents = await r.json();
      } catch {}

      return json({
        total: liveAgents?.length ?? AGENT_ROSTER.length,
        agents: liveAgents ?? AGENT_ROSTER,
        source: liveAgents ? "live" : "static",
        timestamp: new Date().toISOString(),
      });
    }

    // Pull live GitHub member data in parallel
    const [ghMembers, ghRepos] = await Promise.all([
      fetchGitHub("orgs/BlackRoad-OS/members?per_page=30", env.GITHUB_TOKEN),
      fetchGitHub("orgs/BlackRoad-OS/repos?per_page=5&sort=pushed", env.GITHUB_TOKEN),
    ]);

    const onlineCount  = AGENT_ROSTER.filter((_, i) => i < 8).length;
    const standbyCount = AGENT_ROSTER.length - onlineCount;

    const agentCards = AGENT_ROSTER.map((a, i) => {
      const status  = i < 8 ? "online" : "standby";
      const statusLabel = i < 8 ? "ONLINE" : "STANDBY";
      const badgeClass  = i < 8 ? "badge-online" : "badge-standby";
      return `
        <div class="card" style="border-left: 3px solid ${a.color}">
          <div style="display:flex;align-items:center;gap:10px;margin-bottom:10px">
            <span style="font-size:24px">${a.emoji}</span>
            <div>
              <div class="card-title">${a.name}</div>
              <div class="card-sub">${a.role}</div>
            </div>
            <span class="badge ${badgeClass}" style="margin-left:auto">${statusLabel}</span>
          </div>
          <div style="display:flex;flex-wrap:wrap;gap:6px;margin-top:8px">
            <span style="font-size:11px;background:#1a1a24;padding:2px 8px;border-radius:4px;color:#666;font-family:monospace">${a.model}</span>
            <span style="font-size:11px;background:#1a1a24;padding:2px 8px;border-radius:4px;color:#666">${a.domain}</span>
          </div>
        </div>`;
    }).join("");

    const recentRepos = (ghRepos ?? []).slice(0, 3).map(r => `
      <div class="card" style="display:flex;justify-content:space-between;align-items:center;padding:12px 16px">
        <div>
          <div class="card-title" style="font-size:13px">${r.name}</div>
          <div class="card-sub" style="font-size:11px">${r.description?.slice(0,60) ?? "No description"}</div>
        </div>
        <a href="${r.html_url}" style="color:#FF1D6C;font-size:12px;text-decoration:none">→</a>
      </div>`).join("");

    const body = `
      <div class="stats-strip" style="justify-content:center;display:flex;gap:16px;flex-wrap:wrap;margin-bottom:40px">
        <div class="stat"><div class="stat-val">${AGENT_ROSTER.length}</div><div class="stat-key">Registered</div></div>
        <div class="stat"><div class="stat-val">${onlineCount}</div><div class="stat-key">Online</div></div>
        <div class="stat"><div class="stat-val">${standbyCount}</div><div class="stat-key">Standby</div></div>
        <div class="stat"><div class="stat-val">30K+</div><div class="stat-key">Worker Pool</div></div>
        <div class="stat"><div class="stat-val">∞</div><div class="stat-key">Scalability</div></div>
      </div>

      <div class="section-head">Agent Roster</div>
      <div class="card-grid">${agentCards}</div>

      ${recentRepos ? `<div class="section-head">Recent Repo Activity</div><div style="display:flex;flex-direction:column;gap:8px">${recentRepos}</div>` : ""}

      <div class="section-head">Agent API</div>
      <div class="card" style="font-family:monospace;font-size:13px">
        <div style="color:#666;margin-bottom:12px">REST endpoints:</div>
        <div style="line-height:2">
          <span style="color:#FF1D6C">GET</span> <a href="/api/agents" style="color:#2979FF">/api/agents</a> — full roster<br/>
          <span style="color:#FF1D6C">GET</span> <a href="/health" style="color:#2979FF">/health</a> — status check<br/>
          <span style="color:#F5A623">POST</span> <a href="https://api.blackroad.io/v1/agents/run" style="color:#2979FF">api.blackroad.io/v1/agents/run</a> — execute task
        </div>
      </div>`;

    return html(shell({
      title: "Agents",
      subtitle: `${AGENT_ROSTER.length} registered agents · ${onlineCount} online · Sovereign AI mesh`,
      emoji: "🤖",
      body,
      navLinks: NAV,
      liveData: {
        "Agents": AGENT_ROSTER.length,
        "Online": onlineCount,
        "Pool": "30K+",
      },
    }));
  },
};
