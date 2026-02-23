import { NextResponse } from 'next/server'

export const runtime = 'nodejs'
export const dynamic = 'force-dynamic'

const CF_ACCOUNT = process.env.CLOUDFLARE_ACCOUNT_ID || '848cf0b18d51e0170e0d1537aec3505a'

// Known zones
const KNOWN_ZONES = [
  'blackroad.io', 'blackroad.ai', 'blackroad.network', 'blackroad.systems',
  'blackroad.me', 'blackroad.inc', 'lucidia.earth', 'lucidia.studio',
  'blackroad.quantum', 'aliceqi.com', 'blackroadai.com',
]

async function cfGet(path: string, token: string) {
  try {
    const r = await fetch(`https://api.cloudflare.com/client/v4${path}`, {
      headers: { Authorization: `Bearer ${token}` },
      signal: AbortSignal.timeout(5000),
    })
    return await r.json()
  } catch { return null }
}

export async function GET(req: Request) {
  const token = process.env.CLOUDFLARE_API_TOKEN || ''
  const url = new URL(req.url)
  const zoneId = url.searchParams.get('zone')

  if (zoneId) {
    // Return DNS records for a zone
    const data = await cfGet(`/zones/${zoneId}/dns_records?per_page=50`, token)
    if (!data?.result) return NextResponse.json({ records: [], zone: zoneId })
    return NextResponse.json({
      records: data.result.map((r: any) => ({
        id: r.id, type: r.type, name: r.name,
        content: r.content, ttl: r.ttl, proxied: r.proxied,
      })),
      total: data.result.length,
    })
  }

  // List all zones
  const data = await cfGet(`/zones?account.id=${CF_ACCOUNT}&per_page=50`, token)
  if (!data?.result) {
    // Return static fallback
    return NextResponse.json({
      zones: KNOWN_ZONES.map((name, i) => ({
        id: `zone-${i}`,
        name,
        status: 'active',
        nameservers: ['ns1.cloudflare.com', 'ns2.cloudflare.com'],
        recordCount: null,
        plan: 'free',
      })),
      total: KNOWN_ZONES.length,
      live: false,
    })
  }

  return NextResponse.json({
    zones: data.result.map((z: any) => ({
      id: z.id,
      name: z.name,
      status: z.status,
      nameservers: z.name_servers || [],
      plan: z.plan?.name || 'free',
      recordCount: null,
    })),
    total: data.result.length,
    live: true,
  })
}
