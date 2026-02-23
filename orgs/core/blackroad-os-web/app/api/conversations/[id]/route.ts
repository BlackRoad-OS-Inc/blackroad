import { NextResponse } from 'next/server';
import type { Conversation, Message } from '../route';

export const runtime = 'edge';

// eslint-disable-next-line @typescript-eslint/no-explicit-any
declare const CONVERSATIONS_KV: any;

// ── GET /api/conversations/[id] ─────────────────────────────────────────────
export async function GET(_req: Request, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;

  try {
    if (typeof CONVERSATIONS_KV !== 'undefined') {
      const conv = await CONVERSATIONS_KV.get(`conv:${id}`, 'json') as Conversation | null;
      if (!conv) return NextResponse.json({ error: 'not found' }, { status: 404 });
      return NextResponse.json(conv);
    }
  } catch { /* KV not available */ }

  return NextResponse.json({ error: 'not found' }, { status: 404 });
}

// ── PATCH /api/conversations/[id] — append messages ────────────────────────
export async function PATCH(request: Request, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  let body: { messages?: Message[]; title?: string };
  try { body = await request.json(); }
  catch { return NextResponse.json({ error: 'Invalid JSON' }, { status: 400 }); }

  try {
    if (typeof CONVERSATIONS_KV !== 'undefined') {
      const conv = await CONVERSATIONS_KV.get(`conv:${id}`, 'json') as Conversation | null;
      if (!conv) return NextResponse.json({ error: 'not found' }, { status: 404 });

      const updated: Conversation = {
        ...conv,
        title:      body.title ?? conv.title,
        messages:   [...conv.messages, ...(body.messages ?? [])],
        updated_at: new Date().toISOString(),
        preview:    body.messages?.at(-1)?.content?.slice(0, 120) ?? conv.preview,
      };

      await CONVERSATIONS_KV.put(`conv:${id}`, JSON.stringify(updated), {
        expirationTtl: 60 * 60 * 24 * 365,
      });

      // Update index entry
      const index = (await CONVERSATIONS_KV.get('convs:index', 'json') as Conversation[] | null) ?? [];
      const newIndex = index.map(c => c.id === id ? { ...updated, messages: [] } : c);
      await CONVERSATIONS_KV.put('convs:index', JSON.stringify(newIndex), {
        expirationTtl: 60 * 60 * 24 * 365,
      });

      return NextResponse.json(updated);
    }
  } catch { /* KV not available */ }

  return NextResponse.json({ error: 'storage unavailable' }, { status: 503 });
}

// ── DELETE /api/conversations/[id] ─────────────────────────────────────────
export async function DELETE(_req: Request, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;

  try {
    if (typeof CONVERSATIONS_KV !== 'undefined') {
      await CONVERSATIONS_KV.delete(`conv:${id}`);
      const index = (await CONVERSATIONS_KV.get('convs:index', 'json') as Conversation[] | null) ?? [];
      await CONVERSATIONS_KV.put('convs:index', JSON.stringify(index.filter(c => c.id !== id)), {
        expirationTtl: 60 * 60 * 24 * 365,
      });
    }
  } catch { /* KV not available */ }

  return new Response(null, { status: 204 });
}
