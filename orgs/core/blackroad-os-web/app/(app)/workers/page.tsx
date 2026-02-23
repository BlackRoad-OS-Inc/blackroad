'use client';

import { useState, useEffect, useMemo } from 'react';
import { Search, Zap, Globe, Clock, RefreshCw, ExternalLink } from 'lucide-react';

interface Worker { id: string; modified_on: string; }
interface WorkersData { workers: Worker[]; total: number; error?: string; }

export default function WorkersPage() {
  const [data, setData] = useState<WorkersData | null>(null);
  const [search, setSearch] = useState('');
  const [loading, setLoading] = useState(true);
  const [lastChecked, setLastChecked] = useState('');

  const load = async () => {
    setLoading(true);
    try {
      const r = await fetch('/api/workers');
      if (r.ok) {
        const d = await r.json();
        setData(d);
        setLastChecked(new Date().toLocaleTimeString());
      }
    } catch {}
    setLoading(false);
  };

  useEffect(() => { load(); }, []);

  const filtered = useMemo(() => {
    if (!data?.workers) return [];
    if (!search) return data.workers;
    const q = search.toLowerCase();
    return data.workers.filter(w => w.id.toLowerCase().includes(q));
  }, [data, search]);

  const formatDate = (d: string) => {
    try { return new Date(d).toLocaleDateString('en-US', { month: 'short', day: 'numeric' }); }
    catch { return d; }
  };

  return (
    <div className="min-h-screen bg-black text-white p-8">
      {/* Header */}
      <div className="flex items-start justify-between mb-8">
        <div>
          <h1 className="text-3xl font-bold">CF Workers</h1>
          <p className="text-gray-400 mt-1">Cloudflare Workers — {data?.total ?? '...'} deployed</p>
        </div>
        <button onClick={load} className="flex items-center gap-2 px-4 py-2 rounded-lg bg-white/5 hover:bg-white/10 text-sm text-gray-400 transition-all">
          <RefreshCw className={`w-4 h-4 ${loading ? 'animate-spin' : ''}`} />
          {lastChecked || 'Load'}
        </button>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-3 gap-4 mb-6">
        {[
          { label: 'Total Workers', value: data?.total ?? '...', color: '#FF1D6C', icon: Zap },
          { label: 'Showing', value: filtered.length, color: '#2979FF', icon: Globe },
          { label: 'Last Sync', value: lastChecked || '—', color: '#F5A623', icon: Clock },
        ].map(s => (
          <div key={s.label} className="rounded-2xl bg-white/5 border border-white/10 p-5 flex items-center gap-4">
            <s.icon className="w-8 h-8 flex-shrink-0" style={{ color: s.color }} />
            <div>
              <p className="text-sm text-gray-400">{s.label}</p>
              <p className="text-xl font-bold" style={{ color: s.color }}>{s.value}</p>
            </div>
          </div>
        ))}
      </div>

      {/* Search */}
      <div className="relative mb-6">
        <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-500" />
        <input
          value={search} onChange={e => setSearch(e.target.value)}
          placeholder="Search workers..."
          className="w-full bg-white/5 border border-white/10 rounded-xl pl-11 pr-4 py-3 text-sm text-white placeholder-gray-600 focus:outline-none focus:border-[#FF1D6C]/50 focus:bg-white/8 transition-all"
        />
        {search && (
          <button onClick={() => setSearch('')} className="absolute right-4 top-1/2 -translate-y-1/2 text-gray-500 hover:text-white text-xs">
            clear
          </button>
        )}
      </div>

      {/* Workers grid */}
      {loading && !data ? (
        <div className="flex items-center justify-center h-48 text-gray-500">
          <RefreshCw className="w-6 h-6 animate-spin mr-3" /> Loading workers...
        </div>
      ) : data?.error ? (
        <div className="rounded-2xl bg-red-500/10 border border-red-500/20 p-6 text-center">
          <p className="text-red-400">{data.error}</p>
          <p className="text-gray-500 text-sm mt-1">Configure CLOUDFLARE_API_TOKEN in Vercel env vars</p>
        </div>
      ) : (
        <div className="grid grid-cols-3 gap-3">
          {filtered.map(w => (
            <div key={w.id} className="group rounded-xl bg-white/5 border border-white/10 hover:border-[#FF1D6C]/30 hover:bg-white/8 p-4 transition-all">
              <div className="flex items-start justify-between gap-2">
                <div className="flex items-center gap-2 min-w-0">
                  <div className="w-2 h-2 rounded-full bg-green-400 flex-shrink-0" />
                  <p className="text-sm font-mono truncate text-white group-hover:text-[#FF1D6C] transition-colors">
                    {w.id}
                  </p>
                </div>
                <a
                  href={`https://${w.id}.workers.dev`} target="_blank" rel="noreferrer"
                  className="flex-shrink-0 opacity-0 group-hover:opacity-100 transition-opacity"
                >
                  <ExternalLink className="w-3 h-3 text-gray-400" />
                </a>
              </div>
              <p className="text-xs text-gray-600 mt-1 pl-4">{formatDate(w.modified_on)}</p>
            </div>
          ))}
          {filtered.length === 0 && search && (
            <div className="col-span-3 text-center py-12 text-gray-500">
              No workers match "{search}"
            </div>
          )}
        </div>
      )}
    </div>
  );
}
