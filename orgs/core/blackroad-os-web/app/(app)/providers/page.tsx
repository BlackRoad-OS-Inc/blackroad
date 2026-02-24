// app/(app)/providers/page.tsx
import { Cloud, CheckCircle, XCircle, AlertCircle } from 'lucide-react'

const PROVIDERS = [
  { id: 'ollama',    name: 'Ollama',    icon: '🦙', color: '#4A9EFF', endpoint: 'http://localhost:11434' },
  { id: 'openai',    name: 'OpenAI',    icon: '🤖', color: '#10A37F', endpoint: 'https://api.openai.com/v1' },
  { id: 'anthropic', name: 'Anthropic', icon: '🔷', color: '#8B5CF6', endpoint: 'https://api.anthropic.com' },
  { id: 'gemini',    name: 'Gemini',    icon: '✨', color: '#F5A623', endpoint: 'https://generativelanguage.googleapis.com' },
  { id: 'deepseek',  name: 'DeepSeek',  icon: '🌊', color: '#FF1D6C', endpoint: 'https://api.deepseek.com' },
  { id: 'groq',      name: 'Groq',      icon: '⚡', color: '#F97316', endpoint: 'https://api.groq.com/openai' },
  { id: 'mistral',   name: 'Mistral',   icon: '🌫️', color: '#6366F1', endpoint: 'https://api.mistral.ai' },
]

async function getGatewayProviders() {
  try {
    const res = await fetch('http://127.0.0.1:8787/v1/providers', { next: { revalidate: 30 } })
    if (!res.ok) return null
    return await res.json()
  } catch { return null }
}

export default async function ProvidersPage() {
  const data = await getGatewayProviders()
  return (
    <div className="p-8 max-w-5xl">
      <h1 className="text-3xl font-bold mb-2">AI Providers</h1>
      <p className="text-muted-foreground mb-8">
        7 providers connected through the BlackRoad tokenless gateway
      </p>
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {PROVIDERS.map(p => (
          <div key={p.id} className="rounded-xl border p-5 flex flex-col gap-3">
            <div className="flex items-center gap-3">
              <span className="text-3xl">{p.icon}</span>
              <div>
                <div className="font-semibold text-lg">{p.name}</div>
                <div className="text-xs text-muted-foreground font-mono">{p.id}</div>
              </div>
            </div>
            <div className="text-xs text-muted-foreground font-mono truncate">{p.endpoint}</div>
            {data && (
              <div className="flex items-center gap-2 text-xs">
                <CheckCircle className="w-3 h-3 text-green-500" />
                <span className="text-green-600">Registered in gateway</span>
              </div>
            )}
          </div>
        ))}
      </div>
      {!data && (
        <p className="mt-4 text-sm text-muted-foreground">
          💡 Start the gateway to see live provider status: <code className="font-mono text-xs">br gateway start</code>
        </p>
      )}
    </div>
  )
}
