'use client'
import { useEffect, useState } from 'react'
import { Settings, Server, Key, Globe, Cpu, Save, CheckCircle } from 'lucide-react'

interface SettingsData {
  gatewayUrl?: string
  ollamaUrl?: string
  tunnelId?: string
  cloudflareAccountId?: string
  cloudflareToken?: string
  vercelToken?: string
  vercelOrgId?: string
  piNodes?: Array<{ name: string; ip: string; role: string; capacity: number }>
}

function Field({ label, value, onChange, placeholder, type = 'text', mono = false }: any) {
  return (
    <div style={{ marginBottom: 16 }}>
      <label style={{ display: 'block', color: 'rgba(255,255,255,0.5)', fontSize: 11, fontWeight: 600, textTransform: 'uppercase', letterSpacing: 1, marginBottom: 6 }}>{label}</label>
      <input
        type={type}
        value={value ?? ''}
        onChange={e => onChange(e.target.value)}
        placeholder={placeholder}
        style={{ width: '100%', background: 'rgba(255,255,255,0.06)', border: '1px solid rgba(255,255,255,0.1)', borderRadius: 8, padding: '10px 14px', color: '#fff', fontSize: 13, outline: 'none', boxSizing: 'border-box', fontFamily: mono ? 'monospace' : 'inherit' }}
      />
    </div>
  )
}

function Section({ title, icon: Icon, color = '#FF1D6C', children }: any) {
  return (
    <div style={{ background: 'rgba(255,255,255,0.04)', border: '1px solid rgba(255,255,255,0.08)', borderRadius: 12, padding: 24, marginBottom: 20 }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 20 }}>
        <div style={{ width: 32, height: 32, borderRadius: 8, background: `${color}22`, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <Icon size={16} style={{ color }} />
        </div>
        <span style={{ color: '#fff', fontWeight: 600, fontSize: 15 }}>{title}</span>
      </div>
      {children}
    </div>
  )
}

export default function SettingsPage() {
  const [data, setData] = useState<SettingsData>({})
  const [saved, setSaved] = useState(false)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    fetch('/api/settings').then(r => r.json()).then(d => { setData(d); setLoading(false) }).catch(() => setLoading(false))
  }, [])

  const update = (key: string) => (val: string) => setData((d: any) => ({ ...d, [key]: val }))

  const handleSave = async () => {
    await fetch('/api/settings', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data),
    })
    setSaved(true)
    setTimeout(() => setSaved(false), 3000)
  }

  if (loading) return <div style={{ padding: 32, color: 'rgba(255,255,255,0.4)' }}>Loading settings…</div>

  return (
    <div style={{ padding: 32, maxWidth: 700 }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 32 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
          <Settings size={28} style={{ color: '#9C27B0' }} />
          <div>
            <h1 style={{ fontSize: 24, fontWeight: 700, color: '#fff', margin: 0 }}>Settings</h1>
            <p style={{ color: 'rgba(255,255,255,0.4)', fontSize: 13, margin: 0 }}>BlackRoad OS configuration</p>
          </div>
        </div>
        <button
          onClick={handleSave}
          style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '10px 20px', background: saved ? '#22c55e' : '#FF1D6C', border: 'none', borderRadius: 8, color: '#fff', fontSize: 14, fontWeight: 600, cursor: 'pointer', transition: 'all .2s' }}
        >
          {saved ? '✅ Saved!' : '💾 Save'}
        </button>
      </div>

      <Section title="Gateway & AI" icon={Cpu} color="#FF1D6C">
        <Field label="Gateway URL" value={data.gatewayUrl} onChange={update('gatewayUrl')} placeholder="http://127.0.0.1:8787" mono />
        <Field label="Ollama URL" value={data.ollamaUrl} onChange={update('ollamaUrl')} placeholder="http://localhost:11434" mono />
      </Section>

      <Section title="Cloudflare" icon={Globe} color="#F5A623">
        <Field label="CF Account ID" value={data.cloudflareAccountId} onChange={update('cloudflareAccountId')} placeholder="848cf0b18d51e0170e0d1537aec3505a" mono />
        <Field label="CF API Token" value={data.cloudflareToken} onChange={update('cloudflareToken')} placeholder="(stored securely)" type="password" mono />
        <Field label="Tunnel ID" value={data.tunnelId} onChange={update('tunnelId')} placeholder="8ae67ab0-71fb-4461-befc-a91302369a7e" mono />
      </Section>

      <Section title="Vercel" icon={Key} color="#2979FF">
        <Field label="Vercel Token" value={data.vercelToken} onChange={update('vercelToken')} placeholder="(stored securely)" type="password" mono />
        <Field label="Vercel Org ID" value={data.vercelOrgId} onChange={update('vercelOrgId')} placeholder="org id" mono />
      </Section>

      <Section title="Pi Fleet" icon={Server} color="#22c55e">
        {(data.piNodes ?? [
          { name: 'aria64', ip: '192.168.4.38', role: 'primary', capacity: 22500 },
          { name: 'blackroad-pi', ip: '192.168.4.64', role: 'secondary', capacity: 7500 },
          { name: 'alice', ip: '192.168.4.49', role: 'mesh', capacity: 5000 },
          { name: 'cecilia', ip: '192.168.4.89', role: 'ai', capacity: 5000 },
        ]).map(node => (
          <div key={node.name} style={{ display: 'flex', gap: 10, marginBottom: 8, alignItems: 'center' }}>
            <div style={{ width: 8, height: 8, borderRadius: '50%', background: '#22c55e', flexShrink: 0 }} />
            <span style={{ color: '#fff', fontWeight: 600, fontSize: 13, minWidth: 100 }}>{node.name}</span>
            <span style={{ color: 'rgba(255,255,255,0.4)', fontSize: 12, fontFamily: 'monospace' }}>{node.ip}</span>
            <span style={{ color: 'rgba(255,255,255,0.3)', fontSize: 12, marginLeft: 'auto' }}>{node.role} · {node.capacity.toLocaleString()} slots</span>
          </div>
        ))}
        <p style={{ color: 'rgba(255,255,255,0.3)', fontSize: 11, marginTop: 12 }}>Edit Pi nodes in ~/.cloudflared/config.yml</p>
      </Section>
    </div>
  )
}
