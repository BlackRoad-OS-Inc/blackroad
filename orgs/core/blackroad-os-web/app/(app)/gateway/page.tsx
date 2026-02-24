import { Activity, Server, Zap, Shield, Brain } from 'lucide-react'

interface GatewayStats {
  status: 'online' | 'offline'
  providers: string[]
  metrics: {
    total_requests: number
    successful: number
    errors: number
  }
}

interface MemoryStats {
  journal_entries: number
  context_keys: number
  total_session_calls: number
  session_calls: Record<string, number>
}

const GATEWAY_URL = process.env.NEXT_PUBLIC_GATEWAY_URL || 'http://127.0.0.1:8787'

async function getGatewayData(): Promise<{ stats: GatewayStats | null; memory: MemoryStats | null; providers: string[] }> {
  try {
    const [statsResp, memResp, provResp] = await Promise.allSettled([
      fetch(`${GATEWAY_URL}/metrics`, { next: { revalidate: 10 } }),
      fetch(`${GATEWAY_URL}/v1/memory`, { next: { revalidate: 10 } }),
      fetch(`${GATEWAY_URL}/v1/providers`, { next: { revalidate: 60 } }),
    ])

    const stats = statsResp.status === 'fulfilled' && statsResp.value.ok
      ? { status: 'online' as const, providers: [], metrics: (await statsResp.value.json()).metrics || {} }
      : null

    const memory = memResp.status === 'fulfilled' && memResp.value.ok
      ? (await memResp.value.json()).memory
      : null

    const providers = provResp.status === 'fulfilled' && provResp.value.ok
      ? (await provResp.value.json()).providers || []
      : ['ollama', 'openai', 'anthropic', 'gemini', 'deepseek', 'groq', 'mistral']

    return { stats, memory, providers }
  } catch {
    return { stats: null, memory: null, providers: ['ollama', 'openai', 'anthropic', 'gemini', 'deepseek', 'groq', 'mistral'] }
  }
}

export default async function GatewayPage() {
  const { stats, memory, providers } = await getGatewayData()
  const isOnline = stats !== null

  const providerIcons: Record<string, string> = {
    ollama: '🦙', openai: '🤖', anthropic: '🧬', claude: '🧬',
    gemini: '💎', deepseek: '🔭', groq: '⚡', mistral: '💨'
  }

  return (
    <div className="p-6 space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold">Gateway</h1>
          <p className="text-gray-500 text-sm mt-1">BlackRoad Core AI Gateway — tokenless provider routing</p>
        </div>
        <div className={`flex items-center gap-2 px-3 py-1.5 rounded-full text-sm font-medium ${
          isOnline ? 'bg-green-50 text-green-700' : 'bg-gray-100 text-gray-500'
        }`}>
          <span className={`w-2 h-2 rounded-full ${isOnline ? 'bg-green-500 animate-pulse' : 'bg-gray-400'}`} />
          {isOnline ? 'Online' : 'Offline'}
        </div>
      </div>

      {/* Metrics Row */}
      <div className="grid grid-cols-3 gap-4">
        {[
          { label: 'Total Requests', value: stats?.metrics?.total_requests ?? '—', icon: Activity },
          { label: 'Successful', value: stats?.metrics?.successful ?? '—', icon: Zap },
          { label: 'Errors', value: stats?.metrics?.errors ?? '—', icon: Shield },
        ].map(({ label, value, icon: Icon }) => (
          <div key={label} className="bg-white border rounded-xl p-4 flex items-center gap-3">
            <Icon className="w-5 h-5 text-gray-400" />
            <div>
              <div className="text-2xl font-bold">{value}</div>
              <div className="text-xs text-gray-500">{label}</div>
            </div>
          </div>
        ))}
      </div>

      {/* Providers */}
      <div className="bg-white border rounded-xl p-5">
        <h2 className="font-semibold mb-4 flex items-center gap-2">
          <Brain className="w-4 h-4" /> AI Providers ({providers.length})
        </h2>
        <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-3">
          {providers.map(p => (
            <div key={p} className="flex items-center gap-2 p-3 bg-gray-50 rounded-lg">
              <span className="text-lg">{providerIcons[p] || '🔌'}</span>
              <span className="text-sm font-medium capitalize">{p}</span>
            </div>
          ))}
        </div>
      </div>

      {/* Memory */}
      {memory && (
        <div className="bg-white border rounded-xl p-5">
          <h2 className="font-semibold mb-4 flex items-center gap-2">
            <Server className="w-4 h-4" /> PS-SHA∞ Memory Journal
          </h2>
          <div className="grid grid-cols-3 gap-4 mb-4">
            <div className="text-center">
              <div className="text-2xl font-bold">{memory.journal_entries}</div>
              <div className="text-xs text-gray-500">Journal Entries</div>
            </div>
            <div className="text-center">
              <div className="text-2xl font-bold">{memory.total_session_calls}</div>
              <div className="text-xs text-gray-500">Session Calls</div>
            </div>
            <div className="text-center">
              <div className="text-2xl font-bold">{memory.context_keys}</div>
              <div className="text-xs text-gray-500">Context Keys</div>
            </div>
          </div>
          {memory.session_calls && Object.keys(memory.session_calls).length > 0 && (
            <div className="space-y-2">
              <div className="text-xs font-medium text-gray-500 uppercase tracking-wide">By Agent</div>
              {Object.entries(memory.session_calls)
                .sort(([,a], [,b]) => b - a)
                .map(([agent, count]) => (
                  <div key={agent} className="flex items-center gap-3">
                    <span className="text-sm w-24 truncate">{agent}</span>
                    <div className="flex-1 bg-gray-100 rounded-full h-2">
                      <div
                        className="bg-indigo-500 rounded-full h-2"
                        style={{ width: `${Math.min(100, (count / memory.total_session_calls) * 100)}%` }}
                      />
                    </div>
                    <span className="text-sm text-gray-500 w-8 text-right">{count}</span>
                  </div>
                ))}
            </div>
          )}
        </div>
      )}

      {/* Offline state */}
      {!isOnline && (
        <div className="bg-amber-50 border border-amber-200 rounded-xl p-5 text-center">
          <p className="text-amber-700 font-medium">Gateway is offline</p>
          <p className="text-amber-600 text-sm mt-1">Run <code className="bg-amber-100 px-1.5 py-0.5 rounded">br gateway start</code> to start the gateway</p>
        </div>
      )}
    </div>
  )
}
