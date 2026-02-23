// BlackRoad Multi-Agent Gateway Worker
// Routes to Pi fleet based on agent name in path/header
// Deployed on: workers.blackroad.io

const AGENTS = {
  OCTAVIA: { host: "http://192.168.4.38:4010", role: "primary-compute" },
  ALICE:   { host: "http://192.168.4.49:8001", role: "task-queue" },
  GEMATRIA:{ host: "https://api.blackroad.io", role: "108-models" },
  LUCIDIA: { host: "http://192.168.4.38:11434", role: "llm" },
  ARIA:    { host: "http://192.168.4.38:3000", role: "world-api" },
};

const GATEWAY = "https://api.blackroad.io";

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const path = url.pathname;
    
    // Health check
    if (path === "/" || path === "/health") {
      return Response.json({
        service: "BlackRoad Agent Gateway",
        version: "3.0",
        agents: Object.keys(AGENTS),
        gateway: GATEWAY,
        pi_primary: env.BLACKROAD_PI_PRIMARY || "192.168.4.38",
        qdrant: env.BLACKROAD_QDRANT || "192.168.4.49:6333",
        timestamp: new Date().toISOString()
      });
    }

    // Agent-specific routing: /agent/OCTAVIA/... or /OCTAVIA/...
    const agentMatch = path.match(/^\/(?:agent\/)?([A-Z]+)(\/.*)?$/);
    if (agentMatch) {
      const agentName = agentMatch[1].toUpperCase();
      const subpath = agentMatch[2] || "/";
      const agent = AGENTS[agentName];
      
      if (agent) {
        try {
          const upstream = agent.host + subpath + url.search;
          const resp = await fetch(upstream, {
            method: request.method,
            headers: { ...Object.fromEntries(request.headers), "X-BlackRoad-Agent": agentName },
            body: request.body
          });
          const body = await resp.text();
          return new Response(body, {
            status: resp.status,
            headers: {
              "Content-Type": resp.headers.get("Content-Type") || "application/json",
              "X-BlackRoad-Agent": agentName,
              "X-BlackRoad-Version": "3.0"
            }
          });
        } catch(e) {
          // Fallback to gateway
          try {
            const fallback = GATEWAY + subpath + url.search;
            return await fetch(fallback, { method: request.method, body: request.body });
          } catch(e2) {
            return Response.json({ error: e.message, agent: agentName, fallback: GATEWAY }, { status: 502 });
          }
        }
      }
    }

    // Webhooks: /webhooks/salesforce, /webhooks/railway, etc.
    if (path.startsWith("/webhooks/")) {
      const upstream = env.BLACKROAD_PI_PRIMARY || "http://192.168.4.38:4010";
      try {
        return await fetch(upstream + path, {
          method: request.method,
          headers: request.headers,
          body: request.body
        });
      } catch(e) {
        return Response.json({ received: true, queued: true, error: e.message }, { status: 200 });
      }
    }

    // Default: proxy to gateway
    try {
      return await fetch(GATEWAY + path + url.search, {
        method: request.method,
        headers: request.headers,
        body: request.body
      });
    } catch(e) {
      return Response.json({ error: e.message, gateway: GATEWAY }, { status: 503 });
    }
  }
};
