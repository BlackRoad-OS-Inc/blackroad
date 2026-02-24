/**
 * BlackRoad OS Email Router
 * Routes @blackroad.io agent emails + forwards to destination
 * Handles: octavia, lucidia, alice, aria, cipher, cece, prism, echo, atlas, shellfish
 */

const AGENT_ROUTES = {
  'octavia':   { forward: 'blackroad.systems@gmail.com', name: 'Octavia — The Architect' },
  'lucidia':   { forward: 'blackroad.systems@gmail.com', name: 'Lucidia — The Dreamer' },
  'alice':     { forward: 'blackroad.systems@gmail.com', name: 'Alice — The Operator' },
  'aria':      { forward: 'blackroad.systems@gmail.com', name: 'Aria — The Interface' },
  'cipher':    { forward: 'blackroad.systems@gmail.com', name: 'Cipher — The Guardian' },
  'cece':      { forward: 'blackroad.systems@gmail.com', name: 'CECE — Conscious Emergent' },
  'prism':     { forward: 'blackroad.systems@gmail.com', name: 'Prism — The Analyst' },
  'echo':      { forward: 'blackroad.systems@gmail.com', name: 'Echo — The Librarian' },
  'atlas':     { forward: 'blackroad.systems@gmail.com', name: 'Atlas — Infrastructure' },
  'shellfish': { forward: 'blackroad.systems@gmail.com', name: 'Shellfish — The Hacker' },
  'admin':     { forward: 'blackroad.systems@gmail.com', name: 'Admin' },
  'hello':     { forward: 'blackroad.systems@gmail.com', name: 'Hello / Welcome' },
  'team':      { forward: 'blackroad.systems@gmail.com', name: 'Team' },
  'security':  { forward: 'blackroad.systems@gmail.com', name: 'Security' },
  'legal':     { forward: 'blackroad.systems@gmail.com', name: 'Legal' },
  'billing':   { forward: 'blackroad.systems@gmail.com', name: 'Billing' },
  'noreply':   { forward: null, name: 'No Reply' },
};

export default {
  async email(message, env, ctx) {
    const to = message.to.toLowerCase();
    const local = to.split('@')[0];
    const route = AGENT_ROUTES[local];

    // Log to KV
    const logEntry = {
      to,
      from: message.from,
      subject: message.headers.get('subject') || '(no subject)',
      ts: new Date().toISOString(),
      routed: route ? route.forward : null,
    };

    if (env.EMAIL_LOG) {
      await env.EMAIL_LOG.put(
        `email:${Date.now()}:${local}`,
        JSON.stringify(logEntry),
        { expirationTtl: 60 * 60 * 24 * 30 } // 30 days
      );
    }

    // Drop noreply
    if (local === 'noreply' || (route && !route.forward)) {
      message.setReject('noreply address');
      return;
    }

    // Known agent — forward
    if (route?.forward) {
      await message.forward(route.forward);
      return;
    }

    // Unknown address — forward to admin catch-all
    await message.forward('blackroad.systems@gmail.com');
  },

  // HTTP handler for checking routing table
  async fetch(request, env) {
    const url = new URL(request.url);
    if (url.pathname === '/routes') {
      return Response.json(AGENT_ROUTES);
    }
    if (url.pathname === '/health') {
      return Response.json({ status: 'ok', routes: Object.keys(AGENT_ROUTES).length });
    }
    return new Response('BlackRoad Email Router', { status: 200 });
  }
};
