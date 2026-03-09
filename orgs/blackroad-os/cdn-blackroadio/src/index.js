/**
 * BlackRoad OS — Cloudflare Worker
 * Subdomain: cdn.blackroad.io
 *
 * Account: 848cf0b18d51e0170e0d1537aec3505a
 */

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
};

const SECURITY_HEADERS = {
  "X-Frame-Options": "DENY",
  "X-Content-Type-Options": "nosniff",
  "Referrer-Policy": "strict-origin-when-cross-origin",
  "Permissions-Policy": "camera=(), microphone=(), geolocation=()",
  "Strict-Transport-Security": "max-age=31536000; includeSubDomains",
  "Content-Security-Policy": "default-src 'self'; script-src 'self' 'unsafe-inline' cdn.blackroad.io; style-src 'self' 'unsafe-inline'",
};

function json(data, status = 200) {
  return new Response(JSON.stringify(data, null, 2), {
    status,
    headers: {
      "Content-Type": "application/json",
      ...CORS_HEADERS,
      ...SECURITY_HEADERS,
    },
  });
}

function html(content, status = 200) {
  return new Response(content, {
    status,
    headers: {
      "Content-Type": "text/html; charset=utf-8",
      ...SECURITY_HEADERS,
    },
  });
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    // CORS preflight
    if (request.method === "OPTIONS") {
      return new Response(null, { headers: CORS_HEADERS });
    }

    // Health check
    if (url.pathname === "/health") {
      return json({
        status: "ok",
        worker: env.WORKER_NAME || "blackroad-worker",
        region: request.cf?.colo || "unknown",
        timestamp: new Date().toISOString(),
      });
    }

    // Robots
    if (url.pathname === "/robots.txt") {
      return new Response("User-agent: *\nDisallow: /api/\n", {
        headers: { "Content-Type": "text/plain" },
      });
    }

    // Main route
    if (url.pathname === "/" || url.pathname === "") {
      return html(`<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>BlackRoad OS</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      background: #000;
      color: #fff;
      font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Display', sans-serif;
      display: flex;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
      flex-direction: column;
      gap: 16px;
    }
    .logo {
      font-size: 2rem;
      font-weight: 700;
      background: linear-gradient(135deg, #F5A623 0%, #FF1D6C 38.2%, #9C27B0 61.8%, #2979FF 100%);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
    }
    .sub { color: #64748b; font-size: 0.875rem; }
    a { color: #FF1D6C; text-decoration: none; }
    a:hover { text-decoration: underline; }
  </style>
</head>
<body>
  <div class="logo">BlackRoad OS</div>
  <div class="sub">Your AI. Your Hardware. Your Rules.</div>
  <a href="https://blackroad.ai">blackroad.ai</a>
</body>
</html>`);
    }

    // 404
    return json({ error: "not_found", path: url.pathname }, 404);
  },
};
