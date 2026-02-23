'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { Bot, Zap, Globe, Activity, Plus, ArrowRight, Terminal } from 'lucide-react';
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
  { id: 'new-1', icon: '🌀', agent: 'Lucidia', title: 'Deep analysis', desc: 'Recursive reasoning & strategy', href: '/conversations/lucidia-1' },
  { id: 'new-2', icon: '🚪', agent: 'Alice', title: 'Run a task', desc: 'Deploy, automate, execute', href: '/conversations/alice-1' },
  { id: 'new-3', icon: '⚡', agent: 'Octavia', title: 'Infra review', desc: 'Architecture & system health', href: '/conversations/octavia-1' },
  { id: 'new-4', icon: '🔐', agent: 'Shellfish', title: 'Security scan', desc: 'Audit, harden, verify', href: '/conversations/shellfish-1' },
];

export default function WorkspacePage() {
  const user = useAuthStore((state) => state.user);
  const [agentData, setAgentData] = useState<AgentData | null>(null);
  const [statusData, setStatusData] = useState<StatusData | null>(null);

  useEffect(() => {
    fetch('/api/agents').then(r => r.json()).then(setAgentData).catch(() => {});
    fetch('/api/status').then(r => r.json()).then(setStatusData).catch(() => {});
  }, []);

  const hour = new Date().getHours();
  const greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';
  const firstName = user?.name?.split(' ')[0] || 'Alexa';

  return (
    <div className="min-h-full p-6 max-w-6xl mx-auto space-y-8">

      {/* Greeting */}
      <div className="pt-2">
        <h1 className="text-3xl font-bold text-white">
          {greeting}, <span className="bg-gradient-to-r from-amber-500 via-[#FF1D6C] to-violet-500 bg-clip-text text-transparent">{firstName}</span> 👋
        </h1>
        <p className="text-gray-500 mt-1 text-sm">BlackRoad OS is running. {agentData?.fleet?.online_nodes ?? 2} nodes online · {(agentData?.fleet?.total_capacity ?? 30000).toLocaleString()} agents ready.</p>
      </div>

      {/* Stats row */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        {[
          { label: 'Fleet Capacity', value: (agentData?.fleet?.total_capacity ?? 30000).toLocaleString(), icon: Bot, color: '#9C27B0' },
          { label: 'Online Nodes', value: agentData?.fleet?.online_nodes ?? 2, icon: Activity, color: '#22c55e' },
          { label: 'Active Agents', value: agentData?.agents?.filter(a => a.status === 'active').length ?? 6, icon: Zap, color: '#F5A623' },
          { label: 'System Status', value: statusData?.status === 'operational' ? '✓ All Good' : '⚠ Check', icon: Globe, color: '#2979FF' },
        ].map((stat) => (
          <div key={stat.label} className="bg-white/5 border border-white/10 rounded-xl p-4">
            <div className="flex items-center justify-between mb-3">
              <span className="text-xs text-gray-500 uppercase tracking-wider">{stat.label}</span>
              <stat.icon className="w-4 h-4" style={{ color: stat.color }} />
            </div>
            <div className="text-2xl font-bold text-white">{stat.value}</div>
          </div>
        ))}
      </div>

      {/* Start a conversation */}
      <div>
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-sm font-semibold text-gray-400 uppercase tracking-wider">Start a Conversation</h2>
          <Link href="/conversations" className="text-xs text-gray-600 hover:text-white transition-colors flex items-center gap-1">
            All conversations <ArrowRight className="w-3 h-3" />
          </Link>
        </div>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
          {QUICK_STARTS.map((q) => (
            <Link
              key={q.id}
              href={q.href}
              className="group p-4 bg-white/5 border border-white/10 rounded-xl hover:border-white/20 hover:bg-white/[0.08] transition-all"
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
        <h2 className="text-sm font-semibold text-gray-400 uppercase tracking-wider mb-4">Live Agents</h2>
        <div className="grid gap-2 sm:grid-cols-2 lg:grid-cols-3">
          {(agentData?.agents || [
            { id: 'lucidia', name: 'Lucidia', role: 'Coordinator', status: 'active', node: 'aria64', color: '#2979FF' },
            { id: 'alice', name: 'Alice', role: 'Operator', status: 'active', node: 'alice', color: '#22c55e' },
            { id: 'octavia', name: 'Octavia', role: 'Architect', status: 'active', node: 'aria64', color: '#F5A623' },
            { id: 'cecilia', name: 'Cecilia', role: 'Core', status: 'active', node: 'aria64', color: '#9C27B0' },
            { id: 'aria', name: 'Aria', role: 'Interface', status: 'idle', node: 'alice', color: '#FF1D6C' },
            { id: 'shellfish', name: 'Shellfish', role: 'Security', status: 'active', node: 'aria64', color: '#ef4444' },
          ]).map((agent) => (
            <Link
              key={agent.id}
              href={`/conversations/${agent.id}-${Date.now()}`}
              className="flex items-center gap-3 p-3 bg-white/5 border border-white/10 rounded-xl hover:border-white/20 transition-all group"
            >
              <div className="w-2.5 h-2.5 rounded-full flex-shrink-0" style={{ backgroundColor: agent.color }} />
              <div className="flex-1 min-w-0">
                <div className="text-sm font-medium text-white">{agent.name}</div>
                <div className="text-xs text-gray-500">{agent.role} · {agent.node}</div>
              </div>
              <span className={`text-xs px-2 py-0.5 rounded-full ${
                agent.status === 'active' ? 'bg-green-900/50 text-green-400' : 'bg-gray-800 text-gray-500'
              }`}>{agent.status}</span>
              <Plus className="w-4 h-4 text-gray-600 group-hover:text-white transition-colors" />
            </Link>
          ))}
        </div>
      </div>

      {/* Terminal shortcut */}
      <div className="bg-black border border-white/10 rounded-xl p-4 font-mono text-sm">
        <div className="flex items-center gap-2 mb-3">
          <Terminal className="w-4 h-4 text-gray-500" />
          <span className="text-gray-500 text-xs uppercase tracking-wider">Quick commands</span>
        </div>
        <div className="space-y-1">
          {[
            ['br radar', 'context suggestions for current project'],
            ['br cece whoami', 'CECE identity status'],
            ['br nodes list', 'Pi fleet status'],
            ['br geb oracle', 'Ask the Gödel oracle'],
          ].map(([cmd, desc]) => (
            <div key={cmd} className="flex gap-4">
              <span className="text-[#FF1D6C] min-w-[160px]">{cmd}</span>
              <span className="text-gray-600"># {desc}</span>
            </div>
          ))}
        </div>
      </div>

    </div>
  );
}
