/**
 * BlackRoad Smart Router — Failover Cascade
 * Pi fleet → DigitalOcean → Cloudflare Pages → GitHub Pages → Railway
 */

export interface Env {
  // Cloudflare Tunnel origin for Pi fleet
  PI_TUNNEL_URL: string;     // e.g. https://api.blackroad.io (octavia tunnel)
  // DigitalOcean droplet direct IP (hot standby)
  DO_ORIGIN: string;         // e.g. http://159.65.43.12
  // CF Pages fallback
  CF_PAGES_URL: string;      // e.g. https://blackroad.pages.dev
  // GitHub Pages cold standby
  GH_PAGES_URL: string;      // e.g. https://blackroad-os.github.io/blackroad
  // Railway last-resort
  RAILWAY_URL: string;       // e.g. https://blackroad.up.railway.app
}

const TIMEOUT_MS = 3000;

async function tryFetch(url: string, request: Request, timeout = TIMEOUT_MS): Promise<Response | null> {
  try {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), timeout);
    const newUrl = new URL(request.url);
    const origin = new URL(url);
    newUrl.hostname = origin.hostname;
    newUrl.protocol = origin.protocol;
    newUrl.port = origin.port;
    const resp = await fetch(newUrl.toString(), {
      method: request.method,
      headers: request.headers,
      body: ['GET', 'HEAD'].includes(request.method) ? undefined : request.body,
      signal: controller.signal,
    });
    clearTimeout(timer);
    if (resp.ok) return resp;
    return null;
  } catch {
    return null;
  }
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);
    const origins = [
      { name: 'pi-tunnel',   url: env.PI_TUNNEL_URL,  tier: 1 },
      { name: 'digitalocean', url: env.DO_ORIGIN,      tier: 2 },
      { name: 'cf-pages',    url: env.CF_PAGES_URL,   tier: 3 },
      { name: 'github-pages', url: env.GH_PAGES_URL,  tier: 4 },
      { name: 'railway',     url: env.RAILWAY_URL,    tier: 5 },
    ].filter(o => o.url);

    for (const origin of origins) {
      const resp = await tryFetch(origin.url, request);
      if (resp) {
        const headers = new Headers(resp.headers);
        headers.set('X-BlackRoad-Tier', String(origin.tier));
        headers.set('X-BlackRoad-Origin', origin.name);
        return new Response(resp.body, { status: resp.status, headers });
      }
    }

    return new Response(
      JSON.stringify({ error: 'All origins unavailable', tiers: origins.length }),
      { status: 503, headers: { 'Content-Type': 'application/json' } }
    );
  },

  // Health check endpoint called by continuous-engine
  async scheduled(event: ScheduledEvent, env: Env, ctx: ExecutionContext): Promise<void> {
    const results: Record<string, boolean> = {};
    for (const origin of [
      { name: 'pi', url: env.PI_TUNNEL_URL },
      { name: 'do', url: env.DO_ORIGIN },
    ]) {
      if (!origin.url) continue;
      try {
        const r = await fetch(`${origin.url}/health`, { signal: AbortSignal.timeout(3000) });
        results[origin.name] = r.ok;
      } catch {
        results[origin.name] = false;
      }
    }
    console.log('Health check results:', JSON.stringify(results));
  },
};
