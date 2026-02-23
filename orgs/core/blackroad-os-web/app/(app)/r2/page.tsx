'use client'
import { useEffect, useState } from 'react'
import { HardDrive, ChevronRight, AlertCircle, Folder, File, RefreshCw } from 'lucide-react'

interface Bucket { name: string; creation_date: string; region?: string }
interface R2Object { key: string; size: number; uploaded: string; etag: string }

function fmtSize(bytes: number) {
  if (bytes >= 1e12) return (bytes / 1e12).toFixed(1) + ' TB'
  if (bytes >= 1e9) return (bytes / 1e9).toFixed(1) + ' GB'
  if (bytes >= 1e6) return (bytes / 1e6).toFixed(1) + ' MB'
  if (bytes >= 1e3) return (bytes / 1e3).toFixed(1) + ' KB'
  return bytes + ' B'
}

function timeAgo(iso?: string) {
  if (!iso) return '—'
  try {
    const diff = Date.now() - new Date(iso).getTime()
    const d = Math.floor(diff / 86400000)
    if (d > 0) return `${d}d ago`; return 'today'
  } catch { return '—' }
}

export default function R2Page() {
  const [buckets, setBuckets] = useState<Bucket[]>([])
  const [selectedBucket, setSelectedBucket] = useState<Bucket | null>(null)
  const [objects, setObjects] = useState<R2Object[]>([])
  const [live, setLive] = useState(false)
  const [loading, setLoading] = useState(true)
  const [loadingObjs, setLoadingObjs] = useState(false)
  const [prefix, setPrefix] = useState('')

  useEffect(() => {
    fetch('/api/r2').then(r => r.json()).then(d => { setBuckets(d.buckets || []); setLive(d.live); setLoading(false) }).catch(() => setLoading(false))
  }, [])

  const selectBucket = async (b: Bucket) => {
    setSelectedBucket(b); setPrefix('')
    setLoadingObjs(true)
    try {
      const r = await fetch(`/api/r2?bucket=${b.name}`)
      const d = await r.json()
      setObjects(d.objects || [])
    } finally { setLoadingObjs(false) }
  }

  const filterObjs = prefix ? objects.filter(o => o.key.startsWith(prefix)) : objects

  // Group objects by folder prefix
  const folders = [...new Set(filterObjs.map(o => o.key.includes('/') ? o.key.split('/')[0] : '').filter(Boolean))]
  const rootFiles = filterObjs.filter(o => !o.key.includes('/'))

  const totalSize = objects.reduce((s, o) => s + o.size, 0)

  return (
    <div style={{ padding: 32, maxWidth: 1000 }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 28 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
          <HardDrive size={28} style={{ color: '#2979FF' }} />
          <div>
            <h1 style={{ fontSize: 24, fontWeight: 700, color: '#fff', margin: 0 }}>R2 Storage</h1>
            <p style={{ color: 'rgba(255,255,255,0.4)', fontSize: 13, margin: 0 }}>
              {buckets.length} buckets · Cloudflare R2 {live ? '● live' : '○ mock data'}
            </p>
          </div>
        </div>
        {!live && (
          <div style={{ display: 'flex', alignItems: 'center', gap: 6, padding: '6px 14px', background: 'rgba(41,121,255,0.1)', border: '1px solid rgba(41,121,255,0.3)', borderRadius: 20, fontSize: 12, color: '#2979FF' }}>
            <AlertCircle size={12} />Set CLOUDFLARE_API_TOKEN for live data
          </div>
        )}
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '220px 1fr', gap: 14 }}>
        {/* Bucket list */}
        <div style={{ background: 'rgba(255,255,255,0.03)', border: '1px solid rgba(255,255,255,0.07)', borderRadius: 12, overflow: 'hidden' }}>
          <div style={{ padding: '10px 14px', borderBottom: '1px solid rgba(255,255,255,0.06)', fontSize: 11, color: 'rgba(255,255,255,0.3)', fontWeight: 600, textTransform: 'uppercase', letterSpacing: 1 }}>Buckets</div>
          {loading ? <div style={{ padding: 16, color: 'rgba(255,255,255,0.3)', fontSize: 12 }}>Loading…</div>
            : buckets.map(b => (
              <div key={b.name} onClick={() => selectBucket(b)} style={{
                display: 'flex', alignItems: 'center', gap: 8, padding: '10px 14px', cursor: 'pointer',
                background: selectedBucket?.name === b.name ? 'rgba(41,121,255,0.1)' : 'transparent',
                borderLeft: `3px solid ${selectedBucket?.name === b.name ? '#2979FF' : 'transparent'}`,
              }}>
                <HardDrive size={13} style={{ color: selectedBucket?.name === b.name ? '#2979FF' : 'rgba(255,255,255,0.3)' }} />
                <span style={{ color: selectedBucket?.name === b.name ? '#fff' : 'rgba(255,255,255,0.6)', fontSize: 12, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{b.name}</span>
              </div>
            ))}
        </div>

        {/* Object browser */}
        <div>
          {!selectedBucket ? (
            <div style={{ background: 'rgba(255,255,255,0.02)', border: '1px solid rgba(255,255,255,0.06)', borderRadius: 12, padding: 40, textAlign: 'center', color: 'rgba(255,255,255,0.2)' }}>
              ← Select a bucket
            </div>
          ) : (
            <div style={{ background: 'rgba(255,255,255,0.03)', border: '1px solid rgba(255,255,255,0.07)', borderRadius: 12, overflow: 'hidden' }}>
              <div style={{ padding: '10px 16px', borderBottom: '1px solid rgba(255,255,255,0.06)', display: 'flex', alignItems: 'center', gap: 10 }}>
                <HardDrive size={14} style={{ color: '#2979FF' }} />
                <span style={{ color: '#fff', fontSize: 13, fontWeight: 600 }}>{selectedBucket.name}</span>
                <span style={{ color: 'rgba(255,255,255,0.3)', fontSize: 11 }}>· {objects.length} objects · {fmtSize(totalSize)}</span>
                {loadingObjs && <RefreshCw size={12} style={{ color: '#aaa', marginLeft: 'auto', animation: 'spin 1s linear infinite' }} />}
              </div>

              {prefix && (
                <div style={{ padding: '8px 16px', borderBottom: '1px solid rgba(255,255,255,0.05)' }}>
                  <button onClick={() => setPrefix('')} style={{ display: 'flex', alignItems: 'center', gap: 4, color: '#2979FF', fontSize: 12, background: 'none', border: 'none', cursor: 'pointer', padding: 0 }}>
                    ← {selectedBucket.name}/
                  </button>
                </div>
              )}

              <div style={{ maxHeight: 500, overflowY: 'auto' }}>
                {/* Folders */}
                {!prefix && folders.map(folder => (
                  <div key={folder} onClick={() => setPrefix(folder + '/')} style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '9px 16px', cursor: 'pointer', borderBottom: '1px solid rgba(255,255,255,0.04)' }}>
                    <Folder size={13} style={{ color: '#F5A623' }} />
                    <span style={{ color: 'rgba(255,255,255,0.7)', fontSize: 12 }}>{folder}/</span>
                    <span style={{ color: 'rgba(255,255,255,0.2)', fontSize: 11, marginLeft: 'auto' }}>{objects.filter(o => o.key.startsWith(folder + '/')).length} files</span>
                    <ChevronRight size={11} style={{ color: 'rgba(255,255,255,0.2)' }} />
                  </div>
                ))}
                {/* Files */}
                {(prefix ? filterObjs : rootFiles).map(obj => {
                  const displayKey = prefix ? obj.key.slice(prefix.length) : obj.key
                  return (
                    <div key={obj.key} style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '9px 16px', borderBottom: '1px solid rgba(255,255,255,0.04)' }}>
                      <File size={13} style={{ color: 'rgba(255,255,255,0.3)' }} />
                      <span style={{ color: 'rgba(255,255,255,0.65)', fontSize: 12, flex: 1, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap', fontFamily: 'monospace' }}>{displayKey}</span>
                      <span style={{ color: '#2979FF', fontSize: 11, flexShrink: 0 }}>{fmtSize(obj.size)}</span>
                      <span style={{ color: 'rgba(255,255,255,0.2)', fontSize: 11, flexShrink: 0 }}>{timeAgo(obj.uploaded)}</span>
                    </div>
                  )
                })}
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
