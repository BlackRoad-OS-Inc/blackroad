'use client'
import { useEffect, useState } from 'react'
import { Brain, Search, ChevronLeft, ChevronRight, Hash, Clock, Tag, FileText } from 'lucide-react'

interface MemEntry {
  hash?: string; parent?: string; action?: string; entity?: string
  details?: string; timestamp?: string; lineNumber: number; parse_error?: boolean; raw?: string
}

const ACTION_COLORS: Record<string, string> = {
  'code-change': '#2979FF', 'session-start': '#22c55e', 'session-end': '#888',
  'file-create': '#F5A623', 'commit': '#9C27B0', 'deploy': '#FF1D6C',
  'memory-sync': '#06b6d4', 'agent-dm': '#2979FF', 'broadcast': '#FF1D6C',
}

function timeAgo(iso?: string) {
  if (!iso) return '—'
  try {
    const diff = Date.now() - new Date(iso).getTime()
    const m = Math.floor(diff / 60000), h = Math.floor(m / 60), d = Math.floor(h / 24)
    if (d > 0) return `${d}d ago`; if (h > 0) return `${h}h ago`; if (m > 0) return `${m}m ago`; return 'just now'
  } catch { return iso }
}

export default function MemoryPage() {
  const [data, setData] = useState<{ entries: MemEntry[]; total: number; page: number; pages: number; ledgerPath: string } | null>(null)
  const [search, setSearch] = useState('')
  const [page, setPage] = useState(1)
  const [loading, setLoading] = useState(true)
  const [view, setView] = useState<'ledger' | 'files'>('ledger')
  const [files, setFiles] = useState<any[]>([])

  const load = async () => {
    setLoading(true)
    try {
      const r = await fetch(`/api/memory?view=${view}&search=${encodeURIComponent(search)}&page=${page}`)
      const d = await r.json()
      if (view === 'files') setFiles(d.files || [])
      else setData(d)
    } finally { setLoading(false) }
  }

  useEffect(() => { load() }, [view, page])
  const handleSearch = (e: React.FormEvent) => { e.preventDefault(); setPage(1); load() }

  return (
    <div style={{ padding: 32, maxWidth: 1000 }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 28 }}>
        <Brain size={28} style={{ color: '#9C27B0' }} />
        <div>
          <h1 style={{ fontSize: 24, fontWeight: 700, color: '#fff', margin: 0 }}>Memory Ledger</h1>
          <p style={{ color: 'rgba(255,255,255,0.4)', fontSize: 13, margin: 0 }}>
            PS-SHA∞ hash-chain · {data?.total ?? 0} entries · {data?.ledgerPath?.replace('/Users/alexa', '~')}
          </p>
        </div>
      </div>

      {/* View tabs */}
      <div style={{ display: 'flex', gap: 8, marginBottom: 16 }}>
        {[{ key: 'ledger', label: 'Journal Entries', icon: Hash }, { key: 'files', label: 'Context Files', icon: FileText }].map(({ key, label, icon: Icon }) => (
          <button key={key} onClick={() => { setView(key as any); setPage(1) }} style={{
            display: 'flex', alignItems: 'center', gap: 6, padding: '7px 14px',
            background: view === key ? 'rgba(156,39,176,0.15)' : 'rgba(255,255,255,0.04)',
            border: `1px solid ${view === key ? '#9C27B0' : 'rgba(255,255,255,0.08)'}`,
            borderRadius: 20, color: view === key ? '#9C27B0' : '#888', fontSize: 13, cursor: 'pointer',
          }}>
            <Icon size={12} />{label}
          </button>
        ))}
      </div>

      {view === 'ledger' && (
        <>
          <form onSubmit={handleSearch} style={{ display: 'flex', gap: 8, marginBottom: 16 }}>
            <div style={{ flex: 1, position: 'relative' }}>
              <Search size={14} style={{ position: 'absolute', left: 12, top: '50%', transform: 'translateY(-50%)', color: 'rgba(255,255,255,0.3)' }} />
              <input
                value={search} onChange={e => setSearch(e.target.value)}
                placeholder="Search memory entries…"
                style={{ width: '100%', background: 'rgba(255,255,255,0.06)', border: '1px solid rgba(255,255,255,0.1)', borderRadius: 8, padding: '9px 12px 9px 34px', color: '#fff', fontSize: 13, outline: 'none', boxSizing: 'border-box' }}
              />
            </div>
            <button type="submit" style={{ padding: '9px 18px', background: '#9C27B0', border: 'none', borderRadius: 8, color: '#fff', fontSize: 13, cursor: 'pointer' }}>Search</button>
          </form>

          {loading ? (
            <div style={{ color: 'rgba(255,255,255,0.3)', textAlign: 'center', padding: 40 }}>Loading…</div>
          ) : (
            <>
              <div style={{ display: 'flex', flexDirection: 'column', gap: 6, marginBottom: 16 }}>
                {(data?.entries || []).map((entry, i) => {
                  if (entry.parse_error) return (
                    <div key={i} style={{ padding: '8px 14px', background: 'rgba(239,68,68,0.05)', border: '1px solid rgba(239,68,68,0.15)', borderRadius: 8, fontFamily: 'monospace', fontSize: 11, color: '#ef4444' }}>
                      Parse error: {entry.raw}
                    </div>
                  )
                  const color = ACTION_COLORS[entry.action || ''] || '#888'
                  return (
                    <div key={i} style={{ display: 'flex', alignItems: 'flex-start', gap: 12, padding: '12px 16px', background: 'rgba(255,255,255,0.03)', border: '1px solid rgba(255,255,255,0.06)', borderRadius: 10 }}>
                      <div style={{ flexShrink: 0, paddingTop: 2 }}>
                        <div style={{ fontSize: 10, fontWeight: 700, padding: '2px 7px', borderRadius: 4, background: `${color}22`, color, minWidth: 80, textAlign: 'center' }}>
                          {entry.action || 'entry'}
                        </div>
                      </div>
                      <div style={{ flex: 1, minWidth: 0 }}>
                        {entry.entity && <div style={{ color: '#fff', fontSize: 13, fontWeight: 600, marginBottom: 2 }}>{entry.entity}</div>}
                        {entry.details && <div style={{ color: 'rgba(255,255,255,0.5)', fontSize: 12 }}>{entry.details}</div>}
                        <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginTop: 6 }}>
                          {entry.hash && (
                            <span style={{ display: 'flex', alignItems: 'center', gap: 4, color: 'rgba(255,255,255,0.2)', fontSize: 10, fontFamily: 'monospace' }}>
                              <Hash size={9} />#{entry.hash.slice(0, 8)}
                            </span>
                          )}
                          {entry.timestamp && (
                            <span style={{ display: 'flex', alignItems: 'center', gap: 4, color: 'rgba(255,255,255,0.25)', fontSize: 11 }}>
                              <Clock size={9} />{timeAgo(entry.timestamp)}
                            </span>
                          )}
                          <span style={{ color: 'rgba(255,255,255,0.15)', fontSize: 10 }}>#{entry.lineNumber}</span>
                        </div>
                      </div>
                    </div>
                  )
                })}
              </div>

              {/* Pagination */}
              {(data?.pages || 1) > 1 && (
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 12 }}>
                  <button onClick={() => setPage(p => Math.max(1, p - 1))} disabled={page === 1} style={{ display: 'flex', alignItems: 'center', gap: 4, padding: '6px 12px', background: 'rgba(255,255,255,0.05)', border: '1px solid rgba(255,255,255,0.1)', borderRadius: 8, color: page === 1 ? '#555' : '#aaa', cursor: page === 1 ? 'not-allowed' : 'pointer', fontSize: 13 }}>
                    <ChevronLeft size={14} />Prev
                  </button>
                  <span style={{ color: 'rgba(255,255,255,0.4)', fontSize: 13 }}>Page {data?.page} of {data?.pages}</span>
                  <button onClick={() => setPage(p => Math.min(data?.pages || 1, p + 1))} disabled={page === (data?.pages || 1)} style={{ display: 'flex', alignItems: 'center', gap: 4, padding: '6px 12px', background: 'rgba(255,255,255,0.05)', border: '1px solid rgba(255,255,255,0.1)', borderRadius: 8, color: page === (data?.pages || 1) ? '#555' : '#aaa', cursor: page === (data?.pages || 1) ? 'not-allowed' : 'pointer', fontSize: 13 }}>
                    Next<ChevronRight size={14} />
                  </button>
                </div>
              )}
            </>
          )}
        </>
      )}

      {view === 'files' && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
          {loading ? <div style={{ color: 'rgba(255,255,255,0.3)', textAlign: 'center', padding: 40 }}>Loading…</div>
            : files.map((f, i) => (
              <div key={i} style={{ background: 'rgba(255,255,255,0.03)', border: '1px solid rgba(255,255,255,0.07)', borderRadius: 10, padding: 16 }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 10 }}>
                  <FileText size={14} style={{ color: '#9C27B0' }} />
                  <span style={{ color: '#fff', fontWeight: 600, fontSize: 13, fontFamily: 'monospace' }}>~/.blackroad/memory/{f.path}</span>
                  <span style={{ color: 'rgba(255,255,255,0.3)', fontSize: 11, marginLeft: 'auto' }}>{(f.size / 1024).toFixed(1)}KB · {timeAgo(f.modifiedAt)}</span>
                </div>
                <pre style={{ color: 'rgba(255,255,255,0.45)', fontSize: 11, fontFamily: 'monospace', margin: 0, whiteSpace: 'pre-wrap', wordBreak: 'break-word', maxHeight: 120, overflow: 'hidden' }}>
                  {f.preview}
                </pre>
              </div>
            ))}
        </div>
      )}
    </div>
  )
}
