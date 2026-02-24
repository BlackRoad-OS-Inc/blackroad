import { NextRequest, NextResponse } from "next/server";

const GATEWAY = process.env.BLACKROAD_GATEWAY_URL ?? "http://127.0.0.1:8787";

export async function GET(req: NextRequest) {
  const { searchParams } = new URL(req.url);
  const key = searchParams.get("key");
  const url = key ? `${GATEWAY}/memory/${encodeURIComponent(key)}` : `${GATEWAY}/memory`;
  const res = await fetch(url, { headers: { "Content-Type": "application/json" } });
  const data = await res.json();
  return NextResponse.json(data, { status: res.status });
}

export async function POST(req: NextRequest) {
  const body = await req.json();
  const res = await fetch(`${GATEWAY}/memory`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
  const data = await res.json();
  return NextResponse.json(data, { status: res.status });
}

export async function DELETE(req: NextRequest) {
  const { searchParams } = new URL(req.url);
  const key = searchParams.get("key");
  if (!key) return NextResponse.json({ error: "key required" }, { status: 400 });
  const res = await fetch(`${GATEWAY}/memory/${encodeURIComponent(key)}`, { method: "DELETE" });
  const data = await res.json();
  return NextResponse.json(data, { status: res.status });
}
