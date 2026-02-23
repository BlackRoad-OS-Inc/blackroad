/**
 * BlackRoad OS — Email Setup Worker
 *
 * Automates full Cloudflare Email Routing configuration for blackroad.io:
 *   - Finds zone
 *   - Enables Email Routing
 *   - Switches MX from Google → Cloudflare
 *   - Adds alexa@blackroad.io as verified destination
 *   - Creates catch-all rule → blackroad-email worker
 *
 * Endpoints:
 *   GET  /           → status
 *   POST /setup      → run full setup
 *   GET  /status     → check current routing state
 *   POST /mx/switch  → swap MX records only
 *   POST /mx/restore → restore Google MX (rollback)
 */

const CF_API = "https://api.cloudflare.com/client/v4";

const MX_CLOUDFLARE = [
  { name: "@", content: "route1.mx.cloudflare.net", priority: 86 },
  { name: "@", content: "route2.mx.cloudflare.net", priority: 30 },
];

const MX_GOOGLE = [
  { content: "aspmx.l.google.com",      priority: 1  },
  { content: "alt1.aspmx.l.google.com", priority: 5  },
  { content: "alt2.aspmx.l.google.com", priority: 10 },
  { content: "alt3.aspmx.l.google.com", priority: 10 },
  { content: "alt4.aspmx.l.google.com", priority: 10 },
];

// ─── Helpers ─────────────────────────────────────────────────────────────────

function cf(token, path, opts = {}) {
  return fetch(`${CF_API}${path}`, {
    ...opts,
    headers: {
      "Authorization": `Bearer ${token}`,
      "Content-Type":  "application/json",
      ...(opts.headers ?? {}),
    },
    body: opts.body ? JSON.stringify(opts.body) : undefined,
  }).then(async r => {
    const text = await r.text();
    if (!text) return { success: r.ok, result: null };
    try { return JSON.parse(text); }
    catch { return { success: r.ok, result: null, _raw: text.slice(0, 200) }; }
  });
}

async function getZone(token, domain) {
  const r = await cf(token, `/zones?name=${domain}&per_page=5`);
  if (!r.success || !r.result?.length) {
    throw new Error(`Zone not found for ${domain}: ${JSON.stringify(r.errors)}`);
  }
  return r.result[0];
}

function ok(label, result) {
  return { step: label, success: result.success, errors: result.errors ?? [] };
}

// ─── Setup steps ─────────────────────────────────────────────────────────────

async function stepEnable(token, zoneId) {
  const r = await cf(token, `/zones/${zoneId}/email/routing/enable`, { method: "POST" });
  // Auth error (10000) = token lacks Email Routing Edit permission — needs manual dashboard enable
  if (!r.success && r.errors?.some(e => e.code === 10000)) {
    return { step: "enable_routing", success: false, manual_required: true,
      message: "Go to CF Dashboard → blackroad.io → Email → Email Routing → Enable (one click)" };
  }
  return ok("enable_routing", r);
}

async function stepDestination(token, account, email) {
  const r = await cf(token, `/accounts/${account}/email/routing/addresses`, {
    method: "POST",
    body:   { email },
  });
  return ok("add_destination", r);
}

async function stepCatchAll(token, zoneId, workerName) {
  // CF API: catch_all rule requires PUT (not POST)
  const r = await cf(token, `/zones/${zoneId}/email/routing/rules/catch_all`, {
    method: "PUT",
    body: {
      actions:  [{ type: "worker", value: [workerName] }],
      enabled:  true,
      matchers: [{ field: "to", type: "all" }],
      name:     "BlackRoad OS catch-all",
      priority: 0,
    },
  });
  return ok("catch_all_rule", r);
}

async function stepSwitchMX(token, zoneId, domain) {
  const steps = [];

  // Delete existing MX records
  const existing = await cf(token, `/zones/${zoneId}/dns_records?type=MX&per_page=50`);
  for (const rec of existing.result ?? []) {
    const d = await cf(token, `/zones/${zoneId}/dns_records/${rec.id}`, { method: "DELETE" });
    steps.push({ action: "delete_mx", record: rec.content, success: d.success });
  }

  // Add Cloudflare MX records
  for (const mx of MX_CLOUDFLARE) {
    const r = await cf(token, `/zones/${zoneId}/dns_records`, {
      method: "POST",
      body: {
        type:     "MX",
        name:     mx.name,
        content:  mx.content,
        priority: mx.priority,
        ttl:      1, // auto
      },
    });
    steps.push({ action: "add_mx", record: mx.content, priority: mx.priority, success: r.success });
  }

  // Add/update SPF
  const spfRecords = await cf(token, `/zones/${zoneId}/dns_records?type=TXT&per_page=50`);
  const spf = (spfRecords.result ?? []).find(r => r.content.startsWith("v=spf1"));
  const newSpf = "v=spf1 include:_spf.mx.cloudflare.net ~all";
  if (spf) {
    const r = await cf(token, `/zones/${zoneId}/dns_records/${spf.id}`, {
      method: "PUT",
      body: { type: "TXT", name: "@", content: newSpf, ttl: 1 },
    });
    steps.push({ action: "update_spf", success: r.success });
  } else {
    const r = await cf(token, `/zones/${zoneId}/dns_records`, {
      method: "POST",
      body: { type: "TXT", name: "@", content: newSpf, ttl: 1 },
    });
    steps.push({ action: "add_spf", success: r.success });
  }

  return steps;
}

async function stepRestoreMX(token, zoneId) {
  const steps = [];

  // Delete current MX records
  const existing = await cf(token, `/zones/${zoneId}/dns_records?type=MX&per_page=50`);
  for (const rec of existing.result ?? []) {
    const d = await cf(token, `/zones/${zoneId}/dns_records/${rec.id}`, { method: "DELETE" });
    steps.push({ action: "delete_mx", record: rec.content, success: d.success });
  }

  // Restore Google MX
  for (const mx of MX_GOOGLE) {
    const r = await cf(token, `/zones/${zoneId}/dns_records`, {
      method: "POST",
      body: { type: "MX", name: "@", content: mx.content, priority: mx.priority, ttl: 1 },
    });
    steps.push({ action: "restore_mx", record: mx.content, success: r.success });
  }

  return steps;
}

// ─── Status check ─────────────────────────────────────────────────────────────

async function getStatus(token, zoneId, domain) {
  const [routing, catchAll, dns] = await Promise.all([
    cf(token, `/zones/${zoneId}/email/routing`),
    cf(token, `/zones/${zoneId}/email/routing/rules/catch_all`),
    cf(token, `/zones/${zoneId}/dns_records?type=MX&per_page=20`),
  ]);

  const mxRecords = (dns.result ?? []).map(r => ({ content: r.content, priority: r.priority }));
  const mxProvider = mxRecords.some(r => r.content.includes("cloudflare"))
    ? "cloudflare" : mxRecords.some(r => r.content.includes("google")) ? "google" : "other";

  return {
    domain,
    routing: {
      enabled: routing.result?.enabled ?? false,
      status:  routing.result?.status  ?? "unknown",
    },
    catch_all: {
      configured: (catchAll.result?.actions?.length ?? 0) > 0,
      actions:    catchAll.result?.actions ?? [],
    },
    mx: { provider: mxProvider, records: mxRecords },
    ready: routing.result?.enabled && mxProvider === "cloudflare",
  };
}

// ─── Request handler ─────────────────────────────────────────────────────────

export default {
  async fetch(request, env) {
    const url    = new URL(request.url);
    const path   = url.pathname.replace(/\/$/, "") || "/";
    const method = request.method;

    const cors = {
      "Access-Control-Allow-Origin":  "*",
      "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type",
    };
    if (method === "OPTIONS") return new Response(null, { headers: cors });

    const json = (data, status = 200) => new Response(
      JSON.stringify(data, null, 2),
      { status, headers: { "Content-Type": "application/json", ...cors } }
    );

    const TOKEN   = env.CF_API_TOKEN;
    const DOMAIN  = env.DOMAIN        ?? "blackroad.io";
    const DEST    = env.FORWARD_TO    ?? "alexa@blackroad.io";
    const WORKER  = env.EMAIL_WORKER  ?? "blackroad-email";

    if (!TOKEN) return json({ error: "CF_API_TOKEN secret not set — run: wrangler secret put CF_API_TOKEN" }, 500);

    // GET / — info
    if (path === "/" && method === "GET") {
      return json({
        service:  "blackroad-email-setup",
        domain:   DOMAIN,
        routes: {
          "POST /setup":      "Run full email routing setup",
          "GET  /status":     "Check current routing state",
          "POST /mx/switch":  "Switch MX → Cloudflare only",
          "POST /mx/restore": "Restore Google MX (rollback)",
        },
      });
    }

    let zone;
    try {
      zone = await getZone(TOKEN, DOMAIN);
    } catch (e) {
      return json({ error: e.message }, 400);
    }

    // GET /status
    if (path === "/status" && method === "GET") {
      const status = await getStatus(TOKEN, zone.id, DOMAIN);
      return json(status);
    }

    // POST /setup — full setup
    if (path === "/setup" && method === "POST") {
      const results = [];

      results.push(await stepEnable(TOKEN, zone.id));
      results.push(await stepDestination(TOKEN, zone.account.id, DEST));
      results.push(await stepCatchAll(TOKEN, zone.id, WORKER));
      const mxSteps = await stepSwitchMX(TOKEN, zone.id, DOMAIN);
      results.push({ step: "switch_mx", substeps: mxSteps });

      const status = await getStatus(TOKEN, zone.id, DOMAIN);

      return json({
        domain:  DOMAIN,
        results,
        status,
        message: status.ready
          ? `✓ All *@${DOMAIN} → ${WORKER} → forwarded to ${DEST}`
          : "⚠ Setup ran — check status for remaining issues",
      });
    }

    // POST /mx/switch — MX only
    if (path === "/mx/switch" && method === "POST") {
      const steps = await stepSwitchMX(TOKEN, zone.id, DOMAIN);
      return json({ domain: DOMAIN, steps });
    }

    // POST /mx/restore — rollback
    if (path === "/mx/restore" && method === "POST") {
      const steps = await stepRestoreMX(TOKEN, zone.id);
      return json({ domain: DOMAIN, steps, message: "Google MX restored" });
    }

    return json({ error: "Not found", path }, 404);
  },
};
