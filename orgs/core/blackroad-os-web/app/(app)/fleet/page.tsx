'use client';

import { useState, useEffect } from 'react';
import { Cpu, Globe, Wifi, WifiOff, Activity, Zap, Server, ArrowRight } from 'lucide-react';
import Link from 'next/link';

interface Node {
  name: string; ip: string; role: string; capacity: number;
  model: string; status: string; latencyMs: number; services: string[];
}
interface TunnelRoute { hostname: string; service: string; pi: string; group: string; }
interface FleetData { nodes: Node[]; summary: { total_nodes: number; online_nodes: number; total_capacity: number; tunnel_routes: number }; }
interface TunnelData { routes: TunnelRoute[]; by_pi: Record<string, TunnelRoute[]>; tunnel_id: string; }

const ROLE_COLORS: Record<string, string> = {
  PRIMARY: '#FF1D6C', SECONDARY: '#2979FF', TERTIARY: '#F5A623', IDENTITY: '#9C27B0',
};

const ROLE_GLOW: Record<string, string> = {
  PRIMARY: 'shadow-[0_0_20px_rgba(255,29,108,0.3)]',
  SECONDARY: 'shadow-[0_0_20px_rgba(41,121,255,0.3)]',
  TERTIARY: 'shadow-[0_0_20px_rgba(245,166,35,0.3)]',
  IDENTITY: 'shadow-[0_0_20px_rgba(156,39,176,0.3)]',
};

export default function FleetPage() {
  const [fleet, setFleet] = useState<FleetData | null>(null);
  const [tunnel, setTunnel] = useState<TunnelData | null>(null);
  const [loading, setLoading] = useState(true);
  const [lastChecked, setLastChecked] = useState('');

  const load = async () => {
    try {
      const [f, t] = await Promise.all([fetch('/api/fleet'), fetch('/api/tunnel')]);
      if (f.ok) setFleet(await f.json());
      if (t.ok) setTunnel(await t.json());
      setLastChecked(new Date().toLocaleTimeString());
    } catch {}
    setLoading(false);
  };

  useEffect(() => { load(); const iv = setInterval(load, 30000); return () => clearInterval(iv); }, []);

  const onlineCount = fleet?.summary.online_nodes ?? 0;
  const totalCapacity = fleet?.summary.total_capacity ?? 30000;
  const tunnelRoutes = fleet?.summary.tunnel_routes ?? 14;

  return (
    <div className="min-h-screen bg-black text-white p-8">
      {/* Header */}
      <div className="mb-8">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-3xl font-bold">Pi Fleet</h1>
            <p className="text-gray-400 mt-1">Cloudflare Tunnel → Raspberry Pi Network</p>
          </div>
          <button onClick={load} className="flex items-center gap-2 px-4 py-2 rounded-lg bg-white/5 hover:bg-white/10 text-sm text-gray-400 transition-all">
            <Activity className="w-4 h-4" />
            Refresh {lastChecked && <span className="text-gray-600">{lastChecked}</span>}
          </button>
        </div>
      </div>

      {/* Stats bar */}
      <div className="grid grid-cols-4 gap-4 mb-8">
        {[
          { label: 'Nodes', value: `${onlineCount}/${fleet?.summary.total_nodes ?? 4}`, icon: Server, color: '#22c55e' },
          { label: 'Agent Slots', value: totalCapacity.toLocaleString(), icon: Cpu, color: '#FF1D6C' },
          { label: 'Tunnel Routes', value: tunnelRoutes, icon: Globe, color: '#2979FF' },
          { label: 'Tunnel ID', value: '8ae67ab0', icon: Zap, color: '#F5A623' },
        ].map(s => (
          <div key={s.label} className="rounded-2xl bg-white/5 border border-white/10 p-5">
            <div className="flex items-center gap-3 mb-2">
              <s.icon className="w-5 h-5" style={{ color: s.color }} />
              <span className="text-sm text-gray-400">{s.label}</span>
            </div>
            <p className="text-2xl font-bold font-mono" style={{ color: s.color }}>{s.value}</p>
          </div>
        ))}
      </div>

      {/* Node cards */}
      <div className="grid grid-cols-2 gap-6 mb-8">
        {(fleet?.nodes ?? []).map(node => {
          const routes = tunnel?.by_pi[node.name] ?? [];
          const color = ROLE_COLORS[node.role] ?? '#fff';
          const glow = ROLE_GLOW[node.role] ?? '';
          return (
            <div key={node.name} className={`rounded-2xl bg-white/5 border border-white/10 p-6 ${glow} transition-all`}>
              {/* Node header */}
              <div className="flex items-start justify-between mb-4">
                <div className="flex items-center gap-3">
                  {node.status === 'online'
                    ? <Wifi className="w-5 h-5 text-green-400" />
                    : <WifiOff className="w-5 h-5 text-gray-600" />}
                  <div>
                    <h3 className="font-bold text-lg">{node.name}</h3>
                    <p className="text-sm text-gray-500">{node.ip} · {node.model}</p>
                  </div>
                </div>
                <div className="flex flex-col items-end gap-1">
                  <span className="text-xs font-bold px-2 py-1 rounded-full" style={{ backgroundColor: color + '22', color }}>
                    {node.role}
                  </span>
                  {node.capacity > 0 && (
                    <span className="text-xs text-gray-500">{node.capacity.toLocaleString()} slots</span>
                  )}
                </div>
              </div>

              {/* Latency */}
              <div className="flex items-center gap-2 mb-4">
                <div className={`w-2 h-2 rounded-full ${node.status === 'online' ? 'bg-green-400 animate-pulse' : 'bg-gray-600'}`} />
                <span className="text-xs text-gray-400">
                  {node.status === 'online'
                    ? node.latencyMs > 0 ? `${node.latencyMs}ms` : 'online'
                    : 'offline / unreachable'}
                </span>
              </div>

              {/* Routes */}
              {routes.length > 0 && (
                <div className="space-y-1">
                  <p className="text-xs text-gray-600 uppercase tracking-wider mb-2">Tunnel Routes</p>
                  {routes.map(r => (
                    <div key={r.hostname} className="flex items-center gap-2 text-sm">
                      <ArrowRight className="w-3 h-3 flex-shrink-0" style={{ color }} />
                      <a href={`https://${r.hostname}`} target="_blank" rel="noreferrer"
                        className="hover:underline truncate" style={{ color }}>
                        {r.hostname}
                      </a>
                      <span className="text-gray-600 text-xs ml-auto flex-shrink-0">
                        {r.service.split(':').pop()}
                      </span>
                    </div>
                  ))}
                </div>
              )}
            </div>
          );
        })}
      </div>

      {/* All routes table */}
      {tunnel && (
        <div className="rounded-2xl bg-white/5 border border-white/10 p-6">
          <h2 className="text-lg font-bold mb-4">All Tunnel Routes ({tunnel.routes.length})</h2>
          <div className="space-y-2">
            {tunnel.routes.map(r => (
              <div key={r.hostname} className="flex items-center gap-4 py-2 border-b border-white/5 last:border-0">
                <div className="w-2 h-2 rounded-full bg-green-400 flex-shrink-0" />
                <a href={`https://${r.hostname}`} target="_blank" rel="noreferrer"
                  className="text-sm font-mono hover:text-[#FF1D6C] transition-colors flex-1">
                  {r.hostname}
                </a>
                <span className="text-sm text-gray-500 font-mono">{r.service}</span>
                <span className="text-xs px-2 py-0.5 rounded-full"
                  style={{ backgroundColor: (ROLE_COLORS[r.group] ?? '#888') + '22', color: ROLE_COLORS[r.group] ?? '#888' }}>
                  {r.pi}
                </span>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
