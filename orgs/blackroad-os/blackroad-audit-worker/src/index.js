export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    const service = url.hostname.split('.')[0];
    
    const headers = {
      'Access-Control-Allow-Origin': '*',
      'Content-Type': 'application/json'
    };
    
    const data = {
      service: `BlackRoad ${service.charAt(0).toUpperCase() + service.slice(1)} API`,
      version: '1.0.0',
      status: 'operational',
      timestamp: new Date().toISOString(),
      endpoints: {
        health: '/health',
        status: '/status'
      }
    };
    
    if (url.pathname === '/health') {
      return new Response(JSON.stringify({ status: 'healthy' }), { headers });
    }
    
    return new Response(JSON.stringify(data, null, 2), { headers });
  }
};
