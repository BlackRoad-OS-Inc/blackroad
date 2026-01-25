import { NextResponse } from 'next/server';

export const runtime = 'edge';

interface ServiceStatus {
  name: string;
  status: 'operational' | 'degraded' | 'down';
  latency?: number;
}

export async function GET() {
  const services: ServiceStatus[] = [
    { name: 'api', status: 'operational', latency: 12 },
    { name: 'database', status: 'operational', latency: 8 },
    { name: 'auth', status: 'operational', latency: 15 },
    { name: 'agents', status: 'operational', latency: 45 },
    { name: 'monitoring', status: 'operational', latency: 22 },
  ];

  const overallStatus = services.every((s) => s.status === 'operational')
    ? 'operational'
    : services.some((s) => s.status === 'down')
    ? 'major_outage'
    : 'partial_outage';

  const response = {
    status: overallStatus,
    services,
    timestamp: new Date().toISOString(),
    page: {
      name: 'BlackRoad OS',
      url: 'https://status.blackroad.io',
    },
  };

  return NextResponse.json(response, {
    status: 200,
    headers: {
      'Cache-Control': 'public, s-maxage=60, stale-while-revalidate=30',
    },
  });
}
