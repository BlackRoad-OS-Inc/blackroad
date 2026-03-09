import type { Tab } from "../../types/browser";

interface TabBarProps {
  tabs: Tab[];
  activeTabId: string;
  onTabClick: (id: string) => void;
  onTabClose: (id: string) => void;
  onNewTab: () => void;
}

export function TabBar({
  tabs,
  activeTabId,
  onTabClick,
  onTabClose,
  onNewTab,
}: TabBarProps) {
  return (
    <div className="flex items-center bg-black border-b border-gray-800 select-none">
      <div className="flex flex-1 overflow-x-auto">
        {tabs.map((tab) => (
          <div
            key={tab.id}
            className={`group flex items-center gap-2 px-4 py-2 min-w-[140px] max-w-[240px] cursor-pointer border-r border-gray-800 transition-colors ${
              tab.id === activeTabId
                ? "bg-surface-elevated text-white"
                : "bg-black text-muted hover:bg-surface hover:text-gray-300"
            }`}
            onClick={() => onTabClick(tab.id)}
          >
            {tab.isLoading && (
              <div className="w-3 h-3 border border-hotpink border-t-transparent rounded-full animate-spin shrink-0" />
            )}
            <span className="text-xs truncate flex-1">
              {tab.title || extractDomain(tab.url) || "New Tab"}
            </span>
            <button
              className="w-4 h-4 flex items-center justify-center rounded opacity-0 group-hover:opacity-100 hover:bg-gray-600 transition-opacity text-[10px]"
              onClick={(e) => {
                e.stopPropagation();
                onTabClose(tab.id);
              }}
            >
              x
            </button>
          </div>
        ))}
      </div>
      <button
        onClick={onNewTab}
        className="px-3 py-2 text-muted hover:text-white hover:bg-surface transition-colors text-sm"
        title="New tab"
      >
        +
      </button>
    </div>
  );
}

function extractDomain(url: string): string {
  if (url.startsWith("blackroad://")) {
    return url.replace("blackroad://", "");
  }
  try {
    return new URL(url).hostname;
  } catch {
    return url;
  }
}
