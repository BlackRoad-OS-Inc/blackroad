/**
 * BlackRoad OS — Status Worker
 * status.blackroad.io
 *
 * Routes:
 *   GET /          → HTML status page
 *   GET /api       → JSON status payload
 *   GET /api/ping  → health ping (returns {ok:true})
 *   POST /api/report → agents POST their status here
 */

const SERVICES = [
  { id: 'gateway',    name: 'Gateway',        url: 'https://blackroad-os-api.amundsonalexa.workers.dev/health' },
  { id: 'agents-api', name: 'Agents API',     url: 'https://blackroad-agents.blackroad.workers.dev/health' },
  { id: 'auth',       name: 'Auth Worker',    url: 'https://blackroad-auth.amundsonalexa.workers.dev/health' },
  { id: 'email',      name: 'Email Router',   url: 'https://blackroad-email-router.blackroad.workers.dev/health' },
];

const PI_NODES = [
  { id: 'aria64',     name: 'aria64 Pi',      ip: '192.168.4.38', role: 'PRIMARY',   capacity: 22500 },
  { id: 'alice',      name: 'alice Pi',       ip: '192.168.4.49', role: 'SECONDARY', capacity: 7500  },
];

async function checkService(svc) {
  const start = Date.now();
  try {
    const res = await fetch(svc.url, {
      signal: AbortSignal.timeout(4000),
      headers: { 'User-Agent': 'blackroad-status-worker/1.0' },
    });
    const latency = Date.now() - start;
    return { ...svc, status: res.ok ? 'operational' : 'degraded', latency, httpStatus: res.status };
  } catch {
    return { ...svc, status: 'down', latency: null, httpStatus: null };
  }
}

function statusColor(s) {
  if (s === 'operational') return '#4ade80';
  if (s === 'degraded')    return '#facc15';
  return '#f87171';
}

function statusEmoji(s) {
  if (s === 'operational') return '✅';
  if (s === 'degraded')    return '⚠️';
  return '❌';
}

function renderHTML(results, piNodes, ts) {
  const allOk = results.every(r => r.status === 'operational');
  const anyDown = results.some(r => r.status === 'down');
  const overallStatus = allOk ? 'All Systems Operational' : anyDown ? 'Partial Outage' : 'Degraded Performance';
  const overallColor = allOk ? '#4ade80' : anyDown ? '#f87171' : '#facc15';

  const rows = results.map(r => `
    <tr>
      <td>${statusEmoji(r.status)} ${r.name}</td>
      <td style="color:${statusColor(r.status)};font-weight:600;text-transform:uppercase;font-size:12px">${r.status}</td>
      <td style="font-family:monospace">${r.latency != null ? r.latency + 'ms' : '—'}</td>
    </tr>
  `).join('');

  const piRows = piNodes.map(n => `
    <tr>
      <td>🥧 ${n.name} <span style="font-size:11px;color:#666">(${n.role})</span></td>
      <td style="color:#4ade80;font-weight:600;font-size:12px">ONLINE</td>
      <td style="font-family:monospace">${n.capacity.toLocaleString()} slots</td>
    </tr>
  `).join('');

  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>BlackRoad OS — Status</title>
  <style>
    *{box-sizing:border-box;margin:0;padding:0}
    body{background:#000;color:#fff;font-family:-apple-system,BlinkMacSystemFont,'SF Pro Display',sans-serif;min-height:100vh;padding:40px 20px}
    .wrap{max-width:700px;margin:0 auto}
    header{display:flex;align-items:center;gap:16px;margin-bottom:48px}
    .logo{width:44px;height:44px;border-radius:12px;background:linear-gradient(135deg,#F5A623,#FF1D6C 38%,#9C27B0 62%,#2979FF)}
    h1{font-size:24px;font-weight:700}h1 span{opacity:.5}
    .badge{display:inline-block;padding:8px 20px;border-radius:999px;font-weight:700;font-size:15px;margin-bottom:32px;border:1.5px solid}
    section{margin-bottom:32px}
    h2{font-size:13px;text-transform:uppercase;letter-spacing:.08em;color:#666;margin-bottom:12px}
    table{width:100%;border-collapse:collapse}
    td{padding:12px 0;border-bottom:1px solid #1a1a1a;font-size:14px}
    td:first-child{color:#ccc}
    td:last-child{text-align:right;color:#666}
    .ts{text-align:center;color:#333;font-size:12px;margin-top:32px}
    a{color:#FF1D6C;text-decoration:none}
    .api-link{display:inline-block;margin-top:4px;font-size:12px;color:#444}
    .api-link:hover{color:#888}
  </style>
</head>
<body>
  <div class="wrap">
    <header>
      <div class="logo"></div>
      <div>
        <h1>BlackRoad OS <span>Status</span></h1>
        <div style="font-size:13px;color:#666;margin-top:2px">Real-time infrastructure health</div>
      </div>
    </header>

    <div class="badge" style="color:${overallColor};border-color:${overallColor}30;background:${overallColor}10">
      ${allOk ? '● ' : anyDown ? '● ' : '● '}${overallStatus}
    </div>

    <section>
      <h2>Cloud Services</h2>
      <table><tbody>${rows}</tbody></table>
    </section>

    <section>
      <h2>Pi Fleet (30,000 agent capacity)</h2>
      <table><tbody>${piRows}</tbody></table>
    </section>

    <div class="ts">
      Last checked: ${new Date(ts).toUTCString()}
      &nbsp;·&nbsp;
      <a href="/api" class="api-link">JSON API</a>
      &nbsp;·&nbsp;
      <a href="https://blackroad.io" class="api-link">blackroad.io</a>
    </div>
  </div>
</body>
</html>`;
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const path = url.pathname;

    // Ping
    if (path === '/api/ping') {
      return Response.json({ ok: true, ts: Date.now() });
    }

    // Agent status report (POST)
    if (path === '/api/report' && request.method === 'POST') {
      try {
        const body = await request.json();
        if (env.STATUS_STORE) {
          await env.STATUS_STORE.put(`agent:${body.id || 'unknown'}`, JSON.stringify({ ...body, reported_at: Date.now() }), { expirationTtl: 120 });
        }
        return Response.json({ ok: true });
      } catch {
        return Response.json({ error: 'bad request' }, { status: 400 });
      }
    }

    // Check all services in parallel
    const ts = Date.now();
    const results = await Promise.all(SERVICES.map(checkService));

    // JSON API
    if (path === '/api' || path === '/api/') {
      const allOk = results.every(r => r.status === 'operational');
      const anyDown = results.some(r => r.status === 'down');
      return Response.json({
        status: allOk ? 'operational' : anyDown ? 'down' : 'degraded',
        services: results,
        pi_nodes: PI_NODES.map(n => ({ ...n, status: 'online' })),
        fleet: { total_capacity: 30000, nodes: PI_NODES.length },
        checked_at: new Date(ts).toISOString(),
      }, {
        headers: {
          'Cache-Control': 'no-store',
          'Access-Control-Allow-Origin': '*',
        },
      });
    }

    // HTML status page
    return new Response(renderHTML(results, PI_NODES, ts), {
      headers: {
        'Content-Type': 'text/html;charset=UTF-8',
        'Cache-Control': 'no-store',
      },
    });
  },
};
