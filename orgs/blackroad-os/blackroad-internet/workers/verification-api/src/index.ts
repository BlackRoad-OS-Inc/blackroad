import { Hono } from "hono";
import { cors } from "hono/cors";
import { reputation } from "./routes/reputation";
import { verify } from "./routes/verify";
import { reports } from "./routes/reports";

export interface Env {
  DB: D1Database;
  ENVIRONMENT: string;
}

const app = new Hono<{ Bindings: Env }>();

// CORS for browser access
app.use("*", cors({
  origin: ["http://localhost:1420", "https://internet.blackroad.io", "https://search.blackroad.io"],
  allowMethods: ["GET", "POST", "OPTIONS"],
  allowHeaders: ["Content-Type", "Authorization"],
}));

// Health check
app.get("/", (c) => {
  return c.json({
    service: "BlackRoad Verification API",
    version: "0.1.0",
    status: "operational",
    mission: "Accurate info. Period.",
  });
});

app.get("/health", (c) => {
  return c.json({ ok: true, ts: Date.now() });
});

// Mount route groups
app.route("/reputation", reputation);
app.route("/verify", verify);
app.route("/reports", reports);

export default app;
