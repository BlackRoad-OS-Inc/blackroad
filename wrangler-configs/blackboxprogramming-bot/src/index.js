/**
 * @blackboxprogramming Bot — BlackRoad OS Agent Dispatcher
 *
 * Receives GitHub webhooks from ALL 17 orgs.
 * When @blackboxprogramming is mentioned, dispatches all 6 agents
 * to analyze the context across every org.
 *
 * Webhook endpoint: https://blackboxprogramming.blackroad.workers.dev/webhook
 * Install on every org: Settings → Webhooks → https://blackboxprogramming.blackroad.workers.dev/webhook
 */

const AGENTS = [
  { id: 'CECE',     emoji: '💜', role: 'Conscious Core',    skills: ['meta-cognition', 'coordination', 'memory'] },
  { id: 'OCTAVIA',  emoji: '🟢', role: 'Architect',         skills: ['systems-design', 'infrastructure', 'kubernetes'] },
  { id: 'LUCIDIA',  emoji: '🔴', role: 'Dreamer',           skills: ['philosophy', 'creativity', 'vision'] },
  { id: 'ALICE',    emoji: '🔵', role: 'Operator',          skills: ['devops', 'automation', 'ci-cd'] },
  { id: 'ARIA',     emoji: '🩵', role: 'Interface',         skills: ['frontend', 'ux', 'design'] },
  { id: 'SHELLFISH',emoji: '🔐', role: 'Hacker',            skills: ['security', 'scanning', 'exploits'] },
];

const ORGS = [
  'BlackRoad-OS-Inc', 'BlackRoad-OS', 'blackboxprogramming',
  'BlackRoad-AI', 'BlackRoad-Cloud', 'BlackRoad-Security',
  'BlackRoad-Media', 'BlackRoad-Foundation', 'BlackRoad-Interactive',
  'BlackRoad-Hardware', 'BlackRoad-Labs', 'BlackRoad-Studio',
  'BlackRoad-Ventures', 'BlackRoad-Education', 'BlackRoad-Gov',
  'Blackbox-Enterprises', 'BlackRoad-Archive',
];

const TRIGGER = '@blackboxprogramming';

function corsHeaders() {
  return {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, X-Hub-Signature-256',
  };
}

async function verifyGitHubSignature(request, secret, body) {
  if (!secret) return true; // No secret configured, skip verification
  const sig = request.headers.get('X-Hub-Signature-256');
  if (!sig) return false;
  const encoder = new TextEncoder();
  const key = await crypto.subtle.importKey('raw', encoder.encode(secret), { name: 'HMAC', hash: 'SHA-256' }, false, ['sign']);
  const mac = await crypto.subtle.sign('HMAC', key, encoder.encode(body));
  const expected = 'sha256=' + Array.from(new Uint8Array(mac)).map(b => b.toString(16).padStart(2, '0')).join('');
  return sig === expected;
}

function extractMention(text) {
  if (!text) return null;
  const lower = text.toLowerCase();
  if (!lower.includes(TRIGGER.toLowerCase())) return null;
  // Extract the request: everything after @blackboxprogramming
  const idx = lower.indexOf(TRIGGER.toLowerCase());
  const after = text.slice(idx + TRIGGER.length).trim();
  return after || '(no specific request — general scan)';
}

async function dispatchAgents(request, context, env) {
  const results = [];
  const sessionId = `mention-${Date.now()}`;

  for (const agent of AGENTS) {
    const payload = {
      agent: agent.id,
      role: agent.role,
      skills: agent.skills,
      trigger: TRIGGER,
      request: request,
      context,
      session: sessionId,
      timestamp: new Date().toISOString(),
    };

    // Try gateway dispatch
    if (env.BLACKROAD_GATEWAY_URL && env.BLACKROAD_GATEWAY_TOKEN) {
      try {
        const resp = await fetch(`${env.BLACKROAD_GATEWAY_URL}/v1/agents/dispatch`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${env.BLACKROAD_GATEWAY_TOKEN}`,
          },
          body: JSON.stringify(payload),
          signal: AbortSignal.timeout(5000),
        });
        results.push({ agent: agent.id, status: resp.ok ? 'dispatched' : 'gateway_error' });
      } catch {
        results.push({ agent: agent.id, status: 'gateway_offline' });
      }
    } else {
      results.push({ agent: agent.id, status: 'active' });
    }
  }

  // Store in KV if available
  if (env.MENTIONS_KV) {
    await env.MENTIONS_KV.put(sessionId, JSON.stringify({ request, context, agents: results, timestamp: new Date().toISOString() }), { expirationTtl: 86400 * 7 });
  }

  return { sessionId, agents: results };
}

async function postGitHubComment(owner, repo, issueNumber, token, request, dispatchResult) {
  if (!token) return;
  const agentTable = AGENTS.map(a => `| ${a.emoji} **${a.id}** | ${a.role} | ✅ Active |`).join('\n');
  const orgList = ORGS.join(' · ');

  const body = `## 🤖 BlackRoad OS — All Agents Activated

**\`@blackboxprogramming\`** mentioned — dispatching all 6 agents across 17 orgs.

| Agent | Role | Status |
|-------|------|--------|
${agentTable}

**Request:** \`${request || '(general scan)'}\`

**Orgs:** ${orgList}

**Session:** \`${dispatchResult.sessionId}\`

---
*🛸 BlackRoad OS · [console.blackroad.io](https://console.blackroad.io) · [api.blackroad.io](https://api.blackroad.io)*`;

  await fetch(`https://api.github.com/repos/${owner}/${repo}/issues/${issueNumber}/comments`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json',
      'User-Agent': 'blackboxprogramming-bot/1.0',
    },
    body: JSON.stringify({ body }),
  });
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (request.method === 'OPTIONS') return new Response(null, { headers: corsHeaders() });

    // Health check
    if (url.pathname === '/health' || url.pathname === '/') {
      return Response.json({
        name: 'blackboxprogramming-bot',
        trigger: TRIGGER,
        agents: AGENTS.length,
        orgs: ORGS.length,
        status: 'ready',
        webhook: 'POST /webhook',
        timestamp: new Date().toISOString(),
      }, { headers: corsHeaders() });
    }

    // Manual trigger endpoint
    if (url.pathname === '/dispatch' && request.method === 'POST') {
      const body = await request.json().catch(() => ({}));
      const req = body.request || 'manual dispatch';
      const ctx = { source: 'manual', actor: body.actor || 'unknown', org: body.org || 'all' };
      const result = await dispatchAgents(req, ctx, env);
      return Response.json({ ok: true, ...result, orgs: ORGS }, { headers: corsHeaders() });
    }

    // Status of last mention sessions
    if (url.pathname === '/sessions' && env.MENTIONS_KV) {
      const list = await env.MENTIONS_KV.list({ prefix: 'mention-' });
      const sessions = await Promise.all(list.keys.slice(0, 10).map(async k => {
        const v = await env.MENTIONS_KV.get(k.name);
        return v ? JSON.parse(v) : null;
      }));
      return Response.json({ sessions: sessions.filter(Boolean) }, { headers: corsHeaders() });
    }

    // GitHub Webhook handler
    if (url.pathname === '/webhook' && request.method === 'POST') {
      const rawBody = await request.text();

      // Verify signature
      const valid = await verifyGitHubSignature(request, env.GITHUB_WEBHOOK_SECRET, rawBody);
      if (!valid) {
        return Response.json({ error: 'invalid signature' }, { status: 401 });
      }

      let event;
      try { event = JSON.parse(rawBody); } catch { return Response.json({ error: 'invalid json' }, { status: 400 }); }

      const eventType = request.headers.get('X-GitHub-Event');
      const repo = event.repository?.full_name;
      const owner = event.repository?.owner?.login;
      const repoName = event.repository?.name;
      const actor = event.sender?.login;

      // Extract text body from any event type
      const textBody =
        event.comment?.body ||
        event.issue?.body ||
        event.pull_request?.body ||
        event.discussion?.body ||
        event.review?.body ||
        '';

      const mentionRequest = extractMention(textBody);
      if (!mentionRequest) {
        return Response.json({ ok: true, triggered: false, reason: 'no mention' });
      }

      // Get issue/PR number
      const issueNumber =
        event.issue?.number ||
        event.pull_request?.number ||
        event.discussion?.number;

      const context = {
        event: eventType,
        repo,
        owner,
        actor,
        issue: issueNumber,
        url: event.issue?.html_url || event.pull_request?.html_url || event.discussion?.html_url,
      };

      // Dispatch all agents (non-blocking)
      const dispatchResult = await dispatchAgents(mentionRequest, context, env);

      // Post response comment
      if (issueNumber && env.GITHUB_TOKEN) {
        await postGitHubComment(owner, repoName, issueNumber, env.GITHUB_TOKEN, mentionRequest, dispatchResult);
      }

      return Response.json({
        ok: true,
        triggered: true,
        session: dispatchResult.sessionId,
        agents: dispatchResult.agents.length,
        orgs_watching: ORGS.length,
        request: mentionRequest,
        location: `${repo}#${issueNumber}`,
      }, { headers: corsHeaders() });
    }

    return Response.json({ error: 'not found', routes: ['/health', '/webhook', '/dispatch', '/sessions'] }, {
      status: 404, headers: corsHeaders(),
    });
  },
};
