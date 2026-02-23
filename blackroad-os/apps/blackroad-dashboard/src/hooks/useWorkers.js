import { useState, useEffect, useCallback } from 'react'

const WORKERS = [
  { name: 'blackroad-os-api',    url: 'https://blackroad-os-api.amundsonalexa.workers.dev/health' },
  { name: 'email-router',        url: 'https://blackroad-email-router.amundsonalexa.workers.dev/health' },
]

export function useWorkers() {
  const [statuses, setStatuses] = useState({})
  const [loading, setLoading] = useState(true)

  const ping = useCallback(async () => {
    const results = await Promise.all(
      WORKERS.map(async w => {
        const t0 = Date.now()
        try {
          const r = await fetch(w.url, { signal: AbortSignal.timeout(5000) })
          const data = await r.json()
          return { ...w, ok: r.ok, latency: Date.now() - t0, data }
        } catch {
          return { ...w, ok: false, latency: Date.now() - t0, data: null }
        }
      })
    )
    const map = {}
    results.forEach(r => { map[r.name] = r })
    setStatuses(map)
    setLoading(false)
  }, [])

  useEffect(() => { ping(); const t = setInterval(ping, 20000); return () => clearInterval(t) }, [ping])
  return { statuses, loading, workers: WORKERS, reload: ping }
}
