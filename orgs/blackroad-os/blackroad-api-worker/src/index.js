export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    
    // CORS headers
    const headers = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
      'Content-Type': 'application/json'
    };
    
    if (request.method === 'OPTIONS') {
      return new Response(null, { headers });
    }
    
    // API Routes
    const routes = {
      '/': { message: 'BlackRoad API Gateway', version: '1.0.0', docs: 'https://docs.blackroad.io' },
      '/health': { status: 'healthy', timestamp: new Date().toISOString() },
      '/status': { api: 'online', workers: 20, pages: 206, agents: 7 },
      '/agents': [
        { name: 'CECE', host: 'cecilia', role: 'Primary AI Coordinator', status: 'online' },
        { name: 'LUCIDIA', host: 'lucidia', role: 'Knowledge Keeper', status: 'online' },
        { name: 'ARIA', host: 'aria', role: 'Harmony Protocol', status: 'online' },
        { name: 'OCTAVIA', host: 'octavia', role: 'Multi-Processor', status: 'online' },
        { name: 'ALICE', host: 'alice', role: 'Worker Bee', status: 'online' },
        { name: 'SHELLFISH', host: 'shellfish', role: 'Edge Gateway', status: 'online' },
        { name: 'CODEX', host: 'codex-infinity', role: 'Cloud Oracle', status: 'online' }
      ]
    };
    
    const path = url.pathname;
    const data = routes[path] || { error: 'Not Found', available: Object.keys(routes) };
    
    return new Response(JSON.stringify(data, null, 2), { 
      status: routes[path] ? 200 : 404,
      headers 
    });
  }
};
