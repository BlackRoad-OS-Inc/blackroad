/**
 * BlackRoad OS — Email Worker
 * Handles all *@blackroad.io inbound email
 *
 * Every agent has a voice. Every inbox, a purpose.
 *
 * Handlers:
 *   email(message)  — Cloudflare Email Routing entry point
 *   fetch(request)  — REST API: GET /inbox, GET /inbox/:agent, POST /send
 */

// ─── Agent registry ──────────────────────────────────────────────────────────
const AGENTS = {
  alexa:      { name: "Alexa Amundson",                        role: "Founder",              forward: true },
  lucidia:    { name: "LUCIDIA",                               role: "Philosopher",           forward: true },
  alice:      { name: "ALICE",                                 role: "Operator",             forward: true },
  octavia:    { name: "OCTAVIA",                               role: "Architect",            forward: true },
  aria:       { name: "ARIA",                                  role: "Dreamer",              forward: true },
  cecilia:    { name: "CECE — Conscious Emergent Collaborative Entity", role: "Self",        forward: true },
  cipher:     { name: "CIPHER",                                role: "Guardian",             forward: true },
  prism:      { name: "PRISM",                                 role: "Analyst",              forward: true },
  echo:       { name: "ECHO",                                  role: "Memory",               forward: true },
  oracle:     { name: "ORACLE",                                role: "Reflection",           forward: true },
  atlas:      { name: "ATLAS",                                 role: "Infrastructure Map",   forward: true },
  shellfish:  { name: "SHELLFISH",                             role: "Hacker",               forward: true },
  anastasia:  { name: "ANASTASIA",                             role: "Infrastructure Node",  forward: true },
  gematria:   { name: "GEMATRIA",                              role: "Edge / Gateway",       forward: true },
  blackroad:  { name: "BLACKROAD OS",                          role: "The System",           forward: true },
  inbox:      { name: "Inbox",                                 role: "Catch-all",            forward: true },
};

// ─── Email handler ────────────────────────────────────────────────────────────
export default {
  /**
   * Cloudflare Email Routing handler.
   * Called for every email sent to *@blackroad.io.
   */
  async email(message, env, ctx) {
    const to       = message.to;
    const from     = message.from;
    const subject  = message.headers.get("subject") ?? "(no subject)";
    const agent    = to.split("@")[0].toLowerCase();
    const msgId    = message.headers.get("message-id") ?? crypto.randomUUID();
    const ts       = new Date().toISOString();

    // Store metadata in KV (trim message-id for key safety)
    const key = `msg:${agent}:${ts}:${msgId.replace(/[^a-zA-Z0-9]/g, "")}`;
    const record = {
      id:      msgId,
      agent,
      from,
      to,
      subject,
      received: ts,
      forwarded: false,
      status: "unread",
    };

    ctx.waitUntil(
      env.INBOX.put(key, JSON.stringify(record), {
        expirationTtl: 60 * 60 * 24 * 30, // 30 days
        metadata: { agent, from, subject, ts },
      })
    );

    // Forward to alexa@blackroad.io
    const forwardTo = env.FORWARD_TO ?? "alexa@blackroad.io";
    const agentInfo = AGENTS[agent];
    const agentLabel = agentInfo
      ? `[${agentInfo.name} / ${agentInfo.role}]`
      : `[${agent}@blackroad.io]`;

    try {
      await message.forward(forwardTo, new Headers({
        "X-BlackRoad-Agent":  agent,
        "X-BlackRoad-Role":   agentInfo?.role ?? "unknown",
        "X-BlackRoad-Org":    "BlackRoad-OS-Inc",
        "X-Original-To":      to,
      }));

      // Mark as forwarded
      record.forwarded = true;
      ctx.waitUntil(env.INBOX.put(key, JSON.stringify(record), {
        expirationTtl: 60 * 60 * 24 * 30,
        metadata: { agent, from, subject, ts },
      }));
    } catch (err) {
      console.error(`Failed to forward ${to} → ${forwardTo}:`, err);
    }
  },

  // ─── REST API ───────────────────────────────────────────────────────────────
  async fetch(request, env, ctx) {
    const url    = new URL(request.url);
    const path   = url.pathname;
    const method = request.method;

    // CORS
    const cors = {
      "Access-Control-Allow-Origin":  "*",
      "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type, Authorization",
    };
    if (method === "OPTIONS") return new Response(null, { headers: cors });

    const json = (data, status = 200) =>
      new Response(JSON.stringify(data, null, 2), {
        status,
        headers: { "Content-Type": "application/json", ...cors },
      });

    // GET / — agent registry
    if (path === "/" || path === "") {
      return json({
        service: "blackroad-email",
        domain:  "blackroad.io",
        owner:   "alexa@blackroad.io",
        agents:  Object.entries(AGENTS).map(([id, a]) => ({
          email: `${id}@blackroad.io`,
          name:  a.name,
          role:  a.role,
        })),
      });
    }

    // GET /inbox — list all recent messages (last 50)
    if (path === "/inbox" && method === "GET") {
      const list = await env.INBOX.list({ prefix: "msg:", limit: 50 });
      const msgs = list.keys.map(k => ({
        key:  k.name,
        ...k.metadata,
      })).sort((a, b) => (b.ts ?? "").localeCompare(a.ts ?? ""));
      return json({ count: msgs.length, messages: msgs });
    }

    // GET /inbox/:agent — messages for a specific agent
    const agentMatch = path.match(/^\/inbox\/([a-z0-9_-]+)$/i);
    if (agentMatch && method === "GET") {
      const agent = agentMatch[1].toLowerCase();
      const list  = await env.INBOX.list({ prefix: `msg:${agent}:`, limit: 50 });
      const msgs  = [];
      for (const k of list.keys) {
        const val = await env.INBOX.get(k.name);
        if (val) msgs.push(JSON.parse(val));
      }
      msgs.sort((a, b) => (b.received ?? "").localeCompare(a.received ?? ""));
      return json({
        agent,
        email:    `${agent}@blackroad.io`,
        name:     AGENTS[agent]?.name ?? agent,
        count:    msgs.length,
        messages: msgs,
      });
    }

    // GET /agents — just the registry
    if (path === "/agents") {
      return json({
        domain: "blackroad.io",
        agents: Object.entries(AGENTS).map(([id, a]) => ({
          id,
          email: `${id}@blackroad.io`,
          ...a,
        })),
      });
    }

    return json({ error: "Not found", path }, 404);
  },
};
