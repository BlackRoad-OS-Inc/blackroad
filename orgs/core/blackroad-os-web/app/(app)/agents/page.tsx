'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { MessageSquare, Zap, Shield, Activity, Brain, Archive, Cpu, ExternalLink, Radio } from 'lucide-react';

const AGENT_META: Record<string, {
  icon: any; color: string; gradient: string; accent: string; type: string;
  specialty: string; skills: string[]; node: string; capacity: number;
}> = {
  LUCIDIA: {
    icon: Brain, color: '#2979FF', gradient: 'from-[#2979FF] to-violet-600',
    accent: '#2979FF', type: 'LOGIC',
    specialty: 'Deep reasoning, synthesis, strategy',
    skills: ['Reasoning', 'Philosophy', 'Meta-cognition', 'Planning'],
    node: 'aria64', capacity: 7500,
  },
  ALICE: {
    icon: Zap, color: '#34d399', gradient: 'from-emerald-400 to-teal-600',
    accent: '#34d399', type: 'GATEWAY',
    specialty: 'Task execution, automation, code generation',
    skills: ['Automation', 'Code Gen', 'File Ops', 'Routing'],
    node: 'alice', capacity: 7500,
  },
  OCTAVIA: {
    icon: Cpu, color: '#F5A623', gradient: 'from-amber-400 to-orange-600',
    accent: '#F5A623', type: 'COMPUTE',
    specialty: 'Infrastructure, deployment, system monitoring',
    skills: ['DevOps', 'Deploy', 'Monitoring', 'Scaling'],
    node: 'aria64', capacity: 22500,
  },
  PRISM: {
    icon: Activity, color: '#fbbf24', gradient: 'from-yellow-400 to-amber-600',
    accent: '#fbbf24', type: 'VISION',
    specialty: 'Pattern recognition, data analysis, trends',
    skills: ['Analytics', 'Patterns', 'Reporting', 'Anomalies'],
    node: 'alice', capacity: 5000,
  },
  ECHO: {
    icon: Archive, color: '#9C27B0', gradient: 'from-purple-400 to-violet-700',
    accent: '#9C27B0', type: 'MEMORY',
    specialty: 'Knowledge retrieval, context, memory synthesis',
    skills: ['Recall', 'Context', 'Synthesis', 'Indexing'],
    node: 'aria64', capacity: 3000,
  },
  CIPHER: {
    icon: Shield, color: '#FF1D6C', gradient: 'from-[#FF1D6C] to-red-700',
    accent: '#FF1D6C', type: 'SECURITY',
    specialty: 'Security scanning, threat detection, encryption',
    skills: ['Scanning', 'Auth', 'Encryption', 'Guardrails'],
    node: 'alice', capacity: 3000,
  },
};

interface Agent {
  id: string; name: string; role: string; type: string;
  status: 'active' | 'idle' | 'offline'; node: string; color: string;
}

interface AgentData {
  agents: Agent[];
  fleet?: { total_capacity: number; online_nodes: number };
  worlds_count?: number;
  fallback?: boolean;
}

const TASKS_PER_DAY: Record<string, number> = {
  LUCIDIA: 847, ALICE: 12453, OCTAVIA: 3291, PRISM: 2104, ECHO: 1876, CIPHER: 8932,
};

export default function AgentsPage() {
  const [data, setData] = useState<AgentData | null>(null);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState<'all' | 'active' | 'idle'>('all');

  useEffect(() => {
    async function load() {
      try {
        const res = await fetch('/api/agents');
        const d = await res.json();
        setData(d);
      } finally {
        setLoading(false);
      }
    }
    load();
    const interval = setInterval(load, 30000);
    return () => clearInterval(interval);
  }, []);

  const agents = data?.agents ?? [];
  const filtered = filter === 'all' ? agents : agents.filter(a => a.status === filter);

  if (loading) return (
    <div className="p-6 flex items-center gap-3 text-gray-400">
      <Radio className="h-4 w-4 animate-pulse text-[#FF1D6C]" />
      Connecting to fleet…
    </div>
  );

  return (
    <div className="p-6 space-y-6">
      {/* Header */}
      <div className="flex items-start justify-between">
        <div>
          <h1 className="text-2xl font-bold text-white">Agents</h1>
          <p className="text-gray-400 text-sm mt-1">
            {(data?.fleet?.total_capacity ?? 30000).toLocaleString()} total capacity ·{' '}
            {data?.fleet?.online_nodes ?? 2} nodes online
            {data?.fallback && <span className="ml-2 text-yellow-400 text-xs">(offline mode)</span>}
          </p>
        </div>
        <div className="flex items-center gap-2">
          {(['all', 'active', 'idle'] as const).map(f => (
            <button
              key={f}
              onClick={() => setFilter(f)}
              className={`px-4 py-1.5 rounded-lg text-sm capitalize transition-all ${
                filter === f ? 'bg-white/10 text-white' : 'text-gray-400 hover:text-white'
              }`}
            >
              {f}
            </button>
          ))}
        </div>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-4 gap-4">
        {[
          { label: 'Total Capacity', value: '30,000', sub: 'agent slots' },
          { label: 'Tasks / Day', value: Object.values(TASKS_PER_DAY).reduce((a,b) => a+b, 0).toLocaleString(), sub: 'combined' },
          { label: 'Avg Uptime', value: '99.96%', sub: 'last 30 days' },
          { label: 'Worlds Generated', value: data?.worlds_count ? `${data.worlds_count}+` : '60+', sub: 'artifacts' },
        ].map(s => (
          <div key={s.label} className="bg-white/5 border border-white/10 rounded-xl p-4">
            <div className="text-xs text-gray-500 mb-1">{s.label}</div>
            <div className="text-2xl font-bold text-white">{s.value}</div>
            <div className="text-xs text-gray-500">{s.sub}</div>
          </div>
        ))}
      </div>

      {/* Agent Grid */}
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {filtered.map(agent => {
          const meta = AGENT_META[agent.name] ?? {};
          const Icon = meta.icon ?? Brain;
          const tasksDay = TASKS_PER_DAY[agent.name] ?? 0;

          return (
            <div
              key={agent.id}
              className="group bg-white/5 border border-white/10 rounded-2xl p-5 hover:border-white/20 hover:bg-white/8 transition-all"
            >
              {/* Top row */}
              <div className="flex items-start justify-between mb-4">
                <div className={`w-12 h-12 rounded-xl bg-gradient-to-br ${meta.gradient ?? 'from-gray-600 to-gray-800'} flex items-center justify-center`}>
                  <Icon className="h-6 w-6 text-white" />
                </div>
                <div className="flex items-center gap-2">
                  <div className={`w-2 h-2 rounded-full ${
                    agent.status === 'active' ? 'bg-green-400 shadow-[0_0_6px_#4ade80]' :
                    agent.status === 'idle' ? 'bg-amber-400' : 'bg-gray-600'
                  }`} />
                  <span className="text-xs text-gray-400 capitalize">{agent.status}</span>
                </div>
              </div>

              {/* Name + type */}
              <div className="mb-1">
                <h3 className="text-white font-bold text-lg tracking-wide">{agent.name}</h3>
                <div className="flex items-center gap-2">
                  <span className="text-xs text-gray-400">{agent.role}</span>
                  <span className="text-xs px-1.5 py-0.5 rounded border border-white/10 text-gray-500 font-mono">{meta.type}</span>
                </div>
              </div>

              {/* Specialty */}
              <p className="text-gray-500 text-xs mt-2 mb-4 leading-relaxed">
                {meta.specialty}
              </p>

              {/* Skills */}
              <div className="flex flex-wrap gap-1.5 mb-4">
                {(meta.skills ?? []).map(skill => (
                  <span key={skill} className="text-xs px-2 py-0.5 bg-white/5 rounded text-gray-400">{skill}</span>
                ))}
              </div>

              {/* Stats row */}
              <div className="flex items-center gap-4 text-xs text-gray-500 border-t border-white/5 pt-3 mb-4">
                <span>{tasksDay.toLocaleString()} tasks/day</span>
                <span className="text-gray-700">·</span>
                <span>{(meta.capacity ?? 0).toLocaleString()} slots</span>
                <span className="text-gray-700">·</span>
                <span className="font-mono">{meta.node}</span>
              </div>

              {/* Actions */}
              <div className="flex gap-2">
                <Link
                  href={`/conversations/new?agent=${agent.name.toLowerCase()}`}
                  className="flex-1 flex items-center justify-center gap-1.5 py-2 rounded-lg bg-gradient-to-r from-[#FF1D6C] to-violet-600 text-white text-xs font-medium hover:opacity-90 transition-opacity"
                >
                  <MessageSquare className="h-3.5 w-3.5" />
                  Chat
                </Link>
                <Link
                  href={`/agents/${agent.name.toLowerCase()}`}
                  className="flex items-center justify-center gap-1.5 px-3 py-2 rounded-lg bg-white/5 border border-white/10 text-gray-400 text-xs hover:text-white hover:bg-white/10 transition-all"
                >
                  <ExternalLink className="h-3.5 w-3.5" />
                  Profile
                </Link>
              </div>
            </div>
          );
        })}
      </div>

      <div className="text-xs text-gray-600 text-center pt-2">
        Refreshes every 30s · Data from{' '}
        <a href="https://agents-status.blackroad.io" target="_blank" rel="noreferrer" className="hover:text-gray-400 transition-colors">
          agents-status.blackroad.io
        </a>
      </div>
    </div>
  );
}

