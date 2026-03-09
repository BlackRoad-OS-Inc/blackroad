import type { Bookmark } from "../../hooks/useBookmarks";

interface BookmarksPageProps {
  bookmarks: Bookmark[];
  onNavigate: (url: string) => void;
  onRemoveBookmark: (url: string) => void;
}

export function BookmarksPage({ bookmarks, onNavigate, onRemoveBookmark }: BookmarksPageProps) {
  return (
    <div className="min-h-full bg-black p-6">
      <div className="max-w-3xl mx-auto">
        <h1 className="text-xl font-bold text-white mb-6">Bookmarks</h1>

        {bookmarks.length === 0 ? (
          <div className="text-center py-20">
            <p className="text-muted text-sm">No bookmarks yet</p>
            <p className="text-[10px] text-gray-700 mt-2">
              Press {"\u2318"}D to bookmark the current page
            </p>
          </div>
        ) : (
          <div className="space-y-1">
            {bookmarks.map((bm) => (
              <div
                key={bm.id}
                className="flex items-center gap-3 p-2 rounded-lg hover:bg-surface-elevated cursor-pointer transition-colors group"
                onClick={() => onNavigate(bm.url)}
              >
                {bm.accuracy_score !== undefined && (
                  <span
                    className={`text-[9px] font-mono font-bold px-1.5 py-0.5 rounded ${
                      bm.accuracy_score > 0.8
                        ? "text-emerald-400 bg-emerald-400/10"
                        : bm.accuracy_score > 0.5
                          ? "text-amber-400 bg-amber-400/10"
                          : "text-red-400 bg-red-400/10"
                    }`}
                  >
                    {Math.round(bm.accuracy_score * 100)}
                  </span>
                )}
                {bm.source_category && (
                  <span className="text-[9px] px-1 py-0.5 rounded bg-gray-800 text-gray-500 uppercase">
                    {bm.source_category}
                  </span>
                )}
                <div className="flex-1 min-w-0">
                  <p className="text-sm text-gray-300 group-hover:text-white truncate">
                    {bm.title || bm.url}
                  </p>
                  <p className="text-[10px] text-gray-600 truncate">{bm.url}</p>
                </div>
                <button
                  onClick={(e) => {
                    e.stopPropagation();
                    onRemoveBookmark(bm.url);
                  }}
                  className="text-gray-700 hover:text-red-400 transition-colors opacity-0 group-hover:opacity-100"
                  title="Remove bookmark"
                >
                  <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                    <path strokeLinecap="round" strokeLinejoin="round" d="M6 18L18 6M6 6l12 12" />
                  </svg>
                </button>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
