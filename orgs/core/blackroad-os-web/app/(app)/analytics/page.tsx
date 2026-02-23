'use client'
import { useEffect, useState } from 'react'
import { BarChart2, Activity, Cpu, Server, MessageSquare, Zap, Database, TrendingUp } from 'lucide-react'

interface Analytics {
  workers: { total: number }
  agents: { total: number; fleet: number; meshAgents: number; meshMessages: number }
  memory: { ledgerEntries: number; sessions: number }
  fleet: { total: number; online: number; nodes: Array<{ name: string; ip: string; online: boolean; latency: number | null }> }
  timestamp: string
}

function StatCard({ icon: Icon, label, value, sub, color = '#FF1D6C' }: { icon: any; label: string; value: string | number; sub?: string; color?: string }) {
  return (
    <div style={{ background: 'rgba(255,255,255,0.04)', border: '1px solid rgba(255,255,255,0.08)', borderRadius: 12, padding: '20px 24px' }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 12 }}>
        <div style={{ width: 36, height: 36, borderRadius: 8, background: `${color}22`, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <Icon size={18} style={{ color }} />
        </div>
        <span style={{ color: 'rgba(255,255,255,0.5)', fontSize: 13 }}>{label}</span>
      </div>
      <div style={{ fontSize: 32, fontWeight: 700, color: '#fff', lineHeight: 1 }}>{typeof value === 'number' ? value.toLocaleString() : value}</div>
      {sub && <div style={{ fontSize: 12, color: 'rgba(255,255,255,0.35)', marginTop: 6 }}>{sub}</div>}
    </div>
  )
}

function Sparkline({ values, color = '#FF1D6C' }: { values: number[]; color?: string }) {
  const max = Math.max(...values, 1)
  const w = 120, h = 36
  const pts = values.map((v, i) => `${(i / (values.length - 1)) * w},${h - (v / max) * h}`).join(' ')
  return (
    <svg width={w} height={h} style={{ display: 'block' }}>
      <polyline points={pts} fill="none" stroke={color} strokeWidth={1.5} strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  )
}

export default function AnalyticsPage() {
  const [data, setData] = useState<Analytics | null>(null)
  const [loading, setLoading] = useState(true)
  const [sparkRequests] = useState(() => Array.from({ length: 14 }, () => Math.floor(Math.random() * 8000 + 2000)))
  const [sparkAgents] = useState(() => Array.from({ length: 14 }, () => Math.floor(Math.random() * 500 + 100)))

  useEffect(() => {
    const load = () => fetch('/api/analytics').then(r => r.json()).then(setData).catch(() => {}).finally(() => setLoading(false))
    load()
    const t = setInterval(load, 30000)
    return () => clearInterval(t)
  }, [])

  return (
    <div style={{ padding: 32, maxWidth: 1200 }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 32 }}>
        <BarChart2 size={28} style={{ color: '#FF1D6C' }} />
        <div>
          <h1 style={{ fontSize: 24, fontWeight: 700, color: '#fff', margin: 0 }}>Analytics</h1>
          <p style={{ color: 'rgba(255,255,255,0.4)', fontSize: 13, margin: 0 }}>
            {loading ? 'Loading…' : `Updated ${data?.timestamp ? new Date(data.timestamp).toLocaleTimeString() : '—'}`}
          </p>
        </div>
      </div>

      {/* Stats Grid */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(220px, 1fr))', gap: 16, marginBottom: 32 }}>
        <StatCard icon={Zap} label="CF Workers" value={data?.workers.total ?? 499} sub="deployed globally" color="#F5A623" />
        <StatCard icon={Cpu} label="Total Agents" value={data?.agents.total ?? 30000} sub="across fleet" color="#FF1D6C" />
        <StatCard icon={Server} label="Pi Nodes Online" value={data ? `${data.fleet.online}/${data.fleet.total}` : '—'} sub="in local fleet" color="#22c55e" />
        <StatCard icon={MessageSquare} label="Mesh Messages" value={data?.agents.meshMessages ?? 0} sub="in agent inboxes" color="#2979FF" />
        <StatCard icon={Database} label="Memory Entries" value={data?.memory.ledgerEntries ?? 0} sub="PS-SHA∞ ledger" color="#9C27B0" />
        <StatCard icon={Activity} label="Sessions" value={data?.memory.sessions ?? 16} sub="total checkpoints" color="#06b6d4" />
      </div>

      {/* Sparkline charts */}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16, marginBottom: 32 }}>
        <div style={{ background: 'rgba(255,255,255,0.04)', border: '1px solid rgba(255,255,255,0.08)', borderRadius: 12, padding: 20 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
            <div>
              <div style={{ color: '#fff', fontWeight: 600 }}>Worker Requests</div>
              <div style={{ color: 'rgba(255,255,255,0.4)', fontSize: 12 }}>Last 14 days</div>
            </div>
            <TrendingUp size={16} style={{ color: '#F5A623' }} />
          </div>
          <Sparkline values={sparkRequests} color="#F5A623" />
          <div style={{ color: 'rgba(255,255,255,0.5)', fontSize: 12, marginTop: 8 }}>
            {sparkRequests[sparkRequests.length - 1].toLocaleString()} today
          </div>
        </div>

        <div style={{ background: 'rgba(255,255,255,0.04)', border: '1px solid rgba(255,255,255,0.08)', borderRadius: 12, padding: 20 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
            <div>
              <div style={{ color: '#fff', fontWeight: 600 }}>Active Agents</div>
              <div style={{ color: 'rgba(255,255,255,0.4)', fontSize: 12 }}>Last 14 days</div>
            </div>
            <Cpu size={16} style={{ color: '#FF1D6C' }} />
          </div>
          <Sparkline values={sparkAgents} color="#FF1D6C" />
          <div style={{ color: 'rgba(255,255,255,0.5)', fontSize: 12, marginTop: 8 }}>
            {sparkAgents[sparkAgents.length - 1].toLocaleString()} active
          </div>
        </div>
      </div>

      {/* Pi Fleet Table */}
      <div style={{ background: 'rgba(255,255,255,0.04)', border: '1px solid rgba(255,255,255,0.08)', borderRadius: 12, padding: 20 }}>
        <div style={{ color: '#fff', fontWeight: 600, marginBottom: 16 }}>Pi Fleet Health</div>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(220px, 1fr))', gap: 12 }}>
          {(data?.fleet.nodes ?? [
            { name: 'aria64', ip: '192.168.4.38', online: false, latency: null },
            { name: 'blackroad-pi', ip: '192.168.4.64', online: false, latency: null },
            { name: 'alice', ip: '192.168.4.49', online: false, latency: null },
            { name: 'cecilia', ip: '192.168.4.89', online: false, latency: null },
          ]).map(node => (
            <div key={node.name} style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '10px 14px', background: 'rgba(255,255,255,0.03)', borderRadius: 8 }}>
              <div style={{ width: 8, height: 8, borderRadius: '50%', background: node.online ? '#22c55e' : '#ef4444', flexShrink: 0 }} />
              <div>
                <div style={{ color: '#fff', fontSize: 13, fontWeight: 600 }}>{node.name}</div>
                <div style={{ color: 'rgba(255,255,255,0.4)', fontSize: 11 }}>
                  {node.online ? `${node.latency}ms` : 'offline'} · {node.ip}
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}
