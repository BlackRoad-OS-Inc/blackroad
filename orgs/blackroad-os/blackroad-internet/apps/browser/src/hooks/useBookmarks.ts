import { useState, useCallback } from "react";

export interface Bookmark {
  id: string;
  url: string;
  title: string;
  accuracy_score?: number;
  source_category?: string;
  created_at: number;
}

// Phase 1: localStorage. Phase 2: Tauri SQLite via IPC.
const STORAGE_KEY = "blackroad-bookmarks";

function loadBookmarks(): Bookmark[] {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    return raw ? JSON.parse(raw) : [];
  } catch {
    return [];
  }
}

function saveBookmarks(bookmarks: Bookmark[]) {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(bookmarks));
}

export function useBookmarks() {
  const [bookmarks, setBookmarks] = useState<Bookmark[]>(loadBookmarks);

  const addBookmark = useCallback(
    (url: string, title: string, accuracy_score?: number, source_category?: string) => {
      setBookmarks((prev) => {
        // Don't duplicate
        if (prev.some((b) => b.url === url)) return prev;
        const next = [
          ...prev,
          {
            id: `bm-${Date.now()}`,
            url,
            title,
            accuracy_score,
            source_category,
            created_at: Date.now(),
          },
        ];
        saveBookmarks(next);
        return next;
      });
    },
    [],
  );

  const removeBookmark = useCallback((url: string) => {
    setBookmarks((prev) => {
      const next = prev.filter((b) => b.url !== url);
      saveBookmarks(next);
      return next;
    });
  }, []);

  const isBookmarked = useCallback(
    (url: string) => bookmarks.some((b) => b.url === url),
    [bookmarks],
  );

  const toggleBookmark = useCallback(
    (url: string, title: string, accuracy_score?: number, source_category?: string) => {
      if (isBookmarked(url)) {
        removeBookmark(url);
      } else {
        addBookmark(url, title, accuracy_score, source_category);
      }
    },
    [isBookmarked, addBookmark, removeBookmark],
  );

  return { bookmarks, addBookmark, removeBookmark, isBookmarked, toggleBookmark };
}
