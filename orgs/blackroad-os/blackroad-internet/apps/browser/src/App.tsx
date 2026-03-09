import { useState, useCallback } from "react";
import { TabBar } from "./components/browser/TabBar";
import { AddressBar } from "./components/browser/AddressBar";
import { NavigationControls } from "./components/browser/NavigationControls";
import { BrowserFrame } from "./components/browser/BrowserFrame";
import { ReaderMode } from "./components/browser/ReaderMode";
import { VerificationPanel } from "./components/sidebar/VerificationPanel";
import { StatusBar } from "./components/browser/StatusBar";
import { CommandPalette } from "./components/browser/CommandPalette";
import { useTabs } from "./hooks/useTabs";
import { useVerification } from "./hooks/useVerification";
import { useBookmarks } from "./hooks/useBookmarks";
import { useHistory } from "./hooks/useHistory";
import { useKeyboardShortcuts } from "./hooks/useKeyboardShortcuts";

function App() {
  const { tabs, activeTab, addTab, closeTab, setActiveTab, navigateTo, updateTabTitle } =
    useTabs();
  const { verification, isVerifying, sidebarOpen, toggleSidebar, onContentReady } =
    useVerification(activeTab?.url);
  const { bookmarks, isBookmarked, toggleBookmark, removeBookmark } = useBookmarks();
  const { history, addEntry: addHistoryEntry, clearHistory } = useHistory();

  const [commandPaletteOpen, setCommandPaletteOpen] = useState(false);
  const [readerMode, setReaderMode] = useState(false);
  const [pageContent, setPageContent] = useState("");

  // Wrap onContentReady to also store content for reader mode
  const handleContentReady = useCallback(
    (content: string) => {
      setPageContent(content);
      onContentReady(content);
    },
    [onContentReady],
  );

  // Track history when navigation happens
  const handleNavigate = useCallback(
    (url: string) => {
      navigateTo(url);
      setReaderMode(false);
    },
    [navigateTo],
  );

  // Record history when title updates (means page loaded)
  const handleTitleChange = useCallback(
    (title: string) => {
      updateTabTitle(title);
      if (activeTab?.url) {
        addHistoryEntry(
          activeTab.url,
          title,
          verification?.overall_score,
          verification?.source_category,
        );
      }
    },
    [updateTabTitle, activeTab?.url, addHistoryEntry, verification?.overall_score, verification?.source_category],
  );

  // Keyboard shortcuts
  useKeyboardShortcuts({
    newTab: addTab,
    closeTab: () => activeTab && closeTab(activeTab.id),
    focusAddressBar: () => {
      const el = document.querySelector<HTMLInputElement>("[data-address-bar]");
      el?.focus();
      el?.select();
    },
    toggleCommandPalette: () => setCommandPaletteOpen((v) => !v),
    toggleSidebar,
    toggleReaderMode: () => setReaderMode((v) => !v),
    goBack: () => {},  // TODO: implement with Tauri navigation stack
    goForward: () => {},
    refresh: () => activeTab?.url && navigateTo(activeTab.url),
    switchToTab: (index: number) => {
      if (index < tabs.length) setActiveTab(tabs[index].id);
      else if (tabs.length > 0) setActiveTab(tabs[tabs.length - 1].id);
    },
    toggleBookmark: () => {
      if (activeTab?.url && !activeTab.url.startsWith("blackroad://")) {
        toggleBookmark(
          activeTab.url,
          activeTab.title,
          verification?.overall_score,
          verification?.source_category,
        );
      }
    },
    openHistory: () => handleNavigate("blackroad://history"),
    openBookmarks: () => handleNavigate("blackroad://bookmarks"),
  });

  const currentUrl = activeTab?.url ?? "blackroad://newtab";
  const isInternal = currentUrl.startsWith("blackroad://");
  const isBookmarkedUrl = activeTab?.url ? isBookmarked(activeTab.url) : false;

  return (
    <div className="flex flex-col h-screen bg-black text-white font-mono">
      {/* Tab bar */}
      <TabBar
        tabs={tabs}
        activeTabId={activeTab?.id ?? ""}
        onTabClick={setActiveTab}
        onTabClose={closeTab}
        onNewTab={addTab}
      />

      {/* Navigation + Address */}
      <div className="flex items-center gap-2 px-3 py-1.5 bg-surface border-b border-gray-800">
        <NavigationControls />
        <AddressBar
          url={activeTab?.url ?? ""}
          onNavigate={handleNavigate}
          verificationScore={verification?.overall_score}
        />

        {/* Bookmark button */}
        {!isInternal && (
          <button
            onClick={() =>
              activeTab?.url &&
              toggleBookmark(
                activeTab.url,
                activeTab.title,
                verification?.overall_score,
                verification?.source_category,
              )
            }
            className="flex items-center justify-center w-8 h-8 rounded-lg hover:bg-surface-elevated transition-colors"
            title={isBookmarkedUrl ? "Remove bookmark (Cmd+D)" : "Bookmark this page (Cmd+D)"}
          >
            <svg
              className={`w-4 h-4 ${isBookmarkedUrl ? "text-amber fill-amber" : "text-muted"}`}
              fill={isBookmarkedUrl ? "currentColor" : "none"}
              viewBox="0 0 24 24"
              stroke="currentColor"
              strokeWidth={2}
            >
              <path strokeLinecap="round" strokeLinejoin="round" d="M5 5a2 2 0 012-2h10a2 2 0 012 2v16l-7-3.5L5 21V5z" />
            </svg>
          </button>
        )}

        {/* Reader mode button */}
        {!isInternal && (
          <button
            onClick={() => setReaderMode((v) => !v)}
            className={`flex items-center justify-center w-8 h-8 rounded-lg hover:bg-surface-elevated transition-colors ${
              readerMode ? "text-electricblue" : "text-muted"
            }`}
            title="Toggle reader mode (Cmd+Shift+R)"
          >
            <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" />
            </svg>
          </button>
        )}

        {/* Verification sidebar toggle */}
        <button
          onClick={toggleSidebar}
          className="flex items-center justify-center w-8 h-8 rounded-lg hover:bg-surface-elevated transition-colors"
          title="Toggle verification panel (Cmd+E)"
        >
          <svg
            className={`w-4 h-4 ${sidebarOpen ? "text-hotpink" : "text-muted"}`}
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
            strokeWidth={2}
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"
            />
          </svg>
        </button>

        {/* Command palette button */}
        <button
          onClick={() => setCommandPaletteOpen(true)}
          className="flex items-center justify-center w-8 h-8 rounded-lg hover:bg-surface-elevated transition-colors text-muted"
          title="Command palette (Cmd+K)"
        >
          <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
            <path strokeLinecap="round" strokeLinejoin="round" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
          </svg>
        </button>
      </div>

      {/* Main content area */}
      <div className="flex flex-1 overflow-hidden">
        {readerMode && !isInternal ? (
          <ReaderMode
            content={pageContent}
            title={activeTab?.title ?? ""}
            url={activeTab?.url ?? ""}
            claims={verification?.claims ?? []}
            onExit={() => setReaderMode(false)}
          />
        ) : (
          <BrowserFrame
            url={currentUrl}
            onNavigate={handleNavigate}
            onTitleChange={handleTitleChange}
            onContentReady={handleContentReady}
            bookmarks={bookmarks}
            history={history}
            onRemoveBookmark={removeBookmark}
            onClearHistory={clearHistory}
          />
        )}

        {sidebarOpen && (
          <VerificationPanel
            verification={verification}
            isVerifying={isVerifying}
          />
        )}
      </div>

      {/* Status bar */}
      <StatusBar
        url={activeTab?.url}
        isSecure={activeTab?.url?.startsWith("https") ?? false}
        verificationScore={verification?.overall_score}
        readerMode={readerMode}
        isBookmarked={isBookmarkedUrl}
      />

      {/* Command palette overlay */}
      <CommandPalette
        isOpen={commandPaletteOpen}
        onClose={() => setCommandPaletteOpen(false)}
        onNavigate={(url) => {
          handleNavigate(url);
          setCommandPaletteOpen(false);
        }}
        onNewTab={addTab}
        onToggleSidebar={toggleSidebar}
        onToggleReaderMode={() => setReaderMode((v) => !v)}
        onOpenHistory={() => handleNavigate("blackroad://history")}
        onOpenBookmarks={() => handleNavigate("blackroad://bookmarks")}
      />
    </div>
  );
}

export default App;
