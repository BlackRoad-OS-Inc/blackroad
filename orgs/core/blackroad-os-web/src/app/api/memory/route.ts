import { NextResponse } from "next/server";
import { createHash } from "crypto";

interface MemoryEntry {
  hash: string;
  prev_hash: string;
  key: string;
  content: string;
  type: "fact" | "observation" | "inference" | "commitment";
  truth_state: 1 | 0 | -1;
  created_at: string;
}

// In-memory store (production: Qdrant or SQLite)
const MEMORY: MemoryEntry[] = [];
let prevHash = "GENESIS";

function pssha(prev: string, key: string, content: string): string {
  const ts = Date.now().toString();
  return createHash("sha256").update(`${prev}:${key}:${content}:${ts}`).digest("hex");
}

export async function GET(req: Request) {
  const { searchParams } = new URL(req.url);
  const q = searchParams.get("q")?.toLowerCase();
  const type = searchParams.get("type");
  
  let entries = [...MEMORY];
  if (q) entries = entries.filter(e => e.content.toLowerCase().includes(q) || e.key.includes(q));
  if (type) entries = entries.filter(e => e.type === type);
  
  return NextResponse.json({
    entries: entries.slice(-50).reverse(),
    total: MEMORY.length,
    chain_head: prevHash.slice(0, 16),
  });
}

export async function POST(req: Request) {
  const { key, content, type = "fact", truth_state = 1 } = await req.json();
  
  const hash = pssha(prevHash, key, content);
  const entry: MemoryEntry = {
    hash: hash.slice(0, 16),
    prev_hash: prevHash.slice(0, 16),
    key, content, type, truth_state,
    created_at: new Date().toISOString(),
  };
  MEMORY.push(entry);
  prevHash = hash;
  
  return NextResponse.json({ stored: true, hash: entry.hash, chain_length: MEMORY.length }, { status: 201 });
}
