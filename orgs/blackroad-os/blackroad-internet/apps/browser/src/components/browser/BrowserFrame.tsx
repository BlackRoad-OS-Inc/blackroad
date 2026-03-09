import { useCallback } from "react";
import { NewTabPage } from "./NewTabPage";
import { HistoryPage } from "./HistoryPage";
import { BookmarksPage } from "./BookmarksPage";
import { PrivacyDashboard } from "./PrivacyDashboard";
import { SearchPage } from "../search/SearchPage";
import type { Bookmark } from "../../hooks/useBookmarks";
import type { HistoryEntry } from "../../hooks/useHistory";

interface BrowserFrameProps {
  url: string;
  onNavigate: (url: string) => void;
  onTitleChange: (title: string) => void;
  onContentReady: (content: string) => void;
  bookmarks: Bookmark[];
  history: HistoryEntry[];
  onRemoveBookmark: (url: string) => void;
  onClearHistory: () => void;
}

export function BrowserFrame({
  url,
  onNavigate,
  onTitleChange,
  onContentReady,
  bookmarks,
  history,
  onRemoveBookmark,
  onClearHistory,
}: BrowserFrameProps) {
  const handleIframeLoad = useCallback(
    (e: React.SyntheticEvent<HTMLIFrameElement>) => {
      try {
        const frame = e.target as HTMLIFrameElement;
        const doc = frame.contentDocument;
        if (!doc) return;

        const title = doc.title;
        if (title) onTitleChange(title);

        const body = doc.body;
        if (body) {
          const clone = body.cloneNode(true) as HTMLElement;
          clone.querySelectorAll("script, style, nav, footer, header, iframe").forEach((el) => el.remove());
          const text = clone.innerText || clone.textContent || "";
          if (text.trim().length > 50) {
            onContentReady(text.trim().slice(0, 10000));
          }
        }
      } catch {
        onContentReady("");
      }
    },
    [onTitleChange, onContentReady],
  );

  // Internal BlackRoad pages
  if (url === "blackroad://newtab" || url === "") {
    return (
      <div className="flex-1 overflow-auto">
        <NewTabPage onNavigate={onNavigate} />
      </div>
    );
  }

  if (url.startsWith("blackroad://search")) {
    const params = new URLSearchParams(url.split("?")[1] || "");
    return (
      <div className="flex-1 overflow-auto">
        <SearchPage query={params.get("q") || ""} onNavigate={onNavigate} />
      </div>
    );
  }

  if (url === "blackroad://history") {
    return (
      <div className="flex-1 overflow-auto">
        <HistoryPage history={history} onNavigate={onNavigate} onClearHistory={onClearHistory} />
      </div>
    );
  }

  if (url === "blackroad://bookmarks") {
    return (
      <div className="flex-1 overflow-auto">
        <BookmarksPage bookmarks={bookmarks} onNavigate={onNavigate} onRemoveBookmark={onRemoveBookmark} />
      </div>
    );
  }

  if (url === "blackroad://privacy") {
    return (
      <div className="flex-1 overflow-auto">
        <PrivacyDashboard onNavigate={onNavigate} />
      </div>
    );
  }

  // External web pages via iframe
  return (
    <div className="flex-1 relative">
      <iframe
        src={url}
        className="w-full h-full border-0 bg-white"
        sandbox="allow-scripts allow-same-origin allow-forms allow-popups allow-popups-to-escape-sandbox"
        referrerPolicy="no-referrer"
        onLoad={handleIframeLoad}
      />
    </div>
  );
}
