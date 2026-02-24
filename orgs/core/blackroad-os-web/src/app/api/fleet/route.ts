import { NextResponse } from "next/server";

const PI_NODES = [
  {
    id: "aria64", name: "octavia", ip: "192.168.4.38",
    role: "Primary", capacity: 22500,
    models: ["qwen2.5:3b", "nomic-embed-text"],
    status: "online",
  },
  {
    id: "alice", name: "alice", ip: "192.168.4.49",
    role: "Secondary", capacity: 7500,
    models: ["llama3.2:1b"],
    status: "online",
  },
];

export async function GET() {
  const nodes = PI_NODES.map(node => ({
    ...node,
    checked_at: new Date().toISOString(),
  }));
  
  return NextResponse.json({
    nodes,
    total: nodes.length,
    online: nodes.filter(n => n.status === "online").length,
    total_capacity: nodes.reduce((sum, n) => sum + n.capacity, 0),
  });
}
