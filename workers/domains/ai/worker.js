/**
 * ai.blackroad.io — AI Platform Worker
 * ─────────────────────────────────────────────────────────────────
 * Owner: LUCIDIA (AI/core)
 * Data:  Ollama model list · gateway status · inference metrics
 * Route: ai.blackroad.io/*
 */

import { shell, html, json, fetchGitHub, BRAND } from "../_template/worker.js";

const NAV = [
  { label: "← Home",  url: "https://blackroad.io"        },
  { label: "Agents",  url: "https://agents.blackroad.io" },
  { label: "API",     url: "https://api.blackroad.io"    },
  { label: "Docs",    url: "https://docs.blackroad.io"   },
];

const MODELS = [
  { name: "qwen2.5:7b",      provider: "Ollama",     type: "Chat",       ctx: "128K", speed: "fast",   status: "online"  },
  { name: "llama3.2:3b",     provider: "Ollama",     type: "Chat",       ctx: "8K",   speed: "fast",   status: "online"  },
  { name: "deepseek-r1",     provider: "Ollama",     type: "Reasoning",  ctx: "64K",  speed: "medium", status: "online"  },
  { name: "claude-3-7",      provider: "Anthropic",  type: "Chat",       ctx: "200K", speed: "fast",   status: "online"  },
  { name: "gpt-4o",          provider: "OpenAI",     type: "Chat",       ctx: "128K", speed: "fast",   status: "standby" },
  { name: "nomic-embed-text",provider: "Ollama",     type: "Embeddings", ctx: "2K",   speed: "fast",   status: "online"  },
  { name: "mistral:7b",      provider: "Ollama",     type: "Chat",       ctx: "32K",  speed: "fast",   status: "standby" },
  { name: "phi4",            provider: "Ollama",     type: "Reasoning",  ctx: "16K",  speed: "fast",   status: "online"  },
];

const CAPABILITIES = [
  { emoji: "💬", title: "Chat Completion",  desc: "Multi-model chat with streaming, tool calls, and memory injection." },
  { emoji: "🔍", title: "Embeddings",       desc: "Vector embeddings via nomic-embed-text for semantic search." },
  { emoji: "🧠", title: "Reasoning Chains", desc: "DeepSeek-R1 multi-step reasoning for complex tasks." },
  { emoji: "🔀", title: "Model Router",     desc: "Intelligent routing: local Ollama → cloud fallback." },
  { emoji: "💾", title: "PS-SHA∞ Memory",   desc: "Persistent memory chains with cryptographic integrity." },
  { emoji: "⚡", title: "Streaming",        desc: "Real-time token streaming via SSE and WebSocket." },
];

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    if (request.method === "OPTIONS") return new Response(null, { status: 204 });
    if (url.pathname === "/health") return json({ status: "ok", service: "ai", models: MODELS.length, timestamp: new Date().toISOString() });

    if (url.pathname === "/api/models") {
      // Try live Ollama endpoint
      let ollamaModels = null;
      try {
        const r = await fetch("https://gateway.blackroad.io/api/tags", { cf: { cacheTtl: 60 } });
        if (r.ok) ollamaModels = await r.json();
      } catch {}
      return json({ models: ollamaModels?.models ?? MODELS, source: ollamaModels ? "live" : "static", timestamp: new Date().toISOString() });
    }

    const onlineModels  = MODELS.filter(m => m.status === "online").length;
    const standbyModels = MODELS.filter(m => m.status === "standby").length;

    const modelCards = MODELS.map(m => {
      const online = m.status === "online";
      const providerColor = m.provider === "Anthropic" ? BRAND.violet : m.provider === "OpenAI" ? BRAND.blue : BRAND.amber;
      return `
        <div class="card">
          <div style="display:flex;align-items:center;gap:8px;margin-bottom:10px">
            <div style="width:8px;height:8px;border-radius:50%;background:${online ? "#39ff14" : "#666"}"></div>
            <div class="card-title" style="font-family:monospace;font-size:13px">${m.name}</div>
            <span class="badge ${online ? "badge-online" : "badge-standby"}" style="margin-left:auto">${m.status.toUpperCase()}</span>
          </div>
          <div style="display:flex;gap:6px;flex-wrap:wrap">
            <span style="font-size:11px;background:${providerColor}22;color:${providerColor};padding:2px 8px;border-radius:4px">${m.provider}</span>
            <span style="font-size:11px;background:#1a1a24;color:#666;padding:2px 8px;border-radius:4px">${m.type}</span>
            <span style="font-size:11px;background:#1a1a24;color:#666;padding:2px 8px;border-radius:4px">${m.ctx}</span>
            <span style="font-size:11px;background:#1a1a24;color:#666;padding:2px 8px;border-radius:4px">⚡ ${m.speed}</span>
          </div>
        </div>`;
    }).join("");

    const capCards = CAPABILITIES.map(c => `
      <div class="card">
        <div style="font-size:28px;margin-bottom:8px">${c.emoji}</div>
        <div class="card-title">${c.title}</div>
        <div class="card-sub">${c.desc}</div>
      </div>`).join("");

    const body = `
      <div class="stats-strip" style="justify-content:center;display:flex;gap:16px;flex-wrap:wrap;margin-bottom:40px">
        <div class="stat"><div class="stat-val">${MODELS.length}</div><div class="stat-key">Models</div></div>
        <div class="stat"><div class="stat-val" style="color:#39ff14">${onlineModels}</div><div class="stat-key">Online</div></div>
        <div class="stat"><div class="stat-val">3</div><div class="stat-key">Providers</div></div>
        <div class="stat"><div class="stat-val">200K</div><div class="stat-key">Max Context</div></div>
        <div class="stat"><div class="stat-val">∞</div><div class="stat-key">Memory</div></div>
      </div>

      <div class="section-head">Capabilities</div>
      <div class="card-grid">${capCards}</div>

      <div class="section-head">Model Registry</div>
      <div class="card-grid">${modelCards}</div>

      <div class="section-head">API Usage</div>
      <div class="card" style="font-family:monospace;font-size:13px;line-height:2.2">
        <div style="color:#555;margin-bottom:8px"># Chat completion</div>
        <div style="color:#e8e8f0">curl https://api.blackroad.io/v1/chat/completions \\</div>
        <div style="color:#666">&nbsp;&nbsp;-H "Authorization: Bearer &lt;token&gt;" \\</div>
        <div style="color:#666">&nbsp;&nbsp;-d '{"model":"qwen2.5:7b","messages":[{"role":"user","content":"Hello"}]}'</div>
      </div>`;

    return html(shell({
      title: "AI",
      subtitle: `${onlineModels} models online · Sovereign inference · Local-first, cloud-fallback`,
      emoji: "🧠",
      body,
      navLinks: NAV,
      liveData: { "Models": `${onlineModels}/${MODELS.length}`, "Providers": 3, "Memory": "∞" },
    }));
  },
};
