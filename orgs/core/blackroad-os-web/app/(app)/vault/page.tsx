'use client'
import { useEffect, useState } from 'react'
import { Lock, Plus, Eye, EyeOff, Trash2, RefreshCw, Shield, AlertCircle } from 'lucide-react'

interface Secret { name: string; size: number; modifiedAt: string; isDir: boolean }

function timeAgo(iso?: string) {
  if (!iso) return '—'
  try {
    const diff = Date.now() - new Date(iso).getTime()
    const m = Math.floor(diff / 60000), h = Math.floor(m / 60), d = Math.floor(h / 24)
    if (d > 0) return `${d}d ago`; if (h > 0) return `${h}h ago`; if (m > 0) return `${m}m ago`; return 'just now'
  } catch { return '—' }
}

export default function VaultPage() {
  const [secrets, setSecrets] = useState<Secret[]>([])
  const [vaultExists, setVaultExists] = useState(false)
  const [loading, setLoading] = useState(true)
  const [adding, setAdding] = useState(false)
  const [form, setForm] = useState({ name: '', value: '', category: 'general' })
  const [saving, setSaving] = useState(false)
  const [visible, setVisible] = useState<Record<string, string>>({})
  const [output, setOutput] = useState('')

  const load = () => {
    setLoading(true)
    fetch('/api/vault?action=list').then(r => r.json()).then(d => {
      setSecrets(d.secrets || [])
      setVaultExists(d.vaultExists)
      setLoading(false)
    }).catch(() => setLoading(false))
  }
  useEffect(() => { load() }, [])

  const addSecret = async () => {
    if (!form.name || !form.value) return
    setSaving(true)
    const r = await fetch('/api/vault', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ action: 'add', ...form }) })
    const d = await r.json()
    setOutput(d.output || '')
    setSaving(false)
    if (d.success !== false) { setAdding(false); setForm({ name: '', value: '', category: 'general' }); load() }
  }

  const viewSecret = async (name: string) => {
    if (visible[name] !== undefined) { setVisible(v => { const n = { ...v }; delete n[name]; return n }); return }
    const r = await fetch('/api/vault', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ action: 'get', name }) })
    const d = await r.json()
    setVisible(v => ({ ...v, [name]: d.output || '' }))
  }

  const deleteSecret = async (name: string) => {
    if (!confirm(`Delete "${name}"?`)) return
    const r = await fetch('/api/vault', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ action: 'delete', name }) })
    const d = await r.json()
    setOutput(d.output || '')
    load()
  }

  const CATEGORIES = ['api-key', 'token', 'password', 'certificate', 'ssh-key', 'general']

  return (
    <div style={{ padding: 32, maxWidth: 800 }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 28 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
          <Lock size={28} style={{ color: '#FF1D6C' }} />
          <div>
            <h1 style={{ fontSize: 24, fontWeight: 700, color: '#fff', margin: 0 }}>Secrets Vault</h1>
            <p style={{ color: 'rgba(255,255,255,0.4)', fontSize: 13, margin: 0 }}>
              AES-256-CBC encrypted · {secrets.length} secrets · {vaultExists ? '~/.blackroad/vault/' : 'vault not initialized'}
            </p>
          </div>
        </div>
        <div style={{ display: 'flex', gap: 8 }}>
          <button onClick={load} style={{ display: 'flex', alignItems: 'center', gap: 4, padding: '7px 12px', background: 'rgba(255,255,255,0.05)', border: '1px solid rgba(255,255,255,0.1)', borderRadius: 8, color: '#aaa', fontSize: 12, cursor: 'pointer' }}>
            <RefreshCw size={12} />
          </button>
          <button onClick={() => setAdding(a => !a)} style={{ display: 'flex', alignItems: 'center', gap: 4, padding: '7px 16px', background: adding ? 'rgba(255,29,108,0.2)' : '#FF1D6C', border: 'none', borderRadius: 8, color: '#fff', fontSize: 13, fontWeight: 600, cursor: 'pointer' }}>
            <Plus size={14} />Add Secret
          </button>
        </div>
      </div>

      {/* Security notice */}
      <div style={{ display: 'flex', alignItems: 'flex-start', gap: 10, padding: '12px 16px', background: 'rgba(255,29,108,0.06)', border: '1px solid rgba(255,29,108,0.2)', borderRadius: 10, marginBottom: 20 }}>
        <Shield size={15} style={{ color: '#FF1D6C', flexShrink: 0, marginTop: 2 }} />
        <p style={{ color: 'rgba(255,255,255,0.5)', fontSize: 12, margin: 0 }}>
          Secrets are encrypted at rest using AES-256-CBC. Master key stored at <code style={{ fontFamily: 'monospace', color: '#F5A623' }}>~/.blackroad/vault/.master.key</code> (chmod 400). Never commit vault contents.
        </p>
      </div>

      {/* Add form */}
      {adding && (
        <div style={{ background: 'rgba(255,255,255,0.04)', border: '1px solid rgba(255,29,108,0.3)', borderRadius: 12, padding: 20, marginBottom: 20 }}>
          <h3 style={{ color: '#fff', fontSize: 15, fontWeight: 600, marginBottom: 16, marginTop: 0 }}>Add New Secret</h3>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12, marginBottom: 12 }}>
            <div>
              <label style={{ color: 'rgba(255,255,255,0.5)', fontSize: 12, display: 'block', marginBottom: 6 }}>Secret Name *</label>
              <input value={form.name} onChange={e => setForm(f => ({ ...f, name: e.target.value }))} placeholder="e.g. GITHUB_TOKEN"
                style={{ width: '100%', background: 'rgba(255,255,255,0.06)', border: '1px solid rgba(255,255,255,0.1)', borderRadius: 8, padding: '9px 12px', color: '#fff', fontSize: 13, outline: 'none', boxSizing: 'border-box', fontFamily: 'monospace' }} />
            </div>
            <div>
              <label style={{ color: 'rgba(255,255,255,0.5)', fontSize: 12, display: 'block', marginBottom: 6 }}>Category</label>
              <select value={form.category} onChange={e => setForm(f => ({ ...f, category: e.target.value }))}
                style={{ width: '100%', background: 'rgba(0,0,0,0.6)', border: '1px solid rgba(255,255,255,0.1)', borderRadius: 8, padding: '9px 12px', color: '#fff', fontSize: 13, outline: 'none', boxSizing: 'border-box' }}>
                {CATEGORIES.map(c => <option key={c} value={c}>{c}</option>)}
              </select>
            </div>
          </div>
          <div style={{ marginBottom: 14 }}>
            <label style={{ color: 'rgba(255,255,255,0.5)', fontSize: 12, display: 'block', marginBottom: 6 }}>Secret Value *</label>
            <textarea value={form.value} onChange={e => setForm(f => ({ ...f, value: e.target.value }))} rows={3} placeholder="Paste secret value here…"
              style={{ width: '100%', background: 'rgba(255,255,255,0.06)', border: '1px solid rgba(255,255,255,0.1)', borderRadius: 8, padding: '9px 12px', color: '#fff', fontSize: 13, outline: 'none', resize: 'vertical', boxSizing: 'border-box', fontFamily: 'monospace' }} />
          </div>
          <div style={{ display: 'flex', gap: 8 }}>
            <button onClick={addSecret} disabled={saving || !form.name || !form.value} style={{ padding: '8px 20px', background: '#FF1D6C', border: 'none', borderRadius: 8, color: '#fff', fontSize: 13, fontWeight: 600, cursor: 'pointer' }}>
              {saving ? 'Saving…' : 'Save Secret'}
            </button>
            <button onClick={() => setAdding(false)} style={{ padding: '8px 16px', background: 'rgba(255,255,255,0.05)', border: '1px solid rgba(255,255,255,0.1)', borderRadius: 8, color: '#888', fontSize: 13, cursor: 'pointer' }}>Cancel</button>
          </div>
          {output && <pre style={{ marginTop: 12, color: 'rgba(255,255,255,0.5)', fontSize: 12, fontFamily: 'monospace', whiteSpace: 'pre-wrap' }}>{output}</pre>}
        </div>
      )}

      {/* Secrets list */}
      {loading ? (
        <div style={{ color: 'rgba(255,255,255,0.3)', textAlign: 'center', padding: 40 }}>Loading vault…</div>
      ) : secrets.length === 0 ? (
        <div style={{ color: 'rgba(255,255,255,0.25)', textAlign: 'center', padding: 40, background: 'rgba(255,255,255,0.02)', border: '1px solid rgba(255,255,255,0.06)', borderRadius: 12 }}>
          <Lock size={32} style={{ color: 'rgba(255,255,255,0.1)', marginBottom: 12 }} />
          <div>No secrets in vault.</div>
          <div style={{ fontSize: 12, marginTop: 8 }}>Use <code style={{ fontFamily: 'monospace', color: '#F5A623' }}>br security vault add NAME VALUE</code> or click Add Secret above.</div>
        </div>
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
          {secrets.map(s => (
            <div key={s.name} style={{ background: 'rgba(255,255,255,0.03)', border: '1px solid rgba(255,255,255,0.07)', borderRadius: 10 }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '12px 16px' }}>
                <Lock size={14} style={{ color: '#FF1D6C', flexShrink: 0 }} />
                <span style={{ color: '#fff', fontFamily: 'monospace', fontSize: 13, fontWeight: 600, flex: 1 }}>{s.name}</span>
                <span style={{ color: 'rgba(255,255,255,0.25)', fontSize: 11 }}>{s.size}B · {timeAgo(s.modifiedAt)}</span>
                <button onClick={() => viewSecret(s.name)} style={{ display: 'flex', alignItems: 'center', gap: 4, padding: '4px 10px', background: 'rgba(255,255,255,0.05)', border: '1px solid rgba(255,255,255,0.1)', borderRadius: 6, color: '#aaa', fontSize: 11, cursor: 'pointer' }}>
                  {visible[s.name] !== undefined ? <EyeOff size={11} /> : <Eye size={11} />}
                  {visible[s.name] !== undefined ? 'Hide' : 'View'}
                </button>
                <button onClick={() => deleteSecret(s.name)} style={{ display: 'flex', alignItems: 'center', padding: '4px 8px', background: 'rgba(239,68,68,0.08)', border: '1px solid rgba(239,68,68,0.2)', borderRadius: 6, color: '#ef4444', cursor: 'pointer' }}>
                  <Trash2 size={11} />
                </button>
              </div>
              {visible[s.name] !== undefined && (
                <div style={{ padding: '0 16px 12px', borderTop: '1px solid rgba(255,255,255,0.05)', paddingTop: 10 }}>
                  <pre style={{ fontFamily: 'monospace', fontSize: 12, color: '#F5A623', whiteSpace: 'pre-wrap', wordBreak: 'break-all', margin: 0, background: 'rgba(0,0,0,0.3)', padding: '8px 12px', borderRadius: 6 }}>
                    {visible[s.name] || '(empty)'}
                  </pre>
                </div>
              )}
            </div>
          ))}
        </div>
      )}
    </div>
  )
}
