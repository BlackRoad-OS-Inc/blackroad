import { useState } from "react";
import type { HistoryEntry } from "../../hooks/useHistory";

interface HistoryPageProps {
  history: HistoryEntry[];
  onNavigate: (url: string) => void;
  onClearHistory: () => void;
}

export function HistoryPage({ history, onNavigate, onClearHistory }: HistoryPageProps) {
  const [searchQuery, setSearchQuery] = useState("");

  const filtered = searchQuery.trim()
    ? history.filter(
        (e) =>
          e.url.toLowerCase().includes(searchQuery.toLowerCase()) ||
          e.title.toLowerCase().includes(searchQuery.toLowerCase()),
      )
    : history;

  // Group by date
  const grouped = new Map<string, HistoryEntry[]>();
  for (const entry of filtered) {
    const date = new Date(entry.visited_at).toLocaleDateString("en-US", {
      weekday: "long",
      year: "numeric",
      month: "long",
      day: "numeric",
    });
    const list = grouped.get(date) || [];
    list.push(entry);
    grouped.set(date, list);
  }

  return (
    <div className="min-h-full bg-black p-6">
      <div className="max-w-3xl mx-auto">
        <div className="flex items-center justify-between mb-6">
          <h1 className="text-xl font-bold text-white">History</h1>
          {history.length > 0 && (
            <button
              onClick={onClearHistory}
              className="text-xs text-red-400 hover:text-red-300 transition-colors"
            >
              Clear all history
            </button>
          )}
        </div>

        <input
          type="text"
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          className="w-full px-4 py-2 mb-6 rounded-lg bg-surface-elevated border border-gray-700 text-white text-sm outline-none focus:border-hotpink transition-colors placeholder-gray-500"
          placeholder="Search history..."
        />

        {filtered.length === 0 ? (
          <div className="text-center py-20">
            <p className="text-muted text-sm">
              {history.length === 0 ? "No browsing history yet" : "No matching history entries"}
            </p>
          </div>
        ) : (
          <div className="space-y-6">
            {[...grouped.entries()].map(([date, entries]) => (
              <div key={date}>
                <h2 className="text-xs font-semibold text-muted mb-2 uppercase tracking-wider">
                  {date}
                </h2>
                <div className="space-y-1">
                  {entries.map((entry, i) => (
                    <div
                      key={i}
                      className="flex items-center gap-3 p-2 rounded-lg hover:bg-surface-elevated cursor-pointer transition-colors group"
                      onClick={() => onNavigate(entry.url)}
                    >
                      {entry.accuracy_score !== undefined && (
                        <span
                          className={`text-[9px] font-mono font-bold px-1.5 py-0.5 rounded ${
                            entry.accuracy_score > 0.8
                              ? "text-emerald-400 bg-emerald-400/10"
                              : entry.accuracy_score > 0.5
                                ? "text-amber-400 bg-amber-400/10"
                                : "text-red-400 bg-red-400/10"
                          }`}
                        >
                          {Math.round(entry.accuracy_score * 100)}
                        </span>
                      )}
                      <div className="flex-1 min-w-0">
                        <p className="text-sm text-gray-300 group-hover:text-white truncate">
                          {entry.title || entry.url}
                        </p>
                        <p className="text-[10px] text-gray-600 truncate">{entry.url}</p>
                      </div>
                      <span className="text-[10px] text-gray-700 shrink-0">
                        {new Date(entry.visited_at).toLocaleTimeString("en-US", {
                          hour: "numeric",
                          minute: "2-digit",
                        })}
                      </span>
                    </div>
                  ))}
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
