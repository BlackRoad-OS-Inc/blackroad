'use client';

import { useEffect, useState, useCallback } from 'react';

// ── types ─────────────────────────────────────────────────────────────────────
interface Service {
  name: string;
  status: 'operational' | 'degraded' | 'down';
  latencyMs: number;
}

interface StatusData {
  status: string;
  score: number;
  services: Service[];
  summary: { operational: number; degraded: number; down: number; total: number };
  platform: { workers: number; tunnel_routes: number; agent_capacity: number; orgs: number; repos: number };
  timestamp: string;
}

interface Agent {
  id: string;
  name: string;
  role: string;
  status: string;
  node: string;
  color: string;
  skills: string[];
  tasks: number;
  uptime: number;
}

interface AgentsData {
  agents: Agent[];
  total: number;
  active: number;
}

// ── helpers ───────────────────────────────────────────────────────────────────
const PI_FLEET = [
  { name: 'octavia',    ip: '192.168.4.38', role: 'Primary — 22,500 agents', port: 8080 },
  { name: 'lucidia',   ip: '192.168.4.64', role: 'Secondary — 7,500 agents', port: 11434 },
  { name: 'alice',     ip: '192.168.4.49', role: 'Mesh node',               port: 8001 },
  { name: 'cecilia',   ip: '192.168.4.89', role: 'Identity node',           port: 80 },
];

function statusColor(s?: string) {
  if (s === 'operational') return '#4ade80';
  if (s === 'degraded')    return '#F5A623';
  return '#ef4444';
}

function statusLabel(s?: string) {
  if (s === 'operational') return 'All Systems Operational';
  if (s === 'partial_outage') return 'Partial Outage';
  if (s === 'major_outage')   return 'Major Outage';
  return 'Checking…';
}

function timeAgo(iso?: string) {
  if (!iso) return '';
  const secs = Math.floor((Date.now() - new Date(iso).getTime()) / 1000);
  if (secs < 5)   return 'just now';
  if (secs < 60)  return `${secs}s ago`;
  return `${Math.floor(secs / 60)}m ago`;
}

// ── sub-components ────────────────────────────────────────────────────────────
function MetricCard({ label, value, color }: { label: string; value: string | number; color: string }) {
  return (
    <div className="rounded-xl border border-white/10 bg-white/[0.04] p-5 flex flex-col gap-1">
      <div className="text-3xl font-bold" style={{ color }}>{value}</div>
      <div className="text-xs text-gray-500 uppercase tracking-widest">{label}</div>
    </div>
  );
}

function ServiceRow({ svc }: { svc: Service }) {
  const dot = statusColor(svc.status);
  return (
    <div className="flex items-center justify-between py-2.5 border-b border-white/5 last:border-0">
      <div className="flex items-center gap-2">
        <span className="w-2 h-2 rounded-full" style={{ backgroundColor: dot, boxShadow: svc.status === 'operational' ? `0 0 6px ${dot}` : 'none' }} />
        <span className="text-sm text-gray-300">{svc.name}</span>
      </div>
      <div className="flex items-center gap-3">
        {svc.latencyMs > 0 && (
          <span className="text-xs text-gray-600">{svc.latencyMs}ms</span>
        )}
        <span className="text-xs font-medium capitalize" style={{ color: dot }}>{svc.status}</span>
      </div>
    </div>
  );
}

function AgentCard({ agent }: { agent: Agent }) {
  const active = agent.status === 'active' || agent.status === 'online';
  return (
    <div className="rounded-xl border border-white/10 bg-white/[0.04] p-4 hover:bg-white/[0.07] transition-colors">
      <div className="flex items-start justify-between mb-3">
        <div>
          <div className="flex items-center gap-2">
            <span className={`w-2 h-2 rounded-full ${active ? 'animate-pulse' : ''}`}
              style={{ backgroundColor: active ? '#4ade80' : '#ef4444' }} />
            <span className="font-semibold text-white">{agent.name}</span>
          </div>
          <div className="text-xs text-gray-500 mt-0.5">{agent.role} · {agent.node}</div>
        </div>
        <span className="text-xs px-2 py-0.5 rounded-full border"
          style={{ color: agent.color, borderColor: agent.color + '40', backgroundColor: agent.color + '15' }}>
          {agent.status}
        </span>
      </div>
      <div className="flex flex-wrap gap-1 mb-3">
        {agent.skills.map(s => (
          <span key={s} className="text-xs px-1.5 py-0.5 rounded bg-white/5 text-gray-400">{s}</span>
        ))}
      </div>
      <div className="flex justify-between text-xs text-gray-500">
        <span>{agent.tasks.toLocaleString()} tasks</span>
        <span>{agent.uptime}% uptime</span>
      </div>
    </div>
  );
}

function PiNode({ node, online }: { node: typeof PI_FLEET[0]; online: boolean }) {
  return (
    <div className="rounded-xl border border-white/10 bg-white/[0.04] p-4">
      <div className="flex items-center gap-2 mb-1">
        <span className={`w-2 h-2 rounded-full ${online ? 'bg-green-400 animate-pulse' : 'bg-red-500'}`} />
        <span className="font-medium text-white capitalize">{node.name}</span>
      </div>
      <div className="text-xs text-gray-500 font-mono mb-1">{node.ip}:{node.port}</div>
      <div className="text-xs text-gray-600">{node.role}</div>
    </div>
  );
}

// ── main dashboard ────────────────────────────────────────────────────────────
export default function DashboardPage() {
  const [status,   setStatus]   = useState<StatusData | null>(null);
  const [agents,   setAgents]   = useState<AgentsData | null>(null);
  const [loading,  setLoading]  = useState(true);
  const [lastTick, setLastTick] = useState('');
  const [countdown, setCountdown] = useState(30);

  const refresh = useCallback(async () => {
    const [s, a] = await Promise.allSettled([
      fetch('/api/status').then(r => r.json()),
      fetch('/api/agents').then(r => r.json()),
    ]);
    if (s.status === 'fulfilled') setStatus(s.value);
    if (a.status === 'fulfilled') setAgents(a.value);
    setLoading(false);
    setLastTick(new Date().toISOString());
    setCountdown(30);
  }, []);

  useEffect(() => {
    refresh();
    const interval = setInterval(refresh, 30_000);
    return () => clearInterval(interval);
  }, [refresh]);

  // countdown ticker
  useEffect(() => {
    const t = setInterval(() => setCountdown(c => c > 0 ? c - 1 : 0), 1000);
    return () => clearInterval(t);
  }, []);

  const overallColor = statusColor(status?.status === 'operational' ? 'operational' : status?.status === 'partial_outage' ? 'degraded' : 'down');

  // map Pi nodes to online status from services
  const piOnline = (name: string) => {
    if (!status?.services) return false;
    const svc = status.services.find(s => s.name.toLowerCase().includes(name.toLowerCase()));
    return svc?.status === 'operational';
  };

  return (
    <div className="min-h-screen bg-black text-white font-sans">
      {/* header */}
      <header className="border-b border-white/10 px-6 py-4">
        <div className="max-w-7xl mx-auto flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-9 h-9 rounded-xl flex items-center justify-center font-bold text-lg"
              style={{ background: 'linear-gradient(135deg,#F5A623,#FF1D6C,#9C27B0,#2979FF)' }}>B</div>
            <div>
              <span className="font-semibold text-lg">BlackRoad OS</span>
              <span className="ml-2 text-xs text-gray-500 uppercase tracking-widest">Infrastructure</span>
            </div>
          </div>
          <div className="flex items-center gap-4 text-xs text-gray-500">
            <span className="flex items-center gap-1.5">
              <span className="w-1.5 h-1.5 rounded-full animate-pulse" style={{ backgroundColor: overallColor }} />
              <span style={{ color: overallColor }}>{loading ? 'Loading…' : statusLabel(status?.status)}</span>
            </span>
            <span>· Updated {timeAgo(lastTick)}</span>
            <span className="text-gray-700">· refresh in {countdown}s</span>
          </div>
        </div>
      </header>

      <main className="max-w-7xl mx-auto px-6 py-8 space-y-8">

        {/* key metrics */}
        <section>
          <h2 className="text-xs text-gray-500 uppercase tracking-widest mb-4">Platform Scale</h2>
          <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-6 gap-3">
            <MetricCard label="Agents"       value={status?.platform.agent_capacity?.toLocaleString() ?? '30,000'} color="#FF1D6C" />
            <MetricCard label="Orgs"         value={status?.platform.orgs ?? 17}         color="#F5A623" />
            <MetricCard label="Repos"        value={status?.platform.repos?.toLocaleString() ?? '1,825+'} color="#2979FF" />
            <MetricCard label="CF Workers"   value={status?.platform.workers ?? 499}     color="#9C27B0" />
            <MetricCard label="Score"        value={loading ? '…' : `${status?.score ?? 0}%`} color="#4ade80" />
            <MetricCard label="Services"     value={status ? `${status.summary.operational}/${status.summary.total}` : '…'} color="#F5A623" />
          </div>
        </section>

        {/* main grid: services + agents */}
        <div className="grid lg:grid-cols-2 gap-6">

          {/* services */}
          <section className="rounded-2xl border border-white/10 bg-white/[0.02] p-6">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-sm font-semibold text-white">Service Health</h2>
              <div className="flex gap-3 text-xs">
                <span className="text-green-400">{status?.summary.operational ?? '—'} up</span>
                <span className="text-yellow-400">{status?.summary.degraded ?? '—'} degraded</span>
                <span className="text-red-400">{status?.summary.down ?? '—'} down</span>
              </div>
            </div>
            {loading ? (
              <div className="space-y-2">
                {[...Array(6)].map((_, i) => (
                  <div key={i} className="h-8 rounded bg-white/5 animate-pulse" />
                ))}
              </div>
            ) : (
              <div>{status?.services.map(s => <ServiceRow key={s.name} svc={s} />)}</div>
            )}
          </section>

          {/* agent roster */}
          <section className="rounded-2xl border border-white/10 bg-white/[0.02] p-6">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-sm font-semibold text-white">Agent Roster</h2>
              <span className="text-xs text-gray-500">{agents?.active ?? '—'} active / {agents?.total ?? '—'} total</span>
            </div>
            {loading ? (
              <div className="grid grid-cols-2 gap-3">
                {[...Array(4)].map((_, i) => (
                  <div key={i} className="h-28 rounded-xl bg-white/5 animate-pulse" />
                ))}
              </div>
            ) : (
              <div className="grid grid-cols-2 gap-3 max-h-96 overflow-y-auto">
                {(agents?.agents ?? []).map(a => <AgentCard key={a.id} agent={a} />)}
              </div>
            )}
          </section>
        </div>

        {/* Pi fleet */}
        <section className="rounded-2xl border border-white/10 bg-white/[0.02] p-6">
          <h2 className="text-sm font-semibold text-white mb-4">Pi Fleet</h2>
          <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
            {PI_FLEET.map(n => (
              <PiNode key={n.name} node={n} online={piOnline(n.name)} />
            ))}
          </div>
        </section>

        {/* footer */}
        <footer className="text-center text-xs text-gray-700 pb-4">
          © 2026 BlackRoad OS, Inc. · All rights reserved ·{' '}
          <a href="https://github.com/BlackRoad-OS-Inc" target="_blank" rel="noreferrer" className="hover:text-gray-500 transition-colors">GitHub</a>
        </footer>
      </main>
    </div>
  );
}

