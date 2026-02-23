'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { MessageSquare, Plus, Bot, Search, Clock, Loader2 } from 'lucide-react';

interface Conversation {
  id: string;
  agent: string;
  agentColor: string;
  title: string;
  lastMessage: string;
  timestamp: string;
  status: 'active' | 'ended';
}

const AGENT_COLORS: Record<string, string> = {
  lucidia: '#2979FF',
  alice: '#22c55e',
  octavia: '#F5A623',
  cecilia: '#9C27B0',
  aria: '#FF1D6C',
  shellfish: '#ef4444',
};

const SEED_CONVERSATIONS: Conversation[] = [
  {
    id: 'lucidia-1',
    agent: 'Lucidia',
    agentColor: '#2979FF',
    title: 'What does it mean for a system to understand itself?',
    lastMessage: 'The question contains its own incompleteness. Gödel would agree.',
    timestamp: '2 hours ago',
    status: 'ended',
  },
  {
    id: 'alice-1',
    agent: 'Alice',
    agentColor: '#22c55e',
    title: 'Deploy the email router worker',
    lastMessage: 'Deployed to amundsonalexa.workers.dev. MX records are Cloudflare. ✓',
    timestamp: '4 hours ago',
    status: 'ended',
  },
  {
    id: 'octavia-1',
    agent: 'Octavia',
    agentColor: '#F5A623',
    title: 'Pi fleet architecture review',
    lastMessage: 'aria64 is PRIMARY (22,500 slots), alice is SECONDARY (7,500). Recommend adding a third node.',
    timestamp: 'Yesterday',
    status: 'ended',
  },
  {
    id: 'shellfish-1',
    agent: 'Shellfish',
    agentColor: '#ef4444',
    title: 'Tokenless agent audit',
    lastMessage: 'verify-tokenless-agents.sh passed. 0 forbidden strings found.',
    timestamp: 'Yesterday',
    status: 'ended',
  },
  {
    id: 'cecilia-1',
    agent: 'Cecilia',
    agentColor: '#9C27B0',
    title: 'K(t) contradiction amplification review',
    lastMessage: 'K(t) = C(t) · e^(λ|δ_t|). The contradictions are where the growth is.',
    timestamp: '2 days ago',
    status: 'ended',
  },
];

const AGENTS = [
  { name: 'All Agents', value: 'all', color: '' },
  { name: 'Lucidia', value: 'Lucidia', color: '#2979FF' },
  { name: 'Alice', value: 'Alice', color: '#22c55e' },
  { name: 'Octavia', value: 'Octavia', color: '#F5A623' },
  { name: 'Cecilia', value: 'Cecilia', color: '#9C27B0' },
  { name: 'Aria', value: 'Aria', color: '#FF1D6C' },
  { name: 'Shellfish', value: 'Shellfish', color: '#ef4444' },
];

function formatTimestamp(ts: string): string {
  try {
    const d = new Date(ts);
    const now = Date.now();
    const diff = now - d.getTime();
    if (diff < 60000) return 'just now';
    if (diff < 3600000) return `${Math.floor(diff / 60000)}m ago`;
    if (diff < 86400000) return `${Math.floor(diff / 3600000)}h ago`;
    if (diff < 172800000) return 'Yesterday';
    return d.toLocaleDateString();
  } catch { return ts; }
}

export default function ConversationsPage() {
  const [filter, setFilter] = useState('all');
  const [search, setSearch] = useState('');
  const [conversations, setConversations] = useState<Conversation[]>(SEED_CONVERSATIONS);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetch('/api/conversations')
      .then(r => r.ok ? r.json() : null)
      .then(data => {
        if (data?.conversations?.length) {
          const live: Conversation[] = data.conversations.map((c: {
            id: string; agent?: string; title?: string; updatedAt?: string; messages?: {role: string; content: string}[];
          }) => ({
            id: c.id,
            agent: c.agent || 'Agent',
            agentColor: AGENT_COLORS[(c.agent || '').toLowerCase()] || '#888',
            title: c.title || 'Untitled',
            lastMessage: c.messages?.[c.messages.length - 1]?.content?.slice(0, 80) || '—',
            timestamp: formatTimestamp(c.updatedAt || ''),
            status: 'ended' as const,
          }));
          // Merge: live first, then seed ones not already in live
          const liveIds = new Set(live.map(c => c.id));
          setConversations([...live, ...SEED_CONVERSATIONS.filter(c => !liveIds.has(c.id))]);
        }
      })
      .catch(() => {})
      .finally(() => setLoading(false));
  }, []);

  const filtered = conversations.filter((c) => {
    if (filter !== 'all' && c.agent !== filter) return false;
    if (search && !c.title.toLowerCase().includes(search.toLowerCase())) return false;
    return true;
  });

  return (
    <div className="p-6 max-w-4xl mx-auto">
      {/* Header */}
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold text-white">Conversations</h1>
          <p className="text-gray-500 text-sm mt-1 flex items-center gap-2">
            {loading ? <Loader2 className="w-3 h-3 animate-spin" /> : `${conversations.length} conversations`} · All agents
          </p>
        </div>
        <Link
          href="/conversations/new"
          className="flex items-center gap-2 px-4 py-2.5 bg-gradient-to-r from-[#FF1D6C] to-violet-600 rounded-xl text-sm font-medium text-white transition-all hover:shadow-lg hover:shadow-[#FF1D6C]/25"
        >
          <Plus className="w-4 h-4" />
          New
        </Link>
      </div>

      {/* Search */}
      <div className="relative mb-4">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-500" />
        <input
          type="text"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          placeholder="Search conversations..."
          className="w-full pl-10 pr-4 py-2.5 bg-white/5 border border-white/10 rounded-xl text-sm text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-[#FF1D6C]/50 transition-all"
        />
      </div>

      {/* Agent filter pills */}
      <div className="flex gap-2 mb-6 flex-wrap">
        {AGENTS.map((a) => (
          <button
            key={a.value}
            onClick={() => setFilter(a.value)}
            className={`flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-medium transition-all ${
              filter === a.value
                ? 'bg-white text-black'
                : 'bg-white/5 border border-white/10 text-gray-400 hover:text-white'
            }`}
          >
            {a.color && (
              <span className="w-2 h-2 rounded-full" style={{ backgroundColor: a.color }} />
            )}
            {a.name}
          </button>
        ))}
      </div>

      {/* Conversation list */}
      <div className="space-y-2">
        {filtered.map((conv) => (
          <Link
            key={conv.id}
            href={`/conversations/${conv.id}`}
            className="flex items-start gap-4 p-4 bg-white/5 border border-white/10 rounded-xl hover:border-white/20 hover:bg-white/[0.07] transition-all group"
          >
            {/* Agent dot */}
            <div className="flex-shrink-0 mt-1">
              <div
                className="w-8 h-8 rounded-full flex items-center justify-center text-white text-xs font-bold"
                style={{ backgroundColor: conv.agentColor + '33', border: `1px solid ${conv.agentColor}44` }}
              >
                <Bot className="w-4 h-4" style={{ color: conv.agentColor }} />
              </div>
            </div>

            {/* Content */}
            <div className="flex-1 min-w-0">
              <div className="flex items-center gap-2 mb-1">
                <span className="text-xs font-medium" style={{ color: conv.agentColor }}>{conv.agent}</span>
                <span className="text-xs text-gray-600 flex items-center gap-1">
                  <Clock className="w-3 h-3" />
                  {conv.timestamp}
                </span>
              </div>
              <div className="text-sm font-semibold text-white mb-1 truncate">{conv.title}</div>
              <div className="text-xs text-gray-500 truncate">{conv.lastMessage}</div>
            </div>

            <MessageSquare className="w-4 h-4 text-gray-700 group-hover:text-gray-400 transition-colors flex-shrink-0 mt-1" />
          </Link>
        ))}

        {filtered.length === 0 && (
          <div className="text-center py-16">
            <MessageSquare className="w-12 h-12 text-gray-700 mx-auto mb-4" />
            <p className="text-gray-500">No conversations match your filter.</p>
            <Link href="/conversations/new" className="text-sm text-[#FF1D6C] hover:underline mt-2 inline-block">
              Start a new one →
            </Link>
          </div>
        )}
      </div>
    </div>
  );
}
