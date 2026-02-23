import { useState, useEffect, useCallback } from 'react'

const WORKER = 'https://blackroad-os-api.amundsonalexa.workers.dev'

export function useAgents() {
  const [data, setData] = useState(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)

  const load = useCallback(async () => {
    try {
      const r = await fetch(`${WORKER}/agents`)
      setData(await r.json())
      setError(null)
    } catch (e) {
      setError(e.message)
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => { load(); const t = setInterval(load, 30000); return () => clearInterval(t) }, [load])
  return { data, loading, error, reload: load }
}
