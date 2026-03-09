/**
 * console.blackroad.io — BlackRoad Prism Console API
 * Handles admin operations: agent management, task queue ops, system status.
 */
export interface Env {
  BLACKROAD_GATEWAY_URL: string;
  ADMIN_TOKEN: string;
  CACHE: KVNamespace;
}

function unauthorized() {
  return Response.json({ error: "Unauthorized" }, { status: 401 });
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);
    if (request.method === "OPTIONS") return new Response(null, {
      headers: { "Access-Control-Allow-Origin": "https://console.blackroad.io",
                 "Access-Control-Allow-Methods": "GET, POST, DELETE, OPTIONS",
                 "Access-Control-Allow-Headers": "Content-Type, Authorization" }
    });

    const auth = request.headers.get("Authorization");
    if (!auth || auth !== `Bearer ${env.ADMIN_TOKEN}`) return unauthorized();

    const gateway = env.BLACKROAD_GATEWAY_URL || "http://127.0.0.1:8787";

    // System status (cached 5s)
    if (url.pathname === "/console/status" && request.method === "GET") {
      const cached = await env.CACHE.get("console:status");
      if (cached) return Response.json(JSON.parse(cached));
      const [health, agents, tasks] = await Promise.allSettled([
        fetch(`${gateway}/health`).then(r => r.json()),
        fetch(`${gateway}/agents`).then(r => r.json()),
        fetch(`${gateway}/tasks`).then(r => r.json()),
      ]);
      const status = {
        health: health.status === "fulfilled" ? health.value : null,
        agent_count: agents.status === "fulfilled" ? (agents.value.agents?.length ?? 0) : 0,
        task_count: tasks.status === "fulfilled" ? (tasks.value.tasks?.length ?? 0) : 0,
        timestamp: Date.now(),
      };
      await env.CACHE.put("console:status", JSON.stringify(status), { expirationTtl: 5 });
      return Response.json(status);
    }

    // Proxy everything else
    const body = request.method !== "GET" ? await request.text() : undefined;
    const path = url.pathname.replace("/console", "");
    const resp = await fetch(`${gateway}${path}${url.search}`, {
      method: request.method, headers: { "Content-Type": "application/json" }, body
    });
    return new Response(await resp.text(), {
      status: resp.status,
      headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "https://console.blackroad.io" }
    });
  },
};
