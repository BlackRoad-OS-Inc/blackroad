'use client';

import { useEffect, useState } from 'react';

interface LiveStats {
  total_repos?: number;
  online_count?: number;
  active_agents?: number;
  updated_at?: string;
}

const LIVE_API = 'https://blackroad-live-data.blackroad.workers.dev';

export function LiveStatsBar() {
  const [stats, setStats] = useState<LiveStats>({});
  const [loading, setLoading] = useState(true);

  async function refresh() {
    try {
      const [gh, agents] = await Promise.allSettled([
        fetch(`${LIVE_API}/github/stats`).then(r => r.json()),
        fetch(`${LIVE_API}/agents/status`).then(r => r.json()),
      ]);
      setStats({
        total_repos: gh.status === 'fulfilled' ? gh.value.total_repos : undefined,
        online_count: agents.status === 'fulfilled' ? agents.value.online_count : undefined,
        active_agents: agents.status === 'fulfilled' ? agents.value.active_agents : undefined,
        updated_at: new Date().toISOString(),
      });
    } catch {}
    setLoading(false);
  }

  useEffect(() => {
    refresh();
    const id = setInterval(refresh, 60_000);
    return () => clearInterval(id);
  }, []);

  if (loading) return null;

  return (
    <div className="w-full bg-black/60 border-b border-white/5 py-2 px-4">
      <div className="max-w-7xl mx-auto flex flex-wrap items-center gap-4 text-xs text-gray-500">
        <span className="flex items-center gap-1">
          <span className="w-1.5 h-1.5 rounded-full bg-amber-500 animate-pulse" />
          <span className="text-amber-500 font-mono">BlackRoad-OS</span>
          {stats.total_repos && <span className="text-white">{stats.total_repos.toLocaleString()} repos</span>}
        </span>
        <span>·</span>
        <span>🤖 Agents: <span className="text-hot-pink">{stats.online_count ?? '?'}/4</span> Pi nodes</span>
        <span>·</span>
        <span>⚡ <span className="text-electric-blue">{(stats.active_agents ?? 30000).toLocaleString()}</span> active</span>
        <span>·</span>
        <span>☁️ <span className="text-violet-400">58</span> CF Pages</span>
        <span>·</span>
        <span>🚂 <span className="text-amber-400">14</span> Railway</span>
        {stats.updated_at && (
          <span className="ml-auto text-gray-700">
            Live · {new Date(stats.updated_at).toLocaleTimeString()}
          </span>
        )}
      </div>
    </div>
  );
}

export function RecentRepos() {
  const [repos, setRepos] = useState<Array<{ name: string; url: string; language: string | null; pushed: string }>>([]);

  useEffect(() => {
    fetch(`${LIVE_API}/github/stats`)
      .then(r => r.json())
      .then(data => setRepos(data.recent_repos || []))
      .catch(() => {});
  }, []);

  if (!repos.length) return null;

  return (
    <div className="flex flex-wrap gap-2">
      {repos.map(r => (
        <a
          key={r.name}
          href={r.url}
          target="_blank"
          rel="noopener noreferrer"
          className="text-xs px-2 py-1 rounded bg-white/5 hover:bg-white/10 text-gray-400 hover:text-white transition-colors border border-white/10"
        >
          {r.language && <span className="text-amber-500 mr-1">●</span>}
          {r.name}
        </a>
      ))}
    </div>
  );
}

export function AgentStatusGrid() {
  const [fleet, setFleet] = useState<Array<{ name: string; ip: string; online: boolean; models?: number }>>([]);

  useEffect(() => {
    fetch(`${LIVE_API}/agents/status`)
      .then(r => r.json())
      .then(data => setFleet(data.fleet || []))
      .catch(() => {});
  }, []);

  return (
    <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
      {(fleet.length ? fleet : [
        { name: 'octavia', ip: '192.168.4.38', online: true, models: 108 },
        { name: 'alice', ip: '192.168.4.49', online: true, models: 0 },
        { name: 'aria', ip: '192.168.4.82', online: true, models: 0 },
        { name: 'gematria', ip: '159.65.43.12', online: true, type: 'droplet' },
      ]).map(node => (
        <div key={node.name} className="p-3 rounded-lg bg-white/5 border border-white/10">
          <div className="flex items-center gap-2 mb-1">
            <span className={`w-2 h-2 rounded-full ${node.online ? 'bg-green-500 animate-pulse' : 'bg-red-500'}`} />
            <span className="text-sm font-medium capitalize text-white">{node.name}</span>
          </div>
          <div className="text-xs text-gray-500">{node.ip}</div>
          {node.models != null && node.models > 0 && (
            <div className="text-xs text-amber-500 mt-1">{node.models} models</div>
          )}
        </div>
      ))}
    </div>
  );
}
