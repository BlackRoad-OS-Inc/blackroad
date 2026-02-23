'use client'
import { useEffect, useState } from 'react'
import { GitBranch, Play, RefreshCw, CheckCircle, XCircle, Clock, AlertCircle, ChevronRight, FileText } from 'lucide-react'

interface Workflow { file: string; name: string; on: string; size: number; modifiedAt: string; content?: string }
interface Run { name: string; status: string; conclusion: string; startedAt: string; updatedAt: string; url: string; displayTitle: string }

const STATUS_ICON = (status: string, conclusion: string) => {
  if (status === 'completed') {
    if (conclusion === 'success') return <CheckCircle size={14} style={{ color: '#22c55e' }} />
    if (conclusion === 'failure') return <XCircle size={14} style={{ color: '#ef4444' }} />
    return <AlertCircle size={14} style={{ color: '#F5A623' }} />
  }
  return <Clock size={14} style={{ color: '#2979FF', animation: 'spin 2s linear infinite' }} />
}

function timeAgo(iso?: string) {
  if (!iso) return '—'
  try {
    const diff = Date.now() - new Date(iso).getTime()
    const m = Math.floor(diff / 60000), h = Math.floor(m / 60), d = Math.floor(h / 24)
    if (d > 0) return `${d}d ago`; if (h > 0) return `${h}h ago`; if (m > 0) return `${m}m ago`; return 'just now'
  } catch { return '—' }
}

export default function PipelinePage() {
  const [workflows, setWorkflows] = useState<Workflow[]>([])
  const [runs, setRuns] = useState<Run[]>([])
  const [loading, setLoading] = useState(true)
  const [loadingRuns, setLoadingRuns] = useState(false)
  const [triggering, setTriggering] = useState<string | null>(null)
  const [triggerOut, setTriggerOut] = useState<string>('')
  const [selectedWf, setSelectedWf] = useState<Workflow | null>(null)
  const [tab, setTab] = useState<'workflows' | 'runs'>('workflows')

  useEffect(() => {
    fetch('/api/pipeline').then(r => r.json()).then(d => { setWorkflows(d.workflows || []); setLoading(false) }).catch(() => setLoading(false))
  }, [])

  const loadRuns = () => {
    setLoadingRuns(true)
    fetch('/api/pipeline?action=runs').then(r => r.json()).then(d => { setRuns(d.runs || []); setLoadingRuns(false) })
  }
  useEffect(() => { if (tab === 'runs') loadRuns() }, [tab])

  const trigger = async (wf: Workflow) => {
    setTriggering(wf.file)
    const r = await fetch('/api/pipeline', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ action: 'trigger', workflow: wf.file }) })
    const d = await r.json()
    setTriggerOut(d.output || '')
    setTriggering(null)
    setTimeout(() => setTriggerOut(''), 5000)
  }

  return (
    <div style={{ padding: 32, maxWidth: 1000 }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 28 }}>
        <GitBranch size={28} style={{ color: '#22c55e' }} />
        <div>
          <h1 style={{ fontSize: 24, fontWeight: 700, color: '#fff', margin: 0 }}>CI/CD Pipeline</h1>
          <p style={{ color: 'rgba(255,255,255,0.4)', fontSize: 13, margin: 0 }}>{workflows.length} workflows · GitHub Actions</p>
        </div>
      </div>

      <div style={{ display: 'flex', gap: 8, marginBottom: 20 }}>
        {([['workflows', 'Workflows'], ['runs', 'Recent Runs']] as const).map(([key, label]) => (
          <button key={key} onClick={() => setTab(key)} style={{
            padding: '7px 16px', borderRadius: 20, fontSize: 13, cursor: 'pointer', border: 'none',
            background: tab === key ? 'rgba(34,197,94,0.15)' : 'rgba(255,255,255,0.05)',
            color: tab === key ? '#22c55e' : '#888',
            outline: tab === key ? '1px solid #22c55e' : '1px solid transparent',
          }}>{label}</button>
        ))}
      </div>

      {triggerOut && (
        <div style={{ padding: '10px 16px', background: 'rgba(34,197,94,0.08)', border: '1px solid rgba(34,197,94,0.2)', borderRadius: 8, marginBottom: 16, fontFamily: 'monospace', fontSize: 12, color: '#22c55e' }}>{triggerOut}</div>
      )}

      {tab === 'workflows' && (
        <div style={{ display: 'grid', gridTemplateColumns: selectedWf ? '1fr 1fr' : '1fr', gap: 12 }}>
          <div>
            {loading ? <div style={{ color: 'rgba(255,255,255,0.3)', textAlign: 'center', padding: 40 }}>Loading…</div>
              : workflows.map(wf => (
                <div key={wf.file} onClick={() => setSelectedWf(s => s?.file === wf.file ? null : wf)} style={{
                  display: 'flex', alignItems: 'center', gap: 12, padding: '12px 16px', marginBottom: 6,
                  background: selectedWf?.file === wf.file ? 'rgba(34,197,94,0.08)' : 'rgba(255,255,255,0.03)',
                  border: `1px solid ${selectedWf?.file === wf.file ? 'rgba(34,197,94,0.3)' : 'rgba(255,255,255,0.07)'}`,
                  borderRadius: 10, cursor: 'pointer',
                }}>
                  <GitBranch size={14} style={{ color: '#22c55e', flexShrink: 0 }} />
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ color: '#fff', fontSize: 13, fontWeight: 600 }}>{wf.name}</div>
                    <div style={{ color: 'rgba(255,255,255,0.3)', fontSize: 11 }}>{wf.file} · {wf.on}</div>
                  </div>
                  <button onClick={e => { e.stopPropagation(); trigger(wf) }} disabled={triggering === wf.file} style={{ display: 'flex', alignItems: 'center', gap: 4, padding: '5px 10px', background: 'rgba(34,197,94,0.12)', border: '1px solid rgba(34,197,94,0.25)', borderRadius: 7, color: '#22c55e', fontSize: 11, cursor: 'pointer' }}>
                    <Play size={10} />{triggering === wf.file ? 'Running…' : 'Run'}
                  </button>
                </div>
              ))}
          </div>
          {selectedWf && (
            <div style={{ background: 'rgba(255,255,255,0.03)', border: '1px solid rgba(255,255,255,0.07)', borderRadius: 12, overflow: 'hidden' }}>
              <div style={{ padding: '10px 14px', borderBottom: '1px solid rgba(255,255,255,0.06)', display: 'flex', alignItems: 'center', gap: 8 }}>
                <FileText size={13} style={{ color: '#22c55e' }} />
                <span style={{ color: '#fff', fontSize: 13, fontWeight: 600 }}>{selectedWf.file}</span>
              </div>
              <pre style={{ color: 'rgba(255,255,255,0.5)', fontSize: 11, fontFamily: 'monospace', padding: 14, margin: 0, overflowX: 'auto', maxHeight: 500, whiteSpace: 'pre-wrap', wordBreak: 'break-word' }}>{selectedWf.content}</pre>
            </div>
          )}
        </div>
      )}

      {tab === 'runs' && (
        <div>
          <div style={{ display: 'flex', justifyContent: 'flex-end', marginBottom: 10 }}>
            <button onClick={loadRuns} style={{ display: 'flex', alignItems: 'center', gap: 4, padding: '6px 12px', background: 'rgba(255,255,255,0.05)', border: '1px solid rgba(255,255,255,0.1)', borderRadius: 8, color: '#aaa', fontSize: 12, cursor: 'pointer' }}>
              <RefreshCw size={11} />{loadingRuns ? 'Loading…' : 'Refresh'}
            </button>
          </div>
          {runs.length === 0 ? (
            <div style={{ textAlign: 'center', padding: 40, color: 'rgba(255,255,255,0.25)' }}>No runs found — requires <code style={{ fontFamily: 'monospace', color: '#F5A623' }}>gh</code> CLI authenticated</div>
          ) : runs.map((run, i) => (
            <a key={i} href={run.url} target="_blank" rel="noopener" style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '11px 16px', marginBottom: 5, background: 'rgba(255,255,255,0.03)', border: '1px solid rgba(255,255,255,0.07)', borderRadius: 10, textDecoration: 'none' }}>
              {STATUS_ICON(run.status, run.conclusion)}
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ color: '#fff', fontSize: 13, fontWeight: 500 }}>{run.displayTitle || run.name}</div>
                <div style={{ color: 'rgba(255,255,255,0.3)', fontSize: 11 }}>{run.name}</div>
              </div>
              <span style={{ color: 'rgba(255,255,255,0.25)', fontSize: 11 }}>{timeAgo(run.updatedAt)}</span>
              <ChevronRight size={12} style={{ color: 'rgba(255,255,255,0.2)' }} />
            </a>
          ))}
        </div>
      )}
    </div>
  )
}
