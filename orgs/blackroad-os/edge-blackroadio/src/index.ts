/**
 * edge.blackroad.io — Edge cache + CDN worker
 * Caches static assets and API responses at the Cloudflare edge.
 */
export interface Env { CACHE: KVNamespace; }
const CACHEABLE_PREFIXES = ["/v1/models", "/agents", "/health"];
const CACHE_TTL: Record<string, number> = { "/health": 5, "/agents": 10, "/v1/models": 300 };

export default {
  async fetch(req: Request, env: Env): Promise<Response> {
    const url = new URL(req.url);
    const prefix = CACHEABLE_PREFIXES.find(p => url.pathname.startsWith(p));

    if (req.method === "GET" && prefix) {
      const cacheKey = `edge:${url.pathname}${url.search}`;
      const cached = await env.CACHE.get(cacheKey);
      if (cached) {
        return new Response(cached, {
          headers: { "Content-Type": "application/json", "X-Cache": "HIT", "Access-Control-Allow-Origin": "*" }
        });
      }
    }

    // Pass through to origin
    const origin = req.headers.get("X-Origin") || "http://127.0.0.1:8787";
    const resp = await fetch(`${origin}${url.pathname}${url.search}`, {
      method: req.method, headers: { "Content-Type": "application/json" },
      body: req.method !== "GET" ? await req.text() : undefined
    });

    const body = await resp.text();
    if (req.method === "GET" && prefix && resp.ok) {
      await env.CACHE.put(`edge:${url.pathname}${url.search}`, body, {
        expirationTtl: CACHE_TTL[prefix] ?? 30
      });
    }

    return new Response(body, {
      status: resp.status,
      headers: { "Content-Type": "application/json", "X-Cache": "MISS", "Access-Control-Allow-Origin": "*" }
    });
  }
};
