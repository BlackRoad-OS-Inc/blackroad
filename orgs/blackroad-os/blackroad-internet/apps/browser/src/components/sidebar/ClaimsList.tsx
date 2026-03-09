import type { ClaimResult } from "../../types/verification";

interface ClaimsListProps {
  claims: ClaimResult[];
}

const verdictColors: Record<string, string> = {
  Verified: "text-emerald-400 bg-emerald-400/10",
  Likely: "text-green-300 bg-green-300/10",
  Uncertain: "text-amber-400 bg-amber-400/10",
  Disputed: "text-orange-400 bg-orange-400/10",
  False: "text-red-400 bg-red-400/10",
};

const verdictIcons: Record<string, string> = {
  Verified: "\u2713",
  Likely: "~",
  Uncertain: "?",
  Disputed: "!",
  False: "\u2715",
};

export function ClaimsList({ claims }: ClaimsListProps) {
  if (claims.length === 0) {
    return (
      <div className="p-4">
        <h3 className="text-xs font-semibold text-muted mb-3 uppercase tracking-wider">
          Claims Analysis
        </h3>
        <p className="text-[10px] text-gray-700">
          No verifiable claims extracted. This may be because the content is too
          short, cross-origin restricted, or contains only opinions.
        </p>
      </div>
    );
  }

  return (
    <div className="p-4">
      <h3 className="text-xs font-semibold text-muted mb-3 uppercase tracking-wider">
        Claims ({claims.length})
      </h3>
      <div className="space-y-2">
        {claims.map((claim, i) => (
          <div
            key={i}
            className="p-2 rounded-lg bg-surface-elevated border border-gray-800"
          >
            <div className="flex items-start gap-2">
              <span
                className={`shrink-0 w-5 h-5 rounded flex items-center justify-center text-[10px] font-bold ${verdictColors[claim.verdict] || "text-muted bg-gray-800"}`}
              >
                {verdictIcons[claim.verdict] || "?"}
              </span>
              <div className="flex-1 min-w-0">
                <p className="text-[11px] text-gray-300 leading-relaxed">
                  {claim.text}
                </p>
                {claim.reasoning && (
                  <p className="text-[10px] text-gray-500 mt-1 leading-snug">
                    {claim.reasoning}
                  </p>
                )}
                <div className="flex items-center gap-2 mt-1 flex-wrap">
                  <span className="text-[9px] text-gray-600 uppercase">
                    {claim.claim_type}
                  </span>
                  {claim.confidence > 0 && (
                    <span className="text-[9px] text-gray-700">
                      {Math.round(claim.confidence * 100)}% conf
                    </span>
                  )}
                </div>
                {claim.sources.length > 0 && (
                  <div className="mt-1 flex flex-wrap gap-1">
                    {claim.sources.map((src, j) => (
                      <span
                        key={j}
                        className="text-[8px] text-electricblue truncate max-w-[200px]"
                        title={src}
                      >
                        [{j + 1}] {src}
                      </span>
                    ))}
                  </div>
                )}
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
