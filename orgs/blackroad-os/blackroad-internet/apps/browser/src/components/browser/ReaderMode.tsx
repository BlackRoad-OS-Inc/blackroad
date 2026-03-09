import type { ClaimResult } from "../../types/verification";

interface ReaderModeProps {
  content: string;
  title: string;
  url: string;
  claims: ClaimResult[];
  onExit: () => void;
}

const verdictHighlight: Record<string, string> = {
  Verified: "bg-emerald-500/20 border-b-2 border-emerald-500",
  Likely: "bg-green-500/15 border-b-2 border-green-400",
  Uncertain: "bg-amber-500/15 border-b-2 border-amber-400",
  Disputed: "bg-orange-500/20 border-b-2 border-orange-400",
  False: "bg-red-500/20 border-b-2 border-red-500",
};

function highlightClaims(text: string, claims: ClaimResult[]): React.ReactNode[] {
  if (claims.length === 0) {
    return text.split("\n\n").map((para, i) => (
      <p key={i} className="mb-4 leading-relaxed">
        {para}
      </p>
    ));
  }

  // Build a map of claim texts to their verdicts
  const claimMap = new Map<string, ClaimResult>();
  for (const claim of claims) {
    // Use first 60 chars as a match key
    const key = claim.text.slice(0, 60).toLowerCase();
    claimMap.set(key, claim);
  }

  return text.split("\n\n").map((para, i) => {
    // Check if any claim text appears in this paragraph
    let highlighted = false;
    let matchedClaim: ClaimResult | undefined;

    for (const claim of claims) {
      // Fuzzy match: check if significant words from the claim appear in the paragraph
      const claimWords = claim.text.toLowerCase().split(/\s+/).filter((w) => w.length > 4);
      const paraLower = para.toLowerCase();
      const matchCount = claimWords.filter((w) => paraLower.includes(w)).length;

      if (matchCount >= Math.min(3, claimWords.length * 0.5)) {
        highlighted = true;
        matchedClaim = claim;
        break;
      }
    }

    if (highlighted && matchedClaim) {
      const style = verdictHighlight[matchedClaim.verdict] || "";
      return (
        <div key={i} className={`mb-4 p-3 rounded-lg ${style} relative group`}>
          <p className="leading-relaxed">{para}</p>
          <div className="mt-2 flex items-center gap-2 text-[10px]">
            <span className="font-bold uppercase">{matchedClaim.verdict}</span>
            <span className="text-gray-500">
              {Math.round(matchedClaim.confidence * 100)}% confidence
            </span>
            {matchedClaim.reasoning && (
              <span className="text-gray-500 truncate max-w-[300px]">
                - {matchedClaim.reasoning}
              </span>
            )}
          </div>
        </div>
      );
    }

    return (
      <p key={i} className="mb-4 leading-relaxed">
        {para}
      </p>
    );
  });
}

export function ReaderMode({ content, title, url, claims, onExit }: ReaderModeProps) {
  let domain: string;
  try {
    domain = new URL(url).hostname;
  } catch {
    domain = url;
  }

  return (
    <div className="flex-1 overflow-auto bg-black">
      <div className="max-w-2xl mx-auto px-6 py-8">
        {/* Reader toolbar */}
        <div className="flex items-center justify-between mb-8 pb-4 border-b border-gray-800">
          <div>
            <p className="text-[10px] text-muted uppercase tracking-wider">{domain}</p>
          </div>
          <button
            onClick={onExit}
            className="flex items-center gap-2 text-xs text-muted hover:text-white transition-colors"
          >
            <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M6 18L18 6M6 6l12 12" />
            </svg>
            Exit Reader
          </button>
        </div>

        {/* Article title */}
        <h1 className="text-2xl font-bold text-white mb-4 leading-tight">{title}</h1>

        {/* Claim legend */}
        {claims.length > 0 && (
          <div className="flex items-center gap-3 mb-6 pb-4 border-b border-gray-800">
            <span className="text-[9px] text-muted uppercase tracking-wider">Claims:</span>
            {[
              { verdict: "Verified", color: "bg-emerald-500" },
              { verdict: "Likely", color: "bg-green-400" },
              { verdict: "Uncertain", color: "bg-amber-400" },
              { verdict: "Disputed", color: "bg-orange-400" },
              { verdict: "False", color: "bg-red-500" },
            ].map((v) => (
              <span key={v.verdict} className="flex items-center gap-1 text-[9px] text-gray-500">
                <span className={`w-2 h-2 rounded-full ${v.color}`} />
                {v.verdict}
              </span>
            ))}
          </div>
        )}

        {/* Article content with highlights */}
        <article className="text-gray-300 text-[15px] font-sans">
          {content ? (
            highlightClaims(content, claims)
          ) : (
            <p className="text-muted text-center py-12">
              No content available for reader mode.
              <br />
              <span className="text-[10px] text-gray-700">
                Cross-origin pages may not expose their content.
              </span>
            </p>
          )}
        </article>
      </div>
    </div>
  );
}
