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

export default function LandingPage() {
  return (
    <div className="min-h-screen bg-black text-white overflow-hidden">
      {/* Live stats bar */}
      <LiveStatsBar />
      {/* Animated background gradient */}
      <div className="fixed inset-0 bg-gradient-to-br from-black via-black to-violet-950/20 pointer-events-none" />
      <div className="fixed inset-0 opacity-30 pointer-events-none">
        <div className="absolute top-1/4 left-1/4 w-96 h-96 bg-hot-pink/20 rounded-full blur-3xl animate-pulse" />
        <div className="absolute bottom-1/4 right-1/4 w-96 h-96 bg-electric-blue/20 rounded-full blur-3xl animate-pulse delay-1000" />
      </div>

      {/* Navigation */}
      <header className="relative z-50 border-b border-white/10">
        <nav className="max-w-7xl mx-auto px-6 py-5 flex items-center justify-between">
          <Link href="/" className="flex items-center gap-2">
            <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-amber-500 via-hot-pink to-violet-600 flex items-center justify-center">
              <span className="text-white font-bold text-lg">B</span>
            </div>
            <span className="text-2xl font-semibold">
              BlackRoad<span className="bg-gradient-to-r from-hot-pink to-electric-blue bg-clip-text text-transparent"> OS</span>
            </span>
          </Link>

          <div className="hidden md:flex items-center gap-8">
            <Link href="#features" className="text-gray-400 hover:text-white transition-colors">Features</Link>
            <Link href="#agents" className="text-gray-400 hover:text-white transition-colors">Agents</Link>
            <Link href="#pricing" className="text-gray-400 hover:text-white transition-colors">Pricing</Link>
            <Link href="/login" className="text-gray-400 hover:text-white transition-colors">Sign In</Link>
            <Link
              href="/signup"
              className="px-5 py-2.5 bg-gradient-to-r from-hot-pink to-violet-600 hover:from-hot-pink/90 hover:to-violet-600/90 rounded-lg font-medium transition-all hover:shadow-lg hover:shadow-hot-pink/25"
            >
              Get Started
            </Link>
          </div>
        </nav>
      </header>

      {/* Hero Section */}
      <section className="relative z-10 max-w-7xl mx-auto px-6 pt-24 pb-32">
        <div className="text-center max-w-4xl mx-auto">
          <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-white/5 border border-white/10 mb-8">
            <Sparkles className="w-4 h-4 text-amber-500" />
            <span className="text-sm text-gray-300">Powered by Advanced AI Orchestration</span>
          </div>

          <h1 className="text-5xl md:text-7xl font-bold leading-tight mb-8">
            Build the Future with{' '}
            <span className="bg-gradient-to-r from-amber-500 via-hot-pink to-electric-blue bg-clip-text text-transparent">
              AI Agents
            </span>
          </h1>

          <p className="text-xl text-gray-400 mb-12 max-w-2xl mx-auto leading-relaxed">
            Deploy autonomous AI agents at scale. BlackRoad OS provides the infrastructure
            to orchestrate, govern, and monitor thousands of intelligent agents.
          </p>

          <div className="flex flex-col sm:flex-row items-center justify-center gap-4">
            <Link
              href="/signup"
              className="group flex items-center gap-2 px-8 py-4 bg-gradient-to-r from-hot-pink to-violet-600 rounded-xl font-semibold text-lg transition-all hover:shadow-xl hover:shadow-hot-pink/30 hover:scale-105"
            >
              Start Building
              <ArrowRight className="w-5 h-5 group-hover:translate-x-1 transition-transform" />
            </Link>
            <Link
              href="#features"
              className="flex items-center gap-2 px-8 py-4 border border-white/20 hover:border-white/40 rounded-xl font-semibold text-lg transition-all hover:bg-white/5"
            >
              Learn More
              <ChevronRight className="w-5 h-5" />
            </Link>
          </div>
        </div>

        {/* Stats */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-8 mt-24 pt-12 border-t border-white/10">
          {[
            { value: '30K+', label: 'Active Agents' },
            { value: '15', label: 'Organizations' },
            { value: '99.9%', label: 'Uptime' },
            { value: '< 50ms', label: 'Latency' },
          ].map((stat) => (
            <div key={stat.label} className="text-center">
              <div className="text-4xl md:text-5xl font-bold bg-gradient-to-r from-amber-500 to-hot-pink bg-clip-text text-transparent">
                {stat.value}
              </div>
              <div className="text-gray-500 mt-2">{stat.label}</div>
            </div>
          ))}
        </div>
      </section>

      {/* Features Section */}
      <section id="features" className="relative z-10 py-32 border-t border-white/10">
        <div className="max-w-7xl mx-auto px-6">
          <div className="text-center mb-16">
            <h2 className="text-4xl md:text-5xl font-bold mb-6">
              Everything You Need to{' '}
              <span className="bg-gradient-to-r from-electric-blue to-violet-500 bg-clip-text text-transparent">
                Scale AI
              </span>
            </h2>
            <p className="text-xl text-gray-400 max-w-2xl mx-auto">
              Enterprise-grade infrastructure for deploying and managing AI agent fleets.
            </p>
          </div>

          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-8">
            {[
              {
                icon: Cpu,
                title: 'Agent Orchestration',
                description: 'Deploy and manage thousands of AI agents with automated scaling and load balancing.',
                gradient: 'from-amber-500 to-orange-600',
              },
              {
                icon: Shield,
                title: 'Governance & Safety',
                description: 'Built-in guardrails, audit logging, and policy enforcement for responsible AI deployment.',
                gradient: 'from-hot-pink to-violet-600',
              },
              {
                icon: Zap,
                title: 'Real-time Monitoring',
                description: 'Live dashboards, performance metrics, and alerting for complete observability.',
                gradient: 'from-electric-blue to-cyan-500',
              },
              {
                icon: Globe,
                title: 'Global Edge Network',
                description: 'Deploy agents across 200+ edge locations for minimal latency worldwide.',
                gradient: 'from-violet-500 to-purple-600',
              },
              {
                icon: Sparkles,
                title: 'Multi-Model Support',
                description: 'Seamlessly integrate with Claude, GPT, Llama, and custom models.',
                gradient: 'from-amber-500 to-hot-pink',
              },
              {
                icon: ArrowRight,
                title: 'API-First Design',
                description: 'RESTful APIs and SDKs for TypeScript, Python, Go, and Rust.',
                gradient: 'from-electric-blue to-violet-600',
              },
            ].map((feature) => (
              <div
                key={feature.title}
                className="group p-8 rounded-2xl bg-white/5 border border-white/10 hover:border-white/20 transition-all hover:bg-white/[0.07]"
              >
                <div className={`inline-flex p-3 rounded-xl bg-gradient-to-br ${feature.gradient} mb-6`}>
                  <feature.icon className="w-6 h-6 text-white" />
                </div>
                <h3 className="text-xl font-semibold mb-3">{feature.title}</h3>
                <p className="text-gray-400 leading-relaxed">{feature.description}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* CTA Section */}
      <section className="relative z-10 py-32">
        <div className="max-w-4xl mx-auto px-6 text-center">
          <div className="p-12 rounded-3xl bg-gradient-to-br from-white/10 to-white/5 border border-white/10">
            <h2 className="text-4xl md:text-5xl font-bold mb-6">
              Ready to Build?
            </h2>
            <p className="text-xl text-gray-400 mb-10">
              Join the next generation of AI-powered organizations.
            </p>
            <Link
              href="/signup"
              className="inline-flex items-center gap-2 px-10 py-5 bg-gradient-to-r from-hot-pink to-violet-600 rounded-xl font-semibold text-lg transition-all hover:shadow-xl hover:shadow-hot-pink/30 hover:scale-105"
            >
              Get Started Free
              <ArrowRight className="w-5 h-5" />
            </Link>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="relative z-10 border-t border-white/10 py-12">
        <div className="max-w-7xl mx-auto px-6">
          <div className="flex flex-col md:flex-row items-center justify-between gap-6">
            <div className="flex items-center gap-2">
              <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-amber-500 via-hot-pink to-violet-600" />
              <span className="font-semibold">BlackRoad OS</span>
            </div>
            <div className="flex items-center gap-6 text-sm text-gray-500">
              <Link href="/workspace" className="hover:text-white transition-colors">Dashboard</Link>
              <Link href="/agents" className="hover:text-white transition-colors">Agents</Link>
              <a href="https://blackroad.io" target="_blank" rel="noreferrer" className="hover:text-white transition-colors">Website</a>
              <a href="https://github.com/BlackRoad-OS-Inc" target="_blank" rel="noreferrer" className="hover:text-white transition-colors">GitHub</a>
            </div>
            <p className="text-gray-500 text-sm">
              © 2026 BlackRoad OS, Inc. All rights reserved.
            </p>
          </div>
        </div>
      </footer>
    </div>
  );
}
