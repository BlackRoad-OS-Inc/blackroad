/**
 * BlackRoad OS Worker — Multi-service router
 * Routes requests to Pi fleet, agents, and internal services
 */

const ROUTES = {
  '/agents':    'http://192.168.4.89:8080',
  '/api':       'http://192.168.4.49:3000',
  '/tools':     'http://192.168.4.89:9090',
  '/command':   'http://192.168.4.82:8787',
  '/health':    null,  // local handler
};

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    const path = url.pathname;

    if (path === '/health' || path === '/') {
      return new Response(JSON.stringify({
        status: 'ok',
        service: env.SERVICE_NAME || 'blackroad-worker',
        version: '1.0.0',
        timestamp: new Date().toISOString(),
        fleet: {
          cecilia: '192.168.4.89',
          aria: '192.168.4.82',
          alice: '192.168.4.49',
          octavia: '192.168.4.38',
          anastasia: '174.138.44.45',
        }
      }), {
        headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' }
      });
    }

    // CORS preflight
    if (request.method === 'OPTIONS') {
      return new Response(null, {
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type, Authorization',
        }
      });
    }

    // Find matching route prefix
    const route = Object.keys(ROUTES).find(r => path.startsWith(r));
    if (route && ROUTES[route]) {
      const targetUrl = ROUTES[route] + path.slice(route.length) + url.search;
      const proxied = new Request(targetUrl, {
        method: request.method,
        headers: request.headers,
        body: request.method !== 'GET' ? request.body : undefined,
      });
      try {
        return await fetch(proxied);
      } catch (e) {
        return new Response(JSON.stringify({ error: 'upstream unavailable', route, target: ROUTES[route] }), {
          status: 502, headers: { 'Content-Type': 'application/json' }
        });
      }
    }

    return new Response(JSON.stringify({ error: 'not found', path }), {
      status: 404, headers: { 'Content-Type': 'application/json' }
    });
  }
};
