import { NextRequest, NextResponse } from "next/server";

const GATEWAY = process.env.BLACKROAD_GATEWAY_URL ?? "http://127.0.0.1:8787";

export async function GET(_req: NextRequest) {
  const [agentsRes, healthRes] = await Promise.all([
    fetch(`${GATEWAY}/agents`),
    fetch(`${GATEWAY}/health`),
  ]);
  const [agents, health] = await Promise.all([agentsRes.json(), healthRes.json()]);
  return NextResponse.json({ ...agents, gateway: health });
}

export async function POST(req: NextRequest) {
  const { agent_id, action, ...body } = await req.json() as {
    agent_id: string; action: "wake" | "sleep" | "assign"; [k: string]: unknown;
  };
  const res = await fetch(`${GATEWAY}/agents/${agent_id}/${action}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
  return NextResponse.json(await res.json(), { status: res.status });
}
