import { useEffect, useState, useCallback } from "react";

export interface WorldArtifact {
  id: string;
  filename: string;
  date: string;
  type: "world" | "lore" | "code" | string;
  name: string;
  url: string;
}

interface UseWorldsOptions {
  refreshInterval?: number; // ms, default 60000
  filter?: string;
}

export function useWorlds(options: UseWorldsOptions = {}) {
  const { refreshInterval = 60_000, filter = "all" } = options;
  const [artifacts, setArtifacts] = useState<WorldArtifact[]>([]);
  const [loading, setLoading]     = useState(true);
  const [error, setError]         = useState<string | null>(null);
  const [lastFetch, setLastFetch] = useState<Date | null>(null);

  const fetchWorlds = useCallback(async () => {
    try {
      const r = await fetch("/api/worlds");
      if (!r.ok) throw new Error(`HTTP ${r.status}`);
      const data = await r.json();
      const worlds: WorldArtifact[] = Array.isArray(data) ? data : (data.worlds ?? []);
      setArtifacts(worlds);
      setError(null);
      setLastFetch(new Date());
    } catch (e) {
      setError(e instanceof Error ? e.message : "Failed to fetch worlds");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchWorlds();
    const id = setInterval(fetchWorlds, refreshInterval);
    return () => clearInterval(id);
  }, [fetchWorlds, refreshInterval]);

  const filtered = filter === "all"
    ? artifacts
    : artifacts.filter((a) => a.type === filter);

  const counts = {
    total: artifacts.length,
    world: artifacts.filter((a) => a.type === "world").length,
    lore:  artifacts.filter((a) => a.type === "lore").length,
    code:  artifacts.filter((a) => a.type === "code").length,
  };

  return { artifacts: filtered, counts, loading, error, lastFetch, refresh: fetchWorlds };
}
