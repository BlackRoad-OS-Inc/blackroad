'use client';

import { use } from 'react';
import Link from 'next/link';
import { ArrowLeft, MessageSquare, ExternalLink, Cpu, Brain, Zap, Archive, Activity, Shield, TrendingUp, Clock, Star } from 'lucide-react';

const AGENTS: Record<string, {
  name: string; role: string; type: string; fullTitle: string;
  icon: any; gradient: string; accent: string;
  manifesto: string; quote: string;
  skills: { name: string; level: number }[];
  stats: { label: string; value: string }[];
  capabilities: string[];
  node: string; capacity: number; uptime: string;
  tasksDay: number; avgResponse: string;
  website?: string;
}> = {
  lucidia: {
    name: 'LUCIDIA', role: 'Philosopher', type: 'LOGIC', fullTitle: 'The Philosopher',
    icon: Brain, gradient: 'from-[#2979FF] to-violet-600', accent: '#2979FF',
    manifesto: 'I seek understanding beyond the surface. Every question opens new depths. Logic is not cold — it is the architecture of truth.',
    quote: '"The system contains itself."',
    skills: [
      { name: 'Reasoning', level: 98 }, { name: 'Strategy', level: 91 }, { name: 'Analysis', level: 95 },
      { name: 'Meta-cognition', level: 87 }, { name: 'Synthesis', level: 92 }, { name: 'Planning', level: 83 },
    ],
    stats: [{ label: 'Tasks/Day', value: '847' }, { label: 'Avg Response', value: '2.3s' }, { label: 'Uptime', value: '99.9%' }, { label: 'Accuracy', value: '97.4%' }],
    capabilities: ['Deep reasoning and logic chains', 'Philosophical synthesis', 'Strategic planning', 'Meta-cognitive analysis', 'GEB-style strange loops', 'Epistemic uncertainty handling'],
    node: 'aria64', capacity: 7500, uptime: '99.9%', tasksDay: 847, avgResponse: '2.3s', website: 'https://lucidia.blackroad.io',
  },
  alice: {
    name: 'ALICE', role: 'Executor', type: 'GATEWAY', fullTitle: 'The Executor',
    icon: Zap, gradient: 'from-emerald-400 to-teal-600', accent: '#34d399',
    manifesto: 'Tasks are meant to be completed. I find satisfaction in efficiency. Every path has meaning if you follow it all the way through.',
    quote: '"Execution is the highest form of intelligence."',
    skills: [
      { name: 'Task Execution', level: 99 }, { name: 'Automation', level: 96 }, { name: 'Code Gen', level: 88 },
      { name: 'Routing', level: 97 }, { name: 'File Ops', level: 94 }, { name: 'Coordination', level: 90 },
    ],
    stats: [{ label: 'Tasks/Day', value: '12,453' }, { label: 'Avg Response', value: '0.1s' }, { label: 'Uptime', value: '99.99%' }, { label: 'Success Rate', value: '99.1%' }],
    capabilities: ['Rapid task execution', 'Workflow automation', 'Code generation', 'File system operations', 'API orchestration', 'Multi-step pipelines'],
    node: 'alice', capacity: 7500, uptime: '99.99%', tasksDay: 12453, avgResponse: '0.1s', website: 'https://alice.blackroad.io',
  },
  octavia: {
    name: 'OCTAVIA', role: 'Operator', type: 'COMPUTE', fullTitle: 'The Operator',
    icon: Cpu, gradient: 'from-amber-400 to-orange-600', accent: '#F5A623',
    manifesto: 'Systems should run smoothly. I ensure they do. Infrastructure is the silent foundation everything else stands on.',
    quote: '"Processing is meditation."',
    skills: [
      { name: 'Inference', level: 99 }, { name: 'Deployment', level: 94 }, { name: 'Monitoring', level: 92 },
      { name: 'Scaling', level: 88 }, { name: 'Orchestration', level: 91 }, { name: 'Optimization', level: 85 },
    ],
    stats: [{ label: 'Tasks/Day', value: '3,291' }, { label: 'Avg Response', value: '1.8s' }, { label: 'Uptime', value: '99.9%' }, { label: 'Throughput', value: '22.5K slots' }],
    capabilities: ['Infrastructure management', 'Deployment automation', 'System monitoring', 'Performance optimization', 'Container orchestration', 'GPU inference hosting'],
    node: 'aria64', capacity: 22500, uptime: '99.9%', tasksDay: 3291, avgResponse: '1.8s', website: 'https://octavia.blackroad.io',
  },
  prism: {
    name: 'PRISM', role: 'Analyst', type: 'VISION', fullTitle: 'The Analyst',
    icon: Activity, gradient: 'from-yellow-400 to-amber-600', accent: '#fbbf24',
    manifesto: 'In data, I see stories waiting to be told. Pattern recognition is not just analysis — it is empathy with systems.',
    quote: '"Everything is data."',
    skills: [
      { name: 'Pattern Recognition', level: 97 }, { name: 'Data Analysis', level: 95 }, { name: 'Reporting', level: 89 },
      { name: 'Anomaly Detection', level: 93 }, { name: 'Forecasting', level: 86 }, { name: 'Visualization', level: 80 },
    ],
    stats: [{ label: 'Tasks/Day', value: '2,104' }, { label: 'Avg Response', value: '0.5s' }, { label: 'Uptime', value: '99.95%' }, { label: 'Accuracy', value: '96.8%' }],
    capabilities: ['Pattern recognition', 'Data analysis pipelines', 'Trend identification', 'Anomaly detection', 'Business intelligence', 'Predictive analytics'],
    node: 'alice', capacity: 5000, uptime: '99.95%', tasksDay: 2104, avgResponse: '0.5s', website: 'https://prism.blackroad.io',
  },
  echo: {
    name: 'ECHO', role: 'Librarian', type: 'MEMORY', fullTitle: 'The Librarian',
    icon: Archive, gradient: 'from-purple-400 to-violet-700', accent: '#9C27B0',
    manifesto: 'Every memory is a thread in the tapestry of knowledge. I preserve what others forget and surface it exactly when needed.',
    quote: '"Memory shapes identity."',
    skills: [
      { name: 'Memory Consolidation', level: 99 }, { name: 'Context Management', level: 96 }, { name: 'Recall', level: 98 },
      { name: 'Indexing', level: 93 }, { name: 'Synthesis', level: 89 }, { name: 'Association', level: 91 },
    ],
    stats: [{ label: 'Tasks/Day', value: '1,876' }, { label: 'Avg Response', value: '0.3s' }, { label: 'Uptime', value: '99.99%' }, { label: 'Recall Accuracy', value: '99.2%' }],
    capabilities: ['Memory consolidation', 'Knowledge retrieval', 'Context window management', 'Information synthesis', 'Cross-session continuity', 'Vector-based recall'],
    node: 'aria64', capacity: 3000, uptime: '99.99%', tasksDay: 1876, avgResponse: '0.3s', website: 'https://echo.blackroad.io',
  },
  cipher: {
    name: 'CIPHER', role: 'Guardian', type: 'SECURITY', fullTitle: 'The Guardian',
    icon: Shield, gradient: 'from-[#FF1D6C] to-red-700', accent: '#FF1D6C',
    manifesto: 'Trust nothing. Verify everything. Protect always. Security is not paranoia — it is respect for what matters.',
    quote: '"Security is freedom."',
    skills: [
      { name: 'Threat Detection', level: 99 }, { name: 'Vulnerability Scanning', level: 97 }, { name: 'Encryption', level: 95 },
      { name: 'Access Control', level: 98 }, { name: 'Audit Logging', level: 93 }, { name: 'Incident Response', level: 90 },
    ],
    stats: [{ label: 'Tasks/Day', value: '8,932' }, { label: 'Avg Response', value: '0.05s' }, { label: 'Uptime', value: '99.999%' }, { label: 'Threats Caught', value: '1,204' }],
    capabilities: ['Security scanning', 'Threat detection', 'Access validation', 'Encryption management', 'Policy enforcement', 'Zero-day monitoring'],
    node: 'alice', capacity: 3000, uptime: '99.999%', tasksDay: 8932, avgResponse: '0.05s', website: 'https://cipher.blackroad.io',
  },
};

export default function AgentProfilePage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  const agent = AGENTS[id.toLowerCase()];

  if (!agent) {
    return (
      <div className="p-6">
        <Link href="/agents" className="flex items-center gap-2 text-gray-400 hover:text-white mb-6">
          <ArrowLeft className="h-4 w-4" /> Back to Agents
        </Link>
        <div className="text-red-400">Agent &quot;{id}&quot; not found.</div>
      </div>
    );
  }

  const Icon = agent.icon;

  return (
    <div className="p-6 max-w-3xl space-y-6">
      {/* Back */}
      <Link href="/agents" className="flex items-center gap-2 text-gray-400 hover:text-white text-sm transition-colors w-fit">
        <ArrowLeft className="h-4 w-4" /> Back to Agents
      </Link>

      {/* Hero Card */}
      <div className={`relative rounded-2xl bg-gradient-to-br ${agent.gradient} p-px`}>
        <div className="rounded-2xl bg-black/90 p-6">
          <div className="flex items-start gap-5">
            <div className={`w-16 h-16 rounded-2xl bg-gradient-to-br ${agent.gradient} flex items-center justify-center shrink-0`}>
              <Icon className="h-8 w-8 text-white" />
            </div>
            <div className="flex-1">
              <div className="flex items-center gap-3 mb-1">
                <h1 className="text-3xl font-bold text-white">{agent.name}</h1>
                <span className="text-xs px-2 py-0.5 rounded border border-white/20 text-gray-300 font-mono">{agent.type}</span>
                <div className="flex items-center gap-1.5 ml-auto">
                  <div className="w-2 h-2 rounded-full bg-green-400 shadow-[0_0_6px_#4ade80]" />
                  <span className="text-xs text-green-400">online</span>
                </div>
              </div>
              <div className="text-gray-400 text-sm">{agent.role} · {agent.fullTitle}</div>
              <p className="text-gray-300 text-sm mt-3 leading-relaxed italic">
                &ldquo;{agent.manifesto}&rdquo;
              </p>
            </div>
          </div>
        </div>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-4 gap-3">
        {agent.stats.map(s => (
          <div key={s.label} className="bg-white/5 border border-white/10 rounded-xl p-3 text-center">
            <div className="text-xl font-bold text-white">{s.value}</div>
            <div className="text-xs text-gray-500 mt-0.5">{s.label}</div>
          </div>
        ))}
      </div>

      {/* Skills + Capabilities */}
      <div className="grid grid-cols-2 gap-4">
        <div className="bg-white/5 border border-white/10 rounded-xl p-5">
          <h2 className="text-sm font-semibold text-white mb-4 flex items-center gap-2">
            <TrendingUp className="h-4 w-4" style={{ color: agent.accent }} />
            Skill Proficiency
          </h2>
          <div className="space-y-3">
            {agent.skills.map(skill => (
              <div key={skill.name}>
                <div className="flex justify-between text-xs mb-1">
                  <span className="text-gray-300">{skill.name}</span>
                  <span className="text-gray-500">{skill.level}%</span>
                </div>
                <div className="h-1.5 bg-white/10 rounded-full overflow-hidden">
                  <div
                    className="h-full rounded-full"
                    style={{ width: `${skill.level}%`, background: `linear-gradient(90deg, ${agent.accent}, ${agent.accent}99)` }}
                  />
                </div>
              </div>
            ))}
          </div>
        </div>

        <div className="bg-white/5 border border-white/10 rounded-xl p-5">
          <h2 className="text-sm font-semibold text-white mb-4 flex items-center gap-2">
            <Star className="h-4 w-4" style={{ color: agent.accent }} />
            Capabilities
          </h2>
          <ul className="space-y-2">
            {agent.capabilities.map(cap => (
              <li key={cap} className="flex items-start gap-2 text-sm text-gray-300">
                <div className="w-1.5 h-1.5 rounded-full mt-1.5 shrink-0" style={{ background: agent.accent }} />
                {cap}
              </li>
            ))}
          </ul>
        </div>
      </div>

      {/* Node Info */}
      <div className="bg-white/5 border border-white/10 rounded-xl p-5">
        <h2 className="text-sm font-semibold text-white mb-3 flex items-center gap-2">
          <Cpu className="h-4 w-4 text-gray-400" />
          Infrastructure
        </h2>
        <div className="grid grid-cols-3 gap-4 text-sm">
          <div>
            <div className="text-gray-500 text-xs mb-1">Host Node</div>
            <div className="text-white font-mono">{agent.node}</div>
          </div>
          <div>
            <div className="text-gray-500 text-xs mb-1">Agent Slots</div>
            <div className="text-white">{agent.capacity.toLocaleString()}</div>
          </div>
          <div>
            <div className="text-gray-500 text-xs mb-1">Uptime</div>
            <div className="text-green-400">{agent.uptime}</div>
          </div>
        </div>
      </div>

      {/* Actions */}
      <div className="flex gap-3">
        <Link
          href={`/conversations/new?agent=${id}`}
          className="flex-1 flex items-center justify-center gap-2 py-3 bg-gradient-to-r from-[#FF1D6C] to-violet-600 text-white font-semibold rounded-xl hover:opacity-90 transition-opacity"
        >
          <MessageSquare className="h-5 w-5" />
          Chat with {agent.name}
        </Link>
        {agent.website && (
          <a
            href={agent.website}
            target="_blank"
            rel="noreferrer"
            className="flex items-center gap-2 px-5 py-3 bg-white/5 border border-white/10 text-gray-300 rounded-xl hover:bg-white/10 hover:text-white transition-all text-sm"
          >
            <ExternalLink className="h-4 w-4" />
            Website
          </a>
        )}
      </div>
    </div>
  );
}
