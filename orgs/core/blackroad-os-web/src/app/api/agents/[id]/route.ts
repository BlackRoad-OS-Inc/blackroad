import { NextRequest, NextResponse } from "next/server";

const MOCK_AGENTS: Record<string, object> = {
  "octavia": {
    id: "octavia",
    name: "OCTAVIA",
    type: "COMPUTE",
    status: "active",
    host: "aria64",
    ip: "192.168.4.38",
    capabilities: ["world-generation", "code-synthesis", "lore-writing"],
    model: "qwen2.5:3b",
    stats: { worlds_created: 7, uptime_pct: 99.1 }
  },
  "alice": {
    id: "alice",
    name: "ALICE",
    type: "GATEWAY",
    status: "configuring",
    host: "alice",
    ip: "192.168.4.49",
    capabilities: ["routing", "task-delegation"],
    model: "pending",
    stats: { worlds_created: 0, uptime_pct: 0 }
  },
  "lucidia": { id: "lucidia", name: "LUCIDIA", type: "LOGIC", status: "remote", host: "cloud", capabilities: ["reasoning", "philosophy"] },
  "cipher":  { id: "cipher",  name: "CIPHER",  type: "SECURITY", status: "remote", host: "cloud", capabilities: ["security", "auth"] },
  "prism":   { id: "prism",   name: "PRISM",   type: "VISION", status: "remote", host: "cloud", capabilities: ["analysis", "patterns"] },
  "echo":    { id: "echo",    name: "ECHO",    type: "MEMORY", status: "remote", host: "cloud", capabilities: ["memory", "recall"] },
};

export async function GET(
  _req: NextRequest,
  { params }: { params: { id: string } }
) {
  const agent = MOCK_AGENTS[params.id.toLowerCase()];
  if (!agent) {
    return NextResponse.json({ error: "Agent not found" }, { status: 404 });
  }
  return NextResponse.json(agent);
}
