// BlackRoad DNS Setup Worker
// Deploy once, hit the URL, all 20 domains point to your Pi tunnel
// Secrets: CF_EMAIL, CF_GLOBAL_KEY (set via wrangler secret put)

const TUNNEL_CNAME = "52915859-da18-4aa6-add5-7bd9fcac2e0b.cfargotunnel.com";
const ACCOUNT_ID = "848cf0b18d51e0170e0d1537aec3505a";
const TUNNEL_ID = "52915859-da18-4aa6-add5-7bd9fcac2e0b";
const CF_API = "https://api.cloudflare.com/client/v4";

const ZONES = [
  ["aliceqi.com",             "927cead26cb27df79577db1bffbf2dfa"],
  ["blackboxprogramming.io",  "6e27d41cb2d27cd8f2f26e95608d3899"],
  ["blackroadai.com",         "590afe2b9b2ae222e77d89c10b7412d3"],
  ["blackroad.company",       "f654e077612d3d240f96300b7c0c6cae"],
  ["blackroadinc.us",         "decb1bf816ff29197d88751228ad0017"],
  ["blackroad.io",            "d6566eba4500b460ffec6650d3b4baf6"],
  ["blackroad.me",            "622395674d479bad0a7d3790722c14be"],
  ["blackroad.network",       "fae5a76a78154e0509bede2e3eba8124"],
  ["blackroadqi.com",         "e24dbdfd8868183e4093b8cdba709240"],
  ["blackroadquantum.com",    "1c93ece77e64728f506d635f5b58c60a"],
  ["blackroadquantum.info",   "9855ce5bf6602150ea9195f3cd975d3e"],
  ["blackroadquantum.net",    "7d606471c0feab151c8ad493fd8a5c8e"],
  ["blackroadquantum.shop",   "b842746ff2e811c1be959e5a843b25e6"],
  ["blackroadquantum.store",  "498fef62d7a9812e69413e7451edf3b1"],
  ["blackroad.systems",       "13293825c2b0491085cbece9fc02e401"],
  ["lucidia.earth",           "a91af33930bb9b9ddfa0cf12c0232460"],
  ["lucidiaqi.com",           "8a787536b6dd285bdf06dde65e96e8c0"],
  ["lucidia.studio",          "43edda4c64475e5d81934ec7f64f6801"],
  ["roadchain.io",            "86d82685f669fe45d0ee6d24ef21b255"],
  ["roadcoin.io",             "111d9214d54a282b1e889fa3d1e2faa8"],
];

const IO_SUBS = ["agents","api","gateway","ollama","dashboard","docs","hub",
                 "console","app","chat","admin","status","metrics","auth","deploy"];

const INGRESS_ROUTES = [
  ["agents.blackroad.io",    "http://localhost:8080"],
  ["api.blackroad.io",       "http://localhost:3000"],
  ["gateway.blackroad.io",   "http://localhost:8787"],
  ["ollama.blackroad.io",    "http://localhost:11434"],
  ["dashboard.blackroad.io", "http://localhost:4000"],
  ["hub.blackroad.io",       "http://localhost:4000"],
  ["docs.blackroad.io",      "http://localhost:3001"],
  ["status.blackroad.io",    "http://localhost:8090"],
  ["metrics.blackroad.io",   "http://localhost:8090"],
  ["app.blackroad.io",       "http://localhost:3000"],
  ["chat.blackroad.io",      "http://localhost:8080"],
  ["auth.blackroad.io",      "http://localhost:3000"],
  ["models.blackroadai.com", "http://localhost:11434"],
  ["chat.blackroadai.com",   "http://localhost:8080"],
  ["app.lucidia.earth",      "http://localhost:3000"],
  ["app.roadchain.io",       "http://localhost:3000"],
  ["app.roadcoin.io",        "http://localhost:3000"],
  ["*.blackroad.io",         "http://localhost:3000"],
  ["*.lucidia.earth",        "http://localhost:3000"],
  ["*.blackroadai.com",      "http://localhost:3000"],
  ["*.roadchain.io",         "http://localhost:3000"],
  ...ZONES.map(([domain]) => [domain, "http://localhost:3000"]),
];

function cfHeaders(env) {
  return {
    "X-Auth-Email": env.CF_EMAIL,
    "X-Auth-Key": env.CF_GLOBAL_KEY,
    "Content-Type": "application/json",
  };
}

async function upsertCname(zoneId, name, env) {
  const body = { type: "CNAME", name, content: TUNNEL_CNAME, proxied: true, ttl: 1 };
  // Check existing
  const check = await fetch(`${CF_API}/zones/${zoneId}/dns_records?type=CNAME&name=${name}`,
    { headers: cfHeaders(env) });
  const existing = await check.json();
  const id = existing.result?.[0]?.id;
  const method = id ? "PUT" : "POST";
  const url = id
    ? `${CF_API}/zones/${zoneId}/dns_records/${id}`
    : `${CF_API}/zones/${zoneId}/dns_records`;
  const r = await fetch(url, { method, headers: cfHeaders(env), body: JSON.stringify(body) });
  const d = await r.json();
  return { name, ok: d.success, action: id ? "updated" : "created", error: d.errors?.[0]?.message };
}

async function updateTunnel(env) {
  const ingress = [
    ...INGRESS_ROUTES.map(([hostname, service]) => ({ hostname, service })),
    { service: "http_status:404" },
  ];
  const r = await fetch(`${CF_API}/accounts/${ACCOUNT_ID}/cfd_tunnel/${TUNNEL_ID}/configurations`, {
    method: "PUT",
    headers: cfHeaders(env),
    body: JSON.stringify({ config: { ingress } }),
  });
  const d = await r.json();
  return { ok: d.success, error: d.errors?.[0]?.message };
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    // Simple auth gate — pass ?key=<CF_GLOBAL_KEY> or POST with JSON {key}
    let authKey = url.searchParams.get("key");
    if (request.method === "POST") {
      try { const b = await request.json(); authKey = b.key ?? authKey; } catch {}
    }
    if (!authKey || authKey !== env.CF_GLOBAL_KEY) {
      return new Response("Unauthorized — pass ?key=YOUR_CF_GLOBAL_KEY", { status: 401 });
    }

    if (!env.CF_EMAIL || !env.CF_GLOBAL_KEY) {
      return new Response("Missing secrets: CF_EMAIL and CF_GLOBAL_KEY required", { status: 500 });
    }

    const log = [];
    let pass = 0, fail = 0;

    // DNS for all zones
    for (const [domain, zoneId] of ZONES) {
      const results = await Promise.all([
        upsertCname(zoneId, domain, env),
        upsertCname(zoneId, `www.${domain}`, env),
        // blackroad.io gets all app subdomains
        ...(domain === "blackroad.io"
          ? IO_SUBS.map(sub => upsertCname(zoneId, `${sub}.${domain}`, env))
          : []),
      ]);
      for (const r of results) {
        if (r.ok) { log.push(`✓ ${r.name} (${r.action})`); pass++; }
        else       { log.push(`✗ ${r.name} — ${r.error}`); fail++; }
      }
    }

    // Tunnel ingress
    const tunnel = await updateTunnel(env);
    if (tunnel.ok) log.push(`✓ Tunnel ingress updated (${INGRESS_ROUTES.length} routes)`);
    else           log.push(`✗ Tunnel update failed — ${tunnel.error}`);

    const body = [
      "BlackRoad OS — DNS Setup Complete",
      `${pass} records created/updated, ${fail} failed`,
      "",
      ...log,
      "",
      fail === 0 ? "All domains → Pi tunnel ✓" : `${fail} errors — check above`,
      "",
      "Next: revoke Global API Key at dash.cloudflare.com/profile/api-tokens",
    ].join("\n");

    return new Response(body, {
      headers: { "Content-Type": "text/plain" },
      status: fail === 0 ? 200 : 207,
    });
  },
};
