import { NextResponse } from 'next/server';

export const runtime = 'edge';

export async function GET() {
  try {
    const res = await fetch('https://agents-status.blackroad.io/', {
      headers: { 'User-Agent': 'blackroad-web/1.0' },
      cf: { cacheTtl: 30 },
    } as RequestInit);

    if (!res.ok) throw new Error(`upstream ${res.status}`);
    const data = await res.json();

    return NextResponse.json(data, {
      headers: { 'Cache-Control': 'public, s-maxage=30, stale-while-revalidate=15' },
    });
  } catch (e) {
    return NextResponse.json(
      {
        agents: [
          { id: 'octavia', name: 'Octavia', role: 'Architect', status: 'active', node: 'aria64', color: '#9C27B0' },
          { id: 'alice', name: 'Alice', role: 'Operator', status: 'active', node: 'alice', color: '#2979FF' },
        ],
        fleet: { total_capacity: 30000, online_nodes: 2 },
        fallback: true,
        error: String(e),
      },
      { status: 200 }
    );
  }
}
