'use client'
import { useEffect, useState, useRef } from 'react'
import { Terminal, RefreshCw, Filter, Database, Radio, Cpu, AlertCircle } from 'lucide-react'

interface LogEntry {
  type: string; level: string; source: string
  message: string; timestamp: string; from?: string; hash?: string
}

const TYPE_COLORS: Record<string, string> = {
  memory: '#9C27B0', mesh: '#2979FF', broadcast: '#FF1D6C',
  error: '#ef4444', info: '#22c55e', warn: '#F5A623',
}
const TYPE_ICONS: Record<string, any> = {
  memory: Database, mesh: Cpu, broadcast: Radio, error: AlertCircle,
}

function timeStr(iso: string) {
  try { return new Date(iso).toLocaleTimeString() } catch { return iso }
}

export default function LogsPage() {
  const [logs, setLogs] = useState<LogEntry[]>([])
  const [loading, setLoading] = useState(true)
  const [filter, setFilter] = useState('all')
  const [autoRefresh, setAutoRefresh] = useState(true)
  const [refreshing, setRefreshing] = useState(false)
  const bottomRef = useRef<HTMLDivElement>(null)

  const load = async () => {
    setRefreshing(true)
    try {
      const r = await fetch(`/api/logs?filter=${filter}`)
      const d = await r.json()
      setLogs(d.logs || [])
    } finally { setRefreshing(false); setLoading(false) }
  }

  useEffect(() => { load() }, [filter])
  useEffect(() => {
    if (!autoRefresh) return
    const t = setInterval(load, 10000)
    return () => clearInterval(t)
  }, [autoRefresh, filter])

  return (
    <div style={{ padding: 32, maxWidth: 1000, height: 'calc(100vh - 40px)', display: 'flex', flexDirection: 'column' }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 20, flexShrink: 0 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
          <Terminal size={28} style={{ color: '#22c55e' }} />
          <div>
            <h1 style={{ fontSize: 24, fontWeight: 700, color: '#fff', margin: 0 }}>Activity Log</h1>
            <p style={{ color: 'rgba(255,255,255,0.4)', fontSize: 13, margin: 0 }}>
              {logs.length} entries · memory · mesh · agents {autoRefresh && '· auto-refresh 10s'}
            </p>
          </div>
        </div>
        <div style={{ display: 'flex', gap: 8 }}>
          <button
            onClick={() => setAutoRefresh(a => !a)}
            style={{ padding: '7px 12px', background: autoRefresh ? 'rgba(34,197,94,0.15)' : 'rgba(255,255,255,0.05)', border: `1px solid ${autoRefresh ? 'rgba(34,197,94,0.4)' : 'rgba(255,255,255,0.1)'}`, borderRadius: 8, color: autoRefresh ? '#22c55e' : '#aaa', fontSize: 12, cursor: 'pointer' }}
          >
            {autoRefresh ? '● Live' : '○ Paused'}
          </button>
          <button onClick={load} disabled={refreshing} style={{ display: 'flex', alignItems: 'center', gap: 6, padding: '7px 12px', background: 'rgba(255,255,255,0.05)', border: '1px solid rgba(255,255,255,0.1)', borderRadius: 8, color: '#aaa', fontSize: 12, cursor: 'pointer' }}>
            <RefreshCw size={12} style={{ animation: refreshing ? 'spin 1s linear infinite' : 'none' }} />Refresh
          </button>
        </div>
      </div>

      {/* Filter bar */}
      <div style={{ display: 'flex', gap: 8, marginBottom: 16, flexShrink: 0 }}>
        {[
          { key: 'all', label: 'All', icon: Filter },
          { key: 'memory', label: 'Memory', icon: Database },
          { key: 'mesh', label: 'Mesh', icon: Cpu },
          { key: 'broadcast', label: 'Broadcast', icon: Radio },
        ].map(({ key, label, icon: Icon }) => (
          <button key={key} onClick={() => setFilter(key)} style={{
            display: 'flex', alignItems: 'center', gap: 6, padding: '5px 12px',
            background: filter === key ? `${TYPE_COLORS[key] || '#FF1D6C'}22` : 'rgba(255,255,255,0.04)',
            border: `1px solid ${filter === key ? (TYPE_COLORS[key] || '#FF1D6C') : 'rgba(255,255,255,0.08)'}`,
            borderRadius: 20, color: filter === key ? (TYPE_COLORS[key] || '#FF1D6C') : '#888',
            fontSize: 12, cursor: 'pointer',
          }}>
            <Icon size={11} />{label}
          </button>
        ))}
      </div>

      {/* Log stream */}
      <div style={{ flex: 1, overflowY: 'auto', background: 'rgba(0,0,0,0.4)', border: '1px solid rgba(255,255,255,0.07)', borderRadius: 12, fontFamily: 'monospace', fontSize: 12 }}>
        {loading ? (
          <div style={{ padding: 40, color: 'rgba(255,255,255,0.3)', textAlign: 'center' }}>Loading…</div>
        ) : logs.length === 0 ? (
          <div style={{ padding: 40, color: 'rgba(255,255,255,0.2)', textAlign: 'center' }}>No log entries found</div>
        ) : logs.map((log, i) => {
          const color = TYPE_COLORS[log.type] || '#888'
          const Icon = TYPE_ICONS[log.type] || Terminal
          return (
            <div key={i} style={{
              display: 'flex', alignItems: 'flex-start', gap: 10, padding: '7px 14px',
              borderBottom: i < logs.length - 1 ? '1px solid rgba(255,255,255,0.04)' : 'none',
              transition: 'background .1s',
            }}>
              <span style={{ color: 'rgba(255,255,255,0.25)', minWidth: 70, flexShrink: 0 }}>{timeStr(log.timestamp)}</span>
              <span style={{ display: 'inline-flex', alignItems: 'center', gap: 3, fontSize: 10, fontWeight: 700, minWidth: 70, color, background: `${color}15`, padding: '1px 6px', borderRadius: 4, flexShrink: 0 }}>
                <Icon size={9} />{log.type}
              </span>
              <span style={{ color: 'rgba(255,255,255,0.35)', minWidth: 120, flexShrink: 0 }}>{log.source}</span>
              <span style={{ color: 'rgba(255,255,255,0.8)', flex: 1, wordBreak: 'break-word' }}>{log.message}</span>
              {log.hash && <span style={{ color: 'rgba(255,255,255,0.2)', fontSize: 10 }}>#{log.hash}</span>}
            </div>
          )
        })}
        <div ref={bottomRef} />
      </div>
    </div>
  )
}
