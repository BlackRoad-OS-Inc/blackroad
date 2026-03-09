import { useState, useEffect, useRef, useMemo } from "react";

interface Command {
  id: string;
  label: string;
  shortcut?: string;
  category: string;
  action: () => void;
}

interface CommandPaletteProps {
  isOpen: boolean;
  onClose: () => void;
  onNavigate: (url: string) => void;
  onNewTab: () => void;
  onToggleSidebar: () => void;
  onToggleReaderMode: () => void;
  onOpenHistory: () => void;
  onOpenBookmarks: () => void;
}

export function CommandPalette({
  isOpen,
  onClose,
  onNavigate,
  onNewTab,
  onToggleSidebar,
  onToggleReaderMode,
  onOpenHistory,
  onOpenBookmarks,
}: CommandPaletteProps) {
  const [query, setQuery] = useState("");
  const [selectedIndex, setSelectedIndex] = useState(0);
  const inputRef = useRef<HTMLInputElement>(null);

  const commands = useMemo<Command[]>(
    () => [
      { id: "new-tab", label: "New Tab", shortcut: "\u2318T", category: "Tabs", action: onNewTab },
      { id: "history", label: "Open History", shortcut: "\u2318Y", category: "Navigate", action: onOpenHistory },
      { id: "bookmarks", label: "Open Bookmarks", shortcut: "\u2318\u21E7B", category: "Navigate", action: onOpenBookmarks },
      { id: "sidebar", label: "Toggle Verification Panel", shortcut: "\u2318E", category: "View", action: onToggleSidebar },
      { id: "reader", label: "Toggle Reader Mode", shortcut: "\u2318\u21E7R", category: "View", action: onToggleReaderMode },
      { id: "newtab", label: "Go to New Tab Page", category: "Navigate", action: () => onNavigate("blackroad://newtab") },
      { id: "settings", label: "Open Settings", category: "Navigate", action: () => onNavigate("blackroad://settings") },
      { id: "privacy", label: "Privacy Dashboard", category: "Navigate", action: () => onNavigate("blackroad://privacy") },
      { id: "search-wiki", label: "Search Wikipedia", category: "Search", action: () => {} },
      { id: "search-scholar", label: "Search Google Scholar", category: "Search", action: () => {} },
      { id: "search-arxiv", label: "Search arXiv", category: "Search", action: () => {} },
      { id: "search-pubmed", label: "Search PubMed", category: "Search", action: () => {} },
    ],
    [onNewTab, onOpenHistory, onOpenBookmarks, onToggleSidebar, onToggleReaderMode, onNavigate],
  );

  const filtered = useMemo(() => {
    if (!query.trim()) return commands;
    const q = query.toLowerCase();

    // If it looks like a URL or search, offer navigation
    if (q.includes(".") || q.startsWith("http")) {
      return [
        { id: "go", label: `Go to ${query}`, category: "Navigate", action: () => onNavigate(query) },
        ...commands.filter((c) => c.label.toLowerCase().includes(q)),
      ];
    }

    // Check if search commands match - if so, fill in the query
    const searchResults = commands
      .filter((c) => c.category === "Search" && c.label.toLowerCase().includes(q))
      .map((c) => ({
        ...c,
        action: () => onNavigate(`blackroad://search?q=${encodeURIComponent(query)}`),
      }));

    const otherResults = commands.filter(
      (c) => c.category !== "Search" && c.label.toLowerCase().includes(q),
    );

    // Always offer a search option
    return [
      { id: "search", label: `Search "${query}"`, category: "Search", action: () => onNavigate(`blackroad://search?q=${encodeURIComponent(query)}`) },
      ...otherResults,
      ...searchResults,
    ];
  }, [query, commands, onNavigate]);

  useEffect(() => {
    if (isOpen) {
      setQuery("");
      setSelectedIndex(0);
      setTimeout(() => inputRef.current?.focus(), 50);
    }
  }, [isOpen]);

  useEffect(() => {
    setSelectedIndex(0);
  }, [query]);

  if (!isOpen) return null;

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === "Escape") {
      onClose();
    } else if (e.key === "ArrowDown") {
      e.preventDefault();
      setSelectedIndex((i) => Math.min(i + 1, filtered.length - 1));
    } else if (e.key === "ArrowUp") {
      e.preventDefault();
      setSelectedIndex((i) => Math.max(i - 1, 0));
    } else if (e.key === "Enter") {
      e.preventDefault();
      if (filtered[selectedIndex]) {
        filtered[selectedIndex].action();
        onClose();
      }
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-start justify-center pt-[15vh]" onClick={onClose}>
      <div
        className="w-[560px] bg-surface border border-gray-700 rounded-xl shadow-2xl shadow-black/50 overflow-hidden"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Input */}
        <div className="flex items-center gap-3 px-4 py-3 border-b border-gray-800">
          <svg className="w-4 h-4 text-muted shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
            <path strokeLinecap="round" strokeLinejoin="round" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
          </svg>
          <input
            ref={inputRef}
            type="text"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            onKeyDown={handleKeyDown}
            className="flex-1 bg-transparent text-sm text-white outline-none placeholder-gray-500"
            placeholder="Search commands, URLs, or the web..."
          />
          <kbd className="text-[9px] text-gray-600 bg-gray-800 px-1.5 py-0.5 rounded">ESC</kbd>
        </div>

        {/* Results */}
        <div className="max-h-[320px] overflow-y-auto py-1">
          {filtered.length === 0 ? (
            <div className="px-4 py-6 text-center text-xs text-muted">No matching commands</div>
          ) : (
            filtered.map((cmd, i) => (
              <div
                key={cmd.id + i}
                className={`flex items-center justify-between px-4 py-2 cursor-pointer transition-colors ${
                  i === selectedIndex ? "bg-hotpink/10 text-white" : "text-gray-400 hover:bg-surface-elevated"
                }`}
                onClick={() => {
                  cmd.action();
                  onClose();
                }}
                onMouseEnter={() => setSelectedIndex(i)}
              >
                <div className="flex items-center gap-3">
                  <span className="text-[9px] text-gray-600 uppercase w-14">{cmd.category}</span>
                  <span className="text-sm">{cmd.label}</span>
                </div>
                {cmd.shortcut && (
                  <kbd className="text-[9px] text-gray-600 bg-gray-800 px-1.5 py-0.5 rounded">
                    {cmd.shortcut}
                  </kbd>
                )}
              </div>
            ))
          )}
        </div>
      </div>
    </div>
  );
}
