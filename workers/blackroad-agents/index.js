// BlackRoad Agents Worker — routes requests to the right Pi agent
// Deploys from: gematria (online) or any Pi runner

const AGENTS = {
  gematria:  { ip: '159.65.43.12',    port: 8787, status: 'online'  },
  octavia:   { ip: '100.66.235.47',   port: 8787, status: 'pending' },
  alice:     { ip: '100.77.210.18',   port: 8787, status: 'pending' },
  aria:      { ip: '100.109.14.17',   port: 8787, status: 'pending' },
  lucidia:   { ip: '100.83.149.86',   port: 8787, status: 'pending' },
};

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    const agent = url.pathname.split('/')[1] || 'gematria';
    const path  = '/' + url.pathname.split('/').slice(2).join('/');

    // Health check
    if (url.pathname === '/health') {
      return Response.json({ status: 'ok', agents: Object.keys(AGENTS), ts: Date.now() });
    }

    // Agent list
    if (url.pathname === '/agents') {
      return Response.json(AGENTS);
    }

    const target = AGENTS[agent];
    if (!target) {
      return Response.json({ error: `Unknown agent: ${agent}`, available: Object.keys(AGENTS) }, { status: 404 });
    }

    // Route to agent
    const upstream = `http://${target.ip}:${target.port}${path}${url.search}`;
    try {
      const resp = await fetch(upstream, {
        method: request.method,
        headers: { ...Object.fromEntries(request.headers), 'X-Routed-By': 'blackroad-agents-worker', 'X-Agent': agent },
        body: request.method !== 'GET' ? request.body : undefined,
      });
      return new Response(resp.body, { status: resp.status, headers: resp.headers });
    } catch (e) {
      return Response.json({ error: 'Agent unreachable', agent, detail: e.message }, { status: 502 });
    }
  }
};
