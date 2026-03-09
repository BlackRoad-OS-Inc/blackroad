interface SourceReputationProps {
  score: number;
  url: string;
  method: string;
  category: string;
  bias: string;
}

const categoryLabels: Record<string, string> = {
  academic: "Academic",
  journal: "Scientific Journal",
  government: "Government",
  "wire-service": "Wire Service",
  reference: "Reference",
  news: "News",
  "fact-check": "Fact-Checker",
  "tech-docs": "Tech Docs",
  social: "Social Media",
  "low-credibility": "Low Credibility",
  education: "Education",
  organization: "Organization",
  unknown: "Unknown",
};

const biasColors: Record<string, string> = {
  none: "text-emerald-400",
  center: "text-emerald-400",
  "center-left": "text-blue-400",
  "center-right": "text-orange-300",
  left: "text-blue-500",
  right: "text-orange-400",
  extreme: "text-red-400",
  mixed: "text-amber-400",
  unknown: "text-gray-500",
};

export function SourceReputation({ score, url, method, category, bias }: SourceReputationProps) {
  let domain: string;
  try {
    domain = new URL(url).hostname;
  } catch {
    domain = url;
  }

  const percentage = Math.round(score * 100);

  return (
    <div className="p-4 border-b border-gray-800">
      <h3 className="text-xs font-semibold text-muted mb-3 uppercase tracking-wider">
        Source Reputation
      </h3>

      <div className="space-y-2">
        <div className="flex items-center justify-between">
          <span className="text-xs text-gray-400 truncate max-w-[160px]">
            {domain}
          </span>
          <span
            className={`text-xs font-mono font-bold ${
              score > 0.8
                ? "text-emerald-400"
                : score > 0.5
                  ? "text-amber-400"
                  : "text-red-400"
            }`}
          >
            {percentage}%
          </span>
        </div>

        {/* Reputation bar */}
        <div className="w-full h-1.5 bg-gray-800 rounded-full overflow-hidden">
          <div
            className="h-full rounded-full transition-all duration-700"
            style={{
              width: `${percentage}%`,
              background:
                score > 0.8
                  ? "#4ade80"
                  : score > 0.5
                    ? "#F5A623"
                    : "#ef4444",
            }}
          />
        </div>

        {/* Category & Bias */}
        <div className="flex items-center gap-2 flex-wrap">
          {category && category !== "unknown" && (
            <span className="text-[9px] px-1.5 py-0.5 rounded bg-gray-800 text-gray-400 uppercase">
              {categoryLabels[category] || category}
            </span>
          )}
          {bias && bias !== "unknown" && (
            <span className={`text-[9px] px-1.5 py-0.5 rounded bg-gray-800 uppercase ${biasColors[bias] || "text-gray-500"}`}>
              {bias}
            </span>
          )}
        </div>

        <p className="text-[10px] text-gray-700">
          Method: {method}
        </p>
      </div>
    </div>
  );
}
