import { NextResponse } from "next/server";

const GATEWAY_URL = process.env.BLACKROAD_GATEWAY_URL || "http://127.0.0.1:8787";
const PI_NODES = [
  { id: "aria64",      ip: "192.168.4.38", role: "Primary",  capacity: 22500 },
  { id: "blackroad-pi",ip: "192.168.4.64", role: "Tunnel",   capacity: 7500  },
  { id: "lucidia-alt", ip: "192.168.4.99", role: "Backup",   capacity: 1000  },
];

async function pingNode(ip: string): Promise<boolean> {
  try {
    const r = await fetch(`http://${ip}:11434/api/tags`, { signal: AbortSignal.timeout(2000) });
    return r.ok;
  } catch { return false; }
}

export async function GET() {
  const [agentsResp, ...pings] = await Promise.allSettled([
    fetch(`${GATEWAY_URL}/agents`),
    ...PI_NODES.map(n => pingNode(n.ip)),
  ]);

  const agents = agentsResp.status === "fulfilled" && agentsResp.value.ok
    ? (await agentsResp.value.json()).agents ?? []
    : [];

  const nodes = PI_NODES.map((node, i) => ({
    ...node,
    online: pings[i].status === "fulfilled" ? (pings[i] as PromiseFulfilledResult<boolean>).value : false,
    agents: agents.filter((a: { node?: string }) => a.node === node.id).length,
  }));

  return NextResponse.json({ nodes, total_agents: agents.length, timestamp: Date.now() });
}
