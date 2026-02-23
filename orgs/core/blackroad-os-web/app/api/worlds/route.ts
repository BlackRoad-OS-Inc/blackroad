import { NextResponse } from 'next/server';

export const runtime = 'edge';

// In-memory store for edge runtime (resets on cold start).
// For persistence, bind a KV namespace named WORLDS_KV in wrangler.toml / Vercel env.
// eslint-disable-next-line @typescript-eslint/no-explicit-any
declare const WORLDS_KV: any;

interface World {
  id: string;
  name: string;
  type: string;
  description: string;
  lore?: string;
  tags: string[];
  agent: string;
  created_at: string;
}

export async function GET(request: Request) {
  const url = new URL(request.url);
  const limit = Math.min(parseInt(url.searchParams.get('limit') || '20'), 100);

  // Try KV first
  try {
    if (typeof WORLDS_KV !== 'undefined') {
      const raw = await WORLDS_KV.get('worlds:index', 'json') as World[] | null;
      const worlds = (raw ?? []).slice(0, limit);
      return NextResponse.json({ worlds, total: worlds.length, source: 'kv' }, {
        headers: { 'Cache-Control': 'public, s-maxage=30, stale-while-revalidate=15' },
      });
    }
  } catch { /* fall through */ }

  // Fallback: try upstream worlds worker
  try {
    const res = await fetch('https://worlds.blackroad.io/', {
      headers: { 'User-Agent': 'blackroad-web/1.0' },
    });
    if (res.ok) {
      const data = await res.json() as { total: number; worlds: World[] };
      return NextResponse.json({ ...data, worlds: data.worlds.slice(0, limit), source: 'upstream' }, {
        headers: { 'Cache-Control': 'public, s-maxage=60, stale-while-revalidate=30' },
      });
    }
  } catch { /* fall through */ }

  return NextResponse.json({ worlds: [], total: 0, source: 'empty' });
}

export async function POST(request: Request) {
  let body: Partial<World>;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: 'Invalid JSON' }, { status: 400 });
  }

  if (!body.name || !body.description) {
    return NextResponse.json({ error: 'name and description required' }, { status: 400 });
  }

  const world: World = {
    id:          `world_${Date.now()}_${Math.random().toString(36).slice(2, 7)}`,
    name:        String(body.name),
    type:        String(body.type || 'world'),
    description: String(body.description),
    lore:        body.lore ? String(body.lore) : undefined,
    tags:        Array.isArray(body.tags) ? body.tags : [],
    agent:       String(body.agent || 'lucidia'),
    created_at:  new Date().toISOString(),
  };

  // Persist to KV if available
  try {
    if (typeof WORLDS_KV !== 'undefined') {
      const existing = (await WORLDS_KV.get('worlds:index', 'json') as World[] | null) ?? [];
      const updated = [world, ...existing].slice(0, 500);
      await WORLDS_KV.put('worlds:index', JSON.stringify(updated), { expirationTtl: 60 * 60 * 24 * 90 });
    }
  } catch { /* KV not bound — world returned but not persisted */ }

  return NextResponse.json(world, { status: 201 });
}

