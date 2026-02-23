// BlackRoad aria Agent Worker
export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const agent = env.AGENT_NAME || "ARIA";
    
    // Proxy to Pi gateway
    if (url.pathname.startsWith('/api/')) {
      try {
        const upstream = env.BLACKROAD_GATEWAY_URL + url.pathname + url.search;
        const resp = await fetch(upstream, {
          method: request.method,
          headers: request.headers,
          body: request.body
        });
        return resp;
      } catch(e) {
        return Response.json({ error: e.message, agent, fallback: true }, { status: 502 });
      }
    }
    
    return Response.json({
      agent,
      gateway: env.BLACKROAD_GATEWAY_URL,
      pi: env.BLACKROAD_PI_PRIMARY,
      status: "online",
      timestamp: new Date().toISOString()
    });
  }
};
