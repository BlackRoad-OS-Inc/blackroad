import { NextResponse } from 'next/server';

export const runtime = 'edge';

const NODES = [
  { name: 'aria64',       ip: '192.168.4.38', role: 'PRIMARY',   capacity: 22500, model: 'Pi 5',    services: ['agents.blackroad.io','api.blackroad.io','nodes.blackroad.io'] },
  { name: 'blackroad-pi', ip: '192.168.4.64', role: 'SECONDARY', capacity: 7500,  model: 'Pi 4',    services: ['llm.blackroad.io','ollama.blackroad.io','pi-secondary.blackroad.io'] },
  { name: 'alice',        ip: '192.168.4.49', role: 'TERTIARY',  capacity: 0,     model: 'Pi 4',    services: ['mesh.blackroad.io','crm.blackroad.io','ai-cpu.blackroad.io'] },
  { name: 'cecilia',      ip: '192.168.4.89', role: 'IDENTITY',  capacity: 0,     model: 'Pi 5',    services: ['identity.blackroad.io','ai.blackroad.io','mcp.blackroad.io'] },
];

async function pingNode(ip: string): Promise<{ online: boolean; latencyMs: number }> {
  const start = Date.now();
  try {
    const res = await fetch(`http://${ip}:8080/health`, {
      signal: AbortSignal.timeout(2000),
    } as RequestInit);
    return { online: res.ok, latencyMs: Date.now() - start };
  } catch {
    return { online: false, latencyMs: -1 };
  }
}

export async function GET() {
  const results = await Promise.allSettled(NODES.map(n => pingNode(n.ip)));
  const nodes = NODES.map((n, i) => {
    const r = results[i];
    const health = r.status === 'fulfilled' ? r.value : { online: false, latencyMs: -1 };
    return { ...n, status: health.online ? 'online' : 'offline', latencyMs: health.latencyMs };
  });

  return NextResponse.json({
    nodes,
    summary: {
      total_nodes: nodes.length,
      online_nodes: nodes.filter(n => n.status === 'online').length,
      total_capacity: nodes.reduce((s, n) => s + n.capacity, 0),
      tunnel_id: '8ae67ab0-71fb-4461-befc-a91302369a7e',
      tunnel_routes: nodes.reduce((s, n) => s + n.services.length, 0),
    },
    timestamp: new Date().toISOString(),
  }, { headers: { 'Cache-Control': 'no-store' } });
}
