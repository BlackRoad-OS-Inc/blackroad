import { NextResponse } from 'next/server';

// Pi node endpoints - try these first
const PI_NODES = [
  'http://192.168.4.38:8080',  // aria64 - 22,500 agent capacity
  'http://192.168.4.64:8080',  // blackroad-pi
];

const UPSTREAM = 'https://agents-status.blackroad.io/';

const FALLBACK_AGENTS = [
  { id: 'lucidia',  name: 'Lucidia',  role: 'Dreamer',   status: 'active', node: 'aria64',       color: '#2979FF', skills: ['reasoning','strategy','vision'],      tasks: 847,  uptime: 99.9 },
  { id: 'alice',    name: 'Alice',    role: 'Operator',  status: 'active', node: 'alice',        color: '#34d399', skills: ['devops','automation','cicd'],         tasks: 12453, uptime: 99.99 },
  { id: 'octavia',  name: 'Octavia',  role: 'Architect', status: 'active', node: 'aria64',       color: '#F5A623', skills: ['systems','infra','design'],           tasks: 3291, uptime: 99.9 },
  { id: 'prism',    name: 'Prism',    role: 'Analyst',   status: 'active', node: 'aria64',       color: '#F5A623', skills: ['analytics','patterns','data'],        tasks: 2104, uptime: 99.95 },
  { id: 'echo',     name: 'Echo',     role: 'Librarian', status: 'idle',   node: 'alice',        color: '#4CAF50', skills: ['memory','retrieval','context'],       tasks: 1876, uptime: 99.99 },
  { id: 'cipher',   name: 'Cipher',   role: 'Guardian',  status: 'active', node: 'aria64',       color: '#FF1D6C', skills: ['security','encryption','auth'],       tasks: 8932, uptime: 99.999 },
  { id: 'cecilia',  name: 'Cecilia',  role: 'Core',      status: 'active', node: 'blackroad-pi', color: '#9C27B0', skills: ['meta-cognition','identity','memory'], tasks: 5200, uptime: 99.9 },
  { id: 'shellfish',name: 'Shellfish',role: 'Hacker',    status: 'active', node: 'aria64',       color: '#ef4444', skills: ['security','exploits','pentest'],      tasks: 2981, uptime: 99.8 },
];

async function tryPiNode(base: string): Promise<Response | null> {
  try {
    const ctrl = new AbortController();
    const tid = setTimeout(() => ctrl.abort(), 2000);
    const res = await fetch(`${base}/agents`, { signal: ctrl.signal });
    clearTimeout(tid);
    if (res.ok) return res;
  } catch {}
  return null;
}

export const runtime = 'edge';

export async function GET() {
  // 1. Try upstream worker
  try {
    const res = await fetch(UPSTREAM, {
      headers: { 'User-Agent': 'blackroad-web/1.0' },
    } as RequestInit);
    if (res.ok) {
      const data = await res.json();
      return NextResponse.json(data, {
        headers: { 'Cache-Control': 'public, s-maxage=30, stale-while-revalidate=15', 'X-Source': 'upstream' },
      });
    }
  } catch {}

  // 2. Try Pi nodes directly (only works from internal network)
  for (const base of PI_NODES) {
    const res = await tryPiNode(base);
    if (res) {
      try {
        const data = await res.json();
        return NextResponse.json(
          { ...data, source: 'pi-node' },
          { headers: { 'Cache-Control': 'public, s-maxage=10', 'X-Source': base } }
        );
      } catch {}
    }
  }

  // 3. Static fallback with live-ish data
  const now = new Date().toISOString();
  return NextResponse.json({
    agents: FALLBACK_AGENTS,
    fleet: {
      total_capacity: 30000,
      online_nodes: 3,
      online_agents: FALLBACK_AGENTS.filter(a => a.status === 'active').length,
      nodes: [
        { name: 'aria64',       ip: '192.168.4.38', role: 'PRIMARY',   capacity: 22500, status: 'online' },
        { name: 'blackroad-pi', ip: '192.168.4.64', role: 'SECONDARY', capacity: 7500,  status: 'online' },
        { name: 'alice',        ip: '192.168.4.49', role: 'TERTIARY',  capacity: 500,   status: 'online' },
      ],
    },
    source: 'fallback',
    timestamp: now,
  }, {
    status: 200,
    headers: { 'Cache-Control': 'public, s-maxage=60', 'X-Source': 'fallback' },
  });
}
