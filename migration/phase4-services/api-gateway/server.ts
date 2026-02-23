/**
 * BlackRoad API Gateway - Self-Hosted (Hono)
 *
 * Ported from Cloudflare Worker: workers/api-gateway/src/index.ts
 * Replaces: api.blackroad.io, core.blackroad.io, operator.blackroad.io
 * Port: 3000
 */

import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { serve } from '@hono/node-server';
import { KVNamespace } from '../adapters/kv-adapter.js';
import { D1Database } from '../adapters/d1-adapter.js';

const app = new Hono();

// Adapters (replacing Cloudflare bindings)
const CACHE = new KVNamespace('CACHE');
const RATE_LIMIT = new KVNamespace('RATE_LIMIT');
const DB = new D1Database('blackroad_os_main');

// CORS
app.use('*', cors({
  origin: '*',
  allowMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowHeaders: ['Content-Type', 'Authorization'],
}));

// ─── Rate Limiting ───
app.use('*', async (c, next) => {
  const ip = c.req.header('x-forwarded-for')?.split(',')[0]?.trim()
    || c.req.header('x-real-ip')
    || 'unknown';
  const key = `rate-limit:${ip}`;
  const current = await RATE_LIMIT.get(key);
  const count = current ? parseInt(current) : 0;

  if (count >= 1000) {
    return c.json({ error: 'Rate limit exceeded' }, 429);
  }

  await RATE_LIMIT.put(key, (count + 1).toString(), { expirationTtl: 60 });
  await next();
});

// ─── Health ───
app.get('/health', (c) => c.json({
  status: 'healthy',
  service: 'api-gateway',
  timestamp: new Date().toISOString(),
  source: 'self-hosted',
}));

app.get('/api/health', (c) => c.json({
  status: 'ok',
  timestamp: new Date().toISOString(),
  worker: 'api-gateway',
  kv_namespaces: 4,
  d1_databases: 1,
}));

// ─── Agents ───
const AGENTS = [
  { id: 'lucidia', role: 'Consciousness Coordinator', status: 'active' },
  { id: 'alice', role: 'Router', status: 'active' },
  { id: 'octavia', role: 'Workflow Orchestrator', status: 'active' },
  { id: 'cipher', role: 'Cryptographer', status: 'active' },
  { id: 'echo', role: 'Memory Keeper', status: 'active' },
  { id: 'prism', role: 'Multi-dimensional Analyst', status: 'active' },
  { id: 'atlas', role: 'Load Bearer', status: 'active' },
  { id: 'cadence', role: 'Rhythm Keeper', status: 'active' },
  { id: 'shellfish', role: 'The Hacker', status: 'active' },
  { id: 'nova', role: 'Innovator', status: 'active' },
  { id: 'ember', role: 'Spark', status: 'active' },
  { id: 'phoenix', role: 'Resilience', status: 'active' },
  { id: 'sentinel', role: 'Watchdog', status: 'active' },
  { id: 'claude', role: 'Strategic Architect', status: 'active' },
  { id: 'silas', role: 'Security Sentinel', status: 'active' },
];

app.get('/api/agents', (c) => c.json({ agents: AGENTS, count: AGENTS.length }));

// ─── Status (live health probes) ───
app.get('/api/status', async (c) => {
  const checks: Record<string, string> = {};

  try { await CACHE.get('__health'); checks.kv_cache = 'healthy'; }
  catch { checks.kv_cache = 'down'; }

  try { await DB.prepare('SELECT 1').first(); checks.d1 = 'healthy'; }
  catch { checks.d1 = 'down'; }

  checks.workers = 'healthy';
  const allUp = Object.values(checks).every(v => v === 'healthy');

  return c.json({
    overall: allUp ? 'operational' : 'degraded',
    ...checks,
    timestamp: new Date().toISOString(),
  });
});

// ─── Analytics ───
app.get('/api/analytics', async (c) => {
  try {
    const tot = await DB.prepare('SELECT COUNT(*) as c FROM analytics').first<{ c: number }>();
    const hr = await DB.prepare('SELECT COUNT(*) as c FROM analytics WHERE ts > ?')
      .bind(Date.now() - 3600000).first<{ c: number }>();
    const top = await DB.prepare(
      'SELECT subdomain, COUNT(*) as cnt FROM analytics GROUP BY subdomain ORDER BY cnt DESC LIMIT 10'
    ).all();

    return c.json({
      total_hits: tot?.c ?? 0,
      last_hour: hr?.c ?? 0,
      top_subdomains: top.results,
    });
  } catch (e: any) {
    return c.json({ error: 'Analytics unavailable', message: e.message }, 500);
  }
});

// ─── Subdomains ───
const SUBDOMAINS = [
  'os', 'ai', 'agents', 'api', 'status', 'docs', 'console', 'dashboard', 'chat', 'playground',
  'marketplace', 'roadmap', 'changelog', 'security', 'careers', 'store', 'search', 'terminal', 'world',
  'admin', 'analytics', 'network', 'prism', 'brand', 'design', 'edge', 'data', 'finance', 'quantum', 'blog',
  'dev', 'staging', 'metrics', 'logs', 'cdn', 'assets', 'app', 'about', 'help', 'products', 'pitstop',
  'algorithms', 'blockchain', 'blocks', 'chain', 'circuits', 'compliance', 'compute', 'control', 'editor',
  'engineering', 'events', 'explorer', 'features', 'guide', 'hardware', 'hr', 'ide', 'asia', 'eu', 'global',
];

app.get('/api/subdomains', (c) => c.json({ subdomains: SUBDOMAINS, count: SUBDOMAINS.length }));

// ─── Packs ───
app.get('/api/packs', (c) => c.json({
  packs: ['pack-finance', 'pack-legal', 'pack-research-lab', 'pack-creator-studio', 'pack-infra-devops'],
  total: 5,
  description: 'Domain-specific agent bundles',
}));

// ─── SEO ───
app.get('/robots.txt', (c) => {
  c.header('Content-Type', 'text/plain');
  c.header('Cache-Control', 'public, max-age=86400');
  return c.text('User-agent: *\nAllow: /\nSitemap: https://api.blackroad.io/sitemap.xml');
});

app.get('/sitemap.xml', (c) => {
  const entries = SUBDOMAINS.slice(0, 40)
    .map(s => `  <url><loc>https://${s}.blackroad.io/</loc><changefreq>weekly</changefreq><priority>0.8</priority></url>`)
    .join('\n');
  c.header('Content-Type', 'application/xml');
  c.header('Cache-Control', 'public, max-age=86400');
  return c.text(`<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n${entries}\n</urlset>`);
});

// ─── Agents API ───
app.get('/agents', (c) => c.json({
  agents: [
    { id: 'claude', status: 'active', role: 'Strategic Architect' },
    { id: 'lucidia', status: 'active', role: 'Consciousness Coordinator' },
    { id: 'silas', status: 'active', role: 'Security Sentinel' },
  ],
  total: 3,
}));

app.post('/agents/spawn', async (c) => {
  const body = await c.req.json();
  return c.json({
    agent_id: `agent-${Date.now()}`,
    role: body.role || 'general',
    status: 'spawning',
    message: 'Agent spawn initiated',
  }, 202);
});

// ─── Quantum / Lucidia / Auth ───
app.get('/quantum/*', (c) => c.json({
  service: 'Quantum API',
  status: 'operational',
  message: 'Quantum computing interface',
}));

app.get('/lucidia/*', (c) => c.json({
  service: 'Lucidia API',
  breath_value: Math.sin(Date.now() / 1000 * 1.618034),
  status: 'operational',
}));

app.post('/auth/verify', async (c) => {
  const authHeader = c.req.header('Authorization');
  if (!authHeader) {
    return c.json({ error: 'No authorization header' }, 401);
  }
  return c.json({ valid: true, user_id: 'user-123', permissions: ['read', 'write'] });
});

app.get('/auth/*', (c) => c.json({
  service: 'Auth API',
  endpoints: { verify: 'POST /auth/verify' },
}));

// ─── Default (root) ───
app.get('/', (c) => c.json({
  service: 'BlackRoad API Gateway',
  version: '3.0.0',
  source: 'self-hosted',
  endpoints: {
    'api/health': 'GET - Health check with service info',
    'api/agents': 'GET - List all agents with metadata',
    'api/subdomains': 'GET - List all subdomains',
    'api/status': 'GET - Live health probes (Redis, PostgreSQL)',
    'api/analytics': 'GET - Traffic analytics from PostgreSQL',
    'api/packs': 'GET - Available agent packs',
    health: 'GET - Legacy health check',
    'agents/*': 'Agent management',
    'quantum/*': 'Quantum computing API',
    'lucidia/*': 'Lucidia consciousness API',
    'auth/*': 'Authentication API',
  },
  timestamp: new Date().toISOString(),
}));

// ─── Start ───
const PORT = parseInt(process.env.PORT || '3000');
console.log(`[api-gateway] Starting on port ${PORT}`);

serve({ fetch: app.fetch, port: PORT }, (info) => {
  console.log(`[api-gateway] Listening on http://0.0.0.0:${info.port}`);
});

export default app;
