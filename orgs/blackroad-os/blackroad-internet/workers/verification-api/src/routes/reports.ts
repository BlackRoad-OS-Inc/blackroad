import { Hono } from "hono";
import type { Env } from "../index";

export const reports = new Hono<{ Bindings: Env }>();

interface ReportRequest {
  url: string;
  claim_text?: string;
  report_type: "inaccurate" | "misleading" | "satire" | "outdated" | "biased";
  details?: string;
  reporter_id?: string;
}

// POST /reports - Submit a community accuracy report
reports.post("/", async (c) => {
  const body = await c.req.json<ReportRequest>();

  if (!body.url || !body.report_type) {
    return c.json({ error: "url and report_type required" }, 400);
  }

  const validTypes = ["inaccurate", "misleading", "satire", "outdated", "biased"];
  if (!validTypes.includes(body.report_type)) {
    return c.json({ error: `report_type must be one of: ${validTypes.join(", ")}` }, 400);
  }

  try {
    const domain = extractDomain(body.url);

    await c.env.DB.prepare(
      `INSERT INTO community_reports (url, domain, claim_text, report_type, details, reporter_id, created_at)
       VALUES (?, ?, ?, ?, ?, ?, datetime('now'))`,
    )
      .bind(
        body.url,
        domain,
        body.claim_text || null,
        body.report_type,
        body.details || null,
        body.reporter_id || "anonymous",
      )
      .run();

    return c.json({ success: true, message: "Report submitted" });
  } catch (err) {
    return c.json({ error: "Failed to submit report", detail: String(err) }, 500);
  }
});

// GET /reports?domain=... - Get reports for a domain
reports.get("/", async (c) => {
  const domain = c.req.query("domain");
  const url = c.req.query("url");
  const limit = Math.min(parseInt(c.req.query("limit") || "20"), 100);

  let query: string;
  let bindValue: string;

  if (url) {
    query = "SELECT * FROM community_reports WHERE url = ? ORDER BY created_at DESC LIMIT ?";
    bindValue = url;
  } else if (domain) {
    query = "SELECT * FROM community_reports WHERE domain = ? ORDER BY created_at DESC LIMIT ?";
    bindValue = domain;
  } else {
    return c.json({ error: "domain or url query parameter required" }, 400);
  }

  try {
    const { results } = await c.env.DB.prepare(query).bind(bindValue, limit).all();
    return c.json({ reports: results, count: results.length });
  } catch (err) {
    return c.json({ error: "Query failed", detail: String(err) }, 500);
  }
});

// GET /reports/stats?domain=... - Report stats for a domain
reports.get("/stats", async (c) => {
  const domain = c.req.query("domain");
  if (!domain) {
    return c.json({ error: "domain query parameter required" }, 400);
  }

  try {
    const { results } = await c.env.DB.prepare(
      `SELECT report_type, COUNT(*) as count
       FROM community_reports WHERE domain = ?
       GROUP BY report_type`,
    )
      .bind(domain)
      .all();

    const total = await c.env.DB.prepare(
      "SELECT COUNT(*) as total FROM community_reports WHERE domain = ?",
    )
      .bind(domain)
      .first<{ total: number }>();

    return c.json({
      domain,
      total_reports: total?.total || 0,
      by_type: results,
    });
  } catch (err) {
    return c.json({ error: "Query failed", detail: String(err) }, 500);
  }
});

function extractDomain(url: string): string {
  try {
    return new URL(url).hostname.toLowerCase();
  } catch {
    return url;
  }
}
