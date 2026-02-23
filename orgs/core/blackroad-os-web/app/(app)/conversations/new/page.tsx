'use client';

import { useState, useEffect } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import { ArrowLeft, MessageSquare, Zap, Shield, Activity, Brain, Archive, Cpu, Loader2 } from 'lucide-react';
import Link from 'next/link';

const AGENTS = [
  {
    id: 'lucidia',
    name: 'LUCIDIA',
    role: 'Philosopher · Reasoning',
    desc: 'Deep analysis, synthesis, strategy. Ask me anything complex.',
    icon: Brain,
    color: 'from-[#2979FF] to-violet-600',
    accent: '#2979FF',
    tags: ['reasoning', 'strategy', 'analysis'],
  },
  {
    id: 'alice',
    name: 'ALICE',
    role: 'Executor · Gateway',
    desc: 'Task execution, automation, code generation, file ops.',
    icon: Zap,
    color: 'from-emerald-400 to-teal-600',
    accent: '#34d399',
    tags: ['automation', 'code', 'tasks'],
  },
  {
    id: 'octavia',
    name: 'OCTAVIA',
    role: 'Operator · Compute',
    desc: 'Infrastructure management, deployment automation, system monitoring.',
    icon: Cpu,
    color: 'from-amber-400 to-orange-600',
    accent: '#F5A623',
    tags: ['devops', 'infra', 'deploy'],
  },
  {
    id: 'prism',
    name: 'PRISM',
    role: 'Analyst · Vision',
    desc: 'Pattern recognition, data analysis, trend identification.',
    icon: Activity,
    color: 'from-yellow-400 to-amber-600',
    accent: '#fbbf24',
    tags: ['data', 'patterns', 'insights'],
  },
  {
    id: 'echo',
    name: 'ECHO',
    role: 'Librarian · Memory',
    desc: 'Knowledge retrieval, context management, memory synthesis.',
    icon: Archive,
    color: 'from-purple-400 to-violet-700',
    accent: '#9C27B0',
    tags: ['memory', 'recall', 'context'],
  },
  {
    id: 'cipher',
    name: 'CIPHER',
    role: 'Guardian · Security',
    desc: 'Security scanning, threat detection, access validation.',
    icon: Shield,
    color: 'from-[#FF1D6C] to-red-700',
    accent: '#FF1D6C',
    tags: ['security', 'scanning', 'auth'],
  },
];

const STARTERS = [
  'Help me debug this code',
  'What should I deploy next?',
  'Analyze my system health',
  'Explain this architecture',
  'Review my security setup',
  'Brainstorm feature ideas',
];

export default function NewConversationPage() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const [selected, setSelected] = useState<string | null>(searchParams.get('agent'));
  const [prompt, setPrompt] = useState('');

  const [starting, setStarting] = useState(false);

  const start = async () => {
    const agentId = selected || 'lucidia';
    setStarting(true);
    try {
      const res = await fetch('/api/conversations', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          agent: agentId,
          title: prompt || `Chat with ${agentId.toUpperCase()}`,
        }),
      });
      if (res.ok) {
        const data = await res.json();
        router.push(`/conversations/${data.id}?agent=${agentId}`);
      } else {
        // Fallback: local ID
        router.push(`/conversations/${agentId}-${Date.now()}?agent=${agentId}`);
      }
    } catch {
      router.push(`/conversations/${agentId}-${Date.now()}?agent=${agentId}`);
    } finally {
      setStarting(false);
    }
  };

  return (
    <div className="p-6 max-w-3xl mx-auto space-y-8">
      {/* Header */}
      <div className="flex items-center gap-4">
        <Link href="/conversations" className="text-gray-400 hover:text-white transition-colors">
          <ArrowLeft className="h-5 w-5" />
        </Link>
        <div>
          <h1 className="text-2xl font-bold text-white flex items-center gap-3">
            <MessageSquare className="h-6 w-6 text-[#FF1D6C]" />
            New Conversation
          </h1>
          <p className="text-gray-400 text-sm mt-0.5">Pick an agent to talk to.</p>
        </div>
      </div>

      {/* Agent Picker */}
      <div>
        <h2 className="text-xs text-gray-400 uppercase tracking-wider mb-3 font-medium">Choose your agent</h2>
        <div className="grid grid-cols-2 gap-3">
          {AGENTS.map(agent => (
            <button
              key={agent.id}
              onClick={() => setSelected(selected === agent.id ? null : agent.id)}
              className={`text-left p-4 rounded-xl border transition-all ${
                selected === agent.id
                  ? 'border-white/30 bg-white/10'
                  : 'border-white/10 bg-white/5 hover:bg-white/8 hover:border-white/20'
              }`}
            >
              <div className="flex items-center gap-3 mb-2">
                <div className={`w-9 h-9 rounded-lg bg-gradient-to-br ${agent.color} flex items-center justify-center shrink-0`}>
                  <agent.icon className="h-4 w-4 text-white" />
                </div>
                <div>
                  <div className="text-white font-semibold text-sm">{agent.name}</div>
                  <div className="text-gray-400 text-xs">{agent.role}</div>
                </div>
                {selected === agent.id && (
                  <div className="ml-auto w-4 h-4 rounded-full border-2 bg-[#FF1D6C] border-[#FF1D6C]" />
                )}
              </div>
              <p className="text-gray-400 text-xs leading-relaxed">{agent.desc}</p>
              <div className="flex gap-1.5 mt-2 flex-wrap">
                {agent.tags.map(t => (
                  <span key={t} className="text-xs px-2 py-0.5 bg-white/5 rounded text-gray-500">{t}</span>
                ))}
              </div>
            </button>
          ))}
        </div>
      </div>

      {/* Starter Prompts */}
      <div>
        <h2 className="text-xs text-gray-400 uppercase tracking-wider mb-3 font-medium">Or start with a prompt</h2>
        <div className="flex flex-wrap gap-2 mb-4">
          {STARTERS.map(s => (
            <button
              key={s}
              onClick={() => setPrompt(s)}
              className={`text-sm px-3 py-1.5 rounded-lg border transition-all ${
                prompt === s
                  ? 'border-[#FF1D6C]/50 bg-[#FF1D6C]/10 text-white'
                  : 'border-white/10 bg-white/5 text-gray-400 hover:text-white hover:bg-white/10'
              }`}
            >
              {s}
            </button>
          ))}
        </div>
        <textarea
          value={prompt}
          onChange={e => setPrompt(e.target.value)}
          placeholder={`What do you want to ask ${selected ? AGENTS.find(a => a.id === selected)?.name || 'your agent' : 'your agent'}?`}
          rows={3}
          className="w-full bg-black/50 border border-white/10 rounded-xl px-4 py-3 text-sm text-white placeholder-gray-600 focus:outline-none focus:border-[#FF1D6C]/30 resize-none"
        />
      </div>

      {/* Start Button */}
      <button
        onClick={start}
        disabled={(!selected && !prompt) || starting}
        className="w-full flex items-center justify-center gap-2 py-3.5 bg-gradient-to-r from-[#FF1D6C] to-violet-600 text-white font-semibold rounded-xl hover:opacity-90 transition-opacity disabled:opacity-40 disabled:cursor-not-allowed"
      >
        {starting ? (
          <><Loader2 className="h-5 w-5 animate-spin" /> Starting...</>
        ) : (
          <>
            <MessageSquare className="h-5 w-5" />
            Start Conversation
            {selected && (
              <span className="text-white/60 text-sm font-normal">
                with {AGENTS.find(a => a.id === selected)?.name}
              </span>
            )}
          </>
        )}
      </button>
    </div>
  );
}
