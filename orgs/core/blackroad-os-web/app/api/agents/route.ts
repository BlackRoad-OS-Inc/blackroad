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
          { id: 'lucidia',  name: 'Lucidia',  role: 'Dreamer',   status: 'active',  node: 'aria64', color: '#00BCD4', skills: ['reasoning','strategy','vision'] },
          { id: 'alice',    name: 'Alice',    role: 'Operator',  status: 'active',  node: 'alice',  color: '#2979FF', skills: ['devops','automation','cicd'] },
          { id: 'octavia',  name: 'Octavia',  role: 'Architect', status: 'active',  node: 'aria64', color: '#9C27B0', skills: ['systems','infra','design'] },
          { id: 'prism',    name: 'Prism',    role: 'Analyst',   status: 'active',  node: 'aria64', color: '#F5A623', skills: ['analytics','patterns','data'] },
          { id: 'echo',     name: 'Echo',     role: 'Librarian', status: 'idle',    node: 'alice',  color: '#4CAF50', skills: ['memory','retrieval','context'] },
          { id: 'cipher',   name: 'Cipher',   role: 'Guardian',  status: 'active',  node: 'aria64', color: '#FF1D6C', skills: ['security','encryption','auth'] },
        ],
        fleet: { total_capacity: 30000, online_nodes: 2, online_agents: 5 },
        fallback: true,
        error: String(e),
      },
      { status: 200 }
    );
  }
}
