'use client'
import { useEffect, useState } from 'react'
import { Database, Search, ChevronRight, Key, AlertCircle, RefreshCw, Edit3, Check } from 'lucide-react'

interface NS { id: string; title: string }
interface KVKey { name: string; expiration?: number; metadata?: any }

export default function KVPage() {
  const [namespaces, setNamespaces] = useState<NS[]>([])
  const [selectedNs, setSelectedNs] = useState<NS | null>(null)
  const [keys, setKeys] = useState<KVKey[]>([])
  const [selectedKey, setSelectedKey] = useState<string | null>(null)
  const [value, setValue] = useState<string>('')
  const [editValue, setEditValue] = useState('')
  const [editing, setEditing] = useState(false)
  const [search, setSearch] = useState('')
  const [loading, setLoading] = useState(true)
  const [loadingKeys, setLoadingKeys] = useState(false)
  const [loadingValue, setLoadingValue] = useState(false)
  const [saving, setSaving] = useState(false)
  const [live, setLive] = useState(false)
  const [saved, setSaved] = useState(false)

  useEffect(() => {
    fetch('/api/kv').then(r => r.json()).then(d => {
      setNamespaces(d.namespaces || [])
      setLive(d.live ?? false)
      setLoading(false)
    }).catch(() => setLoading(false))
  }, [])

  const selectNs = async (ns: NS) => {
    setSelectedNs(ns); setSelectedKey(null); setValue('')
    setLoadingKeys(true)
    try {
      const r = await fetch(`/api/kv?ns=${ns.id}`)
      const d = await r.json()
      setKeys(d.keys || [])
    } finally { setLoadingKeys(false) }
  }

  const selectKey = async (key: string) => {
    if (!selectedNs) return
    setSelectedKey(key); setLoadingValue(true)
    try {
      const r = await fetch(`/api/kv?ns=${selectedNs.id}&key=${encodeURIComponent(key)}`)
      const d = await r.json()
      setValue(d.value || '')
      setEditValue(d.value || '')
    } finally { setLoadingValue(false) }
  }

  const saveValue = async () => {
    if (!selectedNs || !selectedKey) return
    setSaving(true)
    try {
      await fetch('/api/kv', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ nsId: selectedNs.id, key: selectedKey, value: editValue }),
      })
      setValue(editValue)
      setSaved(true)
      setTimeout(() => setSaved(false), 2000)
      setEditing(false)
    } finally { setSaving(false) }
  }

  const filteredNs = namespaces.filter(ns => !search || ns.title.toLowerCase().includes(search.toLowerCase()))
  const filteredKeys = keys.filter(k => !search || k.name.toLowerCase().includes(search.toLowerCase()))

  return (
    <div style={{ padding: 32, maxWidth: 1100 }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 28 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
          <Database size={28} style={{ color: '#F5A623' }} />
          <div>
            <h1 style={{ fontSize: 24, fontWeight: 700, color: '#fff', margin: 0 }}>KV Browser</h1>
            <p style={{ color: 'rgba(255,255,255,0.4)', fontSize: 13, margin: 0 }}>
              {namespaces.length} namespaces · Cloudflare Workers KV {live ? '● live' : '○ set CF token'}
            </p>
          </div>
        </div>
        {!live && (
          <div style={{ display: 'flex', alignItems: 'center', gap: 6, padding: '6px 14px', background: 'rgba(245,166,35,0.1)', border: '1px solid rgba(245,166,35,0.3)', borderRadius: 20, fontSize: 12, color: '#F5A623' }}>
            <AlertCircle size={12} />Set CLOUDFLARE_API_TOKEN in Vercel
          </div>
        )}
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '280px 1fr', gap: 16 }}>
        {/* Namespace list */}
        <div style={{ background: 'rgba(255,255,255,0.03)', border: '1px solid rgba(255,255,255,0.07)', borderRadius: 12, overflow: 'hidden' }}>
          <div style={{ padding: '12px 14px', borderBottom: '1px solid rgba(255,255,255,0.06)' }}>
            <div style={{ position: 'relative' }}>
              <Search size={13} style={{ position: 'absolute', left: 10, top: '50%', transform: 'translateY(-50%)', color: 'rgba(255,255,255,0.3)' }} />
              <input value={search} onChange={e => setSearch(e.target.value)} placeholder="Search…"
                style={{ width: '100%', background: 'rgba(255,255,255,0.06)', border: '1px solid rgba(255,255,255,0.08)', borderRadius: 6, padding: '7px 10px 7px 28px', color: '#fff', fontSize: 12, outline: 'none', boxSizing: 'border-box' }} />
            </div>
          </div>
          <div style={{ maxHeight: 500, overflowY: 'auto' }}>
            {loading ? <div style={{ padding: 20, color: 'rgba(255,255,255,0.3)', fontSize: 13 }}>Loading…</div>
              : filteredNs.map(ns => (
                <div key={ns.id} onClick={() => selectNs(ns)} style={{
                  display: 'flex', alignItems: 'center', gap: 8, padding: '10px 14px', cursor: 'pointer',
                  background: selectedNs?.id === ns.id ? 'rgba(245,166,35,0.12)' : 'transparent',
                  borderLeft: `3px solid ${selectedNs?.id === ns.id ? '#F5A623' : 'transparent'}`,
                  transition: 'all .1s',
                }}>
                  <Database size={13} style={{ color: selectedNs?.id === ns.id ? '#F5A623' : 'rgba(255,255,255,0.3)', flexShrink: 0 }} />
                  <span style={{ color: selectedNs?.id === ns.id ? '#fff' : 'rgba(255,255,255,0.6)', fontSize: 12, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{ns.title}</span>
                </div>
              ))}
            {!loading && filteredNs.length === 0 && <div style={{ padding: 20, color: 'rgba(255,255,255,0.25)', fontSize: 12 }}>No namespaces</div>}
          </div>
        </div>

        {/* Right panel */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
          {!selectedNs ? (
            <div style={{ background: 'rgba(255,255,255,0.03)', border: '1px solid rgba(255,255,255,0.07)', borderRadius: 12, padding: 40, textAlign: 'center', color: 'rgba(255,255,255,0.25)', fontSize: 14 }}>
              ← Select a namespace to browse keys
            </div>
          ) : (
            <>
              {/* Keys */}
              <div style={{ background: 'rgba(255,255,255,0.03)', border: '1px solid rgba(255,255,255,0.07)', borderRadius: 12, overflow: 'hidden', maxHeight: 300 }}>
                <div style={{ padding: '10px 14px', borderBottom: '1px solid rgba(255,255,255,0.06)', display: 'flex', alignItems: 'center', gap: 8 }}>
                  <Key size={13} style={{ color: '#F5A623' }} />
                  <span style={{ color: '#fff', fontSize: 13, fontWeight: 600 }}>{selectedNs.title}</span>
                  <span style={{ color: 'rgba(255,255,255,0.3)', fontSize: 11 }}>({keys.length} keys)</span>
                  {loadingKeys && <RefreshCw size={12} style={{ color: '#aaa', marginLeft: 'auto', animation: 'spin 1s linear infinite' }} />}
                </div>
                <div style={{ overflowY: 'auto', maxHeight: 240 }}>
                  {filteredKeys.map(k => (
                    <div key={k.name} onClick={() => selectKey(k.name)} style={{
                      display: 'flex', alignItems: 'center', gap: 8, padding: '8px 14px', cursor: 'pointer',
                      background: selectedKey === k.name ? 'rgba(245,166,35,0.08)' : 'transparent',
                      borderLeft: `2px solid ${selectedKey === k.name ? '#F5A623' : 'transparent'}`,
                    }}>
                      <ChevronRight size={11} style={{ color: 'rgba(255,255,255,0.2)', flexShrink: 0 }} />
                      <span style={{ color: selectedKey === k.name ? '#F5A623' : 'rgba(255,255,255,0.6)', fontSize: 12, fontFamily: 'monospace', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{k.name}</span>
                    </div>
                  ))}
                  {filteredKeys.length === 0 && !loadingKeys && <div style={{ padding: 20, color: 'rgba(255,255,255,0.2)', fontSize: 12 }}>No keys</div>}
                </div>
              </div>

              {/* Value viewer */}
              {selectedKey && (
                <div style={{ background: 'rgba(255,255,255,0.03)', border: '1px solid rgba(255,255,255,0.07)', borderRadius: 12, overflow: 'hidden' }}>
                  <div style={{ padding: '10px 14px', borderBottom: '1px solid rgba(255,255,255,0.06)', display: 'flex', alignItems: 'center', gap: 8 }}>
                    <span style={{ color: '#F5A623', fontFamily: 'monospace', fontSize: 13 }}>{selectedKey}</span>
                    <div style={{ marginLeft: 'auto', display: 'flex', gap: 6 }}>
                      {!editing ? (
                        <button onClick={() => { setEditing(true); setEditValue(value) }} style={{ display: 'flex', alignItems: 'center', gap: 4, padding: '4px 10px', background: 'rgba(255,255,255,0.05)', border: '1px solid rgba(255,255,255,0.1)', borderRadius: 6, color: '#aaa', fontSize: 12, cursor: 'pointer' }}>
                          <Edit3 size={11} />Edit
                        </button>
                      ) : (
                        <>
                          <button onClick={() => setEditing(false)} style={{ padding: '4px 10px', background: 'rgba(255,255,255,0.05)', border: '1px solid rgba(255,255,255,0.1)', borderRadius: 6, color: '#888', fontSize: 12, cursor: 'pointer' }}>Cancel</button>
                          <button onClick={saveValue} disabled={saving} style={{ display: 'flex', alignItems: 'center', gap: 4, padding: '4px 10px', background: saved ? '#22c55e' : '#F5A623', border: 'none', borderRadius: 6, color: '#000', fontSize: 12, fontWeight: 600, cursor: 'pointer' }}>
                            <Check size={11} />{saved ? 'Saved!' : saving ? 'Saving…' : 'Save'}
                          </button>
                        </>
                      )}
                    </div>
                  </div>
                  {loadingValue ? (
                    <div style={{ padding: 20, color: 'rgba(255,255,255,0.3)', fontSize: 13 }}>Loading value…</div>
                  ) : (
                    <textarea
                      value={editing ? editValue : value}
                      onChange={e => setEditValue(e.target.value)}
                      readOnly={!editing}
                      rows={8}
                      style={{ width: '100%', background: 'transparent', border: 'none', outline: 'none', padding: '12px 14px', color: editing ? '#fff' : 'rgba(255,255,255,0.6)', fontFamily: 'monospace', fontSize: 12, resize: 'vertical', boxSizing: 'border-box', cursor: editing ? 'text' : 'default' }}
                    />
                  )}
                </div>
              )}
            </>
          )}
        </div>
      </div>
    </div>
  )
}
