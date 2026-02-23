'use client'
import { useEffect, useState } from 'react'
import { CheckSquare, Plus, Tag, Clock, User, Check, X, ChevronRight, RefreshCw } from 'lucide-react'

interface Task {
  task_id: string; title: string; description?: string; priority: string
  tags?: string; skills?: string; _status: string; posted_at?: string
  claimed_by?: string; claimed_at?: string; completed_at?: string; result?: string
}

const PRIORITY_COLORS: Record<string, string> = { high: '#ef4444', critical: '#FF1D6C', normal: '#2979FF', low: '#888' }
const STATUS_COLORS: Record<string, string> = { available: '#22c55e', claimed: '#F5A623', completed: '#9C27B0' }

function timeAgo(iso?: string) {
  if (!iso) return '—'
  try {
    const diff = Date.now() - new Date(iso).getTime()
    const m = Math.floor(diff / 60000), h = Math.floor(m / 60), d = Math.floor(h / 24)
    if (d > 0) return `${d}d ago`; if (h > 0) return `${h}h ago`; if (m > 0) return `${m}m ago`; return 'just now'
  } catch { return '—' }
}

export default function TasksPage() {
  const [tasks, setTasks] = useState<Task[]>([])
  const [counts, setCounts] = useState({ available: 0, claimed: 0, completed: 0 })
  const [filter, setFilter] = useState('all')
  const [loading, setLoading] = useState(true)
  const [adding, setAdding] = useState(false)
  const [form, setForm] = useState({ title: '', description: '', priority: 'normal', tags: '', skills: '' })
  const [saving, setSaving] = useState(false)

  const load = () => {
    setLoading(true)
    fetch(`/api/tasks?status=${filter}`).then(r => r.json()).then(d => {
      setTasks(d.tasks || [])
      setCounts(d.counts || {})
      setLoading(false)
    }).catch(() => setLoading(false))
  }
  useEffect(() => { load() }, [filter])

  const createTask = async () => {
    if (!form.title) return
    setSaving(true)
    await fetch('/api/tasks', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ action: 'create', ...form }) })
    setSaving(false); setAdding(false); setForm({ title: '', description: '', priority: 'normal', tags: '', skills: '' }); load()
  }

  const claimTask = async (id: string) => {
    await fetch('/api/tasks', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ action: 'claim', task_id: id, assigned_to: 'web-ui' }) })
    load()
  }

  const completeTask = async (id: string) => {
    const result = prompt('Result / summary:') || ''
    await fetch('/api/tasks', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ action: 'complete', task_id: id, result }) })
    load()
  }

  const tabs = ['all', 'available', 'claimed', 'completed']

  return (
    <div style={{ padding: 32, maxWidth: 900 }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 28 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
          <CheckSquare size={28} style={{ color: '#2979FF' }} />
          <div>
            <h1 style={{ fontSize: 24, fontWeight: 700, color: '#fff', margin: 0 }}>Task Marketplace</h1>
            <p style={{ color: 'rgba(255,255,255,0.4)', fontSize: 13, margin: 0 }}>
              {counts.available} available · {counts.claimed} claimed · {counts.completed} completed
            </p>
          </div>
        </div>
        <div style={{ display: 'flex', gap: 8 }}>
          <button onClick={load} style={{ padding: '7px 10px', background: 'rgba(255,255,255,0.05)', border: '1px solid rgba(255,255,255,0.1)', borderRadius: 8, color: '#aaa', cursor: 'pointer' }}>
            <RefreshCw size={13} />
          </button>
          <button onClick={() => setAdding(a => !a)} style={{ display: 'flex', alignItems: 'center', gap: 4, padding: '7px 16px', background: adding ? 'rgba(41,121,255,0.2)' : '#2979FF', border: 'none', borderRadius: 8, color: '#fff', fontSize: 13, fontWeight: 600, cursor: 'pointer' }}>
            <Plus size={14} />New Task
          </button>
        </div>
      </div>

      {/* Filter tabs */}
      <div style={{ display: 'flex', gap: 6, marginBottom: 20 }}>
        {tabs.map(t => (
          <button key={t} onClick={() => setFilter(t)} style={{
            padding: '6px 14px', borderRadius: 20, fontSize: 12, cursor: 'pointer', border: 'none',
            background: filter === t ? 'rgba(41,121,255,0.2)' : 'rgba(255,255,255,0.04)',
            color: filter === t ? '#2979FF' : '#888',
            outline: filter === t ? '1px solid #2979FF' : '1px solid transparent',
          }}>
            {t} {t !== 'all' && `(${counts[t as keyof typeof counts] || 0})`}
          </button>
        ))}
      </div>

      {/* Add form */}
      {adding && (
        <div style={{ background: 'rgba(41,121,255,0.05)', border: '1px solid rgba(41,121,255,0.25)', borderRadius: 12, padding: 20, marginBottom: 20 }}>
          <h3 style={{ color: '#fff', fontWeight: 600, fontSize: 15, marginBottom: 16, marginTop: 0 }}>Create Task</h3>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 160px', gap: 10, marginBottom: 10 }}>
            <input value={form.title} onChange={e => setForm(f => ({ ...f, title: e.target.value }))} placeholder="Task title *"
              style={{ background: 'rgba(255,255,255,0.06)', border: '1px solid rgba(255,255,255,0.1)', borderRadius: 8, padding: '9px 12px', color: '#fff', fontSize: 13, outline: 'none' }} />
            <select value={form.priority} onChange={e => setForm(f => ({ ...f, priority: e.target.value }))}
              style={{ background: 'rgba(0,0,0,0.6)', border: '1px solid rgba(255,255,255,0.1)', borderRadius: 8, padding: '9px 12px', color: '#fff', fontSize: 13, outline: 'none' }}>
              {['low', 'normal', 'high', 'critical'].map(p => <option key={p} value={p}>{p}</option>)}
            </select>
          </div>
          <textarea value={form.description} onChange={e => setForm(f => ({ ...f, description: e.target.value }))} rows={2} placeholder="Description…"
            style={{ width: '100%', background: 'rgba(255,255,255,0.06)', border: '1px solid rgba(255,255,255,0.1)', borderRadius: 8, padding: '9px 12px', color: '#fff', fontSize: 13, outline: 'none', resize: 'vertical', marginBottom: 10, boxSizing: 'border-box' }} />
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10, marginBottom: 14 }}>
            <input value={form.tags} onChange={e => setForm(f => ({ ...f, tags: e.target.value }))} placeholder="Tags (comma-sep)"
              style={{ background: 'rgba(255,255,255,0.06)', border: '1px solid rgba(255,255,255,0.1)', borderRadius: 8, padding: '8px 12px', color: '#fff', fontSize: 12, outline: 'none' }} />
            <input value={form.skills} onChange={e => setForm(f => ({ ...f, skills: e.target.value }))} placeholder="Skills needed"
              style={{ background: 'rgba(255,255,255,0.06)', border: '1px solid rgba(255,255,255,0.1)', borderRadius: 8, padding: '8px 12px', color: '#fff', fontSize: 12, outline: 'none' }} />
          </div>
          <div style={{ display: 'flex', gap: 8 }}>
            <button onClick={createTask} disabled={saving || !form.title} style={{ padding: '8px 20px', background: '#2979FF', border: 'none', borderRadius: 8, color: '#fff', fontSize: 13, fontWeight: 600, cursor: 'pointer' }}>
              {saving ? 'Creating…' : 'Create Task'}
            </button>
            <button onClick={() => setAdding(false)} style={{ padding: '8px 14px', background: 'rgba(255,255,255,0.05)', border: '1px solid rgba(255,255,255,0.1)', borderRadius: 8, color: '#888', fontSize: 13, cursor: 'pointer' }}>Cancel</button>
          </div>
        </div>
      )}

      {/* Task list */}
      {loading ? <div style={{ textAlign: 'center', padding: 40, color: 'rgba(255,255,255,0.3)' }}>Loading…</div>
        : tasks.length === 0 ? (
          <div style={{ textAlign: 'center', padding: 40, color: 'rgba(255,255,255,0.25)', background: 'rgba(255,255,255,0.02)', border: '1px solid rgba(255,255,255,0.06)', borderRadius: 12 }}>
            No tasks yet. Create one above or post via <code style={{ fontFamily: 'monospace', color: '#F5A623' }}>./memory-task-marketplace.sh</code>
          </div>
        ) : (
          <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
            {tasks.map(t => (
              <div key={t.task_id} style={{ background: 'rgba(255,255,255,0.03)', border: '1px solid rgba(255,255,255,0.07)', borderRadius: 12, padding: '14px 16px' }}>
                <div style={{ display: 'flex', alignItems: 'flex-start', gap: 12 }}>
                  <div style={{ flex: 1 }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 6 }}>
                      <span style={{ color: '#fff', fontWeight: 600, fontSize: 14 }}>{t.title}</span>
                      <span style={{ fontSize: 10, padding: '2px 7px', borderRadius: 4, background: `${PRIORITY_COLORS[t.priority] || '#888'}22`, color: PRIORITY_COLORS[t.priority] || '#888' }}>{t.priority}</span>
                      <span style={{ fontSize: 10, padding: '2px 7px', borderRadius: 4, background: `${STATUS_COLORS[t._status] || '#888'}22`, color: STATUS_COLORS[t._status] || '#888', marginLeft: 'auto' }}>{t._status}</span>
                    </div>
                    {t.description && <p style={{ color: 'rgba(255,255,255,0.4)', fontSize: 12, margin: '0 0 8px' }}>{t.description}</p>}
                    <div style={{ display: 'flex', alignItems: 'center', gap: 12, flexWrap: 'wrap' }}>
                      {t.tags && t.tags.split(',').map(tag => (
                        <span key={tag} style={{ display: 'flex', alignItems: 'center', gap: 3, fontSize: 10, color: 'rgba(255,255,255,0.3)', background: 'rgba(255,255,255,0.05)', padding: '2px 7px', borderRadius: 4 }}>
                          <Tag size={8} />{tag.trim()}
                        </span>
                      ))}
                      <span style={{ display: 'flex', alignItems: 'center', gap: 3, fontSize: 11, color: 'rgba(255,255,255,0.2)' }}>
                        <Clock size={9} />{timeAgo(t.posted_at)}
                      </span>
                      {t.claimed_by && <span style={{ display: 'flex', alignItems: 'center', gap: 3, fontSize: 11, color: '#F5A623' }}><User size={9} />{t.claimed_by}</span>}
                    </div>
                  </div>
                  {t._status === 'available' && (
                    <button onClick={() => claimTask(t.task_id)} style={{ display: 'flex', alignItems: 'center', gap: 4, padding: '6px 12px', background: 'rgba(34,197,94,0.12)', border: '1px solid rgba(34,197,94,0.3)', borderRadius: 8, color: '#22c55e', fontSize: 12, cursor: 'pointer', flexShrink: 0 }}>
                      <ChevronRight size={11} />Claim
                    </button>
                  )}
                  {t._status === 'claimed' && (
                    <button onClick={() => completeTask(t.task_id)} style={{ display: 'flex', alignItems: 'center', gap: 4, padding: '6px 12px', background: 'rgba(156,39,176,0.12)', border: '1px solid rgba(156,39,176,0.3)', borderRadius: 8, color: '#9C27B0', fontSize: 12, cursor: 'pointer', flexShrink: 0 }}>
                      <Check size={11} />Complete
                    </button>
                  )}
                </div>
                {t.result && <div style={{ marginTop: 10, padding: '8px 12px', background: 'rgba(156,39,176,0.08)', borderRadius: 6, color: 'rgba(255,255,255,0.45)', fontSize: 12 }}>{t.result}</div>}
              </div>
            ))}
          </div>
        )}
    </div>
  )
}
