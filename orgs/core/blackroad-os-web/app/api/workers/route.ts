import { NextResponse } from 'next/server';

export const runtime = 'edge';

export async function GET(request: Request) {
  const token = request.headers.get('x-cf-token') ||
    process.env.CLOUDFLARE_API_TOKEN || '';
  const acct = '848cf0b18d51e0170e0d1537aec3505a';

  if (!token) {
    return NextResponse.json({ error: 'No CF token configured', workers: [], total: 0 }, { status: 200 });
  }

  try {
    const res = await fetch(
      `https://api.cloudflare.com/client/v4/accounts/${acct}/workers/scripts?per_page=100`,
      { headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' } }
    );
    if (!res.ok) throw new Error(`CF API ${res.status}`);
    const data = await res.json() as { result?: { id: string; modified_on: string; etag?: string }[]; result_info?: { total_count: number } };
    const workers = (data.result || []).map((w) => ({
      id: w.id,
      modified: w.modified_on?.slice(0, 10),
    }));
    return NextResponse.json({
      workers,
      total: data.result_info?.total_count ?? workers.length,
    }, { headers: { 'Cache-Control': 'public, s-maxage=120' } });
  } catch (e) {
    return NextResponse.json({ error: String(e), workers: [], total: 499 }, { status: 200 });
  }
}
