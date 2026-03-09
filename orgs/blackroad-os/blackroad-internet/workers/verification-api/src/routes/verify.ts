import { Hono } from "hono";
import type { Env } from "../index";

export const verify = new Hono<{ Bindings: Env }>();

interface VerifyRequest {
  url: string;
  content?: string;
  claims?: string[];
}

// POST /verify - Verify a page or set of claims
verify.post("/", async (c) => {
  const body = await c.req.json<VerifyRequest>();
  if (!body.url) {
    return c.json({ error: "url required" }, 400);
  }

  const domain = extractDomain(body.url);
  const start = Date.now();

  // 1. Get source reputation from D1
  const repRow = await c.env.DB.prepare(
    "SELECT score, category, bias, factual FROM source_reputation WHERE domain = ?",
  )
    .bind(domain)
    .first<{ score: number; category: string; bias: string; factual: string }>();

  const sourceScore = repRow?.score ?? 0.5;
  const sourceCategory = repRow?.category ?? "unknown";
  const sourceBias = repRow?.bias ?? "unknown";

  // 2. Check verification cache
  const cached = await c.env.DB.prepare(
    "SELECT result_json FROM verification_cache WHERE url = ? AND created_at > datetime('now', '-1 hour')",
  )
    .bind(body.url)
    .first<{ result_json: string }>();

  if (cached) {
    return c.json(JSON.parse(cached.result_json));
  }

  // 3. Build verification result
  // In Phase 2, cloud-side AI verification uses source reputation + basic heuristics.
  // Full AI pipeline runs client-side via Ollama.
  const result = {
    url: body.url,
    overall_score: sourceScore,
    source_reputation: sourceScore,
    source_category: sourceCategory,
    source_bias: sourceBias,
    claims: [] as unknown[],
    claims_checked: 0,
    verification_time_ms: Date.now() - start,
    method: "cloud-reputation",
    ai_available: false,
  };

  // 4. Cache result
  try {
    await c.env.DB.prepare(
      "INSERT OR REPLACE INTO verification_cache (url, result_json, created_at) VALUES (?, ?, datetime('now'))",
    )
      .bind(body.url, JSON.stringify(result))
      .run();
  } catch {
    // Cache write failure is non-critical
  }

  return c.json(result);
});

// GET /verify/status?url=... - Check cached verification
verify.get("/status", async (c) => {
  const url = c.req.query("url");
  if (!url) {
    return c.json({ error: "url query parameter required" }, 400);
  }

  const cached = await c.env.DB.prepare(
    "SELECT result_json, created_at FROM verification_cache WHERE url = ?",
  )
    .bind(url)
    .first<{ result_json: string; created_at: string }>();

  if (!cached) {
    return c.json({ found: false });
  }

  return c.json({ found: true, ...JSON.parse(cached.result_json), cached_at: cached.created_at });
});

function extractDomain(url: string): string {
  try {
    return new URL(url).hostname.toLowerCase();
  } catch {
    return url;
  }
}
