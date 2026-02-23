'use client';

import { useState, useEffect } from 'react';
import { ArrowRight, Globe, Server, Cpu, Shield, RefreshCw } from 'lucide-react';

interface TunnelRoute { hostname: string; service: string; pi: string; group: string; }
interface Node { name: string; ip: string; role: string; capacity: number; status: string; services: string[]; }

const GROUP_COLORS: Record<string, string> = {
  PRIMARY: '#FF1D6C', SECONDARY: '#2979FF', TERTIARY: '#F5A623', IDENTITY: '#9C27B0',
};

const PI_ICONS: Record<string, typeof Server> = {
  aria64: Cpu, 'blackroad-pi': Server, alice: Shield, cecilia: Globe,
};

export default function NetworkPage() {
  const [tunnel, setTunnel] = useState<{ routes: TunnelRoute[]; by_pi: Record<string, TunnelRoute[]>; tunnel_id: string } | null>(null);
  const [fleet, setFleet] = useState<{ nodes: Node[] } | null>(null);
  const [loading, setLoading] = useState(true);

  const load = async () => {
    try {
      const [t, f] = await Promise.all([fetch('/api/tunnel'), fetch('/api/fleet')]);
      if (t.ok) setTunnel(await t.json());
      if (f.ok) setFleet(await f.json());
    } catch {}
    setLoading(false);
  };
  useEffect(() => { load(); }, []);

  const nodes = fleet?.nodes ?? [];
  const byPi = tunnel?.by_pi ?? {};

  return (
    <div className="min-h-screen bg-black text-white p-8">
      <div className="flex items-start justify-between mb-8">
        <div>
          <h1 className="text-3xl font-bold">Network</h1>
          <p className="text-gray-400 mt-1">Cloudflare Edge → Tunnel → Pi Fleet → Services</p>
        </div>
        <button onClick={load} className="flex items-center gap-2 px-4 py-2 rounded-lg bg-white/5 hover:bg-white/10 text-sm text-gray-400 transition-all">
          <RefreshCw className={`w-4 h-4 ${loading ? 'animate-spin' : ''}`} />
          Refresh
        </button>
      </div>

      {/* Tunnel header */}
      <div className="rounded-2xl bg-gradient-to-r from-white/5 to-white/3 border border-white/10 p-6 mb-6">
        <div className="flex items-center gap-4">
          <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-amber-500 via-[#FF1D6C] to-violet-600 flex items-center justify-center flex-shrink-0">
            <Globe className="w-6 h-6 text-white" />
          </div>
          <div>
            <p className="text-sm text-gray-400 uppercase tracking-wider">Cloudflare Tunnel</p>
            <p className="font-mono text-white font-bold">{tunnel?.tunnel_id ?? '8ae67ab0-71fb-4461-befc-a91302369a7e'}</p>
            <p className="text-xs text-gray-500 mt-0.5">{tunnel?.routes.length ?? 14} routes · QUIC protocol · Dallas edge</p>
          </div>
          <div className="ml-auto flex items-center gap-2">
            <div className="w-2 h-2 rounded-full bg-green-400 animate-pulse" />
            <span className="text-sm text-green-400">Active</span>
          </div>
        </div>
      </div>

      {/* Topology grid */}
      <div className="flex items-start gap-4 mb-8 overflow-x-auto pb-4">
        {/* CF Edge */}
        <div className="flex-shrink-0 rounded-2xl bg-white/5 border border-white/10 p-5 w-52">
          <p className="text-xs text-gray-500 uppercase tracking-wider mb-3">Cloudflare Edge</p>
          <div className="space-y-1">
            {['*.blackroad.io', '*.blackroad.ai', 'CNAME → tunnel'].map(d => (
              <div key={d} className="text-xs text-gray-400 font-mono bg-white/5 rounded px-2 py-1">{d}</div>
            ))}
          </div>
        </div>

        {/* Arrow */}
        <div className="flex-shrink-0 flex items-center justify-center h-full pt-10">
          <ArrowRight className="w-6 h-6 text-[#FF1D6C]" />
        </div>

        {/* Pi nodes */}
        {nodes.map((node) => {
          const Icon = PI_ICONS[node.name] ?? Server;
          const color = GROUP_COLORS[node.role] ?? '#888';
          const routes = byPi[node.name] ?? [];
          return (
            <div key={node.name} className="flex-shrink-0" style={{ minWidth: '220px' }}>
              <div className="rounded-2xl border p-5 h-full" style={{ borderColor: color + '44', backgroundColor: color + '0d' }}>
                {/* Node header */}
                <div className="flex items-center gap-3 mb-3">
                  <div className="w-9 h-9 rounded-lg flex items-center justify-center" style={{ backgroundColor: color + '22' }}>
                    <Icon className="w-5 h-5" style={{ color }} />
                  </div>
                  <div>
                    <p className="font-bold text-sm">{node.name}</p>
                    <p className="text-xs text-gray-500">{node.ip}</p>
                  </div>
                  <div className="ml-auto">
                    <div className={`w-2 h-2 rounded-full ${node.status === 'online' ? 'bg-green-400 animate-pulse' : 'bg-gray-600'}`} />
                  </div>
                </div>

                <div className="text-xs font-bold px-2 py-0.5 rounded-full inline-block mb-3" style={{ backgroundColor: color + '22', color }}>
                  {node.role} {node.capacity > 0 && `· ${(node.capacity/1000).toFixed(1)}k slots`}
                </div>

                {/* Routes */}
                <div className="space-y-1">
                  {routes.map(r => (
                    <div key={r.hostname} className="flex items-center gap-1.5 text-xs">
                      <ArrowRight className="w-2.5 h-2.5 flex-shrink-0" style={{ color }} />
                      <a href={`https://${r.hostname}`} target="_blank" rel="noreferrer"
                        className="font-mono truncate hover:underline" style={{ color }}>
                        {r.hostname}
                      </a>
                    </div>
                  ))}
                  {routes.length === 0 && (
                    <p className="text-xs text-gray-600 italic">No tunnel routes</p>
                  )}
                </div>
              </div>
            </div>
          );
        })}
      </div>

      {/* Stats footer */}
      <div className="grid grid-cols-4 gap-4">
        {[
          { label: 'Total Routes', value: tunnel?.routes.length ?? 14, color: '#FF1D6C' },
          { label: 'Pi Nodes', value: nodes.length || 4, color: '#2979FF' },
          { label: 'Online', value: nodes.filter(n => n.status === 'online').length || '—', color: '#22c55e' },
          { label: 'Agent Slots', value: '30,000', color: '#9C27B0' },
        ].map(s => (
          <div key={s.label} className="rounded-xl bg-white/5 border border-white/10 px-4 py-3 flex items-center justify-between">
            <span className="text-sm text-gray-400">{s.label}</span>
            <span className="font-bold font-mono" style={{ color: s.color }}>{s.value}</span>
          </div>
        ))}
      </div>
    </div>
  );
}
