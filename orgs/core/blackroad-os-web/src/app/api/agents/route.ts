import { NextResponse } from "next/server";

const GATEWAY = process.env.BLACKROAD_GATEWAY_URL ?? "http://127.0.0.1:8787";

const MOCK_AGENTS = [
  { id: "lucidia-001", name: "LUCIDIA", type: "reasoning", status: "active", model: "qwen2.5:3b", tasks: 847 },
  { id: "alice-001",   name: "ALICE",   type: "worker",    status: "active", model: "qwen2.5:3b", tasks: 12453 },
  { id: "octavia-001", name: "OCTAVIA", type: "devops",    status: "active", model: "qwen2.5:3b", tasks: 3291 },
  { id: "prism-001",   name: "PRISM",   type: "analytics",status: "active", model: "qwen2.5:3b", tasks: 2104 },
  { id: "echo-001",    name: "ECHO",    type: "memory",   status: "active", model: "nomic-embed-text", tasks: 1876 },
  { id: "cipher-001",  name: "CIPHER",  type: "security", status: "active", model: "qwen2.5:3b", tasks: 8932 },
];

export async function GET(req: Request) {
  const { searchParams } = new URL(req.url);
  const type = searchParams.get("type");
  const status = searchParams.get("status");
  
  let agents = MOCK_AGENTS;
  if (type) agents = agents.filter(a => a.type === type);
  if (status) agents = agents.filter(a => a.status === status);
  
  return NextResponse.json({
    agents,
    total: agents.length,
    timestamp: new Date().toISOString(),
  });
}

export async function POST(req: Request) {
  const body = await req.json();
  const { task, agent_id, model } = body;
  
  
  // In production: forward to gateway
  const taskId = `t-${Date.now().toString(36)}`;
  return NextResponse.json({
    task_id: taskId,
    assigned_to: agent_id ?? "lucidia-001",
    model: model ?? "qwen2.5:3b",
    status: "queued",
    created_at: new Date().toISOString(),
  }, { status: 201 });
}
