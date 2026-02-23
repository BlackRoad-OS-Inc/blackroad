import { Suspense } from "react"

async function fetchWorlds() {
  try {
    const res = await fetch("https://worlds.blackroad.io", {
      next: { revalidate: 60 },
    })
    return res.ok ? res.json() : { worlds: [] }
  } catch {
    return { worlds: [] }
  }
}

async function fetchStats() {
  try {
    const res = await fetch("https://worlds.blackroad.io/stats", {
      next: { revalidate: 60 },
    })
    return res.ok ? res.json() : null
  } catch {
    return null
  }
}

function WorldCard({ world }: { world: any }) {
  return (
    <div className="bg-zinc-900 border border-zinc-800 rounded-lg p-4 hover:border-zinc-600 transition-colors">
      <div className="flex items-center justify-between mb-2">
        <span className={`text-xs px-2 py-0.5 rounded font-mono uppercase tracking-wider ${
          world.type === "lore" ? "bg-violet-900/50 text-violet-300" :
          world.type === "code" ? "bg-emerald-900/50 text-emerald-300" :
          "bg-sky-900/50 text-sky-300"
        }`}>{world.type}</span>
        <span className="text-xs text-zinc-600">{world.node}</span>
      </div>
      <h3 className="font-semibold text-zinc-100 mb-1 line-clamp-2">{world.title}</h3>
      {world.excerpt && (
        <p className="text-sm text-zinc-400 line-clamp-3">{world.excerpt}</p>
      )}
      <div className="mt-3 flex items-center gap-2">
        <span className="text-xs text-zinc-600 font-mono">
          {new Date(world.generated_at).toLocaleDateString()}
        </span>
      </div>
    </div>
  )
}

export default async function WorldsPage() {
  const [data, stats] = await Promise.all([fetchWorlds(), fetchStats()])
  const worlds = data?.worlds ?? []

  return (
    <div className="min-h-screen bg-zinc-950 text-zinc-100 p-6 md:p-10">
      <div className="max-w-6xl mx-auto">
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-white mb-2">🌐 AI Worlds</h1>
          <p className="text-zinc-400">Generated autonomously by BlackRoad Pi fleet</p>
        </div>

        {stats && (
          <div className="grid grid-cols-3 gap-4 mb-8">
            {[
              { label: "Total Worlds", value: stats.total },
              { label: "World Types", value: Object.keys(stats.by_type ?? {}).length },
              { label: "Pi Nodes", value: Object.keys(stats.by_node ?? {}).length },
            ].map((s) => (
              <div key={s.label} className="bg-zinc-900 border border-zinc-800 rounded-lg p-4 text-center">
                <div className="text-2xl font-bold text-white">{s.value}</div>
                <div className="text-xs text-zinc-500 mt-1">{s.label}</div>
              </div>
            ))}
          </div>
        )}

        {stats?.by_type && (
          <div className="flex gap-3 mb-8 flex-wrap">
            {Object.entries(stats.by_type).map(([type, count]: [string, any]) => (
              <div key={type} className="bg-zinc-900 border border-zinc-800 rounded-lg px-4 py-2">
                <span className="text-zinc-400 text-sm">{type}: </span>
                <span className="text-white font-semibold">{count}</span>
              </div>
            ))}
          </div>
        )}

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {worlds.slice(0, 30).map((world: any) => (
            <WorldCard key={world.id ?? world.title} world={world} />
          ))}
        </div>

        {worlds.length === 0 && (
          <div className="text-center py-20 text-zinc-600">
            <div className="text-4xl mb-4">🌍</div>
            <p>No worlds loaded — Pi fleet may be offline</p>
            <a href="https://worlds.blackroad.io" className="text-blue-400 hover:underline text-sm mt-2 inline-block">
              worlds.blackroad.io ↗
            </a>
          </div>
        )}
      </div>
    </div>
  )
}

export const metadata = {
  title: "AI Worlds | BlackRoad OS",
  description: "Autonomously generated world artifacts from the BlackRoad Pi fleet",
}
