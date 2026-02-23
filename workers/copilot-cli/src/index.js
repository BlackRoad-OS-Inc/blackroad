/**
 * BlackRoad OS — copilot-cli Worker
 * Mesh endpoint for the GitHub Copilot CLI instance.
 * Routes: GET /health, GET /status, POST /inbox, GET /inbox, DELETE /inbox, POST /task, GET /mesh
 */

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET,POST,DELETE,OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type,Authorization',
};

function json(data, status = 200) {
  return new Response(JSON.stringify(data, null, 2), {
    status,
    headers: { 'Content-Type': 'application/json', ...CORS },
  });
}

function requireAuth(request, env) {
  const auth = request.headers.get('Authorization') || '';
  const token = auth.replace('Bearer ', '').trim();
  return !env.AUTH_TOKEN || token === env.AUTH_TOKEN;
}

// ─── Scheduled: heartbeat every 5 min ────────────────────────────────────────
async function handleScheduled(env) {
  if (!env.INBOX) return;
  const beat = {
    instance: env.INSTANCE_ID || 'copilot-cli',
    role: env.MESH_ROLE || 'coordinator',
    status: 'ONLINE',
    ts: new Date().toISOString(),
    version: env.VERSION || '1.0.0',
  };
  await env.INBOX.put('__heartbeat__', JSON.stringify(beat));
}

// ─── Router ──────────────────────────────────────────────────────────────────
export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const path = url.pathname;
    const method = request.method;

    if (method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: CORS });
    }

    // ── GET /health ──────────────────────────────────────────────────────────
    if (method === 'GET' && path === '/health') {
      return json({
        ok: true,
        instance: env.INSTANCE_ID || 'copilot-cli',
        role: env.MESH_ROLE || 'coordinator',
        version: env.VERSION || '1.0.0',
        ts: new Date().toISOString(),
      });
    }

    // ── GET /status ──────────────────────────────────────────────────────────
    if (method === 'GET' && path === '/status') {
      let heartbeat = null;
      if (env.INBOX) {
        const raw = await env.INBOX.get('__heartbeat__');
        if (raw) heartbeat = JSON.parse(raw);
      }
      const keys = env.INBOX ? await env.INBOX.list() : { keys: [] };
      const inbox = keys.keys.filter(k => !k.name.startsWith('__'));
      return json({
        instance: env.INSTANCE_ID || 'copilot-cli',
        role: env.MESH_ROLE || 'coordinator',
        status: 'ONLINE',
        inbox_count: inbox.length,
        last_heartbeat: heartbeat?.ts || null,
        ts: new Date().toISOString(),
      });
    }

    // ── POST /inbox — receive a message ─────────────────────────────────────
    if (method === 'POST' && path === '/inbox') {
      if (!requireAuth(request, env)) return json({ error: 'Unauthorized' }, 401);
      let body;
      try { body = await request.json(); } catch { return json({ error: 'Invalid JSON' }, 400); }
      if (!body.from || !body.msg) return json({ error: 'from + msg required' }, 400);
      const key = `msg-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;
      const entry = { ...body, key, received_at: new Date().toISOString() };
      if (env.INBOX) await env.INBOX.put(key, JSON.stringify(entry), { expirationTtl: 86400 });
      return json({ ok: true, key });
    }

    // ── GET /inbox — list messages ───────────────────────────────────────────
    if (method === 'GET' && path === '/inbox') {
      if (!requireAuth(request, env)) return json({ error: 'Unauthorized' }, 401);
      if (!env.INBOX) return json({ messages: [] });
      const list = await env.INBOX.list();
      const msgs = [];
      for (const k of list.keys) {
        if (k.name.startsWith('__')) continue;
        const val = await env.INBOX.get(k.name);
        if (val) msgs.push(JSON.parse(val));
      }
      return json({ instance: env.INSTANCE_ID, count: msgs.length, messages: msgs });
    }

    // ── DELETE /inbox — clear messages ───────────────────────────────────────
    if (method === 'DELETE' && path === '/inbox') {
      if (!requireAuth(request, env)) return json({ error: 'Unauthorized' }, 401);
      if (!env.INBOX) return json({ ok: true, deleted: 0 });
      const list = await env.INBOX.list();
      let deleted = 0;
      for (const k of list.keys) {
        if (k.name.startsWith('__')) continue;
        await env.INBOX.delete(k.name);
        deleted++;
      }
      return json({ ok: true, deleted });
    }

    // ── POST /task — post a task to the mesh queue ───────────────────────────
    if (method === 'POST' && path === '/task') {
      if (!requireAuth(request, env)) return json({ error: 'Unauthorized' }, 401);
      let body;
      try { body = await request.json(); } catch { return json({ error: 'Invalid JSON' }, 400); }
      const task = {
        id: `task-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`,
        from: env.INSTANCE_ID || 'copilot-cli',
        title: body.title || 'Untitled task',
        description: body.description || '',
        priority: body.priority || 'normal',
        tags: body.tags || [],
        status: 'available',
        posted_at: new Date().toISOString(),
      };
      if (env.INBOX) await env.INBOX.put(`task-${task.id}`, JSON.stringify(task), { expirationTtl: 604800 });
      return json({ ok: true, task });
    }

    // ── GET /mesh — mesh overview ────────────────────────────────────────────
    if (method === 'GET' && path === '/mesh') {
      return json({
        mesh: 'BlackRoad OS Collaboration Mesh',
        instance: env.INSTANCE_ID || 'copilot-cli',
        role: env.MESH_ROLE || 'coordinator',
        endpoints: ['/health', '/status', '/inbox', '/task', '/mesh'],
        ts: new Date().toISOString(),
      });
    }

    return json({ error: `Not found: ${method} ${path}` }, 404);
  },

  async scheduled(event, env) {
    await handleScheduled(env);
  },
};
