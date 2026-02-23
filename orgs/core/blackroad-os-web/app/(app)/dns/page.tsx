'use client'
import { useEffect, useState } from 'react'
import { Globe, ChevronRight, ChevronDown, RefreshCw, ExternalLink, Shield, AlertCircle } from 'lucide-react'

interface Zone { id: string; name: string; status: string; nameservers: string[]; plan: string; recordCount: number | null }
interface DnsRecord { id: string; type: string; name: string; content: string; ttl: number; proxied: boolean }

const TYPE_COLORS: Record<string, string> = {
  A: '#22c55e', AAAA: '#2979FF', CNAME: '#F5A623', MX: '#9C27B0',
  TXT: '#06b6d4', NS: '#aaa', SRV: '#FF1D6C', CAA: '#f97316',
}

export default function DnsPage() {
  const [zones, setZones] = useState<Zone[]>([])
  const [loading, setLoading] = useState(true)
  const [expanded, setExpanded] = useState<string | null>(null)
  const [records, setRecords] = useState<Record<string, DnsRecord[]>>({})
  const [loadingZone, setLoadingZone] = useState<string | null>(null)
  const [live, setLive] = useState(false)
  const [search, setSearch] = useState('')

  useEffect(() => {
    fetch('/api/dns').then(r => r.json()).then(d => {
      setZones(d.zones || [])
      setLive(d.live ?? false)
      setLoading(false)
    }).catch(() => setLoading(false))
  }, [])

  const toggleZone = async (zone: Zone) => {
    if (expanded === zone.id) { setExpanded(null); return }
    setExpanded(zone.id)
    if (!records[zone.id] && live && zone.id !== `zone-${zones.indexOf(zone)}`) {
      setLoadingZone(zone.id)
      try {
        const r = await fetch(`/api/dns?zone=${zone.id}`)
        const d = await r.json()
        setRecords(prev => ({ ...prev, [zone.id]: d.records || [] }))
      } finally { setLoadingZone(null) }
    }
  }

  const filtered = zones.filter(z => !search || z.name.includes(search.toLowerCase()))

  return (
    <div style={{ padding: 32, maxWidth: 900 }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 28 }}>
        <Globe size={28} style={{ color: '#2979FF' }} />
        <div>
          <h1 style={{ fontSize: 24, fontWeight: 700, color: '#fff', margin: 0 }}>DNS Zones</h1>
          <p style={{ color: 'rgba(255,255,255,0.4)', fontSize: 13, margin: 0 }}>
            {zones.length} zones · Cloudflare {live ? '● live' : '○ cached'}
          </p>
        </div>
        {!live && (
          <div style={{ marginLeft: 'auto', display: 'flex', alignItems: 'center', gap: 6, padding: '4px 12px', background: 'rgba(245,166,35,0.1)', border: '1px solid rgba(245,166,35,0.3)', borderRadius: 20, fontSize: 12, color: '#F5A623' }}>
            <AlertCircle size={12} />Set CLOUDFLARE_API_TOKEN for live data
          </div>
        )}
      </div>

      <input
        value={search}
        onChange={e => setSearch(e.target.value)}
        placeholder="Search zones…"
        style={{ width: '100%', background: 'rgba(255,255,255,0.06)', border: '1px solid rgba(255,255,255,0.1)', borderRadius: 8, padding: '10px 14px', color: '#fff', fontSize: 13, outline: 'none', marginBottom: 16, boxSizing: 'border-box' }}
      />

      {loading ? (
        <div style={{ color: 'rgba(255,255,255,0.3)', textAlign: 'center', padding: 40 }}>Loading zones…</div>
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
          {filtered.map(zone => (
            <div key={zone.id} style={{ background: 'rgba(255,255,255,0.04)', border: `1px solid ${expanded === zone.id ? 'rgba(41,121,255,0.4)' : 'rgba(255,255,255,0.07)'}`, borderRadius: 10, overflow: 'hidden', transition: 'border-color .2s' }}>
              <div onClick={() => toggleZone(zone)} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '14px 18px', cursor: 'pointer' }}>
                {expanded === zone.id ? <ChevronDown size={15} style={{ color: '#2979FF' }} /> : <ChevronRight size={15} style={{ color: 'rgba(255,255,255,0.3)' }} />}
                <div style={{ width: 8, height: 8, borderRadius: '50%', background: zone.status === 'active' ? '#22c55e' : '#F5A623', flexShrink: 0 }} />
                <span style={{ color: '#fff', fontWeight: 600, fontSize: 14, flex: 1 }}>{zone.name}</span>
                <span style={{ color: 'rgba(255,255,255,0.3)', fontSize: 11, background: 'rgba(255,255,255,0.05)', padding: '2px 8px', borderRadius: 10 }}>{zone.plan}</span>
                <a href={`https://${zone.name}`} target="_blank" rel="noreferrer" onClick={e => e.stopPropagation()} style={{ color: 'rgba(255,255,255,0.2)' }}>
                  <ExternalLink size={12} />
                </a>
              </div>

              {expanded === zone.id && (
                <div style={{ borderTop: '1px solid rgba(255,255,255,0.06)', padding: '14px 18px' }}>
                  {/* Nameservers */}
                  <div style={{ marginBottom: 14 }}>
                    <div style={{ color: 'rgba(255,255,255,0.4)', fontSize: 11, fontWeight: 600, textTransform: 'uppercase', letterSpacing: 1, marginBottom: 6 }}>Nameservers</div>
                    <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
                      {zone.nameservers.map(ns => (
                        <span key={ns} style={{ fontSize: 12, fontFamily: 'monospace', background: 'rgba(41,121,255,0.1)', color: '#2979FF', padding: '3px 10px', borderRadius: 6 }}>
                          <Shield size={10} style={{ display: 'inline', marginRight: 4 }} />{ns}
                        </span>
                      ))}
                    </div>
                  </div>
                  {/* DNS Records */}
                  {loadingZone === zone.id ? (
                    <div style={{ color: 'rgba(255,255,255,0.3)', fontSize: 13 }}><RefreshCw size={12} style={{ display: 'inline', marginRight: 6, animation: 'spin 1s linear infinite' }} />Loading records…</div>
                  ) : records[zone.id]?.length ? (
                    <div>
                      <div style={{ color: 'rgba(255,255,255,0.4)', fontSize: 11, fontWeight: 600, textTransform: 'uppercase', letterSpacing: 1, marginBottom: 8 }}>DNS Records ({records[zone.id].length})</div>
                      <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
                        {records[zone.id].map(rec => (
                          <div key={rec.id} style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '6px 10px', background: 'rgba(255,255,255,0.03)', borderRadius: 6 }}>
                            <span style={{ fontSize: 10, fontWeight: 700, padding: '1px 6px', borderRadius: 4, background: `${TYPE_COLORS[rec.type] || '#888'}22`, color: TYPE_COLORS[rec.type] || '#888', minWidth: 36, textAlign: 'center' }}>{rec.type}</span>
                            <span style={{ color: '#fff', fontSize: 12, fontFamily: 'monospace', minWidth: 180 }}>{rec.name}</span>
                            <span style={{ color: 'rgba(255,255,255,0.4)', fontSize: 12, fontFamily: 'monospace', flex: 1, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{rec.content}</span>
                            {rec.proxied && <span style={{ fontSize: 10, color: '#F5A623', background: 'rgba(245,166,35,0.1)', padding: '1px 6px', borderRadius: 4 }}>☁ proxied</span>}
                          </div>
                        ))}
                      </div>
                    </div>
                  ) : (
                    <div style={{ color: 'rgba(255,255,255,0.25)', fontSize: 12 }}>
                      {live ? 'No records found' : 'Add CLOUDFLARE_API_TOKEN to Vercel env to view DNS records'}
                    </div>
                  )}
                </div>
              )}
            </div>
          ))}
        </div>
      )}
    </div>
  )
}
