import { useState, useCallback } from "react";
import { invoke } from "@tauri-apps/api/core";
import type { Tab, PageInfo } from "../types/browser";

let tabCounter = 1;

function makeTab(): Tab {
  const id = `tab-${++tabCounter}`;
  return { id, url: "blackroad://newtab", title: "New Tab", isLoading: false };
}

export function useTabs() {
  const [tabs, setTabs] = useState<Tab[]>([
    { id: "tab-1", url: "blackroad://newtab", title: "New Tab", isLoading: false },
  ]);
  const [activeTabId, setActiveTabId] = useState("tab-1");

  const activeTab = tabs.find((t) => t.id === activeTabId) ?? null;

  const addTab = useCallback(() => {
    const tab = makeTab();
    setTabs((prev) => [...prev, tab]);
    setActiveTabId(tab.id);
  }, []);

  const closeTab = useCallback(
    (id: string) => {
      setTabs((prev) => {
        const next = prev.filter((t) => t.id !== id);
        if (next.length === 0) {
          const tab = makeTab();
          setActiveTabId(tab.id);
          return [tab];
        }
        return next;
      });
      if (activeTabId === id) {
        setTabs((prev) => {
          const remaining = prev.filter((t) => t.id !== id);
          if (remaining.length > 0) {
            setActiveTabId(remaining[remaining.length - 1].id);
          }
          return prev;
        });
      }
    },
    [activeTabId],
  );

  const navigateTo = useCallback(
    async (url: string) => {
      if (!activeTabId) return;
      try {
        const pageInfo = await invoke<PageInfo>("navigate_to", { url });
        setTabs((prev) =>
          prev.map((t) =>
            t.id === activeTabId
              ? { ...t, url: pageInfo.url, isLoading: true }
              : t,
          ),
        );
      } catch (e) {
        console.error("Navigation failed:", e);
      }
    },
    [activeTabId],
  );

  const updateTabTitle = useCallback(
    (title: string) => {
      setTabs((prev) =>
        prev.map((t) =>
          t.id === activeTabId ? { ...t, title, isLoading: false } : t,
        ),
      );
    },
    [activeTabId],
  );

  return {
    tabs,
    activeTab,
    addTab,
    closeTab,
    setActiveTab: setActiveTabId,
    navigateTo,
    updateTabTitle,
  };
}
