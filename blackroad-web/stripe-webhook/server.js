#!/usr/bin/env node
/**
 * Stripe Webhook Listener — runs on Raspberry Pis (port 8445)
 * Receives forwarded Stripe events from roadgateway/stripe-webhook-router
 * and processes them locally (updates agent quotas, logs to memory, etc.)
 *
 * Deploy: scp -r stripe-webhook/ pi@192.168.4.64:~/blackroad-web/
 *         ssh pi@192.168.4.64 "cd ~/blackroad-web/stripe-webhook && node server.js"
 *
 * BlackRoad OS, Inc. © 2026 — All Rights Reserved
 */

const http = require('http');
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

const PORT = process.env.STRIPE_WEBHOOK_PORT || 8445;
const SECRET = process.env.PI_WEBHOOK_SECRET || '';
const LOG_DIR = process.env.HOME + '/.blackroad/stripe-events';
const MEMORY_SH = process.env.HOME + '/memory-system.sh';

// Ensure log directory exists
fs.mkdirSync(LOG_DIR, { recursive: true });

function log(msg) {
  const line = `[${new Date().toISOString()}] ${msg}`;
  console.log(line);
  const logFile = path.join(LOG_DIR, `stripe-${new Date().toISOString().slice(0, 10)}.log`);
  fs.appendFileSync(logFile, line + '\n');
}

function verifySignature(payload, signature) {
  if (!SECRET || !signature) return !SECRET; // skip if no secret configured
  const expected = crypto
    .createHmac('sha256', SECRET)
    .update(payload)
    .digest('hex');
  return crypto.timingSafeEqual(
    Buffer.from(expected, 'hex'),
    Buffer.from(signature, 'hex')
  );
}

function logToMemory(action, entity, details) {
  if (!fs.existsSync(MEMORY_SH)) return;
  const { execSync } = require('child_process');
  try {
    execSync(`bash "${MEMORY_SH}" log "${action}" "${entity}" "${details}"`, {
      stdio: 'pipe',
      timeout: 5000,
    });
  } catch (e) {
    log(`Memory log failed: ${e.message}`);
  }
}

function saveEvent(event) {
  const file = path.join(LOG_DIR, `${event.type}-${Date.now()}.json`);
  fs.writeFileSync(file, JSON.stringify(event, null, 2));
}

// Event handlers
const handlers = {
  'checkout.session.completed': (data) => {
    const tier = data.metadata?.tier || 'unknown';
    const customer = data.customer || 'unknown';
    log(`New subscription: customer=${customer} tier=${tier}`);
    logToMemory('subscription-created', customer, `Tier: ${tier}`);
  },

  'customer.subscription.updated': (data) => {
    log(`Subscription updated: ${data.id} status=${data.status}`);
    logToMemory('subscription-updated', data.id, `Status: ${data.status}`);
  },

  'customer.subscription.deleted': (data) => {
    log(`Subscription canceled: ${data.id}`);
    logToMemory('subscription-canceled', data.id, 'Subscription deleted');
  },

  'invoice.payment_succeeded': (data) => {
    const amount = ((data.amount_paid || 0) / 100).toFixed(2);
    log(`Payment received: $${amount} from ${data.customer}`);
    logToMemory('payment-received', data.customer, `Amount: $${amount}`);
  },

  'invoice.payment_failed': (data) => {
    log(`Payment FAILED: ${data.customer} invoice=${data.id}`);
    logToMemory('payment-failed', data.customer, `Invoice: ${data.id}`);
  },
};

const server = http.createServer((req, res) => {
  // Health check
  if (req.method === 'GET' && req.url === '/health') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({
      status: 'ok',
      service: 'stripe-webhook-listener',
      uptime: process.uptime(),
      hostname: require('os').hostname(),
      eventsDir: LOG_DIR,
    }));
    return;
  }

  if (req.method !== 'POST') {
    res.writeHead(200);
    res.end('Stripe Webhook Listener — BlackRoad OS Pi');
    return;
  }

  let body = '';
  req.on('data', chunk => body += chunk);
  req.on('end', () => {
    try {
      // Verify signature
      const sig = req.headers['x-pi-signature'] || req.headers['x-roadgateway-signature'];
      if (SECRET && !verifySignature(body, sig)) {
        log('Rejected: invalid signature');
        res.writeHead(401);
        res.end('Unauthorized');
        return;
      }

      const event = JSON.parse(body);
      const eventType = req.headers['x-stripe-event'] || req.headers['x-roadgateway-event'] || event.type || 'unknown';
      const data = event.data?.object || event;

      log(`Received: ${eventType}`);
      saveEvent({ type: eventType, data, receivedAt: new Date().toISOString() });

      // Dispatch to handler
      const handler = handlers[eventType];
      if (handler) {
        handler(data);
      } else {
        log(`No handler for: ${eventType}`);
      }

      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ received: true, type: eventType, agent: require('os').hostname() }));
    } catch (e) {
      log(`Parse error: ${e.message}`);
      res.writeHead(400);
      res.end('Bad Request');
    }
  });
});

server.listen(PORT, '0.0.0.0', () => {
  log(`Stripe Webhook Listener running on port ${PORT}`);
  log(`Pi: ${require('os').hostname()}`);
  log(`Events dir: ${LOG_DIR}`);
  log(`Signature verification: ${SECRET ? 'enabled' : 'disabled'}`);
});
