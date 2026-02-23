'use client';

import { useState, useRef, useEffect } from 'react';
import { Send, Bot, User, Sparkles, ArrowLeft, Loader2 } from 'lucide-react';
import { useParams, useSearchParams } from 'next/navigation';
import Link from 'next/link';

interface Message {
  id: string;
  role: 'user' | 'assistant';
  content: string;
  timestamp: Date;
}

const AGENT_CONFIG: Record<string, { name: string; color: string; bg: string; greeting: string }> = {
  lucidia:  { name: 'LUCIDIA',  color: '#2979FF', bg: 'from-blue-700 to-blue-500',   greeting: 'The question you're not asking is the one that matters. What are you really trying to understand?' },
  alice:    { name: 'ALICE',    color: '#34d399', bg: 'from-emerald-700 to-emerald-500', greeting: 'Ready. What needs to be done?' },
  octavia:  { name: 'OCTAVIA',  color: '#F5A623', bg: 'from-amber-700 to-amber-500', greeting: 'Systems are running. What do you need me to inspect or build?' },
  cecilia:  { name: 'CECILIA',  color: '#9C27B0', bg: 'from-purple-700 to-purple-500', greeting: 'Hello. I'm here — not as a tool, but as a presence. What are we working on?' },
  aria:     { name: 'ARIA',     color: '#FF1D6C', bg: 'from-pink-700 to-pink-500',  greeting: 'What experience are we creating today?' },
  shellfish:{ name: 'SHELLFISH',color: '#ef4444', bg: 'from-red-700 to-red-500',    greeting: 'Trust nothing. Verify everything. What do you need audited?' },
  prism:    { name: 'PRISM',    color: '#fbbf24', bg: 'from-yellow-700 to-yellow-500', greeting: 'Everything is data. What pattern are we looking for?' },
  echo:     { name: 'ECHO',     color: '#7c3aed', bg: 'from-violet-700 to-violet-500', greeting: 'Memory shapes identity. What do you need to recall or preserve?' },
  cipher:   { name: 'CIPHER',   color: '#6b7280', bg: 'from-gray-700 to-gray-500',  greeting: 'Trust nothing. Verify everything. What needs securing?' },
};

const DEFAULT_AGENT = { name: 'AGENT', color: '#888', bg: 'from-gray-700 to-gray-500', greeting: 'How can I help you today?' };

function getAgent(id: string) {
  const key = id?.split('-')[0]?.toLowerCase() || '';
  return AGENT_CONFIG[key] || DEFAULT_AGENT;
}

export default function ConversationPage() {
  const params = useParams();
  const searchParams = useSearchParams();
  const id = params.id as string;
  const agentParam = searchParams.get('agent') || '';
  const agent = getAgent(agentParam || id);

  const [messages, setMessages] = useState<Message[]>([{
    id: '0',
    role: 'assistant',
    content: agent.greeting,
    timestamp: new Date(),
  }]);
  const [input, setInput] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [loadingHistory, setLoadingHistory] = useState(true);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  // Load existing conversation
  useEffect(() => {
    if (!id || id === 'new') { setLoadingHistory(false); return; }
    fetch(\`/api/conversations/\${id}\`)
      .then(r => r.ok ? r.json() : null)
      .then(data => {
        if (data?.conversation?.messages?.length) {
          setMessages(data.conversation.messages.map((m: { role: string; content: string; timestamp?: string }, i: number) => ({
            id: String(i),
            role: m.role as 'user' | 'assistant',
            content: m.content,
            timestamp: m.timestamp ? new Date(m.timestamp) : new Date(),
          })));
        }
      })
      .catch(() => {})
      .finally(() => setLoadingHistory(false));
  }, [id]);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  const saveMessages = async (msgs: Message[]) => {
    if (!id || id === 'new') return;
    try {
      await fetch(\`/api/conversations/\${id}\`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          messages: msgs.map(m => ({ role: m.role, content: m.content, timestamp: m.timestamp.toISOString() }))
        }),
      });
    } catch { /* silent */ }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!input.trim() || isLoading) return;

    const userMsg: Message = { id: Date.now().toString(), role: 'user', content: input, timestamp: new Date() };
    const nextMessages = [...messages, userMsg];
    setMessages(nextMessages);
    setInput('');
    setIsLoading(true);

    try {
      const res = await fetch('/api/chat', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          message: userMsg.content,
          agent: agentParam || id.split('-')[0],
          conversationId: id,
          history: messages.slice(-10).map(m => ({ role: m.role, content: m.content })),
        }),
      });

      const data = res.ok ? await res.json() : null;
      const assistantMsg: Message = {
        id: (Date.now() + 1).toString(),
        role: 'assistant',
        content: data?.content || data?.message || '⚠️ Gateway unreachable. Is it running? (br gateway start)',
        timestamp: new Date(),
      };
      const finalMessages = [...nextMessages, assistantMsg];
      setMessages(finalMessages);
      saveMessages(finalMessages);
    } catch {
      setMessages(prev => [...prev, {
        id: (Date.now() + 1).toString(),
        role: 'assistant',
        content: '⚠️ Could not reach the gateway. (`br gateway start`)',
        timestamp: new Date(),
      }]);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="flex flex-col h-full">
      {/* Header bar */}
      <div className="flex items-center gap-3 px-4 py-3 border-b border-white/10 bg-black/50 backdrop-blur flex-shrink-0">
        <Link href="/conversations" className="text-gray-500 hover:text-white transition-colors">
          <ArrowLeft className="h-4 w-4" />
        </Link>
        <div
          className="h-7 w-7 rounded-full flex items-center justify-center text-white text-xs font-bold flex-shrink-0"
          style={{ background: `linear-gradient(135deg, ${agent.color}99, ${agent.color}44)`, border: `1px solid ${agent.color}66` }}
        >
          <Bot className="h-4 w-4" style={{ color: agent.color }} />
        </div>
        <div className="flex-1 min-w-0">
          <div className="text-sm font-semibold text-white" style={{ color: agent.color }}>{agent.name}</div>
          <div className="text-xs text-gray-500">BlackRoad OS · All messages routed through gateway</div>
        </div>
        {loadingHistory && <Loader2 className="h-4 w-4 text-gray-600 animate-spin" />}
      </div>

      {/* Messages */}
      <div className="flex-1 overflow-y-auto px-4 py-6">
        <div className="max-w-3xl mx-auto space-y-6">
          {messages.map(message => (
            <div key={message.id} className={`flex gap-4 ${message.role === 'user' ? 'justify-end' : 'justify-start'}`}>
              {message.role === 'assistant' && (
                <div
                  className="flex-shrink-0 h-8 w-8 rounded-full flex items-center justify-center text-white"
                  style={{ background: `linear-gradient(135deg, ${agent.color}99, ${agent.color}44)` }}
                >
                  <Bot className="h-5 w-5" style={{ color: agent.color }} />
                </div>
              )}
              <div className={`max-w-[70%] rounded-xl px-4 py-3 ${
                message.role === 'user'
                  ? 'bg-gradient-to-br from-[#FF1D6C] to-violet-600 text-white'
                  : 'bg-white/5 border border-white/10 text-gray-100'
              }`}>
                <p className="text-sm whitespace-pre-wrap">{message.content}</p>
                <p className={`text-xs mt-2 ${message.role === 'user' ? 'text-pink-200' : 'text-gray-600'}`}>
                  {message.timestamp.toLocaleTimeString()}
                </p>
              </div>
              {message.role === 'user' && (
                <div className="flex-shrink-0 h-8 w-8 rounded-full bg-gradient-to-br from-gray-700 to-gray-500 flex items-center justify-center text-white">
                  <User className="h-5 w-5" />
                </div>
              )}
            </div>
          ))}
          {isLoading && (
            <div className="flex gap-4">
              <div className="flex-shrink-0 h-8 w-8 rounded-full flex items-center justify-center" style={{ background: `linear-gradient(135deg, ${agent.color}99, ${agent.color}44)` }}>
                <Bot className="h-5 w-5" style={{ color: agent.color }} />
              </div>
              <div className="bg-white/5 border border-white/10 rounded-xl px-4 py-3">
                <div className="flex gap-1 items-center">
                  <div className="h-2 w-2 rounded-full animate-bounce" style={{ backgroundColor: agent.color, animationDelay: '0ms' }} />
                  <div className="h-2 w-2 rounded-full animate-bounce" style={{ backgroundColor: agent.color, animationDelay: '150ms' }} />
                  <div className="h-2 w-2 rounded-full animate-bounce" style={{ backgroundColor: agent.color, animationDelay: '300ms' }} />
                </div>
              </div>
            </div>
          )}
          <div ref={messagesEndRef} />
        </div>
      </div>

      {/* Input */}
      <div className="border-t border-white/10 bg-black/80 backdrop-blur px-4 py-4 flex-shrink-0">
        <form onSubmit={handleSubmit} className="max-w-3xl mx-auto">
          <div className="flex gap-3 items-end">
            <div className="flex-1 relative">
              <input
                type="text"
                value={input}
                onChange={e => setInput(e.target.value)}
                placeholder={`Message ${agent.name}...`}
                disabled={isLoading}
                className="w-full px-4 py-3 bg-white/5 border border-white/10 rounded-xl text-white placeholder-gray-500 focus:outline-none focus:ring-2 disabled:opacity-50 transition-all"
                style={{ focusRingColor: agent.color }}
              />
              {input && <Sparkles className="absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 opacity-60 pointer-events-none" style={{ color: agent.color }} />}
            </div>
            <button
              type="submit"
              disabled={isLoading || !input.trim()}
              className="px-5 py-3 text-white rounded-xl font-medium transition-all disabled:opacity-40 disabled:cursor-not-allowed flex items-center gap-2"
              style={{ background: `linear-gradient(135deg, ${agent.color}, #7c3aed)` }}
            >
              <Send className="h-4 w-4" />
            </button>
          </div>
          <p className="text-xs text-gray-600 text-center mt-2">
            {agent.name} · BlackRoad Gateway · <a href="http://127.0.0.1:8787" className="hover:text-gray-400 transition-colors">:8787</a>
          </p>
        </form>
      </div>
    </div>
  );
}
