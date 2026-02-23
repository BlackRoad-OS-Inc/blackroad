'use client'
import { useEffect, useState, useRef } from 'react'
import { Network, MessageSquare, Send, Users, CheckCircle, Clock } from 'lucide-react'

interface AgentCounts { agents: string[]; counts: Record<string, number>; total: number }

const AGENT_COLORS: Record<string, string> = {
  claude: '#FF1D6C',
  'claude-sonnet': '#FF1D6C',
  codex: '#F5A623',
  'copilot-2': '#2979FF',
  'copilot-3': '#2979FF',
  'copilot-window-2': '#2979FF',
  'copilot-window-3': '#2979FF',
  lucidia: '#9C27B0',
  'ollama-local': '#22c55e',
}

export default function MeshPage() {
  const [mesh, setMesh] = useState<AgentCounts | null>(null)
  const [to, setTo] = useState('all')
  const [subject, setSubject] = useState('')
  const [message, setMessage] = useState('')
  const [sending, setSending] = useState(false)
  const [sent, setSent] = useState<string | null>(null)
  const intervalRef = useRef<any>(null)

  const load = () => fetch('/api/broadcast').then(r => r.json()).then(setMesh).catch(() => {})

  useEffect(() => {
    load()
    intervalRef.current = setInterval(load, 15000)
    return () => clearInterval(intervalRef.current)
  }, [])

  const handleSend = async () => {
    if (!message.trim()) return
    setSending(true)
    setSent(null)
    try {
      const r = await fetch('/api/broadcast', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ to, subject: subject || 'Message from BlackRoad Web', message }),
      })
      const d = await r.json()
      setSent(`✅ Delivered to ${d.count} agent${d.count !== 1 ? 's' : ''} — ID: ${d.id}`)
      setMessage('')
      setSubject('')
      setTimeout(load, 500)
    } catch (e: any) {
      setSent(`❌ Error: ${e.message}`)
    } finally {
      setSending(false)
    }
  }

  return (
    <div style={{ padding: 32, maxWidth: 1100 }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 32 }}>
        <Network size={28} style={{ color: '#2979FF' }} />
        <div>
          <h1 style={{ fontSize: 24, fontWeight: 700, color: '#fff', margin: 0 }}>Agent Mesh</h1>
          <p style={{ color: 'rgba(255,255,255,0.4)', fontSize: 13, margin: 0 }}>
            {mesh?.total ?? 0} messages · {mesh?.agents.length ?? 9} agents · BRAT protocol
          </p>
        </div>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '1fr 380px', gap: 24 }}>
        {/* Agent Cards */}
        <div>
          <div style={{ color: 'rgba(255,255,255,0.5)', fontSize: 12, fontWeight: 600, textTransform: 'uppercase', letterSpacing: 1, marginBottom: 12 }}>
            <Users size={12} style={{ display: 'inline', marginRight: 6 }} />Active Agents
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(180px, 1fr))', gap: 12 }}>
            {(mesh?.agents ?? ['claude', 'claude-sonnet', 'codex', 'copilot-2', 'copilot-3', 'copilot-window-2', 'copilot-window-3', 'lucidia', 'ollama-local']).map(agent => {
              const color = AGENT_COLORS[agent] ?? '#888'
              const count = mesh?.counts[agent] ?? 0
              return (
                <div key={agent}
                  onClick={() => setTo(agent)}
                  style={{
                    background: to === agent ? `${color}22` : 'rgba(255,255,255,0.04)',
                    border: `1px solid ${to === agent ? color : 'rgba(255,255,255,0.08)'}`,
                    borderRadius: 10, padding: '14px 16px', cursor: 'pointer', transition: 'all .15s',
                  }}
                >
                  <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 8 }}>
                    <div style={{ width: 8, height: 8, borderRadius: '50%', background: color, boxShadow: `0 0 6px ${color}` }} />
                    <span style={{ color: '#fff', fontSize: 13, fontWeight: 600 }}>{agent}</span>
                  </div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                    <MessageSquare size={11} style={{ color: 'rgba(255,255,255,0.3)' }} />
                    <span style={{ color: 'rgba(255,255,255,0.4)', fontSize: 11 }}>{count} message{count !== 1 ? 's' : ''}</span>
                  </div>
                </div>
              )
            })}
          </div>

          {/* Broadcast to all card */}
          <div
            onClick={() => setTo('all')}
            style={{
              marginTop: 12,
              background: to === 'all' ? 'rgba(255,29,108,0.12)' : 'rgba(255,255,255,0.04)',
              border: `1px solid ${to === 'all' ? '#FF1D6C' : 'rgba(255,255,255,0.08)'}`,
              borderRadius: 10, padding: '14px 16px', cursor: 'pointer', transition: 'all .15s',
              display: 'flex', alignItems: 'center', gap: 10,
            }}
          >
            <CheckCircle size={16} style={{ color: to === 'all' ? '#FF1D6C' : 'rgba(255,255,255,0.3)' }} />
            <div>
              <div style={{ color: '#fff', fontSize: 13, fontWeight: 600 }}>Broadcast to all agents</div>
              <div style={{ color: 'rgba(255,255,255,0.4)', fontSize: 11 }}>BRAT-RELAY-v1 · {mesh?.agents.length ?? 9} recipients</div>
            </div>
          </div>
        </div>

        {/* Compose panel */}
        <div style={{ background: 'rgba(255,255,255,0.04)', border: '1px solid rgba(255,255,255,0.08)', borderRadius: 12, padding: 20, height: 'fit-content' }}>
          <div style={{ color: '#fff', fontWeight: 600, marginBottom: 16, display: 'flex', alignItems: 'center', gap: 8 }}>
            <Send size={15} style={{ color: '#FF1D6C' }} />
            Send Message
          </div>

          <div style={{ marginBottom: 12 }}>
            <label style={{ display: 'block', color: 'rgba(255,255,255,0.5)', fontSize: 11, fontWeight: 600, textTransform: 'uppercase', letterSpacing: 1, marginBottom: 6 }}>To</label>
            <div style={{ background: 'rgba(255,29,108,0.1)', border: '1px solid rgba(255,29,108,0.3)', borderRadius: 6, padding: '8px 12px', color: '#FF1D6C', fontSize: 13, fontWeight: 600 }}>
              {to === 'all' ? '📡 All agents (broadcast)' : `💬 ${to}`}
            </div>
          </div>

          <div style={{ marginBottom: 12 }}>
            <label style={{ display: 'block', color: 'rgba(255,255,255,0.5)', fontSize: 11, fontWeight: 600, textTransform: 'uppercase', letterSpacing: 1, marginBottom: 6 }}>Subject</label>
            <input
              value={subject}
              onChange={e => setSubject(e.target.value)}
              placeholder="Message from BlackRoad Web"
              style={{ width: '100%', background: 'rgba(255,255,255,0.06)', border: '1px solid rgba(255,255,255,0.1)', borderRadius: 6, padding: '8px 12px', color: '#fff', fontSize: 13, outline: 'none', boxSizing: 'border-box' }}
            />
          </div>

          <div style={{ marginBottom: 16 }}>
            <label style={{ display: 'block', color: 'rgba(255,255,255,0.5)', fontSize: 11, fontWeight: 600, textTransform: 'uppercase', letterSpacing: 1, marginBottom: 6 }}>Message</label>
            <textarea
              value={message}
              onChange={e => setMessage(e.target.value)}
              placeholder="What do you want to tell the agents?"
              rows={5}
              style={{ width: '100%', background: 'rgba(255,255,255,0.06)', border: '1px solid rgba(255,255,255,0.1)', borderRadius: 6, padding: '8px 12px', color: '#fff', fontSize: 13, outline: 'none', resize: 'vertical', fontFamily: 'inherit', boxSizing: 'border-box' }}
            />
          </div>

          <button
            onClick={handleSend}
            disabled={sending || !message.trim()}
            style={{
              width: '100%', padding: '10px 16px', background: sending ? 'rgba(255,29,108,0.3)' : '#FF1D6C',
              border: 'none', borderRadius: 8, color: '#fff', fontSize: 14, fontWeight: 600, cursor: sending ? 'not-allowed' : 'pointer', transition: 'all .15s',
              display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
            }}
          >
            {sending ? <><Clock size={14} />Sending…</> : <><Send size={14} />Send</>}
          </button>

          {sent && (
            <div style={{ marginTop: 12, padding: '8px 12px', background: sent.startsWith('✅') ? 'rgba(34,197,94,0.1)' : 'rgba(239,68,68,0.1)', border: `1px solid ${sent.startsWith('✅') ? 'rgba(34,197,94,0.3)' : 'rgba(239,68,68,0.3)'}`, borderRadius: 6, fontSize: 12, color: sent.startsWith('✅') ? '#22c55e' : '#ef4444' }}>
              {sent}
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
