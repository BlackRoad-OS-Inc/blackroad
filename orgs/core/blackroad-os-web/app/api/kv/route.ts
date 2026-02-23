import { NextResponse } from 'next/server'

export const runtime = 'nodejs'
export const dynamic = 'force-dynamic'

const CF_ACCOUNT = process.env.CLOUDFLARE_ACCOUNT_ID || '848cf0b18d51e0170e0d1537aec3505a'

async function cfGet(path: string, token: string) {
  const r = await fetch(`https://api.cloudflare.com/client/v4${path}`, {
    headers: { Authorization: `Bearer ${token}` },
    signal: AbortSignal.timeout(5000),
  })
  return r.json()
}

async function cfPut(path: string, token: string, body: string) {
  const r = await fetch(`https://api.cloudflare.com/client/v4${path}`, {
    method: 'PUT',
    headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'text/plain' },
    body,
    signal: AbortSignal.timeout(5000),
  })
  return r.json()
}

export async function GET(req: Request) {
  const token = process.env.CLOUDFLARE_API_TOKEN || ''
  const url = new URL(req.url)
  const nsId = url.searchParams.get('ns')
  const key = url.searchParams.get('key')

  if (!token) {
    return NextResponse.json({ error: 'No CLOUDFLARE_API_TOKEN', namespaces: [], live: false })
  }

  // Get specific key value
  if (nsId && key) {
    try {
      const r = await fetch(
        `https://api.cloudflare.com/client/v4/accounts/${CF_ACCOUNT}/storage/kv/namespaces/${nsId}/values/${encodeURIComponent(key)}`,
        { headers: { Authorization: `Bearer ${token}` }, signal: AbortSignal.timeout(4000) }
      )
      const text = await r.text()
      return NextResponse.json({ key, value: text, namespace: nsId })
    } catch (e: any) { return NextResponse.json({ error: e.message }) }
  }

  // List keys in namespace
  if (nsId) {
    try {
      const d = await cfGet(`/accounts/${CF_ACCOUNT}/storage/kv/namespaces/${nsId}/keys?limit=100`, token)
      return NextResponse.json({ keys: d.result || [], namespace: nsId, total: d.result?.length || 0 })
    } catch (e: any) { return NextResponse.json({ error: e.message, keys: [] }) }
  }

  // List namespaces
  try {
    const d = await cfGet(`/accounts/${CF_ACCOUNT}/storage/kv/namespaces?per_page=100`, token)
    return NextResponse.json({
      namespaces: (d.result || []).map((ns: any) => ({
        id: ns.id, title: ns.title,
      })),
      total: d.result?.length || 0,
      live: true,
    })
  } catch (e: any) {
    return NextResponse.json({ error: e.message, namespaces: [], live: false })
  }
}

export async function POST(req: Request) {
  const token = process.env.CLOUDFLARE_API_TOKEN || ''
  if (!token) return NextResponse.json({ error: 'No token' }, { status: 401 })

  const { nsId, key, value } = await req.json()
  if (!nsId || !key || value === undefined) {
    return NextResponse.json({ error: 'nsId, key, value required' }, { status: 400 })
  }

  try {
    const d = await cfPut(
      `/accounts/${CF_ACCOUNT}/storage/kv/namespaces/${nsId}/values/${encodeURIComponent(key)}`,
      token, String(value)
    )
    return NextResponse.json({ ok: d.success, result: d.result })
  } catch (e: any) {
    return NextResponse.json({ error: e.message }, { status: 500 })
  }
}
