import { useState, useEffect, type KeyboardEvent } from "react";

interface SearchPageProps {
  query: string;
  onNavigate: (url: string) => void;
}

interface SearchResult {
  title: string;
  url: string;
  description: string;
  domain: string;
  relevance_score: number;
  accuracy_score: number;
  source_reputation: number;
  freshness_score: number;
  final_score: number;
  source_category: string;
  source_bias: string;
}

interface SearchResponse {
  query: string;
  results: SearchResult[];
  total: number;
  search_time_ms: number;
  engine: string;
  error?: string;
  fallback_url?: string;
}

const SEARCH_API = "https://blackroad-search-api.amundsonalexa.workers.dev";

const categoryIcons: Record<string, string> = {
  academic: "A",
  journal: "J",
  government: "G",
  "wire-service": "W",
  reference: "R",
  news: "N",
  "fact-check": "F",
  "tech-docs": "T",
  social: "S",
  "low-credibility": "!",
};

export function SearchPage({ query, onNavigate }: SearchPageProps) {
  const [searchInput, setSearchInput] = useState(query);
  const [results, setResults] = useState<SearchResult[]>([]);
  const [isSearching, setIsSearching] = useState(false);
  const [searchTime, setSearchTime] = useState(0);
  const [engine, setEngine] = useState("");
  const [searchError, setSearchError] = useState<string | null>(null);
  const [fallbackUrl, setFallbackUrl] = useState<string | null>(null);

  const handleKeyDown = (e: KeyboardEvent) => {
    if (e.key === "Enter" && searchInput.trim()) {
      onNavigate(`blackroad://search?q=${encodeURIComponent(searchInput.trim())}`);
    }
  };

  useEffect(() => {
    if (!query) return;
    let cancelled = false;

    const doSearch = async () => {
      setIsSearching(true);
      setSearchError(null);
      setFallbackUrl(null);

      try {
        const resp = await fetch(`${SEARCH_API}/search?q=${encodeURIComponent(query)}&limit=20`);

        if (resp.ok && !cancelled) {
          const data: SearchResponse = await resp.json();
          setResults(data.results);
          setSearchTime(data.search_time_ms);
          setEngine(data.engine);
          if (data.error) setSearchError(data.error);
          if (data.fallback_url) setFallbackUrl(data.fallback_url);
        } else if (!cancelled) {
          setResults([]);
          setSearchError("Search API returned an error.");
        }
      } catch {
        if (!cancelled) {
          setResults([]);
          setSearchError("Search API offline.");
          setFallbackUrl(`https://duckduckgo.com/?q=${encodeURIComponent(query)}`);
        }
      } finally {
        if (!cancelled) setIsSearching(false);
      }
    };

    doSearch();
    return () => { cancelled = true; };
  }, [query]);

  return (
    <div className="min-h-full bg-black p-6">
      <div className="max-w-3xl mx-auto">
        {/* Search header */}
        <div className="flex items-center gap-4 mb-8">
          <h1
            className="text-2xl font-bold br-gradient-text shrink-0 cursor-pointer"
            onClick={() => onNavigate("blackroad://newtab")}
          >
            BlackRoad
          </h1>
          <div className="flex-1">
            <input
              type="text"
              value={searchInput}
              onChange={(e) => setSearchInput(e.target.value)}
              onKeyDown={handleKeyDown}
              className="w-full px-4 py-2 rounded-lg bg-surface-elevated border border-gray-700 text-white text-sm outline-none focus:border-hotpink transition-colors placeholder-gray-500"
              placeholder="Search the accurate web..."
              autoFocus
            />
          </div>
        </div>

        {/* Search status bar */}
        {query && (
          <div className="flex items-center justify-between mb-4">
            <p className="text-xs text-muted">
              {isSearching
                ? "Searching & ranking by accuracy..."
                : results.length > 0
                  ? `${results.length} results ranked by accuracy (${searchTime}ms via ${engine})`
                  : null}
            </p>
            {!isSearching && results.length > 0 && (
              <p className="text-[10px] text-gray-700">
                0.4*Relevance + 0.3*Accuracy + 0.2*Source + 0.1*Fresh
              </p>
            )}
          </div>
        )}

        {/* Loading */}
        {isSearching && (
          <div className="flex items-center justify-center py-20">
            <div className="text-center">
              <div className="animate-spin w-8 h-8 border-2 border-hotpink border-t-transparent rounded-full mx-auto" />
              <p className="text-xs text-muted mt-4">Ranking by accuracy...</p>
            </div>
          </div>
        )}

        {/* Results */}
        {!isSearching && results.length > 0 && (
          <div className="space-y-5">
            {results.map((result, i) => (
              <div
                key={i}
                className="group cursor-pointer"
                onClick={() => onNavigate(result.url)}
              >
                <div className="flex items-center gap-2 mb-1">
                  <span
                    className={`text-[10px] font-mono font-bold px-1.5 py-0.5 rounded ${
                      result.final_score > 0.7
                        ? "text-emerald-400 bg-emerald-400/10"
                        : result.final_score > 0.45
                          ? "text-amber-400 bg-amber-400/10"
                          : "text-red-400 bg-red-400/10"
                    }`}
                  >
                    {Math.round(result.final_score * 100)}
                  </span>
                  {result.source_category !== "unknown" && (
                    <span
                      className="text-[9px] px-1 py-0.5 rounded bg-gray-800 text-gray-500 font-mono"
                      title={result.source_category}
                    >
                      {categoryIcons[result.source_category] || "?"}
                    </span>
                  )}
                  <span className="text-[11px] text-gray-600 truncate">
                    {result.domain}
                  </span>
                </div>

                <h3 className="text-sm text-electricblue group-hover:underline">
                  {result.title}
                </h3>

                <p className="text-xs text-gray-400 mt-1 leading-relaxed line-clamp-2">
                  {result.description}
                </p>

                <div className="flex items-center gap-3 mt-1.5">
                  <span className="text-[9px] text-gray-700">
                    rel:{Math.round(result.relevance_score * 100)}
                  </span>
                  <span className="text-[9px] text-gray-700">
                    acc:{Math.round(result.accuracy_score * 100)}
                  </span>
                  <span className="text-[9px] text-gray-700">
                    src:{Math.round(result.source_reputation * 100)}
                  </span>
                  <span className="text-[9px] text-gray-700">
                    fresh:{Math.round(result.freshness_score * 100)}
                  </span>
                  {result.source_bias !== "unknown" && result.source_bias !== "none" && (
                    <span className="text-[9px] text-amber-600">
                      bias:{result.source_bias}
                    </span>
                  )}
                </div>
              </div>
            ))}
          </div>
        )}

        {/* No Brave key - DuckDuckGo fallback with accuracy overlay */}
        {!isSearching && results.length === 0 && query && (
          <div className="space-y-6">
            {/* Accuracy-scored quick links for this query */}
            <div className="p-4 rounded-lg border border-gray-800 bg-surface">
              <h3 className="text-xs text-muted font-semibold mb-3 uppercase tracking-wider">
                Accuracy-Ranked Sources
              </h3>
              <p className="text-[10px] text-gray-600 mb-3">
                {searchError || "Searching high-accuracy sources for your query:"}
              </p>
              <div className="space-y-2">
                {[
                  { name: "Wikipedia", url: `https://en.wikipedia.org/w/index.php?search=${encodeURIComponent(query)}`, score: 88, cat: "R" },
                  { name: "Google Scholar", url: `https://scholar.google.com/scholar?q=${encodeURIComponent(query)}`, score: 95, cat: "A" },
                  { name: "PubMed", url: `https://pubmed.ncbi.nlm.nih.gov/?term=${encodeURIComponent(query)}`, score: 95, cat: "A" },
                  { name: "Reuters", url: `https://www.reuters.com/search/news?query=${encodeURIComponent(query)}`, score: 93, cat: "W" },
                  { name: "AP News", url: `https://apnews.com/search#?q=${encodeURIComponent(query)}`, score: 93, cat: "W" },
                  { name: "BBC", url: `https://www.bbc.co.uk/search?q=${encodeURIComponent(query)}`, score: 85, cat: "N" },
                  { name: "Nature", url: `https://www.nature.com/search?q=${encodeURIComponent(query)}`, score: 96, cat: "J" },
                  { name: "arXiv", url: `https://arxiv.org/search/?query=${encodeURIComponent(query)}`, score: 95, cat: "A" },
                ].map((src, i) => (
                  <div
                    key={i}
                    className="flex items-center gap-3 p-2 rounded-lg hover:bg-surface-elevated cursor-pointer transition-colors"
                    onClick={() => onNavigate(src.url)}
                  >
                    <span className="text-[10px] font-mono font-bold text-emerald-400 bg-emerald-400/10 px-1.5 py-0.5 rounded w-8 text-center">
                      {src.score}
                    </span>
                    <span className="text-[9px] px-1 py-0.5 rounded bg-gray-800 text-gray-500 font-mono">
                      {src.cat}
                    </span>
                    <span className="text-sm text-electricblue hover:underline">
                      {src.name}
                    </span>
                    <span className="text-[10px] text-gray-700 ml-auto truncate max-w-[200px]">
                      Search "{query}"
                    </span>
                  </div>
                ))}
              </div>
            </div>

            {/* DuckDuckGo full search fallback */}
            <div className="text-center">
              <button
                onClick={() => onNavigate(fallbackUrl || `https://duckduckgo.com/?q=${encodeURIComponent(query)}`)}
                className="text-xs text-electricblue hover:underline"
              >
                Or search with DuckDuckGo (unranked)
              </button>
              <p className="text-[9px] text-gray-700 mt-2">
                Add a Brave Search API key to enable full accuracy-ranked search
              </p>
            </div>
          </div>
        )}

        {/* Empty state */}
        {!query && (
          <div className="text-center mt-20">
            <p className="text-muted text-sm">
              Enter a search query to get accuracy-ranked results
            </p>
          </div>
        )}
      </div>
    </div>
  );
}
