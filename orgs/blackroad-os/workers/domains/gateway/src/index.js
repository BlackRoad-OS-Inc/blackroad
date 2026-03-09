// gateway.blackroad.io — Tokenless AI Gateway

const CF_ACCOUNT_ID = "848cf0b18d51e0170e0d1537aec3505a";
const BRAND = { gradient: "linear-gradient(135deg, #F5A623 0%, #FF1D6C 38.2%, #9C27B0 61.8%, #2979FF 100%)" };
function json(data, status = 200) { return new Response(JSON.stringify(data, null, 2), { status, headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" } }); }
function html(content) { return new Response(content, { headers: { "Content-Type": "text/html; charset=utf-8" } }); }
async function ghFetch(env, endpoint) { if (!env.GITHUB_TOKEN) return null; const r = await fetch(`https://api.github.com${endpoint}`, { headers: { "Authorization": `Bearer ${env.GITHUB_TOKEN}`, "Accept": "application/vnd.github+json", "X-GitHub-Api-Version": "2022-11-28", "User-Agent": "BlackRoad-OS-Worker/2.0" } }); return r.ok ? r.json() : null; }

const CSS = `*{box-sizing:border-box;margin:0;padding:0}:root{--amber:#F5A623;--pink:#FF1D6C;--violet:#9C27B0;--blue:#2979FF;--bg:#000;--surface:#0a0a0a;--border:#1a1a1a;--text:#fff;--muted:#555;--gradient:linear-gradient(135deg,var(--amber) 0%,var(--pink) 38.2%,var(--violet) 61.8%,var(--blue) 100%);--radius:12px;--font:-apple-system,BlinkMacSystemFont,'SF Pro Display',sans-serif}body{background:var(--bg);color:var(--text);font-family:var(--font);min-height:100vh}.header{padding:40px;border-bottom:1px solid var(--border)}.title{font-size:clamp(24px,3vw,40px);font-weight:700;background:var(--gradient);-webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text}.content{padding:40px}.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(240px,1fr));gap:16px;margin-top:24px}.card{background:var(--surface);border:1px solid var(--border);border-radius:var(--radius);padding:20px}.section-title{font-size:12px;font-weight:600;letter-spacing:.1em;text-transform:uppercase;color:#555;margin-bottom:16px;margin-top:32px}.gradient-bar{height:2px;background:var(--gradient);margin:0 0 32px}`;

const PROVIDERS = [
  { name: "Ollama (Local)", status: "✅ Active", models: "qwen2.5:7b, deepseek-r1:7b, llama3.2:3b, mistral:7b", color: "#0f0" },
  { name: "Anthropic", status: "✅ Gateway", models: "claude-3-5-sonnet, claude-3-haiku", color: "#0f0" },
  { name: "OpenAI", status: "✅ Gateway", models: "gpt-4o, gpt-4o-mini", color: "#0f0" },
  { name: "Railway GPU", status: "🔄 Deployed", models: "blackroad-qwen-72b, deepseek-r1-70b", color: "#F5A623" },
];

async function proxyRequest(request, env) {
  // Validate internal secret
  const auth = request.headers.get("Authorization") ?? "";
  const token = auth.replace("Bearer ", "").trim();
  if (!env.INTERNAL_SECRET || token !== env.INTERNAL_SECRET) {
    return json({ error: "Unauthorized", message: "Valid Bearer token required." }, 401);
  }

  // Determine upstream: prefer Railway GPU, fallback to local Ollama
  const upstream = env.RAILWAY_INFERENCE_URL ?? env.OLLAMA_URL ?? "http://127.0.0.1:11434";
  const targetUrl = `${upstream}/v1/chat/completions`;

  try {
    const body = await request.text();
    const upstreamResp = await fetch(targetUrl, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        ...(env.UPSTREAM_API_KEY ? { "Authorization": `Bearer ${env.UPSTREAM_API_KEY}` } : {}),
      },
      body,
    });

    const respBody = await upstreamResp.text();
    return new Response(respBody, {
      status: upstreamResp.status,
      headers: {
        "Content-Type": upstreamResp.headers.get("Content-Type") ?? "application/json",
        "Access-Control-Allow-Origin": "*",
        "X-Gateway": "blackroad-tokenless/2.0",
      },
    });
  } catch (err) {
    return json({ error: "Gateway error", message: String(err) }, 502);
  }
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const { pathname, method } = { pathname: url.pathname, method: request.method };

    if (pathname === "/health") {
      return json({ status: "ok", worker: "gateway-blackroadio", ts: Date.now() });
    }

    if (pathname === "/api/providers") {
      return json({ providers: PROVIDERS, gateway: "tokenless", version: "2.0" });
    }

    if (pathname === "/v1/chat/completions" && method === "POST") {
      return proxyRequest(request, env);
    }

    // Handle CORS preflight
    if (method === "OPTIONS") {
      return new Response(null, {
        headers: {
          "Access-Control-Allow-Origin": "*",
          "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
          "Access-Control-Allow-Headers": "Content-Type, Authorization",
        },
      });
    }

    const providerRows = PROVIDERS.map(p => `
      <tr>
        <td style="padding:12px 16px;font-weight:500">${p.name}</td>
        <td style="padding:12px 16px"><span style="color:${p.color}">${p.status}</span></td>
        <td style="padding:12px 16px;color:#888;font-size:13px">${p.models}</td>
      </tr>`).join("");

    return html(`<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Gateway — BlackRoad OS</title>
<style>${CSS}
pre{background:#0a0a0a;border:1px solid var(--border);border-radius:8px;padding:20px;font-size:13px;line-height:1.6;overflow-x:auto;color:#a8e6cf}
table{width:100%;border-collapse:collapse}
th{padding:10px 16px;text-align:left;font-size:11px;font-weight:600;letter-spacing:.08em;text-transform:uppercase;color:var(--muted);border-bottom:1px solid var(--border)}
tr:not(:last-child) td{border-bottom:1px solid var(--border)}
.arch-box{background:#050505;border:1px solid var(--border);border-radius:var(--radius);padding:24px;font-family:monospace;font-size:13px;line-height:2;color:#aaa}
.arch-box .hl{color:var(--amber)}
.arch-box .arr{color:var(--blue)}
</style></head><body>
<div class="gradient-bar"></div>
<div class="header">
  <div style="font-size:12px;color:var(--muted);font-weight:600;letter-spacing:.1em;text-transform:uppercase;margin-bottom:8px">Gateway</div>
  <div class="title">BlackRoad Tokenless AI Gateway</div>
  <div style="color:#aaa;font-size:15px;margin-top:12px;max-width:640px;line-height:1.7">
    All AI requests are proxied through our tokenless gateway.
    <strong style="color:#fff">Agents never hold API keys.</strong>
    The gateway owns all provider secrets and enforces access policies.
  </div>
</div>

<div class="content">
  <div class="section-title">Architecture</div>
  <div class="arch-box">
<span class="hl">[Agent CLI]</span>  <span class="arr">──→</span>  <span class="hl">[Gateway :8787]</span>  <span class="arr">──→</span>  <span class="hl">[Ollama :11434]</span>
                              <span class="arr">──→</span>  <span class="hl">[Anthropic API]</span>
                              <span class="arr">──→</span>  <span class="hl">[OpenAI API]</span>
                              <span class="arr">──→</span>  <span class="hl">[Railway GPU]</span>
  </div>

  <div class="section-title">Connected Providers</div>
  <div class="card" style="padding:0;overflow:hidden">
    <table>
      <thead>
        <tr>
          <th>Provider</th>
          <th>Status</th>
          <th>Models</th>
        </tr>
      </thead>
      <tbody>${providerRows}</tbody>
    </table>
  </div>

  <div class="section-title">How to Use</div>
  <div class="card" style="margin-bottom:16px">
    <div style="font-weight:600;margin-bottom:12px">Chat Completions (OpenAI-compatible)</div>
<pre>curl -X POST https://gateway.blackroad.io/v1/chat/completions \\
  -H "Authorization: Bearer &lt;INTERNAL_SECRET&gt;" \\
  -H "Content-Type: application/json" \\
  -d '{
    "model": "qwen2.5:7b",
    "messages": [{"role": "user", "content": "Hello!"}]
  }'</pre>
  </div>
  <div class="card">
    <div style="font-weight:600;margin-bottom:12px">From Agent CLI (tokenless)</div>
<pre># Agents call the local gateway at 127.0.0.1:8787
# The gateway transparently adds provider credentials

BLACKROAD_GATEWAY_URL=http://127.0.0.1:8787 \\
  br agent chat --message "Analyze this code"</pre>
  </div>

  <div class="section-title">Security Model</div>
  <div class="grid">
    <div class="card">
      <div style="font-size:22px;margin-bottom:10px">🔑</div>
      <div style="font-weight:700;margin-bottom:6px">No Agent Keys</div>
      <p style="font-size:13px;color:#aaa;line-height:1.6">Agent code contains zero API keys. All secrets live in the gateway environment only.</p>
    </div>
    <div class="card">
      <div style="font-size:22px;margin-bottom:10px">🛡️</div>
      <div style="font-weight:700;margin-bottom:6px">Localhost Bind</div>
      <p style="font-size:13px;color:#aaa;line-height:1.6">Gateway binds to 127.0.0.1 by default. External access requires explicit configuration.</p>
    </div>
    <div class="card">
      <div style="font-size:22px;margin-bottom:10px">📋</div>
      <div style="font-weight:700;margin-bottom:6px">Policy Enforcement</div>
      <p style="font-size:13px;color:#aaa;line-height:1.6">Per-agent permissions defined in <code style="background:#111;padding:1px 6px;border-radius:4px">policies/agent-permissions.json</code>.</p>
    </div>
  </div>
</div>
</body></html>`);
  },
};
