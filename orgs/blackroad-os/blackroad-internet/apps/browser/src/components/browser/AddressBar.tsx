import { useState, useCallback, useEffect, type KeyboardEvent } from "react";

interface AddressBarProps {
  url: string;
  onNavigate: (url: string) => void;
  verificationScore?: number;
}

export function AddressBar({
  url,
  onNavigate,
  verificationScore,
}: AddressBarProps) {
  const [input, setInput] = useState(url);
  const [focused, setFocused] = useState(false);

  useEffect(() => {
    if (!focused) setInput(url);
  }, [url, focused]);

  const handleKeyDown = useCallback(
    (e: KeyboardEvent) => {
      if (e.key === "Enter") {
        onNavigate(input);
        (e.target as HTMLInputElement).blur();
      }
    },
    [input, onNavigate],
  );

  const scoreColor =
    verificationScore === undefined
      ? "bg-gray-600"
      : verificationScore > 0.8
        ? "bg-emerald-500"
        : verificationScore > 0.5
          ? "bg-amber-400"
          : "bg-red-500";

  const displayUrl = url.startsWith("blackroad://") ? "" : url;

  return (
    <div className="flex-1 flex items-center gap-2 px-3 py-1.5 rounded-lg bg-black/60 border border-gray-700 focus-within:border-hotpink transition-colors">
      {verificationScore !== undefined && (
        <div
          className={`w-2 h-2 rounded-full shrink-0 ${scoreColor}`}
          title={`Accuracy: ${Math.round(verificationScore * 100)}%`}
        />
      )}

      {url.startsWith("https") && (
        <svg
          className="w-3.5 h-3.5 text-emerald-400 shrink-0"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
          strokeWidth={2}
        >
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"
          />
        </svg>
      )}

      <input
        type="text"
        value={focused ? input : displayUrl}
        onChange={(e) => setInput(e.target.value)}
        onKeyDown={handleKeyDown}
        onFocus={() => {
          setFocused(true);
          setInput(url.startsWith("blackroad://") ? "" : url);
        }}
        onBlur={() => setFocused(false)}
        className="flex-1 bg-transparent text-sm text-gray-200 outline-none placeholder-gray-500"
        placeholder="Search or enter URL — Accurate info. Period."
        spellCheck={false}
      />
    </div>
  );
}
