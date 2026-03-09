import { useEffect, useCallback } from "react";

interface ShortcutActions {
  newTab: () => void;
  closeTab: () => void;
  focusAddressBar: () => void;
  toggleCommandPalette: () => void;
  toggleSidebar: () => void;
  toggleReaderMode: () => void;
  goBack: () => void;
  goForward: () => void;
  refresh: () => void;
  switchToTab: (index: number) => void;
  toggleBookmark: () => void;
  openHistory: () => void;
  openBookmarks: () => void;
}

export function useKeyboardShortcuts(actions: ShortcutActions) {
  const handleKeyDown = useCallback(
    (e: KeyboardEvent) => {
      const meta = e.metaKey || e.ctrlKey;

      if (!meta) return;

      switch (e.key) {
        case "t":
          e.preventDefault();
          actions.newTab();
          break;
        case "w":
          e.preventDefault();
          actions.closeTab();
          break;
        case "l":
          e.preventDefault();
          actions.focusAddressBar();
          break;
        case "k":
          e.preventDefault();
          actions.toggleCommandPalette();
          break;
        case "r":
          e.preventDefault();
          if (e.shiftKey) {
            actions.toggleReaderMode();
          } else {
            actions.refresh();
          }
          break;
        case "d":
          e.preventDefault();
          actions.toggleBookmark();
          break;
        case "y":
          e.preventDefault();
          actions.openHistory();
          break;
        case "[":
          e.preventDefault();
          actions.goBack();
          break;
        case "]":
          e.preventDefault();
          actions.goForward();
          break;
        case "b":
          if (e.shiftKey) {
            e.preventDefault();
            actions.openBookmarks();
          }
          break;
        case "e":
          e.preventDefault();
          actions.toggleSidebar();
          break;
        case "1":
        case "2":
        case "3":
        case "4":
        case "5":
        case "6":
        case "7":
        case "8":
        case "9":
          e.preventDefault();
          actions.switchToTab(parseInt(e.key) - 1);
          break;
      }
    },
    [actions],
  );

  useEffect(() => {
    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [handleKeyDown]);
}
