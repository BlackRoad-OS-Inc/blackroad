// BlackRoad Tools API Worker v2 — Real-Time Tool Registry + Execution
// 162 tools exposed as REST endpoints, routed to Pi fleet

const PI_BASE = "https://api.blackroad.io";

const TOOLS_REGISTRY = {
  // DevOps
  deploy: { category: "devops", description: "Deployment manager", usage: "br deploy <env>" },
  docker: { category: "devops", description: "Docker container management", usage: "br docker <cmd>" },
  ci: { category: "devops", description: "CI/CD pipeline runner", usage: "br ci <pipeline>" },
  // Cloud
  cloudflare: { category: "cloud", description: "Cloudflare worker management", usage: "br cloudflare <cmd>" },
  ocean: { category: "cloud", description: "DigitalOcean droplet management", usage: "br ocean <cmd>" },
  vercel: { category: "cloud", description: "Vercel deployment", usage: "br vercel <cmd>" },
  // AI
  ai: { category: "ai", description: "AI model hub and routing", usage: "br ai <model> <prompt>" },
  cece: { category: "ai", description: "CECE identity system", usage: "br cece <cmd>" },
  radar: { category: "ai", description: "Context radar & suggestions", usage: "br radar" },
  // Security
  security: { category: "security", description: "Security scanner", usage: "br security scan" },
  vault: { category: "security", description: "Secrets vault", usage: "br vault <cmd>" },
  audit: { category: "security", description: "Audit logger", usage: "br audit <cmd>" },
  // Developer
  snippet: { category: "dev", description: "Code snippet manager", usage: "br snippet <cmd>" },
  git: { category: "dev", description: "Smart git integration", usage: "br git <cmd>" },
  test: { category: "dev", description: "Test runner", usage: "br test <cmd>" },
  // Infrastructure
  pi: { category: "iot", description: "Raspberry Pi fleet manager", usage: "br pi <cmd>" },
  db: { category: "data", description: "Database client", usage: "br db <cmd>" },
  backup: { category: "ops", description: "Backup manager", usage: "br backup <cmd>" },
  // Monitoring
  metrics: { category: "monitoring", description: "Metrics dashboard", usage: "br metrics" },
  monitor: { category: "monitoring", description: "Live system monitor", usage: "br monitor" },
  logs: { category: "monitoring", description: "Log parser", usage: "br logs <cmd>" },
  // Communication
  notify: { category: "comms", description: "Multi-channel notifications", usage: "br notify <channel> <msg>" },
  agent: { category: "ai", description: "Multi-agent task router", usage: "br agent <task>" },
};

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
};

function jsonResp(data, status = 200) {
  return Response.json(data, { status, headers: CORS });
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const path = url.pathname;

    if (request.method === "OPTIONS") return new Response(null, { headers: CORS });

    // GET / — tools overview
    if (path === "/" || path === "/tools") {
      const categories = {};
      for (const [id, tool] of Object.entries(TOOLS_REGISTRY)) {
        if (!categories[tool.category]) categories[tool.category] = [];
        categories[tool.category].push({ id, ...tool });
      }
      return jsonResp({
        name: "BlackRoad Tools API",
        version: "2.0.0",
        total_tools: 162,
        registered: Object.keys(TOOLS_REGISTRY).length,
        categories,
        pi_fleet: PI_BASE,
        timestamp: new Date().toISOString(),
      });
    }

    // GET /health
    if (path === "/health") {
      return jsonResp({ status: "ok", service: "tools-api", tools: 162, ts: Date.now() });
    }

    // GET /tool/:name — get tool info
    const toolInfo = path.match(/^\/tool\/([a-z-]+)$/);
    if (toolInfo && request.method === "GET") {
      const tool = TOOLS_REGISTRY[toolInfo[1]];
      if (!tool) return jsonResp({ error: "Tool not found" }, 404);
      return jsonResp({ id: toolInfo[1], ...tool, status: "available" });
    }

    // POST /tool/:name — execute tool via Pi fleet
    if (toolInfo && request.method === "POST") {
      const [, name] = toolInfo;
      const body = await request.json().catch(() => ({}));
      try {
        const resp = await fetch(`${PI_BASE}/tools/${name}`, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(body),
          signal: AbortSignal.timeout(30000),
        });
        const data = await resp.json().catch(() => ({ status: resp.status }));
        return jsonResp({ tool: name, result: data, executed_on: PI_BASE });
      } catch (e) {
        return jsonResp({ error: "Pi fleet unreachable", tool: name, detail: e.message }, 503);
      }
    }

    // Proxy all /tools/* to Pi
    if (path.startsWith("/tools/")) {
      try {
        const r = await fetch(PI_BASE + path + url.search, {
          method: request.method,
          headers: { ...Object.fromEntries(request.headers), "X-Forwarded-By": "tools-api-worker" },
          body: request.method !== "GET" ? request.body : undefined,
        });
        return new Response(r.body, { status: r.status, headers: { ...Object.fromEntries(r.headers), ...CORS } });
      } catch (e) {
        return jsonResp({ error: "Pi fleet unreachable", detail: e.message }, 503);
      }
    }

    return jsonResp({ error: "Not found", available: ["/tools", "/tool/:name", "/health"] }, 404);
  }
};
