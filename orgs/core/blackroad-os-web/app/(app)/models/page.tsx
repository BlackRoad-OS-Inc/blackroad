// app/(app)/models/page.tsx
async function getModels() {
  try {
    const res = await fetch('http://localhost:11434/api/tags', { next: { revalidate: 60 } })
    if (!res.ok) return []
    const data = await res.json()
    return data.models || []
  } catch { return [] }
}

const MODEL_META: Record<string, { provider: string; icon: string; desc: string }> = {
  'qwen': { provider: 'Alibaba', icon: '🌊', desc: 'Powerful multilingual reasoning' },
  'deepseek': { provider: 'DeepSeek', icon: '🔵', desc: 'Advanced code & reasoning' },
  'llama': { provider: 'Meta', icon: '🦙', desc: 'Open-source foundation model' },
  'mistral': { provider: 'Mistral AI', icon: '🌫️', desc: 'Efficient European model' },
  'phi': { provider: 'Microsoft', icon: '🔷', desc: 'Small language model' },
  'gemma': { provider: 'Google', icon: '💎', desc: 'Google open model' },
}

function getModelMeta(name: string) {
  for (const [key, meta] of Object.entries(MODEL_META)) {
    if (name.toLowerCase().includes(key)) return meta
  }
  return { provider: 'Unknown', icon: '🤖', desc: 'AI language model' }
}

export default async function ModelsPage() {
  const models = await getModels()
  return (
    <div className="p-8 max-w-5xl">
      <h1 className="text-3xl font-bold mb-2">Model Catalog</h1>
      <p className="text-muted-foreground mb-8">
        {models.length > 0 ? `${models.length} models loaded in Ollama` : 'Connect Ollama to see local models'}
      </p>
      {models.length === 0 ? (
        <div className="rounded-xl border p-8 text-center text-muted-foreground">
          <div className="text-4xl mb-4">🦙</div>
          <p>No models found. Start Ollama and pull a model:</p>
          <code className="text-xs font-mono mt-2 block">ollama pull qwen2.5:7b</code>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {models.map((m: any) => {
            const meta = getModelMeta(m.name)
            const sizeGB = m.size ? (m.size / 1e9).toFixed(1) : '?'
            return (
              <div key={m.name} className="rounded-xl border p-5 flex items-start gap-4">
                <span className="text-3xl">{meta.icon}</span>
                <div className="flex-1 min-w-0">
                  <div className="font-semibold font-mono text-sm truncate">{m.name}</div>
                  <div className="text-xs text-muted-foreground">{meta.provider} · {meta.desc}</div>
                  <div className="text-xs text-muted-foreground mt-1">{sizeGB} GB · {m.details?.parameter_size || '?'} params</div>
                </div>
              </div>
            )
          })}
        </div>
      )}
    </div>
  )
}
