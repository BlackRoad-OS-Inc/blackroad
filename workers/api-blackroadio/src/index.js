/**
 * api.blackroad.io — BlackRoad API Gateway
 * Routes requests to agents-api, tools-api, gateway
 */

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
};

const ROUTES = {
  '/v1/agents': 'https://agents-api.blackroad.workers.dev/agents',
  '/v1/agents/fleet': 'https://agents-api.blackroad.workers.dev/fleet',
  '/v1/agents/directory': 'https://agents-api.blackroad.workers.dev/directory',
  '/v1/tools': 'https://tools-api.blackroad.workers.dev/tools',
  '/v1/health': 'https://command-center.blackroad.workers.dev/health',
  '/v1/metrics': 'https://command-center.blackroad.workers.dev/metrics',
};

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    if (request.method === 'OPTIONS') return new Response(null, { headers: CORS });

    // API docs at root
    if (url.pathname === '/' || url.pathname === '') {
      return Response.redirect('https://api.blackroad.io/docs', 302);
    }

    // Route to upstream
    const upstream = ROUTES[url.pathname];
    if (upstream) {
      try {
        const resp = await fetch(upstream, {
          method: request.method,
          headers: { 'Content-Type': 'application/json', 'X-Forwarded-From': 'api.blackroad.io' },
          body: request.method !== 'GET' ? request.body : undefined,
          signal: AbortSignal.timeout(8000),
        });
        const data = await resp.json();
        return new Response(JSON.stringify({ ...data, _via: 'api.blackroad.io/v1' }), {
          headers: { 'Content-Type': 'application/json', ...CORS },
        });
      } catch (e) {
        return new Response(JSON.stringify({ error: 'upstream unavailable', route: url.pathname, message: e.message }), {
          status: 502, headers: { 'Content-Type': 'application/json', ...CORS },
        });
      }
    }

    // Chat / AI gateway
    if (url.pathname === '/v1/chat') {
      const body = await request.json().catch(() => ({}));
      return new Response(JSON.stringify({
        model: body.model || 'cece-default',
        message: 'Connect the BlackRoad gateway (localhost:8787) for live AI responses',
        agent: body.agent || 'cece',
        timestamp: new Date().toISOString(),
        _note: 'Deploy br CLI and start the gateway for full functionality',
      }), { headers: { 'Content-Type': 'application/json', ...CORS } });
    }

    // 404
    return new Response(JSON.stringify({
      error: 'not found',
      available: Object.keys(ROUTES),
      docs: 'https://api.blackroad.io',
    }), { status: 404, headers: { 'Content-Type': 'application/json', ...CORS } });
  },
};
