/**
 * dashboard.blackroad.io — Real-time metrics dashboard worker
 * Aggregates data from gateway: agents, tasks, memory stats.
 */
export interface Env { BLACKROAD_GATEWAY_URL: string; CACHE: KVNamespace; }

export default {
  async fetch(req: Request, env: Env): Promise<Response> {
    const url = new URL(req.url);
    const gw = env.BLACKROAD_GATEWAY_URL || "http://127.0.0.1:8787";
    const cors = { "Access-Control-Allow-Origin": "*", "Content-Type": "application/json" };

    if (req.method === "OPTIONS") return new Response(null, { headers: cors });

    if (url.pathname === "/dashboard/metrics") {
      const cached = await env.CACHE.get("dashboard:metrics");
      if (cached) return new Response(cached, { headers: { ...cors, "X-Cache": "HIT" } });

      const [agents, tasks, health] = await Promise.allSettled([
        fetch(`${gw}/agents`).then(r => r.ok ? r.json() : null),
        fetch(`${gw}/tasks`).then(r => r.ok ? r.json() : null),
        fetch(`${gw}/health`).then(r => r.ok ? r.json() : null),
      ]);

      const metrics = {
        agents: {
          total: agents.status === "fulfilled" && agents.value ? agents.value.agents?.length ?? 0 : 0,
          active: 0,
        },
        tasks: {
          total: tasks.status === "fulfilled" && tasks.value ? tasks.value.tasks?.length ?? 0 : 0,
          pending: 0, running: 0, completed: 0,
        },
        gateway: { status: health.status === "fulfilled" && health.value ? "ok" : "down" },
        timestamp: Date.now(),
      };
      const body = JSON.stringify(metrics);
      await env.CACHE.put("dashboard:metrics", body, { expirationTtl: 5 });
      return new Response(body, { headers: cors });
    }

    return Response.json({ service: "dashboard.blackroad.io", endpoints: ["/dashboard/metrics"] }, { headers: cors });
  }
};
