import { NextResponse } from 'next/server';

export const runtime = 'edge';

interface ServiceStatus {
  name: string;
  url: string;
  status: 'operational' | 'degraded' | 'down';
  latency?: number;
}

async function checkEndpoint(name: string, url: string): Promise<ServiceStatus> {
  const start = Date.now();
  try {
    const res = await fetch(url, {
      method: 'HEAD',
      signal: AbortSignal.timeout(4000),
      headers: { 'User-Agent': 'blackroad-status/1.0' },
    });
    const latency = Date.now() - start;
    const status = res.ok ? 'operational' : latency > 2000 ? 'degraded' : 'down';
    return { name, url, status, latency };
  } catch {
    return { name, url, status: 'down', latency: Date.now() - start };
  }
}

export async function GET() {
  const gatewayUrl = process.env.BLACKROAD_GATEWAY_URL || 'http://127.0.0.1:8787';
  const workerUrl  = process.env.BLACKROAD_WORKER_URL  || 'https://blackroad-os-api.amundsonalexa.workers.dev';

  const checks = await Promise.all([
    checkEndpoint('gateway',  `${gatewayUrl}/health`),
    checkEndpoint('worker',   `${workerUrl}/health`),
    checkEndpoint('auth',     'https://blackroad-auth.amundsonalexa.workers.dev/auth/status'),
    checkEndpoint('agents',   'https://agents-status.blackroad.io/api/ping'),
    checkEndpoint('status',   'https://blackroad-status.amundsonalexa.workers.dev/api/ping'),
    checkEndpoint('status',   'https://blackroad-os-status.blackroad.workers.dev/api/ping'),
  ]);

  const overallStatus = checks.every(s => s.status === 'operational')
    ? 'operational'
    : checks.some(s => s.status === 'down')
    ? 'partial_outage'
    : 'degraded';

  return NextResponse.json(
    {
      status: overallStatus,
      services: checks,
      timestamp: new Date().toISOString(),
      page: { name: 'BlackRoad OS', url: 'https://status.blackroad.io' },
    },
    { headers: { 'Cache-Control': 'public, s-maxage=30, stale-while-revalidate=15' } }
  );
}
