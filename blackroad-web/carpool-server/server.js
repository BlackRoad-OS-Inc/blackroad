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
  <meta name="description" content="AI-powered expert roundtables. ${commands.length} sessions, 5 agents each.">
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@300;400;500;600;700&display=swap" rel="stylesheet">
  <style>
    /* Inline Schematiq styles — self-contained for server deployment */
    :root {
      --black:#000;--ink:#0A0A0A;--surface:#111;--border:#1A1A1A;--muted:#333;
      --dim:#666;--sub:#999;--white:#FFF;--pink:#FF1D6C;--amber:#F5A623;
      --violet:#9C27B0;--blue:#2979FF;--green:#00FF88;
      --gradient:linear-gradient(135deg,#F5A623 0%,#FF1D6C 38.2%,#9C27B0 61.8%,#2979FF 100%);
      --xs:8px;--sm:13px;--md:21px;--lg:34px;--xl:55px;--xxl:89px;
      --ease:cubic-bezier(.25,.1,.25,1);--ease-out:cubic-bezier(.16,1,.3,1);
    }
    *,*::before,*::after{margin:0;padding:0;box-sizing:border-box}
    html{scroll-behavior:smooth}
    body{font-family:'JetBrains Mono',monospace;background:var(--black);color:var(--white);line-height:1.618;overflow-x:hidden;-webkit-font-smoothing:antialiased}
    h1{font-size:clamp(48px,10vw,100px);font-weight:600;letter-spacing:-.02em;line-height:1.1;background:var(--gradient);-webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text;margin-bottom:var(--md);animation:slide-up .8s var(--ease-out) both}
    h2{font-size:clamp(24px,4vw,40px);font-weight:600;letter-spacing:-.02em;color:var(--white);margin-bottom:var(--md)}
    p{color:var(--sub);line-height:1.8;margin-bottom:var(--md)}
    a{color:var(--blue);text-decoration:none;transition:color .2s}
    a:hover{color:var(--pink)}
    @keyframes slide-up{from{opacity:0;transform:translateY(24px)}to{opacity:1;transform:translateY(0)}}
    @keyframes orb-pulse{0%,100%{transform:translate(-50%,-50%) scale(1);opacity:.6}50%{transform:translate(-50%,-50%) scale(1.3);opacity:1}}

    nav{position:fixed;top:0;left:0;right:0;z-index:1000;display:flex;justify-content:space-between;align-items:center;padding:var(--md) var(--xl);background:rgba(0,0,0,.8);backdrop-filter:blur(20px);-webkit-backdrop-filter:blur(20px);border-bottom:1px solid var(--border)}
    .logo-text{font-size:18px;font-weight:700;background:var(--gradient);-webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text}
    .nav-links{display:flex;gap:var(--lg);list-style:none}
    .nav-links a{font-size:13px;color:var(--sub);letter-spacing:.05em}
    .nav-links a:hover{color:var(--white)}

    .hero{min-height:60vh;display:flex;flex-direction:column;justify-content:center;align-items:center;text-align:center;padding:var(--xxl) var(--xl) var(--xl);position:relative;overflow:hidden}
    .hero::before{content:'';position:absolute;top:50%;left:50%;transform:translate(-50%,-50%);width:600px;height:600px;background:radial-gradient(circle,rgba(255,29,108,.15) 0%,rgba(156,39,176,.1) 40%,transparent 70%);pointer-events:none;animation:orb-pulse 8s ease-in-out infinite}
    .hero p{font-size:18px;max-width:600px;color:var(--sub);margin-bottom:var(--xl);position:relative;z-index:1;animation:slide-up .8s var(--ease-out) .1s both}
    .badge-row{display:flex;gap:var(--sm);position:relative;z-index:1;animation:slide-up .8s var(--ease-out) .15s both}
    .badge{display:inline-block;padding:4px var(--sm);font-size:11px;letter-spacing:.1em;text-transform:uppercase;border:1px solid var(--border);color:var(--sub)}

    .sessions-section{padding:var(--xl);max-width:1200px;margin:0 auto}
    .section-label{display:block;font-size:12px;letter-spacing:.2em;text-transform:uppercase;color:var(--pink);margin-bottom:var(--sm)}

    .sessions{display:grid;grid-template-columns:repeat(auto-fill,minmax(300px,1fr));gap:var(--md);list-style:none;padding:0;margin-top:var(--lg)}
    .session-card{background:rgba(255,255,255,.02);border:1px solid var(--border);padding:var(--md);transition:all .2s var(--ease);cursor:pointer}
    .session-card:hover{background:rgba(255,29,108,.03);border-color:rgba(255,29,108,.4);transform:translateY(-2px)}
    .session-card a{display:block;color:var(--white);text-decoration:none}
    .session-card a:hover{color:var(--pink)}
    .session-emoji{font-size:24px;margin-bottom:var(--sm);display:block}
    .session-cmd{font-size:12px;color:var(--pink);margin-bottom:var(--xs);font-family:inherit}
    .session-desc{font-size:13px;color:var(--dim);line-height:1.6}

    footer{padding:var(--xl);border-top:1px solid var(--border);color:var(--dim);font-size:13px;display:flex;justify-content:space-between;align-items:center;flex-wrap:wrap;gap:var(--md);max-width:none}
    footer a{color:var(--sub)}
    footer a:hover{color:var(--pink)}

    @media(max-width:768px){nav{padding:var(--md)}.nav-links{gap:var(--md)}.hero{padding:var(--xxl) var(--md) var(--xl)}.sessions-section{padding:var(--lg) var(--md)}.sessions{grid-template-columns:1fr}}
  </style>
</head>
<body>

<nav>
  <span class="logo-text">CarPool</span>
  <ul class="nav-links">
    <li><a href="https://br.blackroad.io">br CLI</a></li>
    <li><a href="https://github.com/BlackRoad-OS-Inc/blackroad">GitHub</a></li>
  </ul>
</nav>

<section class="hero">
  <h1>CarPool</h1>
  <p>AI-powered expert roundtables. 8 agents, 1 topic, live stream.</p>
  <div class="badge-row">
    <span class="badge">${commands.length} sessions</span>
    <span class="badge">5 agents each</span>
    <span class="badge">streams live</span>
  </div>
</section>

<div class="sessions-section">
  <span class="section-label">Sessions</span>
  <h2>Pick a roundtable</h2>
  <p>Click any session to run it. Output streams as plain text.</p>

  <ul class="sessions">
    ${commands.map(c => `
    <li class="session-card">
      <a href="/run/${c.cmd}" target="_blank">
        <span class="session-emoji">${c.emoji}</span>
        <div class="session-cmd">br carpool ${c.cmd}</div>
        <div class="session-desc">${c.desc}</div>
      </a>
    </li>`).join('')}
  </ul>
</div>

<footer>
  <span>© 2026 BlackRoad OS, Inc.</span>
  <span><a href="/health">health</a> · <a href="https://github.com/BlackRoad-OS-Inc/blackroad">github</a></span>
</footer>

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
