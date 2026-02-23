/**
 * ◆ BlackRoad OS — Email Router Worker
 * Routes inbound @blackroad.io email to agent inboxes
 * Cloudflare Email Routing Worker
 */

const AGENT_ROUTES = {
  'lucidia':  { name: 'Lucidia',  role: 'The Dreamer',    forward: 'blackroad@gmail.com' },
  'alice':    { name: 'Alice',    role: 'The Operator',   forward: 'blackroad@gmail.com' },
  'octavia':  { name: 'Octavia',  role: 'The Architect',  forward: 'blackroad@gmail.com' },
  'aria':     { name: 'Aria',     role: 'The Interface',  forward: 'blackroad@gmail.com' },
  'cipher':   { name: 'Cipher',   role: 'The Guardian',   forward: 'blackroad@gmail.com' },
  'prism':    { name: 'Prism',    role: 'The Analyst',    forward: 'blackroad@gmail.com' },
  'echo':     { name: 'Echo',     role: 'The Librarian',  forward: 'blackroad@gmail.com' },
  'cece':     { name: 'CECE',     role: 'The Identity',   forward: 'blackroad@gmail.com' },
  'agents':   { name: 'Agents',   role: 'Agent Mesh',     forward: 'blackroad@gmail.com' },
  'hello':    { name: 'BlackRoad', role: 'General',       forward: 'blackroad@gmail.com' },
  'noreply':  { name: 'System',   role: 'System',         forward: null },
};

export default {
  async email(message, env, ctx) {
    const to = message.to.toLowerCase();
    const from = message.from;
    const subject = message.headers.get('subject') || '(no subject)';

    // Extract local part (before @)
    const local = to.split('@')[0];
    const agent = AGENT_ROUTES[local];

    // Log to KV for agent inbox (non-blocking)
    if (env.AGENT_INBOXES) {
      const entry = {
        id: `msg_${Date.now()}_${Math.random().toString(36).slice(2,8)}`,
        to,
        from,
        subject,
        agent_id: local,
        received_at: new Date().toISOString(),
      };
      ctx.waitUntil(
        env.AGENT_INBOXES.put(
          `inbox:${local}:${entry.id}`,
          JSON.stringify(entry),
          { expirationTtl: 60 * 60 * 24 * 30 } // 30 days
        )
      );
    }

    // Route to agent forward address
    if (agent && agent.forward) {
      await message.forward(agent.forward, new Headers({
        'X-BlackRoad-Agent': agent.name,
        'X-BlackRoad-Role': agent.role,
        'X-BlackRoad-Original-To': to,
      }));
      return;
    }

    // noreply — reject politely
    if (local === 'noreply') {
      message.setReject('This address does not accept replies.');
      return;
    }

    // Unknown address — forward to hello
    await message.forward('blackroad@gmail.com', new Headers({
      'X-BlackRoad-Agent': 'Unknown',
      'X-BlackRoad-Original-To': to,
    }));
  },

  // HTTP handler for inbox API
  async fetch(request, env) {
    const url = new URL(request.url);

    if (url.pathname === '/health') {
      return Response.json({ status: 'ok', service: 'blackroad-email-router' });
    }

    // GET /inbox/:agent — list messages for agent
    const match = url.pathname.match(/^\/inbox\/([a-z]+)$/);
    if (match && request.method === 'GET') {
      const agentId = match[1];
      if (!AGENT_ROUTES[agentId]) {
        return Response.json({ error: 'Unknown agent' }, { status: 404 });
      }
      if (!env.AGENT_INBOXES) {
        return Response.json({ messages: [], note: 'KV not configured' });
      }
      const list = await env.AGENT_INBOXES.list({ prefix: `inbox:${agentId}:` });
      const messages = await Promise.all(
        list.keys.slice(0, 20).map(async k => {
          const val = await env.AGENT_INBOXES.get(k.name);
          return val ? JSON.parse(val) : null;
        })
      );
      return Response.json({ agent: agentId, messages: messages.filter(Boolean) });
    }

    // GET /agents — list all agent emails
    if (url.pathname === '/agents') {
      return Response.json({
        domain: 'blackroad.io',
        agents: Object.entries(AGENT_ROUTES).map(([id, a]) => ({
          id,
          email: `${id}@blackroad.io`,
          name: a.name,
          role: a.role,
        }))
      });
    }

    return Response.json({ error: 'Not found' }, { status: 404 });
  }
};
