'use client';

import { useEffect, useState } from 'react';

interface Agent {
  id: string;
  name: string;
  role: string;
  type: string;
  status: 'active' | 'idle' | 'offline';
  node: string;
  color: string;
}

interface AgentData {
  agents: Agent[];
  fleet?: { total_capacity: number; online_nodes: number };
  worlds_count?: number;
  fallback?: boolean;
}

export default function AgentsPage() {
  const [data, setData] = useState<AgentData | null>(null);
  const [loading, setLoading] = useState(true);

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

  if (loading) return <div className="p-6 text-gray-500">Loading agents…</div>;
  if (!data) return <div className="p-6 text-red-400">Failed to load agents.</div>;

  return (
    <div className="p-6 max-w-4xl mx-auto">
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-white">🤖 Live Agents</h1>
        <p className="text-gray-400 text-sm mt-1">
          {data.fleet?.online_nodes ?? data.agents.length} nodes online ·{' '}
          {(data.fleet?.total_capacity ?? 30000).toLocaleString()} agent capacity
          {data.fallback && (
            <span className="ml-2 text-yellow-500 text-xs">(offline mode)</span>
          )}
        </p>
      </div>

      {/* Fleet stats bar */}
      <div className="grid grid-cols-3 gap-3 mb-6">
        <div className="bg-gray-900 border border-gray-800 rounded-lg p-3">
          <div className="text-xs text-gray-500 mb-1">Fleet Capacity</div>
          <div className="text-xl font-bold text-white">
            {(data.fleet?.total_capacity ?? 30000).toLocaleString()}
          </div>
          <div className="text-xs text-gray-600">agents</div>
        </div>
        <div className="bg-gray-900 border border-gray-800 rounded-lg p-3">
          <div className="text-xs text-gray-500 mb-1">Active Nodes</div>
          <div className="text-xl font-bold text-green-400">
            {data.fleet?.online_nodes ?? data.agents.length}
          </div>
          <div className="text-xs text-gray-600">Pi nodes</div>
        </div>
        <div className="bg-gray-900 border border-gray-800 rounded-lg p-3">
          <div className="text-xs text-gray-500 mb-1">Worlds Generated</div>
          <div className="text-xl font-bold text-purple-400">
            {data.worlds_count ?? '60+'}
          </div>
          <div className="text-xs text-gray-600">artifacts</div>
        </div>
      </div>

      {/* Agent cards */}
      <div className="grid gap-3 sm:grid-cols-2">
        {data.agents.map(agent => (
          <div
            key={agent.id}
            className="bg-gray-900 border border-gray-800 rounded-lg p-4 flex items-start gap-3"
          >
            <div
              className="w-3 h-3 rounded-full mt-1 flex-shrink-0"
              style={{ backgroundColor: agent.color }}
            />
            <div className="flex-1 min-w-0">
              <div className="flex items-center gap-2">
                <span className="font-semibold text-white">{agent.name}</span>
                <span
                  className={`text-xs px-1.5 py-0.5 rounded ${
                    agent.status === 'active'
                      ? 'bg-green-900 text-green-400'
                      : 'bg-gray-800 text-gray-500'
                  }`}
                >
                  {agent.status}
                </span>
              </div>
              <div className="text-sm text-gray-400 mt-0.5">{agent.role}</div>
              <div className="text-xs text-gray-600 mt-1">
                📍 {agent.node} · {agent.type}
              </div>
            </div>
          </div>
        ))}
      </div>

      <div className="mt-4 text-xs text-gray-600 text-center">
        Live data from{' '}
        <a href="https://agents-status.blackroad.io" target="_blank" rel="noreferrer" className="text-gray-500 hover:text-white">
          agents-status.blackroad.io
        </a>
        {' · '}refreshes every 30s
      </div>
    </div>
  );
}
