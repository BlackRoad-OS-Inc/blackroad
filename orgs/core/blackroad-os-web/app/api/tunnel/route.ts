import { NextResponse } from 'next/server';

// Static tunnel map — mirrors ~/.cloudflared/config.yml
const TUNNEL_ROUTES = [
  { hostname: 'agents.blackroad.io',      service: 'http://192.168.4.38:8080', pi: 'aria64',       group: 'PRIMARY' },
  { hostname: 'api.blackroad.io',         service: 'http://192.168.4.38:8080', pi: 'aria64',       group: 'PRIMARY' },
  { hostname: 'nodes.blackroad.io',       service: 'http://192.168.4.38:8080', pi: 'aria64',       group: 'PRIMARY' },
  { hostname: 'pi-primary.blackroad.io',  service: 'http://192.168.4.38:80',   pi: 'aria64',       group: 'PRIMARY' },
  { hostname: 'llm.blackroad.io',         service: 'http://192.168.4.64:11434',pi: 'blackroad-pi', group: 'SECONDARY' },
  { hostname: 'ollama.blackroad.io',      service: 'http://192.168.4.64:11434',pi: 'blackroad-pi', group: 'SECONDARY' },
  { hostname: 'pi-secondary.blackroad.io',service: 'http://192.168.4.64:8080', pi: 'blackroad-pi', group: 'SECONDARY' },
  { hostname: 'mesh.blackroad.io',        service: 'http://192.168.4.49:8001', pi: 'alice',        group: 'TERTIARY' },
  { hostname: 'crm.blackroad.io',         service: 'http://192.168.4.49:8083', pi: 'alice',        group: 'TERTIARY' },
  { hostname: 'ai-cpu.blackroad.io',      service: 'http://192.168.4.49:8790', pi: 'alice',        group: 'TERTIARY' },
  { hostname: 'identity.blackroad.io',    service: 'http://192.168.4.89:80',   pi: 'cecilia',      group: 'IDENTITY' },
  { hostname: 'ai.blackroad.io',          service: 'http://192.168.4.89:8787', pi: 'cecilia',      group: 'IDENTITY' },
  { hostname: 'mcp.blackroad.io',         service: 'http://192.168.4.89:5001', pi: 'cecilia',      group: 'IDENTITY' },
];

export const runtime = 'edge';
export async function GET() {
  const byPi = TUNNEL_ROUTES.reduce((acc, r) => {
    if (!acc[r.pi]) acc[r.pi] = [];
    acc[r.pi].push(r);
    return acc;
  }, {} as Record<string, typeof TUNNEL_ROUTES>);

  return NextResponse.json({
    tunnel_id: '8ae67ab0-71fb-4461-befc-a91302369a7e',
    total_routes: TUNNEL_ROUTES.length,
    routes: TUNNEL_ROUTES,
    by_pi: byPi,
    timestamp: new Date().toISOString(),
  }, { headers: { 'Cache-Control': 'public, s-maxage=60' } });
}
