'use client'
import { useEffect, useState } from 'react'
import { Rocket, RefreshCw, ExternalLink, CheckCircle, Clock, AlertCircle, Cloud, Zap, Train } from 'lucide-react'

interface Deployment {
  id: string; platform: 'vercel' | 'cloudflare' | 'railway'
  project: string; url: string; state: string
  branch: string; commit: string; createdAt: string; triggeredBy: string
}

const PLATFORM_COLORS: Record<string, string> = {
  vercel: '#fff',
  cloudflare: '#F5A623',
  railway: '#9C27B0',
}
const PLATFORM_ICONS: Record<string, any> = { vercel: Cloud, cloudflare: Zap, railway: Train }

const STATE_COLORS: Record<string, string> = {
  ready: '#22c55e', active: '#22c55e', succeeded: '#22c55e',
  building: '#F5A623', queued: '#2979FF',
  error: '#ef4444', failed: '#ef4444', cancelled: '#888',
}
const STATE_ICONS: Record<string, any> = {
  ready: CheckCircle, active: CheckCircle, succeeded: CheckCircle,
  building: Clock, queued: Clock, error: AlertCircle, failed: AlertCircle,
}

function timeAgo(iso: string) {
  const diff = Date.now() - new Date(iso).getTime()
  const m = Math.floor(diff / 60000), h = Math.floor(m / 60), d = Math.floor(h / 24)
  if (d > 0) return `${d}d ago`
  if (h > 0) return `${h}h ago`
  if (m > 0) return `${m}m ago`
  return 'just now'
}

export default function DeploymentsPage() {
  const [data, setData] = useState<{ deployments: Deployment[]; counts: any } | null>(null)
  const [loading, setLoading] = useState(true)
  const [filter, setFilter] = useState<string>('all')
  const [refreshing, setRefreshing] = useState(false)

  const load = async () => {
    setRefreshing(true)
    try {
      const r = await fetch('/api/deployments')
      setData(await r.json())
    } finally { setRefreshing(false); setLoading(false) }
  }

  useEffect(() => { load() }, [])

  const deployments = (data?.deployments || []).filter(d => filter === 'all' || d.platform === filter)

  return (
    <div style={{ padding: 32, maxWidth: 1100 }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 28 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
          <Rocket size={28} style={{ color: '#FF1D6C' }} />
          <div>
            <h1 style={{ fontSize: 24, fontWeight: 700, color: '#fff', margin: 0 }}>Deployments</h1>
            <p style={{ color: 'rgba(255,255,255,0.4)', fontSize: 13, margin: 0 }}>
              Vercel · Railway · Cloudflare
            </p>
          </div>
        </div>
        <button onClick={load} disabled={refreshing} style={{ display: 'flex', alignItems: 'center', gap: 6, padding: '8px 14px', background: 'rgba(255,255,255,0.05)', border: '1px solid rgba(255,255,255,0.1)', borderRadius: 8, color: '#aaa', fontSize: 13, cursor: 'pointer' }}>
          <RefreshCw size={13} style={{ animation: refreshing ? 'spin 1s linear infinite' : 'none' }} />Refresh
        </button>
      </div>

      {/* Platform counts */}
      <div style={{ display: 'flex', gap: 10, marginBottom: 20, flexWrap: 'wrap' }}>
        {['all', 'vercel', 'cloudflare', 'railway'].map(p => {
          const count = p === 'all' ? data?.counts?.total : data?.counts?.[p]
          const PlatIcon = p !== 'all' ? PLATFORM_ICONS[p] : Rocket
          return (
            <button key={p} onClick={() => setFilter(p)} style={{
              display: 'flex', alignItems: 'center', gap: 6, padding: '6px 14px',
              background: filter === p ? 'rgba(255,29,108,0.15)' : 'rgba(255,255,255,0.04)',
              border: `1px solid ${filter === p ? '#FF1D6C' : 'rgba(255,255,255,0.08)'}`,
              borderRadius: 20, color: filter === p ? '#FF1D6C' : '#aaa', fontSize: 13, cursor: 'pointer',
            }}>
              <PlatIcon size={12} />
              {p.charAt(0).toUpperCase() + p.slice(1)}
              {count != null && <span style={{ opacity: 0.6 }}>({count})</span>}
            </button>
          )
        })}
      </div>

      {loading ? (
        <div style={{ color: 'rgba(255,255,255,0.3)', padding: 40, textAlign: 'center' }}>Loading deployments…</div>
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
          {deployments.map(dep => {
            const PlatIcon = PLATFORM_ICONS[dep.platform] || Cloud
            const StateIcon = STATE_ICONS[dep.state] || CheckCircle
            const stateColor = STATE_COLORS[dep.state] || '#888'
            const platColor = PLATFORM_COLORS[dep.platform] || '#aaa'
            return (
              <div key={dep.id} style={{ display: 'flex', alignItems: 'center', gap: 14, padding: '14px 18px', background: 'rgba(255,255,255,0.04)', border: '1px solid rgba(255,255,255,0.07)', borderRadius: 10 }}>
                <PlatIcon size={16} style={{ color: platColor, flexShrink: 0 }} />
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                    <span style={{ color: '#fff', fontWeight: 600, fontSize: 14 }}>{dep.project}</span>
                    <span style={{ color: 'rgba(255,255,255,0.3)', fontSize: 11, fontFamily: 'monospace', background: 'rgba(255,255,255,0.05)', padding: '1px 6px', borderRadius: 4 }}>{dep.branch}</span>
                  </div>
                  <div style={{ color: 'rgba(255,255,255,0.35)', fontSize: 12, marginTop: 3, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{dep.commit}</div>
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                  <StateIcon size={13} style={{ color: stateColor }} />
                  <span style={{ color: stateColor, fontSize: 12, fontWeight: 600 }}>{dep.state}</span>
                </div>
                <div style={{ color: 'rgba(255,255,255,0.3)', fontSize: 12, minWidth: 70, textAlign: 'right' }}>{timeAgo(dep.createdAt)}</div>
                <a href={dep.url} target="_blank" rel="noreferrer" style={{ color: 'rgba(255,255,255,0.3)', display: 'flex', alignItems: 'center' }}>
                  <ExternalLink size={13} />
                </a>
              </div>
            )
          })}
          {deployments.length === 0 && (
            <div style={{ color: 'rgba(255,255,255,0.3)', textAlign: 'center', padding: 40 }}>No deployments found for this filter</div>
          )}
        </div>
      )}
    </div>
  )
}
