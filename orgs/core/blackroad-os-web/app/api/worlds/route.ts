import { NextResponse } from 'next/server';

export const runtime = 'edge';

export async function GET(request: Request) {
  const url = new URL(request.url);
  const format = url.searchParams.get('format') || 'json';
  const limit = Math.min(parseInt(url.searchParams.get('limit') || '20'), 100);

  try {
    const upstreamUrl =
      format === 'rss'
        ? 'https://worlds.blackroad.io/rss'
        : format === 'atom'
        ? 'https://worlds.blackroad.io/atom'
        : 'https://worlds.blackroad.io/';

    const res = await fetch(upstreamUrl, {
      headers: { 'User-Agent': 'blackroad-web/1.0' },
    } as RequestInit);

    if (!res.ok) throw new Error(`upstream ${res.status}`);

    if (format === 'rss' || format === 'atom') {
      const text = await res.text();
      return new Response(text, {
        headers: {
          'Content-Type': format === 'rss' ? 'application/rss+xml' : 'application/atom+xml',
          'Cache-Control': 'public, s-maxage=120, stale-while-revalidate=60',
        },
      });
    }

    const data = await res.json() as { total: number; worlds: unknown[]; generated: string };
    const sliced = { ...data, worlds: data.worlds.slice(0, limit) };

    return NextResponse.json(sliced, {
      headers: { 'Cache-Control': 'public, s-maxage=60, stale-while-revalidate=30' },
    });
  } catch (e) {
    return NextResponse.json({ error: String(e), worlds: [] }, { status: 500 });
  }
}
