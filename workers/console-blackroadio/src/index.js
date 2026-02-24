/**
 * console.blackroad.io — BlackRoad OS Admin Console
 * Real-time orchestration dashboard
 */

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const CORS = { 'Access-Control-Allow-Origin': '*', 'Access-Control-Allow-Methods': 'GET, POST, OPTIONS' };
    
    if (request.method === 'OPTIONS') return new Response(null, { headers: CORS });

    if (url.pathname === '/api/status') {
      // Aggregate status from all services
      const checks = await Promise.allSettled([
        fetch('https://agents-api.blackroad.workers.dev/health', { signal: AbortSignal.timeout(3000) }),
        fetch('https://tools-api.blackroad.workers.dev/health', { signal: AbortSignal.timeout(3000) }),
        fetch('https://command-center.blackroad.workers.dev/health', { signal: AbortSignal.timeout(3000) }),
      ]);

      const services = ['agents-api', 'tools-api', 'command-center'].map((name, i) => ({
        name,
        status: checks[i].status === 'fulfilled' && checks[i].value?.ok ? 'operational' : 'offline',
      }));

      return new Response(JSON.stringify({
        services,
        agents: { named: 6, fleet: 30000 },
        workers: { count: 75, deployed: services.filter(s => s.status === 'operational').length },
        timestamp: new Date().toISOString(),
      }), { headers: { 'Content-Type': 'application/json', ...CORS } });
    }

    // Serve console HTML
    return new Response(await fetch('https://console.blackroad.io').then(r => r.text()).catch(() => '<h1>Console</h1>'), {
      headers: { 'Content-Type': 'text/html', ...CORS },
    });
  },
};
