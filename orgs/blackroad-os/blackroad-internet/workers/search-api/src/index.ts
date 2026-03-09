import { Hono } from "hono";
import { cors } from "hono/cors";

export interface Env {
  BRAVE_API_KEY: string;
  VERIFICATION_API: Fetcher;
  ENVIRONMENT: string;
}

interface SearchResult {
  title: string;
  url: string;
  description: string;
  age?: string;
}

interface RankedResult {
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

const app = new Hono<{ Bindings: Env }>();

app.use("*", cors({
  origin: "*",
  allowMethods: ["GET", "POST", "OPTIONS"],
  allowHeaders: ["Content-Type"],
}));

app.get("/", (c) => {
  return c.json({
    service: "BlackRoad Search API",
    version: "0.1.0",
    status: "operational",
    ranking: "0.4*Relevance + 0.3*Accuracy + 0.2*SourceReputation + 0.1*Freshness",
    endpoints: {
      search: "GET /search?q=query&limit=20 (requires BRAVE_API_KEY)",
      enrich: "POST /enrich (enrich client-side results with reputation scores)",
      reputation: "GET /reputation/:domain (via verification-api)",
    },
  });
});

app.get("/health", (c) => c.json({ ok: true, ts: Date.now() }));

// GET /search?q=query&limit=20 - Full search (requires Brave API key)
app.get("/search", async (c) => {
  const query = c.req.query("q");
  if (!query) {
    return c.json({ error: "q query parameter required" }, 400);
  }

  const limit = Math.min(parseInt(c.req.query("limit") || "20"), 50);
  const start = Date.now();

  if (!c.env.BRAVE_API_KEY) {
    return c.json({
      query,
      results: [],
      total: 0,
      search_time_ms: Date.now() - start,
      engine: "none",
      fallback_url: `https://duckduckgo.com/?q=${encodeURIComponent(query)}`,
      error: "BRAVE_API_KEY not configured. Use /enrich endpoint to score client-side results, or set up Brave Search API key.",
    });
  }

  let rawResults: SearchResult[] = [];
  try {
    const braveResp = await fetch(
      `https://api.search.brave.com/res/v1/web/search?q=${encodeURIComponent(query)}&count=${limit}`,
      {
        headers: {
          "Accept": "application/json",
          "Accept-Encoding": "gzip",
          "X-Subscription-Token": c.env.BRAVE_API_KEY,
        },
      },
    );

    if (braveResp.ok) {
      const data = (await braveResp.json()) as { web?: { results: SearchResult[] } };
      rawResults = data.web?.results || [];
    }
  } catch {
    return c.json({
      query,
      results: [],
      total: 0,
      search_time_ms: Date.now() - start,
      engine: "brave",
      error: "Brave Search API error",
    });
  }

  return c.json(await rankResults(rawResults, query, start, "brave", c.env.VERIFICATION_API, limit));
});

// POST /enrich - Score/rank a set of results from client-side scraping
// Body: { query: string, results: [{ title, url, description }] }
app.post("/enrich", async (c) => {
  const body = await c.req.json<{ query: string; results: SearchResult[] }>();
  if (!body.query || !body.results) {
    return c.json({ error: "query and results[] required" }, 400);
  }

  const start = Date.now();
  return c.json(await rankResults(body.results, body.query, start, "enriched", c.env.VERIFICATION_API, 50));
});

// GET /reputation/:domain - Proxy to verification API
app.get("/reputation/:domain", async (c) => {
  const domain = c.req.param("domain");
  try {
    const resp = await c.env.VERIFICATION_API.fetch(
      new Request(`https://internal/reputation/${domain}`),
    );
    const data = await resp.json();
    return c.json(data);
  } catch {
    return c.json({ domain, score: 0.5, category: "unknown", bias: "unknown", error: "lookup failed" });
  }
});

/** Core ranking logic - shared between /search and /enrich */
async function rankResults(
  rawResults: SearchResult[],
  query: string,
  startTime: number,
  engine: string,
  verificationApi: Fetcher,
  limit: number,
) {
  if (rawResults.length === 0) {
    return {
      query,
      results: [],
      total: 0,
      search_time_ms: Date.now() - startTime,
      engine,
    };
  }

  // Batch lookup domain reputations
  const domains = [...new Set(rawResults.map((r) => extractDomain(r.url)))];
  const reputations = await batchLookupReputations(verificationApi, domains);

  // Apply BlackRoad accuracy formula
  const ranked: RankedResult[] = rawResults.map((result, index) => {
    const domain = extractDomain(result.url);
    const rep = reputations[domain] || { score: 0.5, category: "unknown", bias: "unknown" };

    const relevance = 1.0 - (index / rawResults.length) * 0.5;
    const accuracy = rep.score;
    const sourceRep = rep.score;
    const freshness = computeFreshness(result.age);

    const finalScore = 0.4 * relevance + 0.3 * accuracy + 0.2 * sourceRep + 0.1 * freshness;

    return {
      title: result.title,
      url: result.url,
      description: result.description,
      domain,
      relevance_score: Math.round(relevance * 100) / 100,
      accuracy_score: Math.round(accuracy * 100) / 100,
      source_reputation: Math.round(sourceRep * 100) / 100,
      freshness_score: Math.round(freshness * 100) / 100,
      final_score: Math.round(finalScore * 100) / 100,
      source_category: rep.category,
      source_bias: rep.bias,
    };
  });

  ranked.sort((a, b) => b.final_score - a.final_score);

  return {
    query,
    results: ranked.slice(0, limit),
    total: ranked.length,
    search_time_ms: Date.now() - startTime,
    engine,
    ranking_formula: "0.4*Relevance + 0.3*Accuracy + 0.2*SourceReputation + 0.1*Freshness",
  };
}

async function batchLookupReputations(
  verificationApi: Fetcher,
  domains: string[],
): Promise<Record<string, { score: number; category: string; bias: string }>> {
  try {
    const resp = await verificationApi.fetch(
      new Request("https://internal/reputation/batch", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ domains }),
      }),
    );

    if (resp.ok) {
      const data = (await resp.json()) as { results: Record<string, { score: number; category: string; bias: string }> };
      return data.results;
    }
  } catch {
    // Service binding unavailable
  }

  const defaults: Record<string, { score: number; category: string; bias: string }> = {};
  for (const d of domains) {
    defaults[d] = { score: 0.5, category: "unknown", bias: "unknown" };
  }
  return defaults;
}

function computeFreshness(age?: string): number {
  if (!age) return 0.5;
  const lower = age.toLowerCase();
  if (lower.includes("hour") || lower.includes("minute")) return 1.0;
  if (lower.includes("day")) {
    const days = parseInt(lower) || 1;
    return days <= 7 ? 0.9 : days <= 30 ? 0.7 : 0.5;
  }
  if (lower.includes("week")) return 0.7;
  if (lower.includes("month")) {
    const months = parseInt(lower) || 1;
    return months <= 3 ? 0.5 : months <= 12 ? 0.3 : 0.2;
  }
  if (lower.includes("year")) return 0.1;
  return 0.5;
}

function extractDomain(url: string): string {
  try {
    return new URL(url).hostname.toLowerCase();
  } catch {
    return url;
  }
}

export default app;
