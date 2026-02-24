import { NextResponse } from 'next/server';

export const runtime = 'edge';

async function check(name: string, url: string, timeout = 4000) {
  const start = Date.now();
  try {
    const res = await fetch(url, {
      method: 'HEAD', signal: AbortSignal.timeout(timeout),
      headers: { 'User-Agent': 'blackroad-status/1.0' },
    } as RequestInit);
    return { name, status: res.ok ? 'operational' : 'degraded', latencyMs: Date.now() - start, code: res.status };
  } catch {
    return { name, status: 'down', latencyMs: -1, code: 0 };
  }
}

async function fetchJson(url: string, fallback: unknown = null, timeout = 5000) {
  try {
    const res = await fetch(url, {
      signal: AbortSignal.timeout(timeout),
      headers: { 'User-Agent': 'blackroad-status/1.0', Accept: 'application/json' },
    } as RequestInit);
    if (!res.ok) return fallback;
    return await res.json();
  } catch {
    return fallback;
  }
}

export async function GET() {
  const [checks, commandCenter, agentsApi] = await Promise.all([
    Promise.allSettled([
      check('command-center',          'https://command-center.blackroad.workers.dev/health'),
      check('agents-api',              'https://agents-api.blackroad.workers.dev/health'),
      check('blackroad-status worker', 'https://blackroad-status.amundsonalexa.workers.dev/api/ping'),
      check('blackroad-auth worker',   'https://blackroad-auth.amundsonalexa.workers.dev/auth/status'),
      check('agents-status worker',    'https://agents-status.blackroad.io/'),
      check('blackroad.io',            'https://blackroad.io/'),
      check('web app (Vercel)',         'https://blackroad-os-web.vercel.app/'),
      check('aria64 agent node',       'http://192.168.4.38:8080/health', 2000),
      check('blackroad-pi LLM node',   'http://192.168.4.64:11434/', 2000),
      check('alice mesh node',         'http://192.168.4.49:8001/', 2000),
      check('cecilia identity node',   'http://192.168.4.89:80/', 2000),
    ]),
    fetchJson('https://command-center.blackroad.workers.dev/status'),
    fetchJson('https://agents-api.blackroad.workers.dev/agents'),
  ]);

  const services = checks.map(r => r.status === 'fulfilled' ? r.value : { name: 'unknown', status: 'down', latencyMs: -1 });
  const operational = services.filter(s => s.status === 'operational').length;
  const degraded    = services.filter(s => s.status === 'degraded').length;
  const down        = services.filter(s => s.status === 'down').length;

  const overallStatus = down > 3 ? 'major_outage' : down > 0 || degraded > 0 ? 'partial_outage' : 'operational';

  return NextResponse.json({
    status: overallStatus,
    score: Math.round((operational / services.length) * 100),
    services,
    summary: { operational, degraded, down, total: services.length },
    command_center: commandCenter,
    agents_api: agentsApi,
    platform: {
      workers: 499,
      tunnel_routes: 14,
      agent_capacity: 30000,
      orgs: 17,
      repos: 1825,
      git_branch: 'master',
      repo: 'BlackRoad-OS-Inc/blackroad',
    },
    timestamp: new Date().toISOString(),
  }, { headers: { 'Cache-Control': 'no-store' } });
}
