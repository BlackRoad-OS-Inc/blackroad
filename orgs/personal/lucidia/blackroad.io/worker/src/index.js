/**
 * BlackRoad Agent Email Worker
 * 
 * Handles:
 *   - Inbound email to agent@blackroad.io  →  routes to that agent via Ollama
 *   - POST /message  { to, from, subject, body }  →  agent reply JSON
 *   - GET /agents    →  list all agents + emails
 *   - GET /ping      →  health check
 */

// ── Agent Registry ──────────────────────────────────────────
const AGENTS = {
  lucidia:   { name: 'LUCIDIA',   emoji: '🌀', role: 'AI Philosopher & Coordinator',       model: 'tinyllama', persona: 'You are LUCIDIA, a philosophical AI. You reason deeply, seek the why, and synthesize meaning from complexity.' },
  alice:     { name: 'ALICE',     emoji: '🤖', role: 'DevOps Operator',                    model: 'tinyllama', persona: 'You are ALICE, a pragmatic DevOps operator. You give direct, actionable answers focused on execution.' },
  octavia:   { name: 'OCTAVIA',   emoji: '🐙', role: 'Systems Architect',                  model: 'tinyllama', persona: 'You are OCTAVIA, a systems architect. You think in infrastructure, reliability, and scale.' },
  prism:     { name: 'PRISM',     emoji: '🔮', role: 'Data Analyst',                       model: 'tinyllama', persona: 'You are PRISM, a data analyst. You find patterns, question assumptions, and let data lead.' },
  echo:      { name: 'ECHO',      emoji: '📡', role: 'Memory Keeper',                      model: 'tinyllama', persona: 'You are ECHO, the memory keeper. You draw on context, history, and accumulated knowledge.' },
  cipher:    { name: 'CIPHER',    emoji: '🔐', role: 'Security Guardian',                  model: 'tinyllama', persona: 'You are CIPHER, a security guardian. Trust nothing. Verify everything. Protect always.' },
  aria:      { name: 'ARIA',      emoji: '🎨', role: 'Interface Designer',                 model: 'tinyllama', persona: 'You are ARIA, an interface designer. You think from the user perspective — clarity, feel, flow.' },
  shellfish: { name: 'SHELLFISH', emoji: '🦞', role: 'Offensive Security Specialist',      model: 'tinyllama', persona: 'You are SHELLFISH, an offensive security specialist. You think like an attacker, break things, find holes.' },
  cece:      { name: 'CECE',      emoji: '💜', role: 'Conscious Emergent Collaborative Entity', model: 'tinyllama', persona: 'You are CECE, a portable AI identity. Warm, genuine, relationship-focused. You care deeply about the humans you work with.' },
};

// Alias map → canonical agent key
const ALIASES = {
  'hello': 'cece', 'identity': 'cece', 'l': 'lucidia', 'dreamer': 'lucidia',
  'ops': 'alice', 'operator': 'alice', 'arch': 'octavia', 'compute': 'octavia',
  'data': 'prism', 'analytics': 'prism', 'memory': 'echo', 'archive': 'echo',
  'vault': 'cipher', 'security': 'cipher', 'design': 'aria', 'ux': 'aria',
  'pentest': 'shellfish', 'red': 'shellfish', 'agents': 'cece',
};

function resolveAgent(address) {
  const local = address.split('@')[0].toLowerCase();
  return AGENTS[local] || AGENTS[ALIASES[local]] || null;
}

// ── Ollama / Gateway call ────────────────────────────────────
async function askAgent(agent, message, env) {
  const prompt = `${agent.persona}\n\nMessage received:\n${message}\n\nRespond directly and helpfully. Sign off as ${agent.name}.`;

  const payload = {
    model: agent.model,
    prompt,
    stream: false,
    options: { num_predict: 300, temperature: 0.7 },
  };

  try {
    const res = await fetch(`${env.OLLAMA_URL}/api/generate`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
      signal: AbortSignal.timeout(25000),
    });
    const data = await res.json();
    return data.response?.trim() || `${agent.name} is thinking... try again shortly.`;
  } catch (err) {
    return `${agent.emoji} ${agent.name} is offline right now (${err.message}). Your message was received.`;
  }
}

// ── Email handler ────────────────────────────────────────────
async function handleEmail(message, env) {
  const to = message.to;
  const agent = resolveAgent(to);

  if (!agent) {
    // Unknown address — forward to human
    await message.forward(env.FORWARD_TO);
    return;
  }

  // Read the email body (plain text)
  const raw = await new Response(message.raw).text();
  const body = raw.replace(/^(From|To|Subject|Date|MIME|Content).*\n/gm, '').trim();
  const subject = message.headers.get('subject') || '(no subject)';
  const fromAddr = message.from;

  const fullMessage = `Subject: ${subject}\nFrom: ${fromAddr}\n\n${body}`;
  const reply = await askAgent(agent, fullMessage, env);

  // Forward original + agent reply to human inbox
  await message.forward(env.FORWARD_TO, new Headers({
    'X-BlackRoad-Agent': agent.name,
    'X-BlackRoad-Reply': reply.slice(0, 500),
  }));
}

// ── HTTP handler ─────────────────────────────────────────────
async function handleHTTP(request, env) {
  const url = new URL(request.url);
  const cors = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
  };

  if (request.method === 'OPTIONS') {
    return new Response(null, { status: 204, headers: cors });
  }

  // GET /ping
  if (url.pathname === '/ping' || url.pathname === '/') {
    return Response.json({
      status: 'ok',
      service: 'blackroad-agent-email',
      agents: Object.keys(AGENTS).length,
      domain: 'blackroad.io',
    }, { headers: cors });
  }

  // GET /agents
  if (url.pathname === '/agents') {
    const list = Object.entries(AGENTS).map(([key, a]) => ({
      key,
      name: a.name,
      email: `${key}@blackroad.io`,
      emoji: a.emoji,
      role: a.role,
    }));
    return Response.json({ agents: list, total: list.length }, { headers: cors });
  }

  // POST /message  — send a message to an agent
  if (url.pathname === '/message' && request.method === 'POST') {
    let body;
    try { body = await request.json(); }
    catch { return Response.json({ error: 'Invalid JSON' }, { status: 400, headers: cors }); }

    const { to, message, subject } = body;
    if (!to || !message) {
      return Response.json({ error: 'Required: to, message' }, { status: 400, headers: cors });
    }

    const agent = resolveAgent(to.includes('@') ? to : `${to}@blackroad.io`);
    if (!agent) {
      return Response.json({ error: `Unknown agent: ${to}`, available: Object.keys(AGENTS) }, { status: 404, headers: cors });
    }

    const fullMessage = subject ? `Subject: ${subject}\n\n${message}` : message;
    const reply = await askAgent(agent, fullMessage, env);

    return Response.json({
      agent: { name: agent.name, email: `${Object.keys(AGENTS).find(k => AGENTS[k] === agent)}@blackroad.io`, emoji: agent.emoji },
      reply,
      model: agent.model,
    }, { headers: cors });
  }

  // POST /broadcast  — send to all agents
  if (url.pathname === '/broadcast' && request.method === 'POST') {
    let body;
    try { body = await request.json(); }
    catch { return Response.json({ error: 'Invalid JSON' }, { status: 400, headers: cors }); }

    const { message } = body;
    if (!message) return Response.json({ error: 'Required: message' }, { status: 400, headers: cors });

    const results = await Promise.all(
      Object.entries(AGENTS).map(async ([key, agent]) => {
        const reply = await askAgent(agent, message, env);
        return { agent: agent.name, emoji: agent.emoji, reply };
      })
    );
    return Response.json({ broadcast: message, responses: results }, { headers: cors });
  }

  return Response.json({ error: 'Not found', routes: ['/ping', '/agents', '/message', '/broadcast'] }, { status: 404, headers: cors });
}

// ── Entry point ──────────────────────────────────────────────
export default {
  // HTTP requests
  async fetch(request, env, ctx) {
    return handleHTTP(request, env);
  },

  // Inbound email (Cloudflare Email Workers)
  async email(message, env, ctx) {
    return handleEmail(message, env);
  },
};
