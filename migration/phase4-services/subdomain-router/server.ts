/**
 * BlackRoad Subdomain Router - Self-Hosted (Hono)
 *
 * Ported from Cloudflare Worker: workers/subdomain-router/src/index.ts
 * Handles all 67+ subdomains with branded HTML pages.
 * Port: 4000
 *
 * The original is 2,546 lines. This is a functional port of the core
 * routing + rendering logic. The full HTML rendering from the original
 * Worker is preserved - it generates branded landing pages for each subdomain.
 *
 * RUNS ON OCTAVIA
 */

import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { serve } from '@hono/node-server';
import { KVNamespace } from '../adapters/kv-adapter.js';
import { D1Database } from '../adapters/d1-adapter.js';

const app = new Hono();

// Adapters
const CACHE = new KVNamespace('CACHE');
const IDENTITIES = new KVNamespace('IDENTITIES');
const API_KEYS = new KVNamespace('API_KEYS');
const RATE_LIMIT = new KVNamespace('RATE_LIMIT');
const DB = new D1Database('blackroad_os_main');

app.use('*', cors());

// ─── Brand Constants ───
const BRAND = {
  black: '#000000',
  white: '#FFFFFF',
  amber: '#F5A623',
  hotPink: '#FF1D6C',
  electricBlue: '#2979FF',
  violet: '#9C27B0',
  gradient: 'linear-gradient(135deg, #F5A623 0%, #FF1D6C 38.2%, #9C27B0 61.8%, #2979FF 100%)',
};

// ─── Subdomain → Emoji + Title Map ───
const SUBDOMAIN_INFO: Record<string, { emoji: string; title: string; description: string }> = {
  os: { emoji: '🖥️', title: 'Operating System', description: 'The sovereign AI operating system' },
  ai: { emoji: '🤖', title: 'AI Platform', description: 'Multi-model AI inference and orchestration' },
  agents: { emoji: '🕵️', title: 'Agent Hub', description: '30,000 autonomous AI agents' },
  api: { emoji: '⚡', title: 'API Gateway', description: 'RESTful API for all BlackRoad services' },
  status: { emoji: '📊', title: 'System Status', description: 'Real-time infrastructure status' },
  docs: { emoji: '📚', title: 'Documentation', description: 'Guides, tutorials, and API reference' },
  console: { emoji: '🎮', title: 'Console', description: 'Admin console and management' },
  dashboard: { emoji: '📈', title: 'Dashboard', description: 'Metrics and monitoring' },
  chat: { emoji: '💬', title: 'Chat', description: 'Agent communication interface' },
  playground: { emoji: '🎪', title: 'Playground', description: 'Interactive AI sandbox' },
  marketplace: { emoji: '🏪', title: 'Marketplace', description: 'Agent templates and packs' },
  roadmap: { emoji: '🗺️', title: 'Roadmap', description: 'Product roadmap and vision' },
  changelog: { emoji: '📝', title: 'Changelog', description: 'Version history and updates' },
  security: { emoji: '🔒', title: 'Security', description: 'Security policies and audit' },
  careers: { emoji: '👥', title: 'Careers', description: 'Join the team' },
  store: { emoji: '🛍️', title: 'Store', description: 'Hardware and software store' },
  search: { emoji: '🔍', title: 'Search', description: 'Search across all services' },
  terminal: { emoji: '💻', title: 'Terminal', description: 'Web-based terminal' },
  world: { emoji: '🌍', title: 'World', description: '3D metaverse visualization' },
  admin: { emoji: '⚙️', title: 'Admin', description: 'System administration' },
  analytics: { emoji: '📉', title: 'Analytics', description: 'Traffic and usage analytics' },
  network: { emoji: '🌐', title: 'Network', description: 'Network topology and mesh' },
  prism: { emoji: '💎', title: 'Prism Console', description: 'Enterprise management' },
  brand: { emoji: '🎨', title: 'Brand', description: 'Design system and assets' },
  design: { emoji: '✏️', title: 'Design', description: 'UI/UX design system' },
  edge: { emoji: '🔮', title: 'Edge', description: 'Edge computing services' },
  data: { emoji: '🗃️', title: 'Data', description: 'Data management and pipelines' },
  finance: { emoji: '💰', title: 'Finance', description: 'Financial tools and analytics' },
  quantum: { emoji: '⚛️', title: 'Quantum', description: 'Quantum computing interface' },
  blog: { emoji: '✍️', title: 'Blog', description: 'News and articles' },
  dev: { emoji: '🛠️', title: 'Developer', description: 'Developer tools and SDKs' },
  about: { emoji: 'ℹ️', title: 'About', description: 'About BlackRoad OS' },
  help: { emoji: '❓', title: 'Help', description: 'Support and documentation' },
  products: { emoji: '📦', title: 'Products', description: 'Product catalog' },
  pitstop: { emoji: '🏁', title: 'Pitstop', description: 'Portal and quick links' },
  blockchain: { emoji: '⛓️', title: 'Blockchain', description: 'RoadChain and crypto' },
  compliance: { emoji: '✅', title: 'Compliance', description: 'Regulatory compliance' },
  hardware: { emoji: '🔧', title: 'Hardware', description: 'IoT and device management' },
  ide: { emoji: '📝', title: 'IDE', description: 'Web IDE and code editor' },
};

// ─── Rate Limiting ───
app.use('*', async (c, next) => {
  const ip = c.req.header('x-forwarded-for')?.split(',')[0]?.trim() || 'unknown';
  const key = `rate:${ip}`;
  const current = await RATE_LIMIT.get(key);
  const count = current ? parseInt(current) : 0;

  if (count >= 500) {
    return c.json({ error: 'Rate limit exceeded' }, 429);
  }

  await RATE_LIMIT.put(key, (count + 1).toString(), { expirationTtl: 60 });
  await next();
});

// ─── Request ID ───
app.use('*', async (c, next) => {
  const requestId = `br-${Date.now()}-${Math.random().toString(36).substring(2, 8)}`;
  c.header('X-Request-ID', requestId);
  await next();
});

// ─── SEO Routes ───
app.get('/robots.txt', (c) => {
  c.header('Content-Type', 'text/plain');
  return c.text('User-agent: *\nAllow: /\nSitemap: https://blackroad.io/sitemap.xml');
});

app.get('/sitemap.xml', (c) => {
  const subs = Object.keys(SUBDOMAIN_INFO);
  const entries = subs.map(s =>
    `  <url><loc>https://${s}.blackroad.io/</loc><changefreq>weekly</changefreq><priority>0.8</priority></url>`
  ).join('\n');
  c.header('Content-Type', 'application/xml');
  return c.text(`<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n${entries}\n</urlset>`);
});

// ─── Health ───
app.get('/health', (c) => c.json({
  status: 'healthy',
  service: 'subdomain-router',
  source: 'self-hosted',
  subdomains: Object.keys(SUBDOMAIN_INFO).length,
  timestamp: new Date().toISOString(),
}));

// ─── Main Router ───
app.get('*', async (c) => {
  const host = c.req.header('host') || '';
  const subdomain = host.split('.')[0].toLowerCase();

  // If it's the main domain, redirect or serve root
  if (subdomain === 'blackroad' || subdomain === 'www' || !host.includes('.')) {
    return c.redirect('https://blackroad.io', 301);
  }

  const info = SUBDOMAIN_INFO[subdomain] || {
    emoji: '🌌',
    title: subdomain.charAt(0).toUpperCase() + subdomain.slice(1),
    description: `BlackRoad ${subdomain} service`,
  };

  // Track analytics
  try {
    await DB.prepare(
      'INSERT INTO analytics (subdomain, ts, path, ip) VALUES (?, ?, ?, ?)'
    ).bind(subdomain, Date.now(), c.req.path, c.req.header('x-forwarded-for') || 'unknown').run();
  } catch {
    // Analytics failure is non-critical
  }

  return c.html(renderSubdomainPage(subdomain, info));
});

// ─── Render Branded Page ───
function renderSubdomainPage(
  subdomain: string,
  info: { emoji: string; title: string; description: string }
): string {
  return `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>${info.title} - BlackRoad OS</title>
<meta name="description" content="${info.description}">
<link rel="icon" href="data:image/svg+xml,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><text y='.9em' font-size='90'>${info.emoji}</text></svg>">
<meta property="og:title" content="${info.title} - BlackRoad OS">
<meta property="og:description" content="${info.description}">
<meta property="og:type" content="website">
<meta property="og:url" content="https://${subdomain}.blackroad.io">
<script type="application/ld+json">
{"@context":"https://schema.org","@type":"WebApplication","name":"BlackRoad OS - ${info.title}","url":"https://${subdomain}.blackroad.io","description":"${info.description}","applicationCategory":"DeveloperApplication","operatingSystem":"Any","offers":{"@type":"Offer","price":"0","priceCurrency":"USD"}}
</script>
<style>
:root {
  --black: ${BRAND.black}; --white: ${BRAND.white}; --amber: ${BRAND.amber};
  --hot-pink: ${BRAND.hotPink}; --electric-blue: ${BRAND.electricBlue}; --violet: ${BRAND.violet};
  --gradient: ${BRAND.gradient};
  --space-xs:8px; --space-sm:13px; --space-md:21px; --space-lg:34px; --space-xl:55px; --space-2xl:89px;
}
*{margin:0;padding:0;box-sizing:border-box}
body{font-family:-apple-system,BlinkMacSystemFont,'SF Pro Display',sans-serif;background:var(--black);color:var(--white);line-height:1.618;min-height:100vh;display:flex;flex-direction:column;align-items:center;justify-content:center}
.hero{text-align:center;padding:var(--space-2xl) var(--space-lg)}
.emoji{font-size:4rem;margin-bottom:var(--space-md)}
h1{font-size:2.5rem;font-weight:800;background:var(--gradient);-webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text;margin-bottom:var(--space-sm)}
.desc{color:#999;font-size:1.1rem;max-width:500px;margin:0 auto var(--space-lg)}
.badge{display:inline-block;background:rgba(255,29,108,.15);color:var(--hot-pink);padding:4px 13px;border-radius:21px;font-size:.8rem;font-weight:600;margin-bottom:var(--space-lg)}
.links{display:flex;gap:var(--space-sm);flex-wrap:wrap;justify-content:center}
.links a{display:inline-block;padding:var(--space-xs) var(--space-md);border:1px solid #333;border-radius:8px;color:var(--white);text-decoration:none;font-size:.9rem;transition:all .2s}
.links a:hover{border-color:var(--hot-pink);background:rgba(255,29,108,.1)}
.links a.primary{background:var(--gradient);border:none;font-weight:600}
.links a.primary:hover{opacity:.9}
footer{position:fixed;bottom:0;left:0;right:0;text-align:center;padding:var(--space-sm);color:#333;font-size:.75rem}
.pulse{animation:pulse 4s ease-in-out infinite}
@keyframes pulse{0%,100%{opacity:1}50%{opacity:.7}}
</style>
</head>
<body>
<div class="hero">
  <div class="emoji pulse">${info.emoji}</div>
  <h1>${info.title}</h1>
  <p class="desc">${info.description}</p>
  <div class="badge">BlackRoad OS &mdash; Self-Hosted</div>
  <div class="links">
    <a class="primary" href="https://blackroad.io">BlackRoad OS</a>
    <a href="https://docs.blackroad.io">Documentation</a>
    <a href="https://api.blackroad.io">API</a>
    <a href="https://status.blackroad.io">Status</a>
  </div>
</div>
<footer>&copy; ${new Date().getFullYear()} BlackRoad OS, Inc. Your AI. Your Hardware. Your Rules.</footer>
</body>
</html>`;
}

// ─── Start ───
const PORT = parseInt(process.env.PORT || '4000');
console.log(`[subdomain-router] Starting on port ${PORT}`);

serve({ fetch: app.fetch, port: PORT }, (info) => {
  console.log(`[subdomain-router] Listening on http://0.0.0.0:${info.port}`);
});

export default app;
