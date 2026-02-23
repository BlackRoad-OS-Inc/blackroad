/**
 * Salesforce Webhook Listener — runs on alice Pi (port 8444)
 * Receives SF platform events and org changes, syncs to GitHub
 */
const http = require('http');
const { execSync } = require('child_process');
const fs = require('fs');

const PORT = process.env.SF_WEBHOOK_PORT || 8444;
const SECRET = process.env.SF_WEBHOOK_SECRET || '';
const LOG_FILE = process.env.HOME + '/.blackroad/sf-webhook.log';

function log(msg) {
  const line = `[${new Date().toISOString()}] ${msg}`;
  console.log(line);
  fs.appendFileSync(LOG_FILE, line + '\n');
}

const server = http.createServer((req, res) => {
  if (req.method !== 'POST') {
    res.writeHead(200); res.end('SF Webhook Listener — BlackRoad OS'); return;
  }

  let body = '';
  req.on('data', chunk => body += chunk);
  req.on('end', () => {
    try {
      const event = JSON.parse(body);
      log(`📡 SF Event: ${event.type || 'unknown'} — ${JSON.stringify(event).slice(0, 100)}`);

      // Write to shared inbox for agent processing
      const inbox = process.env.HOME + '/.blackroad/agent-inboxes/inbox';
      fs.mkdirSync(inbox, { recursive: true });
      fs.writeFileSync(`${inbox}/sf-event-${Date.now()}.json`, body);

      // Trigger GitHub sync if metadata change
      if (event.type === 'MetadataChange' || event.type === 'DeployComplete') {
        log('🔄 Triggering SF metadata sync...');
        try {
          execSync(`cd ~/blackroad && git add blackroad-sf/ && git commit -m "auto: SF metadata sync $(date -u +%Y-%m-%dT%H:%M:%SZ)" --no-verify`, { stdio: 'pipe' });
          execSync(`cd ~/blackroad && git push origin master`, { stdio: 'pipe' });
          log('✅ GitHub sync complete');
        } catch(e) { log(`⚠️ Sync: ${e.message}`); }
      }

      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ status: 'received', agent: 'alice' }));
    } catch(e) {
      log(`❌ Parse error: ${e.message}`);
      res.writeHead(400); res.end('Bad Request');
    }
  });
});

server.listen(PORT, '0.0.0.0', () => {
  log(`🚀 SF Webhook Listener running on port ${PORT}`);
  log(`📍 Endpoint: https://alice.blackroad.io/sf-webhook`);
});
