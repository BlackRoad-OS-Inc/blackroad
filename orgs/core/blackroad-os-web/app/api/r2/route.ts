import { NextResponse } from 'next/server'

export const runtime = 'nodejs'
export const dynamic = 'force-dynamic'

const CF_ACCOUNT_ID = process.env.CLOUDFLARE_ACCOUNT_ID || '848cf0b18d51e0170e0d1537aec3505a'
const CF_TOKEN = process.env.CLOUDFLARE_API_TOKEN || ''

async function cfFetch(path: string) {
  if (!CF_TOKEN) return null
  try {
    const r = await fetch(`https://api.cloudflare.com/client/v4${path}`, {
      headers: { Authorization: `Bearer ${CF_TOKEN}`, 'Content-Type': 'application/json' }
    })
    return r.ok ? r.json() : null
  } catch { return null }
}

export async function GET(req: Request) {
  const url = new URL(req.url)
  const bucketName = url.searchParams.get('bucket') || ''
  const prefix = url.searchParams.get('prefix') || ''

  if (!bucketName) {
    // List all buckets
    const data = await cfFetch(`/accounts/${CF_ACCOUNT_ID}/r2/buckets`)
    if (!data) {
      return NextResponse.json({
        buckets: [
          { name: 'blackroad-models', creation_date: '2024-01-01', region: 'auto' },
          { name: 'blackroad-assets', creation_date: '2024-01-01', region: 'auto' },
          { name: 'blackroad-backups', creation_date: '2024-01-01', region: 'auto' },
        ],
        live: false
      })
    }
    return NextResponse.json({ buckets: data.result?.buckets || [], live: true })
  }

  // List objects in bucket
  const params = new URLSearchParams()
  if (prefix) params.set('prefix', prefix)
  params.set('max-keys', '100')
  const data = await cfFetch(`/accounts/${CF_ACCOUNT_ID}/r2/buckets/${bucketName}/objects?${params}`)
  if (!data) {
    return NextResponse.json({
      objects: [
        { key: 'models/qwen2.5-72b-q4.gguf', size: 42949672960, uploaded: '2024-12-01T00:00:00Z', etag: 'abc123' },
        { key: 'models/llama3-70b-q4.gguf', size: 35433480192, uploaded: '2024-11-15T00:00:00Z', etag: 'def456' },
        { key: 'models/deepseek-r1-7b.gguf', size: 4831838208, uploaded: '2025-01-10T00:00:00Z', etag: 'ghi789' },
        { key: 'assets/brand.json', size: 2048, uploaded: '2025-01-01T00:00:00Z', etag: 'jkl012' },
        { key: 'backups/2025-01-backup.tar.gz', size: 10485760, uploaded: '2025-01-15T00:00:00Z', etag: 'mno345' },
      ],
      live: false, bucket: bucketName,
    })
  }
  return NextResponse.json({ objects: data.result?.objects || [], live: true, bucket: bucketName })
}
