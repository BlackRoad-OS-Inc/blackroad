#!/usr/bin/env node
// CarPool Web Server — carpool.blackroad.io
// Serves the carpool roundtable CLI over HTTP on port 4040

const http = require('http');
const { spawn } = require('child_process');
const path = require('path');

const PORT = process.env.CARPOOL_PORT || 4040;
const CARPOOL_SH = process.env.CARPOOL_SH || path.join(__dirname, '../../carpool.sh');

// All commands — auto-generated list
const COMMANDS = [
  { cmd: 'startup', emoji: '🚀', desc: 'Founding story, product-market fit, early hiring' },
  { cmd: 'architecture', emoji: '🏛️', desc: 'System design trade-offs and scaling strategies' },
  { cmd: 'fundraising', emoji: '💰', desc: 'Investor narrative, deck structure, term sheets' },
  { cmd: 'devops-culture', emoji: '🔧', desc: 'DevOps mindset and cultural transformation' },
  { cmd: 'security', emoji: '🔒', desc: 'Security architecture and best practices' },
  { cmd: 'team-topology', emoji: '🗺️', desc: 'Team structures for fast-flowing software delivery' },
  { cmd: 'platform-eng', emoji: '🏗️', desc: 'Internal developer platforms and golden paths' },
  { cmd: 'data-mesh', emoji: '🕸️', desc: 'Decentralized data ownership and data products' },
  { cmd: 'ai-infra', emoji: '🧠', desc: 'GPU clusters, inference optimization, model serving' },
  { cmd: 'vector-db', emoji: '🗄️', desc: 'Embeddings, HNSW vs IVF, pgvector vs dedicated' },
  { cmd: 'rate-limiting', emoji: '🚦', desc: 'Token bucket, sliding window, distributed rate limiting' },
  { cmd: 'feature-store', emoji: '🧮', desc: 'Online/offline feature serving, drift detection' },
  { cmd: 'fintech-arch', emoji: '💳', desc: 'Double-entry ledgers, idempotency, PCI-DSS' },
  { cmd: 'real-time-collab', emoji: '🤝', desc: 'OT vs CRDTs, presence, offline sync' },
  { cmd: 'multi-agent-ai', emoji: '🤖', desc: 'Agent orchestration, tool use, cost control' },
  { cmd: 'graph-db', emoji: '🕸️', desc: 'Fraud detection, recommendations, Cypher design' },
  { cmd: 'streaming-arch', emoji: '🌊', desc: 'Kafka vs Kinesis, Flink, lambda vs kappa' },
  { cmd: 'privacy-engineering', emoji: '🔏', desc: 'PII tokenization, differential privacy, GDPR' },
  { cmd: 'docs-system', emoji: '📚', desc: 'Docs-as-code, OpenAPI gen, versioning, search' },
  { cmd: 'caching-strategy', emoji: '⚡', desc: 'Cache invalidation, stampede prevention, CDN vs app' },
  { cmd: 'auth-patterns', emoji: '🔐', desc: 'OAuth2 flows, passkeys, ABAC vs RBAC' },
  { cmd: 'db-sharding', emoji: '🗃️', desc: 'Shard key design, consistent hashing, resharding' },
  { cmd: 'event-sourcing', emoji: '📜', desc: 'Event store, projections, snapshots, CQRS' },
  { cmd: 'api-versioning', emoji: '🔢', desc: 'Breaking changes, deprecation, sunset policies' },
  { cmd: 'distributed-tracing', emoji: '🔭', desc: 'OpenTelemetry, sampling, tail latency debug' },
  { cmd: 'notification-system', emoji: '🔔', desc: 'Fan-out, multi-channel, dedup, preferences' },
  { cmd: 'file-storage', emoji: '📁', desc: 'Object vs block, CDN, multipart uploads' },
  { cmd: 'background-jobs', emoji: '⚙️', desc: 'Retry backoff, DLQs, idempotency, distributed locking' },
  { cmd: 'testing-strategy', emoji: '🧪', desc: 'Test pyramid, contract tests, mutation testing' },
];

const HTML_TEMPLATE = (commands) => `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>🚗 CarPool — AI Roundtables</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body { background: #000; color: #fff; font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Display', sans-serif; min-height: 100vh; }
    header { padding: 40px 40px 20px; border-bottom: 1px solid #1a1a1a; }
    header h1 { font-size: 2rem; font-weight: 700; background: linear-gradient(135deg, #F5A623 0%, #FF1D6C 38.2%, #9C27B0 61.8%, #2979FF 100%); -webkit-background-clip: text; -webkit-text-fill-color: transparent; }
    header p { color: #666; margin-top: 8px; font-size: 0.9rem; }
    .grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(280px, 1fr)); gap: 16px; padding: 32px 40px; }
    .card { background: #0a0a0a; border: 1px solid #1a1a1a; border-radius: 12px; padding: 20px; cursor: pointer; transition: all 0.2s; text-decoration: none; color: inherit; display: block; }
    .card:hover { border-color: #FF1D6C; transform: translateY(-2px); box-shadow: 0 8px 32px rgba(255,29,108,0.15); }
    .card-emoji { font-size: 1.8rem; margin-bottom: 10px; }
    .card-cmd { font-size: 0.75rem; font-family: monospace; color: #FF1D6C; margin-bottom: 6px; }
    .card-desc { font-size: 0.85rem; color: #888; line-height: 1.4; }
    .run-area { padding: 0 40px 40px; }
    .run-area h2 { font-size: 1.1rem; color: #666; margin-bottom: 16px; }
    #output { background: #0a0a0a; border: 1px solid #1a1a1a; border-radius: 12px; padding: 24px; font-family: monospace; font-size: 0.85rem; line-height: 1.6; min-height: 200px; white-space: pre-wrap; color: #0f0; display: none; }
    #output.active { display: block; }
    .badge { display: inline-block; background: #111; border: 1px solid #222; border-radius: 20px; padding: 4px 12px; font-size: 0.75rem; color: #666; margin-right: 8px; }
  </style>
</head>
<body>
  <header>
    <h1>🚗 CarPool</h1>
    <p>AI-powered expert roundtables • Running on BlackRoad OS • <span class="badge">${commands.length} sessions</span><span class="badge">5 agents each</span></p>
  </header>
  <div class="grid">
    ${commands.map(c => `
    <a class="card" href="/run/${c.cmd}" target="_blank">
      <div class="card-emoji">${c.emoji}</div>
      <div class="card-cmd">br carpool ${c.cmd}</div>
      <div class="card-desc">${c.desc}</div>
    </a>`).join('')}
  </div>
</body>
</html>`;

const server = http.createServer((req, res) => {
  const url = req.url;

  if (url === '/' || url === '/index.html') {
    res.writeHead(200, { 'Content-Type': 'text/html' });
    res.end(HTML_TEMPLATE(COMMANDS));
    return;
  }

  if (url.startsWith('/run/')) {
    const cmd = url.replace('/run/', '').split('?')[0].replace(/[^a-z0-9-]/g, '');
    if (!cmd) { res.writeHead(400); res.end('Bad command'); return; }

    res.writeHead(200, {
      'Content-Type': 'text/plain; charset=utf-8',
      'Transfer-Encoding': 'chunked',
      'X-Content-Type-Options': 'nosniff',
    });

    res.write(`=== CarPool: ${cmd} ===\n\n`);
    const proc = spawn('bash', [CARPOOL_SH, cmd], {
      env: { ...process.env, CARPOOL_MODEL: process.env.CARPOOL_MODEL || 'tinyllama' }
    });
    proc.stdout.on('data', d => res.write(d));
    proc.stderr.on('data', d => res.write(d));
    proc.on('close', () => res.end('\n=== done ===\n'));
    return;
  }

  if (url === '/health') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ status: 'ok', commands: COMMANDS.length, uptime: process.uptime() }));
    return;
  }

  res.writeHead(404);
  res.end('Not found');
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`🚗 CarPool web server running on http://0.0.0.0:${PORT}`);
  console.log(`   → carpool.blackroad.io via Cloudflare tunnel`);
  console.log(`   → ${COMMANDS.length} roundtable sessions available`);
});
