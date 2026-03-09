interface NavigationControlsProps {
  canGoBack?: boolean;
  canGoForward?: boolean;
  onBack?: () => void;
  onForward?: () => void;
  onRefresh?: () => void;
}

export function NavigationControls({
  canGoBack = false,
  canGoForward = false,
  onBack,
  onForward,
  onRefresh,
}: NavigationControlsProps) {
  const btnClass = (enabled: boolean) =>
    `w-7 h-7 flex items-center justify-center rounded transition-colors ${
      enabled
        ? "text-gray-300 hover:text-white hover:bg-surface-elevated cursor-pointer"
        : "text-gray-700 cursor-default"
    }`;

  return (
    <div className="flex items-center gap-0.5">
      <button
        className={btnClass(canGoBack)}
        onClick={onBack}
        disabled={!canGoBack}
        title="Back"
      >
        <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
          <path strokeLinecap="round" strokeLinejoin="round" d="M15 19l-7-7 7-7" />
        </svg>
      </button>
      <button
        className={btnClass(canGoForward)}
        onClick={onForward}
        disabled={!canGoForward}
        title="Forward"
      >
        <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
          <path strokeLinecap="round" strokeLinejoin="round" d="M9 5l7 7-7 7" />
        </svg>
      </button>
      <button
        className={btnClass(true)}
        onClick={onRefresh}
        title="Refresh"
      >
        <svg className="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
          <path strokeLinecap="round" strokeLinejoin="round" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
        </svg>
      </button>
    </div>
  );
}
