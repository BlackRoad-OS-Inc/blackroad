import { useState, type KeyboardEvent } from "react";

interface NewTabPageProps {
  onNavigate: (url: string) => void;
}

export function NewTabPage({ onNavigate }: NewTabPageProps) {
  const [query, setQuery] = useState("");

  const handleKeyDown = (e: KeyboardEvent) => {
    if (e.key === "Enter" && query.trim()) {
      onNavigate(query.trim());
    }
  };

  const quickLinks = [
    { title: "Wikipedia", url: "https://wikipedia.org", icon: "W" },
    { title: "arXiv", url: "https://arxiv.org", icon: "a" },
    { title: "Reuters", url: "https://reuters.com", icon: "R" },
    { title: "AP News", url: "https://apnews.com", icon: "AP" },
    { title: "Nature", url: "https://nature.com", icon: "N" },
    { title: "PubMed", url: "https://pubmed.ncbi.nlm.nih.gov", icon: "P" },
  ];

  return (
    <div className="flex flex-col items-center justify-center min-h-full bg-black px-4">
      {/* Logo */}
      <div className="mb-10">
        <h1 className="text-6xl font-black br-gradient-text tracking-tight">
          BlackRoad
        </h1>
        <p className="text-center text-muted text-sm mt-3 tracking-widest uppercase">
          Accurate info. Period.
        </p>
      </div>

      {/* Search bar */}
      <div className="w-full max-w-2xl">
        <div className="relative">
          <svg
            className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-muted"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
            strokeWidth={2}
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
            />
          </svg>
          <input
            type="text"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            onKeyDown={handleKeyDown}
            className="w-full pl-12 pr-6 py-4 rounded-2xl bg-surface-elevated border border-gray-700 text-white text-lg outline-none focus:border-hotpink focus:shadow-glow transition-all placeholder-gray-500"
            placeholder="Search for anything..."
            autoFocus
          />
        </div>
      </div>

      {/* Quick links */}
      <div className="mt-10 grid grid-cols-3 sm:grid-cols-6 gap-4">
        {quickLinks.map((link) => (
          <button
            key={link.url}
            onClick={() => onNavigate(link.url)}
            className="flex flex-col items-center gap-2 p-3 rounded-xl hover:bg-surface-elevated transition-colors group"
          >
            <div className="w-10 h-10 rounded-lg bg-surface-elevated group-hover:bg-gray-700 flex items-center justify-center text-sm font-bold text-hotpink transition-colors">
              {link.icon}
            </div>
            <span className="text-xs text-muted group-hover:text-gray-300 transition-colors">
              {link.title}
            </span>
          </button>
        ))}
      </div>

      {/* Tagline */}
      <div className="mt-16 text-center">
        <p className="text-xs text-gray-700">
          Verification powered by AI. Sources ranked by accuracy.
        </p>
        <p className="text-xs text-gray-800 mt-1">
          BlackRoad Internet v0.1.0
        </p>
      </div>
    </div>
  );
}
