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
  <title>CarPool — AI Roundtables</title>
</head>
<body>

<h1>CarPool</h1>
<p>AI-powered expert roundtables — BlackRoad OS — ${commands.length} sessions, 5 agents each</p>

<hr>

<h2>Roundtable Sessions</h2>
<p>Click any session to run it. Output streams as plain text.</p>

<ul>
  ${commands.map(c => `<li>${c.emoji} <a href="/run/${c.cmd}"><code>br carpool ${c.cmd}</code></a> — ${c.desc}</li>`).join('\n  ')}
</ul>

<hr>
<p><a href="/health">Health check</a> | <a href="https://github.com/BlackRoad-OS-Inc/blackroad">GitHub</a></p>

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
