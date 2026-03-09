/**
 * data.blackroad.io — Data access API
 * Provides structured access to BlackRoad memory entries and analytics.
 */
export interface Env { BLACKROAD_GATEWAY_URL: string; }
export default {
  async fetch(req: Request, env: Env): Promise<Response> {
    const url = new URL(req.url);
    const gw = env.BLACKROAD_GATEWAY_URL || "http://127.0.0.1:8787";
    const cors = { "Access-Control-Allow-Origin": "*", "Content-Type": "application/json" };

    if (req.method === "OPTIONS") return new Response(null, { headers: cors });

    if (url.pathname.startsWith("/data/memory")) {
      const key = url.searchParams.get("key");
      const endpoint = key ? `/memory/${key}` : "/memory";
      const r = await fetch(`${gw}${endpoint}`);
      return new Response(await r.text(), { status: r.status, headers: cors });
    }

    return Response.json({ service: "data.blackroad.io", endpoints: ["/data/memory", "/data/memory?key=..."] }, { headers: cors });
  }
};
