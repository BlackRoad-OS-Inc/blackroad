/**
 * BlackRoad OS — Public API Edge Worker
 * Cloudflare Worker that proxies to the blackroad-api (FastAPI :8788)
 * running on the Pi fleet via Cloudflare Tunnel.
 *
 * Routes:
 *   /health                    → health check
 *   /v1/*                      → blackroad-api FastAPI
 *   /gateway/*                 → blackroad-core gateway :8787 (via tunnel)
 *   /agents                    → merged view (DB agents + gateway roster)
 *
 * Env vars (set in Cloudflare dashboard or wrangler.toml):
 *   API_ORIGIN       = https://api.blackroad.ai          (tunnel → Pi :8788)
 *   GATEWAY_ORIGIN   = https://gateway.blackroad.ai      (tunnel → Pi :8787)
 *   API_SECRET       = internal shared secret (optional bearer check)
 */

const CORS = {
  "Access-Control-Allow-Origin":  "*",
  "Access-Control-Allow-Methods": "GET,POST,PATCH,PUT,DELETE,OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type,Authorization,X-BlackRoad-Agent,X-Request-ID",
  "Access-Control-Max-Age":       "86400",
};

function json(data, status = 200, extra = {}) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json", ...CORS, ...extra },
  });
}

function error(msg, status = 500) {
  return json({ error: msg, status }, status);
}

async function proxy(request, origin, path, env) {
  const url = new URL(request.url);
  const upstream = new URL(path + url.search, origin);

  const headers = new Headers(request.headers);
  headers.set("X-Forwarded-For", request.headers.get("CF-Connecting-IP") || "");
  headers.set("X-BlackRoad-Edge", "cloudflare-worker");
  if (env.API_SECRET) headers.set("X-Internal-Secret", env.API_SECRET);

  try {
    const resp = await fetch(upstream.toString(), {
      method:  request.method,
      headers,
      body:    ["GET", "HEAD"].includes(request.method) ? null : request.body,
    });
    const body = await resp.arrayBuffer();
    return new Response(body, {
      status:  resp.status,
      headers: { ...Object.fromEntries(resp.headers), ...CORS },
    });
  } catch (e) {
    return error(`Upstream unavailable: ${e.message}`, 503);
  }
}

export default {
  async fetch(request, env) {
    const url  = new URL(request.url);
    const path = url.pathname;

    // Preflight
    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: CORS });
    }

    const API     = env.API_ORIGIN     || "https://api.blackroad.ai";
    const GATEWAY = env.GATEWAY_ORIGIN || "https://gateway.blackroad.ai";

    // ── Root health ──────────────────────────────────────────────────
    if (path === "/" || path === "/health") {
      return json({
        service:   "BlackRoad OS API Edge",
        version:   "1.0.0",
        timestamp: new Date().toISOString(),
        endpoints: {
          health:    "/health",
          agents:    "/v1/agents",
          tasks:     "/v1/tasks",
          memory:    "/v1/memory",
          chat:      "/v1/chat",
          gateway:   "/gateway/healthz",
          providers: "/gateway/v1/providers",
          docs:      `${API}/docs`,
        },
      });
    }

    // ── v1/* → FastAPI backend ────────────────────────────────────────
    if (path.startsWith("/v1/")) {
      return proxy(request, API, path, env);
    }

    // ── /agents shorthand → /v1/agents ───────────────────────────────
    if (path === "/agents" || path.startsWith("/agents/")) {
      const rewritten = path.replace(/^\/agents/, "/v1/agents");
      return proxy(request, API, rewritten, env);
    }

    // ── /tasks shorthand ─────────────────────────────────────────────
    if (path === "/tasks" || path.startsWith("/tasks/")) {
      const rewritten = path.replace(/^\/tasks/, "/v1/tasks");
      return proxy(request, API, rewritten, env);
    }

    // ── /memory shorthand ────────────────────────────────────────────
    if (path === "/memory" || path.startsWith("/memory/")) {
      const rewritten = path.replace(/^\/memory/, "/v1/memory");
      return proxy(request, API, rewritten, env);
    }

    // ── /chat shorthand ──────────────────────────────────────────────
    if (path === "/chat") {
      return proxy(request, API, "/v1/chat", env);
    }

    // ── /gateway/* → blackroad-core gateway ──────────────────────────
    if (path.startsWith("/gateway/")) {
      const rewritten = path.replace(/^\/gateway/, "");
      return proxy(request, GATEWAY, rewritten, env);
    }

    // ── /docs → redirect to FastAPI docs ─────────────────────────────
    if (path === "/docs" || path === "/redoc") {
      return Response.redirect(`${API}${path}`, 302);
    }

    return error("Not found", 404);
  },
};
