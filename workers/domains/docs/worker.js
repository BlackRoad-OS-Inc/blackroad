/**
 * docs.blackroad.io — Documentation Hub Worker
 * ─────────────────────────────────────────────────────────────────
 * Owner: ARIA (UI/frontend)
 * Data:  GitHub repo READMEs · BlackRoad-OS repo list · changelogs
 * Route: docs.blackroad.io/*
 */

import { shell, html, json, fetchGitHub, BRAND } from "../_template/worker.js";

const NAV = [
  { label: "← Home",    url: "https://blackroad.io"      },
  { label: "API Ref",   url: "https://api.blackroad.io"  },
  { label: "Agents",    url: "https://agents.blackroad.io"},
  { label: "GitHub",    url: "https://github.com/BlackRoad-OS" },
];

const DOC_SECTIONS = [
  {
    title: "Getting Started",
    icon: "🚀",
    color: BRAND.pink,
    docs: [
      { title: "Quick Start",       href: "#quickstart",   desc: "Deploy your first agent in 5 minutes." },
      { title: "Installation",      href: "#install",      desc: "Install br CLI and configure your environment." },
      { title: "First Agent",       href: "#first-agent",  desc: "Create and run a custom agent." },
      { title: "Architecture",      href: "#architecture", desc: "Understand the BlackRoad OS system design." },
    ],
  },
  {
    title: "CLI Reference",
    icon: "💻",
    color: BRAND.amber,
    docs: [
      { title: "br agents",   href: "#br-agents",   desc: "Manage agent lifecycle." },
      { title: "br deploy",   href: "#br-deploy",   desc: "Deploy workers and services." },
      { title: "br memory",   href: "#br-memory",   desc: "Interact with PS-SHA∞ memory." },
      { title: "br queue",    href: "#br-queue",    desc: "Job queue management." },
    ],
  },
  {
    title: "API Reference",
    icon: "🔌",
    color: BRAND.blue,
    docs: [
      { title: "Authentication",    href: "#auth",         desc: "API keys, JWT, and BRAT tokens." },
      { title: "Agents API",        href: "#agents-api",   desc: "REST endpoints for agent control." },
      { title: "Memory API",        href: "#memory-api",   desc: "PS-SHA∞ persistent memory chains." },
      { title: "Tasks API",         href: "#tasks-api",    desc: "Job scheduling and execution." },
    ],
  },
  {
    title: "Infrastructure",
    icon: "🏗️",
    color: BRAND.violet,
    docs: [
      { title: "Cloudflare Workers", href: "#cf-workers",  desc: "Edge worker deployment guide." },
      { title: "Railway Deploy",     href: "#railway",     desc: "Container services on Railway." },
      { title: "Pi Fleet Setup",     href: "#pi-fleet",    desc: "Raspberry Pi cluster configuration." },
      { title: "Secrets Management", href: "#secrets",     desc: "Vault, KV, and secure config." },
    ],
  },
];

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (request.method === "OPTIONS") return new Response(null, { status: 204 });

    if (url.pathname === "/health") {
      return json({ status: "ok", service: "docs", timestamp: new Date().toISOString() });
    }

    // Fetch live repo list for "open source" section
    const [ghRepos, ghOrg] = await Promise.all([
      fetchGitHub("orgs/BlackRoad-OS/repos?per_page=12&sort=pushed&type=public", env.GITHUB_TOKEN),
      fetchGitHub("orgs/BlackRoad-OS", env.GITHUB_TOKEN),
    ]);

    const totalRepos = ghOrg?.public_repos ?? 1229;

    const repoCards = (ghRepos ?? []).slice(0, 6).map(r => `
      <a href="${r.html_url}" style="text-decoration:none">
        <div class="card" style="cursor:pointer">
          <div class="card-title" style="color:#FF1D6C;margin-bottom:4px">${r.name}</div>
          <div class="card-sub" style="margin-bottom:10px;min-height:32px">${r.description?.slice(0,72) ?? "BlackRoad OS component"}</div>
          <div style="display:flex;gap:8px;flex-wrap:wrap">
            ${r.language ? `<span style="font-size:11px;background:#1a1a24;padding:2px 8px;border-radius:4px;color:#666">${r.language}</span>` : ""}
            <span style="font-size:11px;background:#1a1a24;padding:2px 8px;border-radius:4px;color:#666">⭐ ${r.stargazers_count ?? 0}</span>
            <span style="font-size:11px;background:#1a1a24;padding:2px 8px;border-radius:4px;color:#666">🍴 ${r.forks_count ?? 0}</span>
          </div>
        </div>
      </a>`).join("");

    const docSections = DOC_SECTIONS.map(section => `
      <div style="margin-bottom:32px">
        <div class="section-head">
          ${section.icon} ${section.title}
        </div>
        <div class="card-grid">
          ${section.docs.map(d => `
            <a href="${d.href}" style="text-decoration:none">
              <div class="card" style="border-left: 3px solid ${section.color}">
                <div class="card-title" style="color:${section.color}">${d.title}</div>
                <div class="card-sub">${d.desc}</div>
              </div>
            </a>`).join("")}
        </div>
      </div>`).join("");

    const body = `
      <div class="stats-strip" style="justify-content:center;display:flex;gap:16px;flex-wrap:wrap;margin-bottom:40px">
        <div class="stat"><div class="stat-val">${totalRepos.toLocaleString()}+</div><div class="stat-key">Open Repos</div></div>
        <div class="stat"><div class="stat-val">${DOC_SECTIONS.reduce((a, s) => a + s.docs.length, 0)}</div><div class="stat-key">Doc Pages</div></div>
        <div class="stat"><div class="stat-val">4</div><div class="stat-key">SDKs</div></div>
        <div class="stat"><div class="stat-val">v2.0</div><div class="stat-key">API Version</div></div>
      </div>

      <div style="background:#12121A;border:1px solid rgba(41,121,255,0.3);border-radius:12px;padding:16px 20px;margin-bottom:32px;display:flex;align-items:center;gap:12px">
        <span style="font-size:20px">💡</span>
        <div>
          <div style="font-size:14px;font-weight:600;color:#2979FF;margin-bottom:2px">Quick Start</div>
          <code style="font-family:monospace;font-size:13px;color:#888">npm install -g @blackroad/cli &amp;&amp; br init my-agent</code>
        </div>
      </div>

      ${docSections}

      <div class="section-head">🌐 Open Source Repos</div>
      <div class="card-grid">${repoCards || "<div class='card-sub'>Loading repositories...</div>"}</div>`;

    return html(shell({
      title: "Docs",
      subtitle: "Everything you need to build on BlackRoad OS — guides, API reference, and examples.",
      emoji: "📚",
      body,
      navLinks: NAV,
      liveData: { "Repos": `${totalRepos}+`, "Pages": "120+", "Version": "v2.0" },
    }));
  },
};
