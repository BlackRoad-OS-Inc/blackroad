import { Hono } from "hono";
import type { Env } from "../index";

export const reputation = new Hono<{ Bindings: Env }>();

// GET /reputation/:domain - Look up domain reputation
reputation.get("/:domain", async (c) => {
  const domain = c.req.param("domain").toLowerCase();

  try {
    const row = await c.env.DB.prepare(
      "SELECT domain, score, category, bias, factual, updated_at FROM source_reputation WHERE domain = ?",
    )
      .bind(domain)
      .first();

    if (!row) {
      // Try parent domain
      const parts = domain.split(".");
      if (parts.length > 2) {
        const parent = parts.slice(-2).join(".");
        const parentRow = await c.env.DB.prepare(
          "SELECT domain, score, category, bias, factual, updated_at FROM source_reputation WHERE domain = ?",
        )
          .bind(parent)
          .first();

        if (parentRow) {
          return c.json({ found: true, ...parentRow, matched_via: "parent" });
        }
      }

      // TLD fallbacks
      if (domain.endsWith(".gov")) {
        return c.json({
          found: true,
          domain,
          score: 0.88,
          category: "government",
          bias: "none",
          factual: "high",
          matched_via: "tld",
        });
      }
      if (domain.endsWith(".edu")) {
        return c.json({
          found: true,
          domain,
          score: 0.85,
          category: "education",
          bias: "none",
          factual: "high",
          matched_via: "tld",
        });
      }

      return c.json({ found: false, domain, score: 0.5, category: "unknown", bias: "unknown", factual: "unknown" });
    }

    return c.json({ found: true, ...row });
  } catch (err) {
    return c.json({ error: "Database error", detail: String(err) }, 500);
  }
});

// POST /reputation/batch - Batch lookup with parent domain resolution
reputation.post("/batch", async (c) => {
  const body = await c.req.json<{ domains: string[] }>();
  if (!body.domains || !Array.isArray(body.domains)) {
    return c.json({ error: "domains array required" }, 400);
  }

  const results: Record<string, unknown> = {};
  for (const domain of body.domains.slice(0, 50)) {
    const d = domain.toLowerCase();

    // Direct match
    let row = await c.env.DB.prepare(
      "SELECT score, category, bias, factual FROM source_reputation WHERE domain = ?",
    )
      .bind(d)
      .first();

    // Try parent domain (e.g. climate.nasa.gov -> nasa.gov)
    if (!row) {
      const parts = d.split(".");
      if (parts.length > 2) {
        const parent = parts.slice(-2).join(".");
        row = await c.env.DB.prepare(
          "SELECT score, category, bias, factual FROM source_reputation WHERE domain = ?",
        )
          .bind(parent)
          .first();
      }
    }

    // TLD fallbacks
    if (!row) {
      if (d.endsWith(".gov")) {
        row = { score: 0.88, category: "government", bias: "none", factual: "high" } as any;
      } else if (d.endsWith(".edu")) {
        row = { score: 0.85, category: "education", bias: "none", factual: "high" } as any;
      } else if (d.endsWith(".org")) {
        row = { score: 0.60, category: "organization", bias: "unknown", factual: "mixed" } as any;
      }
    }

    results[domain] = row || { score: 0.5, category: "unknown", bias: "unknown", factual: "unknown" };
  }

  return c.json({ results });
});
