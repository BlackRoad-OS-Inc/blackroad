import { useState, useCallback, useRef } from "react";

export interface HistoryEntry {
  url: string;
  title: string;
  accuracy_score?: number;
  source_category?: string;
  visited_at: number;
}

const STORAGE_KEY = "blackroad-history";
const MAX_ENTRIES = 1000;

function loadHistory(): HistoryEntry[] {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    return raw ? JSON.parse(raw) : [];
  } catch {
    return [];
  }
}

function saveHistory(entries: HistoryEntry[]) {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(entries.slice(0, MAX_ENTRIES)));
}

export function useHistory() {
  const [history, setHistory] = useState<HistoryEntry[]>(loadHistory);
  const lastUrl = useRef<string>("");

  const addEntry = useCallback(
    (url: string, title: string, accuracy_score?: number, source_category?: string) => {
      if (!url || url.startsWith("blackroad://")) return;
      if (url === lastUrl.current) return;
      lastUrl.current = url;

      setHistory((prev) => {
        const entry: HistoryEntry = {
          url,
          title,
          accuracy_score,
          source_category,
          visited_at: Date.now(),
        };
        const next = [entry, ...prev.filter((e) => e.url !== url)].slice(0, MAX_ENTRIES);
        saveHistory(next);
        return next;
      });
    },
    [],
  );

  const clearHistory = useCallback(() => {
    setHistory([]);
    saveHistory([]);
    lastUrl.current = "";
  }, []);

  const search = useCallback(
    (query: string) => {
      if (!query.trim()) return history;
      const q = query.toLowerCase();
      return history.filter(
        (e) => e.url.toLowerCase().includes(q) || e.title.toLowerCase().includes(q),
      );
    },
    [history],
  );

  return { history, addEntry, clearHistory, search };
}
