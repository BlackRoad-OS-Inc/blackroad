import { NextResponse } from 'next/server';

export const runtime = 'edge';

interface PiNode {
  name: string;
  ip: string;
  role: string;
  capacity: number;
  status: 'online' | 'offline' | 'unknown';
}

const NODES: PiNode[] = [
  { name: 'aria64', ip: '192.168.4.38', role: 'PRIMARY', capacity: 22500, status: 'online' },
  { name: 'alice', ip: '192.168.4.49', role: 'SECONDARY', capacity: 7500, status: 'online' },
];

export async function GET() {
  // Fetch live stats from agent status worker
  let agentData: { fleet?: { online_nodes?: number; total_capacity?: number } } = {};
  try {
    const res = await fetch('https://agents-status.blackroad.io/', {
      headers: { 'User-Agent': 'blackroad-web/1.0' },
    } as RequestInit);
    if (res.ok) agentData = await res.json();
  } catch {
    // fallback to static data
  }

  const fleet = agentData?.fleet || {};

  return NextResponse.json(
    {
      nodes: NODES,
      summary: {
        total_nodes: NODES.length,
        online_nodes: fleet.online_nodes ?? NODES.length,
        total_capacity: NODES.reduce((sum, n) => sum + n.capacity, 0),
        worlds_generated: null, // populated by worlds endpoint
      },
      timestamp: new Date().toISOString(),
    },
    {
      headers: { 'Cache-Control': 'public, s-maxage=30, stale-while-revalidate=15' },
    }
  );
}
