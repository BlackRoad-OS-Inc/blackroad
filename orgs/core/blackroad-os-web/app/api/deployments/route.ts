import { NextResponse } from 'next/server'

export const runtime = 'nodejs'
export const dynamic = 'force-dynamic'

const CF_ACCOUNT = process.env.CLOUDFLARE_ACCOUNT_ID || '848cf0b18d51e0170e0d1537aec3505a'

async function getVercelDeployments(token: string) {
  if (!token) return []
  try {
    const r = await fetch('https://api.vercel.com/v6/deployments?limit=10', {
      headers: { Authorization: `Bearer ${token}` },
      signal: AbortSignal.timeout(4000),
    })
    const d = await r.json()
    return (d.deployments || []).slice(0, 10).map((dep: any) => ({
      id: dep.uid,
      platform: 'vercel',
      project: dep.name,
      url: `https://${dep.url}`,
      state: dep.state?.toLowerCase() || 'unknown',
      branch: dep.meta?.githubCommitRef || 'main',
      commit: dep.meta?.githubCommitMessage?.slice(0, 60) || '',
      createdAt: dep.createdAt,
      triggeredBy: dep.creator?.username || 'alexa',
    }))
  } catch { return [] }
}

async function getCFWorkerVersions(token: string) {
  if (!token) return []
  try {
    const r = await fetch(
      `https://api.cloudflare.com/client/v4/accounts/${CF_ACCOUNT}/workers/scripts`,
      { headers: { Authorization: `Bearer ${token}` }, signal: AbortSignal.timeout(4000) }
    )
    const d = await r.json()
    if (!d.result) return []
    return d.result.slice(0, 10).map((w: any) => ({
      id: w.id,
      platform: 'cloudflare',
      project: w.id,
      url: `https://${w.id}.blackroad.workers.dev`,
      state: 'active',
      branch: 'main',
      commit: `Worker ${w.id}`,
      createdAt: w.created_on,
      triggeredBy: 'wrangler',
    }))
  } catch { return [] }
}

// Static Railway projects (no token available)
function getRailwayDeployments() {
  return [
    { id: 'rail-1', platform: 'railway', project: 'RoadWork Production', url: 'https://railway.app/project/9d3d2549', state: 'active', branch: 'main', commit: 'Latest', createdAt: new Date().toISOString(), triggeredBy: 'git' },
    { id: 'rail-2', platform: 'railway', project: 'BlackRoad Core Services', url: 'https://railway.app/project/aa968fb7', state: 'active', branch: 'main', commit: 'Latest', createdAt: new Date().toISOString(), triggeredBy: 'git' },
    { id: 'rail-3', platform: 'railway', project: 'Prism Console', url: 'https://railway.app/project/47f557cf', state: 'active', branch: 'main', commit: 'Latest', createdAt: new Date().toISOString(), triggeredBy: 'git' },
  ]
}

export async function GET() {
  const cfToken = process.env.CLOUDFLARE_API_TOKEN || ''
  const vercelToken = process.env.VERCEL_TOKEN || ''

  const [vercel, cfWorkers] = await Promise.all([
    getVercelDeployments(vercelToken),
    getCFWorkerVersions(cfToken),
  ])
  const railway = getRailwayDeployments()

  const all = [...vercel, ...railway, ...cfWorkers]
    .sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime())

  return NextResponse.json({
    deployments: all,
    counts: {
      vercel: vercel.length,
      railway: railway.length,
      cloudflare: cfWorkers.length,
      total: all.length,
    },
    timestamp: new Date().toISOString(),
  })
}
