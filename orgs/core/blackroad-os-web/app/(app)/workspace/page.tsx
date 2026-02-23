'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { Bot, Zap, Globe, Activity, Plus, ArrowRight, Terminal, Server, Radio } from 'lucide-react';
import { useAuthStore } from '@/stores/auth-store';

interface AgentData {
  agents: { id: string; name: string; role: string; status: string; node: string; color: string }[];
  fleet?: { total_capacity: number; online_nodes: number };
  fallback?: boolean;
}

interface StatusData {
  status: string;
  services: { name: string; status: string; latency?: number }[];
}

const QUICK_STARTS = [
  { id: 'new-lucidia', icon: '🌀', agent: 'Lucidia', title: 'Deep analysis', desc: 'Recursive reasoning & strategy', href: '/conversations/new?agent=lucidia' },
  { id: 'new-alice', icon: '🚪', agent: 'Alice', title: 'Run a task', desc: 'Deploy, automate, execute', href: '/conversations/new?agent=alice' },
  { id: 'new-octavia', icon: '⚡', agent: 'Octavia', title: 'Infra review', desc: 'Architecture & system health', href: '/conversations/new?agent=octavia' },
  { id: 'new-shellfish', icon: '🔐', agent: 'Shellfish', title: 'Security scan', desc: 'Audit, harden, verify', href: '/conversations/new?agent=shellfish' },
];

export default function WorkspacePage() {
  const user = useAuthStore((state) => state.user);
  const [agentData, setAgentData] = useState<AgentData | null>(null);
  const [statusData, setStatusData] = useState<StatusData | null>(null);
  const [analyticsData, setAnalyticsData] = useState<any>(null);
  const [recentConvs, setRecentConvs] = useState<{ id: string; title: string; agent: string; updatedAt?: string }[]>([]);

  useEffect(() => {
    fetch('/api/agents').then(r => r.json()).then(setAgentData).catch(() => {});
    fetch('/api/status').then(r => r.json()).then(setStatusData).catch(() => {});
    fetch('/api/analytics').then(r => r.json()).then(setAnalyticsData).catch(() => {});
    fetch('/api/conversations').then(r => r.ok ? r.json() : null).then(d => {
      if (d?.conversations?.length) setRecentConvs(d.conversations.slice(0, 3));
    }).catch(() => {});
  }, []);

  const INFRA_STATS_STATIC = [
    { label: 'CF Workers', value: analyticsData?.workers?.total?.toString() ?? '499', sub: 'edge functions', color: '#F5A623', icon: Radio },
    { label: 'CF Zones', value: '20', sub: 'domains managed', color: '#2979FF', icon: Globe },
    { label: 'Agent Capacity', value: analyticsData?.agents?.total?.toLocaleString() ?? '30,000', sub: `${analyticsData?.fleet?.online ?? '?'}/${analyticsData?.fleet?.total ?? 4} nodes online`, color: '#FF1D6C', icon: Bot },
    { label: 'GitHub Repos', value: '1,825+', sub: 'across 17 orgs', color: '#9C27B0', icon: Server },
  ];

  const hour = new Date().getHours();
  const greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';
  const firstName = user?.name?.split(' ')[0] || 'Alexa';
  const isOperational = statusData?.status === 'operational';

  return (
    <div className="min-h-full p-6 max-w-6xl mx-auto space-y-8">

      {/* Greeting */}
      <div className="pt-2 flex items-start justify-between">
        <div>
          <h1 className="text-3xl font-bold text-white">
            {greeting}, <span className="bg-gradient-to-r from-amber-500 via-[#FF1D6C] to-violet-500 bg-clip-text text-transparent">{firstName}</span> 👋
          </h1>
          <p className="text-gray-500 mt-1 text-sm">
            {agentData?.fleet?.online_nodes ?? 3} nodes online ·{' '}
            {(agentData?.fleet?.total_capacity ?? 30000).toLocaleString()} agents ready ·{' '}
            <span className={isOperational ? 'text-green-400' : 'text-amber-400'}>
              {isOperational ? '● all systems go' : '⚠ check status'}
            </span>
          </p>
        </div>
        <Link href="/monitoring" className="text-xs text-gray-600 hover:text-white transition-colors flex items-center gap-1 mt-2">
          <Activity className="w-3 h-3" /> Monitoring
        </Link>
      </div>

      {/* Live fleet stats */}
      <div>
        <h2 className="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-3">Fleet &amp; Infrastructure</h2>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
          {INFRA_STATS.map((stat) => (
            <div key={stat.label} className="bg-white/5 border border-white/10 rounded-xl p-4 hover:border-white/20 transition-all">
              <div className="flex items-center justify-between mb-2">
                <span className="text-xs text-gray-500">{stat.label}</span>
                <stat.icon className="w-4 h-4" style={{ color: stat.color }} />
              </div>
              <div className="text-xl font-bold text-white">{stat.value}</div>
              <div className="text-xs text-gray-600 mt-0.5">{stat.sub}</div>
            </div>
          ))}
        </div>
      </div>

      {/* Start a conversation */}
      <div>
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-xs font-semibold text-gray-500 uppercase tracking-wider">Start a Conversation</h2>
          <Link href="/conversations" className="text-xs text-gray-600 hover:text-white transition-colors flex items-center gap-1">
            All <ArrowRight className="w-3 h-3" />
          </Link>
        </div>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
          {QUICK_STARTS.map((q) => (
            <Link
              key={q.id}
              href={q.href}
              className="group p-4 bg-white/5 border border-white/10 rounded-xl hover:border-[#FF1D6C]/40 hover:bg-white/[0.08] transition-all"
            >
              <div className="text-2xl mb-3">{q.icon}</div>
              <div className="text-xs text-gray-500 mb-1">{q.agent}</div>
              <div className="text-sm font-semibold text-white mb-1">{q.title}</div>
              <div className="text-xs text-gray-500">{q.desc}</div>
            </Link>
          ))}
        </div>
      </div>

      {/* Live agents */}
      <div>
        <h2 className="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-3">Live Agents</h2>
        <div className="grid gap-2 sm:grid-cols-2 lg:grid-cols-4">
          {(agentData?.agents || [
            { id: 'lucidia',   name: 'Lucidia',   role: 'Dreamer',   status: 'active', node: 'aria64',       color: '#2979FF' },
            { id: 'alice',     name: 'Alice',     role: 'Operator',  status: 'active', node: 'alice',        color: '#34d399' },
            { id: 'octavia',   name: 'Octavia',   role: 'Architect', status: 'active', node: 'aria64',       color: '#F5A623' },
            { id: 'cecilia',   name: 'Cecilia',   role: 'Core',      status: 'active', node: 'blackroad-pi', color: '#9C27B0' },
            { id: 'shellfish', name: 'Shellfish', role: 'Hacker',    status: 'active', node: 'aria64',       color: '#ef4444' },
            { id: 'cipher',    name: 'Cipher',    role: 'Guardian',  status: 'active', node: 'aria64',       color: '#FF1D6C' },
            { id: 'prism',     name: 'Prism',     role: 'Analyst',   status: 'active', node: 'aria64',       color: '#F5A623' },
            { id: 'echo',      name: 'Echo',      role: 'Librarian', status: 'idle',   node: 'alice',        color: '#4CAF50' },
          ]).map((agent) => (
            <Link
              key={agent.id}
              href={`/conversations/new?agent=${agent.id}`}
              className="flex items-center gap-3 p-3 bg-white/5 border border-white/10 rounded-xl hover:border-white/20 transition-all group"
            >
              <div className="w-2 h-2 rounded-full flex-shrink-0 ring-2 ring-offset-1 ring-offset-black"
                style={{ backgroundColor: agent.color, boxShadow: agent.status === 'active' ? `0 0 6px ${agent.color}` : 'none' }} />
              <div className="flex-1 min-w-0">
                <div className="text-sm font-medium text-white">{agent.name}</div>
                <div className="text-xs text-gray-600">{agent.role}</div>
              </div>
              <Plus className="w-3.5 h-3.5 text-gray-700 group-hover:text-white transition-colors" />
            </Link>
          ))}
        </div>
      </div>

      {/* Recent conversations */}
      {recentConvs.length > 0 && (
        <div>
          <div className="flex items-center justify-between mb-3">
            <h2 className="text-xs font-semibold text-gray-500 uppercase tracking-wider">Recent Conversations</h2>
            <Link href="/conversations" className="text-xs text-gray-600 hover:text-white transition-colors">View all →</Link>
          </div>
          <div className="space-y-2">
            {recentConvs.map(c => (
              <Link key={c.id} href={`/conversations/${c.id}`}
                className="flex items-center gap-3 px-4 py-3 bg-white/5 border border-white/10 rounded-xl hover:border-white/20 transition-all"
              >
                <span className="text-xs font-medium text-gray-500 w-16 truncate capitalize">{c.agent}</span>
                <span className="text-sm text-white truncate flex-1">{c.title}</span>
                <ArrowRight className="w-3.5 h-3.5 text-gray-600 flex-shrink-0" />
              </Link>
            ))}
          </div>
        </div>
      )}

      {/* Terminal shortcuts */}
      <div className="bg-black border border-white/10 rounded-xl p-4 font-mono text-sm">
        <div className="flex items-center gap-2 mb-3">
          <Terminal className="w-4 h-4 text-gray-500" />
          <span className="text-gray-500 text-xs uppercase tracking-wider">CLI quick-reference</span>
        </div>
        <div className="grid sm:grid-cols-2 gap-x-8 gap-y-1">
          {[
            ['br git save', 'stage + smart commit + push'],
            ['br cf-workers list', '499 CF workers'],
            ['br domains zones', '20 DNS zones'],
            ['br kv list', 'KV namespaces'],
            ['br radar', 'context suggestions'],
            ['br cece whoami', 'CECE identity'],
            ['br nodes list', 'Pi fleet status'],
            ['br geb oracle', 'Gödel oracle'],
          ].map(([cmd, desc]) => (
            <div key={cmd} className="flex gap-3">
              <span className="text-[#FF1D6C] min-w-[160px] shrink-0">{cmd}</span>
              <span className="text-gray-600 truncate"># {desc}</span>
            </div>
          ))}
        </div>
      </div>

    </div>
  );
}
