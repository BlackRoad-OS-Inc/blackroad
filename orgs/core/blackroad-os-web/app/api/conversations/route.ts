import { NextResponse } from 'next/server';

export const runtime = 'edge';

// KV binding CONVERSATIONS_KV for persistence (set in wrangler/Vercel env)
// eslint-disable-next-line @typescript-eslint/no-explicit-any
declare const CONVERSATIONS_KV: any;

export interface Message {
  role: 'user' | 'assistant';
  content: string;
  ts: string;
}

export interface Conversation {
  id: string;
  title: string;
  agent: string;
  messages: Message[];
  created_at: string;
  updated_at: string;
  preview: string;
}

// ── GET /api/conversations ──────────────────────────────────────────────────
export async function GET(request: Request) {
  const url = new URL(request.url);
  const limit = Math.min(parseInt(url.searchParams.get('limit') || '50'), 200);
  const agent = url.searchParams.get('agent') || null;

  try {
    if (typeof CONVERSATIONS_KV !== 'undefined') {
      const raw = await CONVERSATIONS_KV.get('convs:index', 'json') as Conversation[] | null;
      let convs = raw ?? [];
      if (agent) convs = convs.filter(c => c.agent === agent);
      return NextResponse.json({ conversations: convs.slice(0, limit), total: convs.length });
    }
  } catch { /* KV not available */ }

  return NextResponse.json({ conversations: [], total: 0, source: 'empty' });
}

// ── POST /api/conversations ─────────────────────────────────────────────────
export async function POST(request: Request) {
  let body: Partial<Conversation & { message: string }>;
  try { body = await request.json(); }
  catch { return NextResponse.json({ error: 'Invalid JSON' }, { status: 400 }); }

  const now = new Date().toISOString();
  const firstMsg: Message | undefined = body.message
    ? { role: 'user', content: body.message, ts: now }
    : undefined;

  const conv: Conversation = {
    id:         `conv_${Date.now()}_${Math.random().toString(36).slice(2, 7)}`,
    title:      body.title || (body.message ? body.message.slice(0, 60) : 'New conversation'),
    agent:      body.agent || 'lucidia',
    messages:   firstMsg ? [firstMsg] : [],
    created_at: now,
    updated_at: now,
    preview:    body.message ? body.message.slice(0, 120) : '',
  };

  try {
    if (typeof CONVERSATIONS_KV !== 'undefined') {
      const existing = (await CONVERSATIONS_KV.get('convs:index', 'json') as Conversation[] | null) ?? [];
      const updated = [conv, ...existing].slice(0, 1000);
      await CONVERSATIONS_KV.put('convs:index', JSON.stringify(updated), {
        expirationTtl: 60 * 60 * 24 * 365,
      });
      await CONVERSATIONS_KV.put(`conv:${conv.id}`, JSON.stringify(conv), {
        expirationTtl: 60 * 60 * 24 * 365,
      });
    }
  } catch { /* KV not bound — return conv without persisting */ }

  return NextResponse.json(conv, { status: 201 });
}
