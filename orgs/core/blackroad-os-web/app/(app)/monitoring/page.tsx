'use client';

import { useEffect, useState } from 'react';
import { Activity, Cpu, Globe, Zap, CheckCircle, AlertCircle, RefreshCw } from 'lucide-react';

interface ServiceStatus {
  name: string;
  status: 'operational' | 'degraded' | 'down';
  latency?: number;
}

interface StatusData {
  status: string;
  services: ServiceStatus[];
  timestamp: string;
}

interface FleetNode {
  name: string;
  ip: string;
  role: string;
  capacity: number;
  status: string;
}

interface FleetData {
  nodes: FleetNode[];
  summary: {
    total_nodes: number;
    online_nodes: number;
    total_capacity: number;
  };
  timestamp: string;
}

interface AgentData {
  agents: { id: string; name: string; role: string; status: string; node: string; color: string }[];
  fleet?: { total_capacity: number; online_nodes: number };
}

const STATUS_COLOR = {
  operational: '#22c55e',
  degraded: '#F5A623',
  down: '#ef4444',
  online: '#22c55e',
  offline: '#ef4444',
  unknown: '#555',
};

function StatusDot({ status }: { status: string }) {
  const color = STATUS_COLOR[status as keyof typeof STATUS_COLOR] || '#555';
  return (
    <span
      className="inline-block w-2 h-2 rounded-full"
      style={{
        backgroundColor: color,
        boxShadow: status === 'operational' || status === 'online' ? `0 0 6px ${color}` : 'none',
      }}
    />
  );
}

export default function MonitoringPage() {
  const [statusData, setStatusData] = useState<StatusData | null>(null);
  const [fleetData, setFleetData] = useState<FleetData | null>(null);
  const [agentData, setAgentData] = useState<AgentData | null>(null);
  const [refreshing, setRefreshing] = useState(false);
  const [lastRefresh, setLastRefresh] = useState<Date>(new Date());

  async function refresh() {
    setRefreshing(true);
    try {
      const [s, f, a] = await Promise.all([
        fetch('/api/status').then(r => r.json()),
        fetch('/api/fleet').then(r => r.json()),
        fetch('/api/agents').then(r => r.json()),
      ]);
      setStatusData(s);
      setFleetData(f);
      setAgentData(a);
      setLastRefresh(new Date());
    } catch { /* ignore */ } finally {
      setRefreshing(false);
    }
  }

  useEffect(() => {
    refresh();
    const interval = setInterval(refresh, 30000);
    return () => clearInterval(interval);
  }, []);

  const overallColor = statusData?.status === 'operational'
    ? '#22c55e'
    : statusData?.status === 'partial_outage'
    ? '#F5A623'
    : '#ef4444';

  return (
    <div className="p-6 max-w-5xl mx-auto space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-white flex items-center gap-2">
            <Activity className="w-6 h-6 text-[#FF1D6C]" />
            Monitoring
          </h1>
          <p className="text-gray-500 text-sm mt-1">
            Live fleet status · refreshes every 30s · last updated {lastRefresh.toLocaleTimeString()}
          </p>
        </div>
        <button
          onClick={refresh}
          disabled={refreshing}
          className="flex items-center gap-2 px-3 py-2 bg-white/5 border border-white/10 rounded-xl text-sm text-gray-400 hover:text-white hover:border-white/20 transition-all disabled:opacity-50"
        >
          <RefreshCw className={`w-4 h-4 ${refreshing ? 'animate-spin' : ''}`} />
          Refresh
        </button>
      </div>

      {/* Infra stats bar */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
        {[
          { label: 'CF Workers', value: '499', color: '#F5A623' },
          { label: 'CF Zones', value: '20', color: '#2979FF' },
          { label: 'Agent Capacity', value: '30,000', color: '#FF1D6C' },
          { label: 'Online Nodes', value: fleetData?.summary?.online_nodes?.toString() ?? '3', color: '#22c55e' },
        ].map(s => (
          <div key={s.label} className="bg-white/5 border border-white/10 rounded-xl p-3 text-center">
            <div className="text-xl font-bold" style={{ color: s.color }}>{s.value}</div>
            <div className="text-xs text-gray-500 mt-0.5">{s.label}</div>
          </div>
        ))}
      </div>

      {/* Overall status banner */}
      <div
        className="flex items-center gap-3 p-4 rounded-xl border"
        style={{ borderColor: overallColor + '44', backgroundColor: overallColor + '11' }}
      >
        <StatusDot status={statusData?.status === 'operational' ? 'operational' : 'degraded'} />
        <span className="text-sm font-semibold text-white">
          {statusData?.status === 'operational'
            ? 'All systems operational'
            : statusData?.status === 'partial_outage'
            ? 'Partial outage detected'
            : 'Checking...'}
        </span>
        <span className="text-xs text-gray-500 ml-auto">{statusData?.timestamp ? new Date(statusData.timestamp).toLocaleTimeString() : '—'}</span>
      </div>

      {/* Fleet nodes */}
      <div>
        <h2 className="text-xs font-semibold text-gray-400 uppercase tracking-wider mb-3 flex items-center gap-2">
          <Cpu className="w-4 h-4" />
          Pi Fleet Nodes
        </h2>
        <div className="grid gap-3 sm:grid-cols-2">
          {(fleetData?.nodes || [
            { name: 'aria64', ip: '192.168.4.38', role: 'PRIMARY', capacity: 22500, status: 'online' },
            { name: 'alice', ip: '192.168.4.49', role: 'SECONDARY', capacity: 7500, status: 'online' },
          ]).map((node) => (
            <div
              key={node.name}
              className="bg-white/5 border border-white/10 rounded-xl p-4"
            >
              <div className="flex items-center justify-between mb-3">
                <div className="flex items-center gap-2">
                  <StatusDot status={node.status} />
                  <span className="font-semibold text-white text-sm">{node.name}</span>
                  <span className={`text-xs px-1.5 py-0.5 rounded font-mono ${
                    node.role === 'PRIMARY' ? 'bg-[#FF1D6C]/20 text-[#FF1D6C]' : 'bg-white/10 text-gray-400'
                  }`}>{node.role}</span>
                </div>
                <span className="text-xs text-gray-600 font-mono">{node.ip}</span>
              </div>
              <div className="flex items-center justify-between text-xs text-gray-500">
                <span>{node.capacity.toLocaleString()} agent slots</span>
                <span className="text-green-400">{node.status}</span>
              </div>
              {/* Capacity bar */}
              <div className="mt-2 h-1 bg-white/5 rounded-full overflow-hidden">
                <div
                  className="h-full rounded-full bg-gradient-to-r from-[#FF1D6C] to-violet-500"
                  style={{ width: `${(node.capacity / 30000) * 100}%` }}
                />
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Services */}
      <div>
        <h2 className="text-xs font-semibold text-gray-400 uppercase tracking-wider mb-3 flex items-center gap-2">
          <Globe className="w-4 h-4" />
          Platform Services
        </h2>
        <div className="bg-white/5 border border-white/10 rounded-xl overflow-hidden">
          {(statusData?.services || [
            { name: 'api', status: 'operational', latency: 12 },
            { name: 'database', status: 'operational', latency: 8 },
            { name: 'auth', status: 'operational', latency: 15 },
            { name: 'agents', status: 'operational', latency: 45 },
            { name: 'monitoring', status: 'operational', latency: 22 },
          ]).map((svc, i, arr) => (
            <div
              key={svc.name}
              className={`flex items-center justify-between px-4 py-3 ${
                i < arr.length - 1 ? 'border-b border-white/5' : ''
              }`}
            >
              <div className="flex items-center gap-3">
                {svc.status === 'operational'
                  ? <CheckCircle className="w-4 h-4 text-green-500" />
                  : <AlertCircle className="w-4 h-4 text-amber-500" />
                }
                <span className="text-sm text-white capitalize">{svc.name}</span>
              </div>
              <div className="flex items-center gap-4">
                {svc.latency && (
                  <span className="text-xs text-gray-500 font-mono">{svc.latency}ms</span>
                )}
                <span className={`text-xs capitalize font-medium ${
                  svc.status === 'operational' ? 'text-green-400' :
                  svc.status === 'degraded' ? 'text-amber-400' : 'text-red-400'
                }`}>{svc.status}</span>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Agent activity */}
      <div>
        <h2 className="text-xs font-semibold text-gray-400 uppercase tracking-wider mb-3 flex items-center gap-2">
          <Zap className="w-4 h-4" />
          Agent Activity
        </h2>
        <div className="grid gap-2 sm:grid-cols-2 lg:grid-cols-3">
          {(agentData?.agents || [
            { id: 'lucidia', name: 'Lucidia', role: 'Coordinator', status: 'active', node: 'aria64', color: '#2979FF' },
            { id: 'alice', name: 'Alice', role: 'Operator', status: 'active', node: 'alice', color: '#22c55e' },
            { id: 'octavia', name: 'Octavia', role: 'Architect', status: 'active', node: 'aria64', color: '#F5A623' },
            { id: 'cecilia', name: 'Cecilia', role: 'Core', status: 'active', node: 'aria64', color: '#9C27B0' },
            { id: 'aria', name: 'Aria', role: 'Interface', status: 'idle', node: 'alice', color: '#FF1D6C' },
            { id: 'shellfish', name: 'Shellfish', role: 'Security', status: 'active', node: 'aria64', color: '#ef4444' },
          ]).map((agent) => (
            <div key={agent.id} className="flex items-center gap-3 p-3 bg-white/5 border border-white/10 rounded-xl">
              <div className="w-2.5 h-2.5 rounded-full flex-shrink-0" style={{ backgroundColor: agent.color }} />
              <div className="flex-1 min-w-0">
                <div className="text-sm font-medium text-white">{agent.name}</div>
                <div className="text-xs text-gray-500">{agent.node}</div>
              </div>
              <span className={`text-xs px-2 py-0.5 rounded-full ${
                agent.status === 'active' ? 'bg-green-900/50 text-green-400' : 'bg-gray-800 text-gray-500'
              }`}>{agent.status}</span>
            </div>
          ))}
        </div>
      </div>

      {/* Quick links */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 pt-2">
        {[
          { label: 'Status Page', href: 'https://status.blackroad.io' },
          { label: 'Agent Status', href: 'https://agents-status.blackroad.io' },
          { label: 'Worlds API', href: 'https://worlds.blackroad.io' },
          { label: 'Gateway', href: 'http://127.0.0.1:8787' },
        ].map((link) => (
          <a
            key={link.label}
            href={link.href}
            target="_blank"
            rel="noreferrer"
            className="text-center p-2 bg-white/5 border border-white/10 rounded-lg text-xs text-gray-500 hover:text-white hover:border-white/20 transition-all"
          >
            {link.label} ↗
          </a>
        ))}
      </div>

    </div>
  );
}
