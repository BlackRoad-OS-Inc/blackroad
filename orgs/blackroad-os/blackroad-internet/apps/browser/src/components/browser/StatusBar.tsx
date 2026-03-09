interface StatusBarProps {
  url?: string;
  isSecure: boolean;
  verificationScore?: number;
  readerMode?: boolean;
  isBookmarked?: boolean;
}

export function StatusBar({ url, isSecure, verificationScore, readerMode, isBookmarked }: StatusBarProps) {
  const scoreLabel =
    verificationScore === undefined
      ? ""
      : `Accuracy: ${Math.round(verificationScore * 100)}%`;

  const scoreColor =
    verificationScore === undefined
      ? "text-muted"
      : verificationScore > 0.8
        ? "text-emerald-400"
        : verificationScore > 0.5
          ? "text-amber-400"
          : "text-red-400";

  return (
    <div className="flex items-center justify-between px-3 py-1 bg-surface border-t border-gray-800 text-[10px] select-none">
      <div className="flex items-center gap-3">
        {isSecure && (
          <span className="text-emerald-400 flex items-center gap-1">
            <svg className="w-2.5 h-2.5" fill="currentColor" viewBox="0 0 20 20">
              <path fillRule="evenodd" d="M5 9V7a5 5 0 0110 0v2a2 2 0 012 2v5a2 2 0 01-2 2H5a2 2 0 01-2-2v-5a2 2 0 012-2zm8-2v2H7V7a3 3 0 016 0z" clipRule="evenodd" />
            </svg>
            Secure
          </span>
        )}
        {readerMode && (
          <span className="text-electricblue flex items-center gap-1">
            <svg className="w-2.5 h-2.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" />
            </svg>
            Reader
          </span>
        )}
        {isBookmarked && (
          <span className="text-amber flex items-center gap-1">
            <svg className="w-2.5 h-2.5" fill="currentColor" viewBox="0 0 20 20">
              <path d="M5 4a2 2 0 012-2h6a2 2 0 012 2v14l-5-2.5L5 18V4z" />
            </svg>
            Bookmarked
          </span>
        )}
        <span className="text-muted truncate max-w-md">
          {url?.startsWith("blackroad://") ? "" : url}
        </span>
      </div>
      <div className="flex items-center gap-3">
        {scoreLabel && <span className={scoreColor}>{scoreLabel}</span>}
        <span className="text-gray-700">BlackRoad Internet</span>
      </div>
    </div>
  );
}
