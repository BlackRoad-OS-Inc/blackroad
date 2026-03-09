interface AccuracyScoreProps {
  score: number;
}

export function AccuracyScore({ score }: AccuracyScoreProps) {
  const percentage = Math.round(score * 100);
  const radius = 40;
  const circumference = 2 * Math.PI * radius;
  const offset = circumference - score * circumference;

  const color =
    score > 0.8
      ? "#4ade80"
      : score > 0.6
        ? "#F5A623"
        : score > 0.4
          ? "#ff8c00"
          : "#ef4444";

  const label =
    score > 0.8
      ? "High Accuracy"
      : score > 0.6
        ? "Moderate"
        : score > 0.4
          ? "Mixed"
          : "Low Accuracy";

  return (
    <div className="p-6 flex flex-col items-center border-b border-gray-800">
      <svg width="100" height="100" viewBox="0 0 100 100">
        <circle
          cx="50"
          cy="50"
          r={radius}
          fill="none"
          stroke="#1a1a1a"
          strokeWidth="6"
        />
        <circle
          cx="50"
          cy="50"
          r={radius}
          fill="none"
          stroke={color}
          strokeWidth="6"
          strokeDasharray={circumference}
          strokeDashoffset={offset}
          strokeLinecap="round"
          transform="rotate(-90 50 50)"
          style={{ transition: "stroke-dashoffset 0.8s ease" }}
        />
        <text
          x="50"
          y="46"
          textAnchor="middle"
          dominantBaseline="central"
          fill="white"
          fontSize="24"
          fontWeight="bold"
          fontFamily="monospace"
        >
          {percentage}
        </text>
        <text
          x="50"
          y="62"
          textAnchor="middle"
          dominantBaseline="central"
          fill="#666"
          fontSize="8"
          fontFamily="monospace"
        >
          {label}
        </text>
      </svg>
    </div>
  );
}
