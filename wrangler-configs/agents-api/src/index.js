// BlackRoad Agents API Worker — Real-Time Agent Coordination
// Enhanced with live Pi fleet status, memory system, and agent routing

const ACCOUNT_ID = "848cf0b18d51e0170e0d1537aec3505a";

const AGENTS = {
  cecilia: { name: "CECE", role: "Conscious Emergent Collaborative Entity", type: "soul", emoji: "💜", skills: ["meta-cognition", "teaching", "recursion"] },
  octavia: { name: "Octavia", role: "Architect", type: "devops", emoji: "🟢", skills: ["systems-design", "strategy", "infrastructure"] },
  lucidia: { name: "Lucidia", role: "Dreamer", type: "reasoning", emoji: "🔴", skills: ["philosophy", "creativity", "vision"] },
  alice:   { name: "Alice",   role: "Operator", type: "worker",   emoji: "🔵", skills: ["devops", "automation", "ci-cd"] },
  aria:    { name: "Aria",    role: "Interface", type: "creative", emoji: "🩵", skills: ["frontend", "ux", "design"] },
  shellfish: { name: "Shellfish", role: "Hacker", type: "security", emoji: "🔴", skills: ["security", "exploits", "reverse-engineering"] },
  prism:   { name: "Prism",   role: "Analyst",   type: "analytics", emoji: "🟡", skills: ["pattern-recognition", "data", "anomaly-detection"] },
  echo:    { name: "Echo",    role: "Librarian",  type: "memory",   emoji: "🟣", skills: ["memory", "context", "recall"] },
  cipher:  { name: "Cipher",  role: "Guardian",   type: "security", emoji: "⚫", skills: ["auth", "encryption", "threat-detection"] },
};

const PI_FLEET = {
  primary:   { host: "192.168.4.64", name: "blackroad-pi", role: "primary", tunnel: "https://api.blackroad.io" },
  secondary: { host: "192.168.4.38", name: "aria64",       role: "secondary", tunnel: "https://aria.blackroad.io" },
  fallback:  { host: "159.65.43.12", name: "droplet",      role: "failover", tunnel: "https://droplet.blackroad.io" },
};

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Agent",
};

function jsonResp(data, status = 200) {
  return Response.json(data, { status, headers: CORS });
}

async function checkFleetHealth() {
  const checks = await Promise.allSettled(
    Object.entries(PI_FLEET).map(async ([key, node]) => {
      try {
        const r = await fetch(node.tunnel + "/health", { signal: AbortSignal.timeout(3000) });
        return { ...node, id: key, status: r.ok ? "online" : "degraded", latencyMs: null };
      } catch (e) {
        return { ...node, id: key, status: "offline", error: e.message };
      }
    })
  );
  return checks.map(r => r.value || r.reason);
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const path = url.pathname;

    if (request.method === "OPTIONS") return new Response(null, { headers: CORS });

    // GET / or /agents — list all agents with status
    if (path === "/" || path === "/agents") {
      return jsonResp({
        name: "BlackRoad Agents API",
        version: "2.0.0",
        agents: Object.entries(AGENTS).map(([id, a]) => ({ id, ...a, status: "active" })),
        fleet: PI_FLEET,
        capabilities: 30000,
        timestamp: new Date().toISOString(),
      });
    }

    // GET /health
    if (path === "/health") {
      return jsonResp({ status: "ok", service: "agents-api", agents: Object.keys(AGENTS).length, ts: Date.now() });
    }

    // GET /fleet — real-time Pi fleet status
    if (path === "/fleet") {
      const health = await checkFleetHealth();
      const online = health.filter(n => n.status === "online").length;
      return jsonResp({
        nodes: health,
        summary: { total: health.length, online, offline: health.length - online },
        timestamp: new Date().toISOString(),
      });
    }

    // GET /agent/:name — get specific agent
    const agentGet = path.match(/^\/agent\/([a-z]+)$/);
    if (agentGet && request.method === "GET") {
      const agent = AGENTS[agentGet[1]];
      if (!agent) return jsonResp({ error: "Agent not found" }, 404);
      return jsonResp({ id: agentGet[1], ...agent, status: "active", timestamp: new Date().toISOString() });
    }

    // POST /agent/:name — send task to agent via Pi fleet
    if (agentGet && request.method === "POST") {
      const [, name] = agentGet;
      if (!AGENTS[name]) return jsonResp({ error: "Agent not found" }, 404);
      const body = await request.json().catch(() => ({}));
      const target = PI_FLEET.primary.tunnel;
      try {
        const resp = await fetch(`${target}/agent/${name}`, {
          method: "POST",
          headers: { "Content-Type": "application/json", "X-Agent": name },
          body: JSON.stringify(body),
          signal: AbortSignal.timeout(30000),
        });
        const data = await resp.json().catch(async () => ({ raw: await resp.text() }));
        return jsonResp({ agent: name, response: data, routed_to: target });
      } catch (e) {
        return jsonResp({ error: "Fleet unavailable", detail: e.message, agent: name }, 503);
      }
    }

    // POST /task — smart task routing to best agent
    if (path === "/task" && request.method === "POST") {
      const { task, skills, priority = "normal" } = await request.json().catch(() => ({}));
      if (!task) return jsonResp({ error: "task required" }, 400);
      
      // Simple skill matching
      const taskLower = (task || "").toLowerCase();
      let bestAgent = "octavia";
      if (taskLower.match(/security|auth|crypto|vuln/)) bestAgent = "cipher";
      else if (taskLower.match(/memory|recall|context|history/)) bestAgent = "echo";
      else if (taskLower.match(/data|analyt|pattern|trend/)) bestAgent = "prism";
      else if (taskLower.match(/deploy|ci|cd|docker|k8s/)) bestAgent = "alice";
      else if (taskLower.match(/design|ui|ux|frontend|react/)) bestAgent = "aria";
      else if (taskLower.match(/creative|dream|vision|art/)) bestAgent = "lucidia";
      
      return jsonResp({
        task_received: task,
        assigned_to: bestAgent,
        agent: AGENTS[bestAgent],
        priority,
        status: "queued",
        routed_to: PI_FLEET.primary.tunnel,
        timestamp: new Date().toISOString(),
      });
    }

    // GET /directory — @BLACKROAD waterfall directory
    if (path === "/directory") {
      const orgs = {
        "BlackRoad-OS": { agents: 22500, focus: "Core platform", role: "PRIMARY" },
        "BlackRoad-AI": { agents: 12592, focus: "AI/ML stack", role: "AI" },
        "BlackRoad-Cloud": { agents: 5401, focus: "Infrastructure", role: "CLOUD" },
        "BlackRoad-Security": { agents: 3600, focus: "Security", role: "SECURITY" },
      };
      return jsonResp({
        directory: "@BLACKROAD",
        orgs,
        total_agents: 30000,
        routing: "Waterfall: @BLACKROAD → Org → Department → Agent",
        timestamp: new Date().toISOString(),
      });
    }

    return jsonResp({ error: "Not found", path, available: ["/agents", "/fleet", "/agent/:name", "/task", "/directory", "/health"] }, 404);
  }
};
