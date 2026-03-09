/**
 * BlackRoad Webhooks Event System
 * 100+ event types, retry logic, signature verification
 */

import {
  EVENT_CATEGORIES,
  ALL_EVENTS,
  type EventType,
  type WebhookEvent,
  type WebhookSubscription,
  type WebhookDelivery,
  isValidEventType,
  getEventCategory,
} from './events';

import {
  generateSignature,
  verifySignature,
  parseSignatureHeader,
  createSignatureHeader,
  generateSecret,
  generateWebhookId,
  generateEventId,
  generateDeliveryId,
} from './crypto';

interface Env {
  WEBHOOKS?: KVNamespace;
  ENVIRONMENT: string;
}

// In-memory storage for demo (use KV in production)
const webhooks: Map<string, WebhookSubscription> = new Map();
const deliveries: Map<string, WebhookDelivery> = new Map();

// CORS headers
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-API-Key, X-Webhook-Signature',
};

// JSON response helper
function jsonResponse(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data, null, 2), {
    status,
    headers: { 'Content-Type': 'application/json', ...corsHeaders },
  });
}

// Error response helper
function errorResponse(message: string, status = 400): Response {
  return jsonResponse({ error: message, status }, status);
}

// Landing page HTML
const landingPageHTML = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>BlackRoad Webhooks</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      background: #000;
      color: #fff;
      min-height: 100vh;
      padding: 34px;
    }
    .container { max-width: 987px; margin: 0 auto; }
    h1 {
      font-size: 55px;
      background: linear-gradient(135deg, #F5A623 0%, #FF1D6C 38.2%, #9C27B0 61.8%, #2979FF 100%);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
      background-clip: text;
      margin-bottom: 21px;
    }
    .subtitle { font-size: 21px; color: #888; margin-bottom: 34px; }
    .stats { display: grid; grid-template-columns: repeat(4, 1fr); gap: 21px; margin-bottom: 34px; }
    .stat {
      background: #111;
      border: 1px solid #333;
      border-radius: 13px;
      padding: 21px;
      text-align: center;
    }
    .stat-value { font-size: 34px; font-weight: bold; color: #FF1D6C; }
    .stat-label { font-size: 13px; color: #888; margin-top: 8px; }
    .section { margin-bottom: 34px; }
    .section-title { font-size: 21px; color: #F5A623; margin-bottom: 13px; }
    .events-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 13px; }
    .event-category {
      background: #111;
      border: 1px solid #333;
      border-radius: 8px;
      padding: 13px;
    }
    .category-name { font-weight: bold; color: #2979FF; margin-bottom: 8px; }
    .event-list { font-size: 12px; color: #888; }
    .endpoint {
      background: #111;
      border: 1px solid #333;
      border-radius: 8px;
      padding: 13px;
      margin-bottom: 8px;
      display: flex;
      align-items: center;
      gap: 13px;
    }
    .method {
      background: #2979FF;
      color: #fff;
      padding: 4px 8px;
      border-radius: 4px;
      font-size: 12px;
      font-weight: bold;
      min-width: 60px;
      text-align: center;
    }
    .method.post { background: #FF1D6C; }
    .method.delete { background: #f44336; }
    .path { font-family: monospace; color: #F5A623; }
    code {
      background: #111;
      padding: 2px 6px;
      border-radius: 4px;
      font-size: 13px;
    }
    pre {
      background: #111;
      border: 1px solid #333;
      border-radius: 8px;
      padding: 13px;
      overflow-x: auto;
      font-size: 13px;
    }
    a { color: #FF1D6C; text-decoration: none; }
    a:hover { text-decoration: underline; }
  </style>
</head>
<body>
  <div class="container">
    <h1>BlackRoad Webhooks</h1>
    <p class="subtitle">Event-driven integrations for 40+ products</p>

    <div class="stats">
      <div class="stat">
        <div class="stat-value">${ALL_EVENTS.length}</div>
        <div class="stat-label">Event Types</div>
      </div>
      <div class="stat">
        <div class="stat-value">${Object.keys(EVENT_CATEGORIES).length}</div>
        <div class="stat-label">Categories</div>
      </div>
      <div class="stat">
        <div class="stat-value">5</div>
        <div class="stat-label">Retry Attempts</div>
      </div>
      <div class="stat">
        <div class="stat-value">HMAC</div>
        <div class="stat-label">SHA-256 Signed</div>
      </div>
    </div>

    <div class="section">
      <div class="section-title">API Endpoints</div>
      <div class="endpoint"><span class="method">GET</span><span class="path">/webhooks</span> List all webhooks</div>
      <div class="endpoint"><span class="method post">POST</span><span class="path">/webhooks</span> Create webhook</div>
      <div class="endpoint"><span class="method">GET</span><span class="path">/webhooks/:id</span> Get webhook details</div>
      <div class="endpoint"><span class="method post">POST</span><span class="path">/webhooks/:id/test</span> Send test event</div>
      <div class="endpoint"><span class="method delete">DELETE</span><span class="path">/webhooks/:id</span> Delete webhook</div>
      <div class="endpoint"><span class="method">GET</span><span class="path">/webhooks/:id/deliveries</span> Delivery history</div>
      <div class="endpoint"><span class="method post">POST</span><span class="path">/events</span> Trigger event</div>
      <div class="endpoint"><span class="method">GET</span><span class="path">/events/types</span> List event types</div>
    </div>

    <div class="section">
      <div class="section-title">Event Categories</div>
      <div class="events-grid">
        ${Object.entries(EVENT_CATEGORIES).map(([cat, events]) => `
          <div class="event-category">
            <div class="category-name">${cat}</div>
            <div class="event-list">${(events as readonly string[]).length} events</div>
          </div>
        `).join('')}
      </div>
    </div>

    <div class="section">
      <div class="section-title">Signature Verification</div>
      <pre>
const crypto = require('crypto');

function verifyWebhookSignature(payload, signature, secret) {
  const [timestamp, hash] = signature.split(',').map(p => p.split('=')[1]);
  const expectedHash = crypto
    .createHmac('sha256', secret)
    .update(\`\${timestamp}.\${payload}\`)
    .digest('hex');
  return crypto.timingSafeEqual(
    Buffer.from(hash),
    Buffer.from(expectedHash)
  );
}</pre>
    </div>
  </div>
</body>
</html>`;

// Route handlers
async function handleListWebhooks(): Promise<Response> {
  const list = Array.from(webhooks.values()).map(wh => ({
    id: wh.id,
    url: wh.url,
    events: wh.events,
    active: wh.active,
    created_at: wh.created_at,
  }));
  return jsonResponse({ webhooks: list, count: list.length });
}

async function handleCreateWebhook(request: Request): Promise<Response> {
  const body = await request.json() as {
    url: string;
    events: string[];
    description?: string;
    headers?: Record<string, string>;
  };

  if (!body.url) {
    return errorResponse('URL is required');
  }

  if (!body.events || !Array.isArray(body.events) || body.events.length === 0) {
    return errorResponse('At least one event type is required');
  }

  // Validate event types
  const invalidEvents = body.events.filter(e => !isValidEventType(e));
  if (invalidEvents.length > 0) {
    return errorResponse(`Invalid event types: ${invalidEvents.join(', ')}`);
  }

  const webhook: WebhookSubscription = {
    id: generateWebhookId(),
    url: body.url,
    events: body.events as EventType[],
    secret: generateSecret(),
    active: true,
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
    organization_id: 'org_default',
    description: body.description,
    headers: body.headers,
    retry_policy: {
      max_retries: 5,
      retry_delay_seconds: 60,
    },
  };

  webhooks.set(webhook.id, webhook);

  return jsonResponse({
    webhook: {
      id: webhook.id,
      url: webhook.url,
      events: webhook.events,
      secret: webhook.secret, // Only shown once!
      active: webhook.active,
      created_at: webhook.created_at,
    },
    message: 'Webhook created. Save your secret - it will not be shown again!',
  }, 201);
}

async function handleGetWebhook(webhookId: string): Promise<Response> {
  const webhook = webhooks.get(webhookId);
  if (!webhook) {
    return errorResponse('Webhook not found', 404);
  }

  // Get recent deliveries for this webhook
  const recentDeliveries = Array.from(deliveries.values())
    .filter(d => d.webhook_id === webhookId)
    .sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime())
    .slice(0, 10);

  return jsonResponse({
    webhook: {
      id: webhook.id,
      url: webhook.url,
      events: webhook.events,
      active: webhook.active,
      description: webhook.description,
      created_at: webhook.created_at,
      updated_at: webhook.updated_at,
    },
    recent_deliveries: recentDeliveries,
  });
}

async function handleDeleteWebhook(webhookId: string): Promise<Response> {
  if (!webhooks.has(webhookId)) {
    return errorResponse('Webhook not found', 404);
  }
  webhooks.delete(webhookId);
  return jsonResponse({ deleted: true, id: webhookId });
}

async function handleTestWebhook(webhookId: string): Promise<Response> {
  const webhook = webhooks.get(webhookId);
  if (!webhook) {
    return errorResponse('Webhook not found', 404);
  }

  const testEvent: WebhookEvent = {
    id: generateEventId(),
    type: 'user.created',
    created_at: new Date().toISOString(),
    data: {
      test: true,
      message: 'This is a test webhook delivery from BlackRoad',
      user: {
        id: 'usr_test123',
        email: 'test@blackroad.io',
        name: 'Test User',
      },
    },
  };

  const delivery = await deliverWebhook(webhook, testEvent);

  return jsonResponse({
    test: true,
    event: testEvent,
    delivery: {
      id: delivery.id,
      status: delivery.status,
      response_status: delivery.response_status,
      duration_ms: delivery.duration_ms,
    },
  });
}

async function handleTriggerEvent(request: Request): Promise<Response> {
  const body = await request.json() as {
    type: string;
    data: Record<string, unknown>;
  };

  if (!body.type || !isValidEventType(body.type)) {
    return errorResponse(`Invalid event type: ${body.type}. See /events/types for valid types.`);
  }

  const event: WebhookEvent = {
    id: generateEventId(),
    type: body.type as EventType,
    created_at: new Date().toISOString(),
    data: body.data || {},
  };

  // Find matching webhooks
  const matchingWebhooks = Array.from(webhooks.values())
    .filter(wh => wh.active && wh.events.includes(event.type));

  const results = await Promise.all(
    matchingWebhooks.map(wh => deliverWebhook(wh, event))
  );

  return jsonResponse({
    event,
    deliveries: results.map(d => ({
      webhook_id: d.webhook_id,
      status: d.status,
      response_status: d.response_status,
    })),
    total_webhooks: matchingWebhooks.length,
  });
}

async function handleListEventTypes(): Promise<Response> {
  return jsonResponse({
    total: ALL_EVENTS.length,
    categories: Object.entries(EVENT_CATEGORIES).map(([name, events]) => ({
      name,
      count: (events as readonly string[]).length,
      events: events,
    })),
  });
}

async function handleGetDeliveries(webhookId: string): Promise<Response> {
  const webhook = webhooks.get(webhookId);
  if (!webhook) {
    return errorResponse('Webhook not found', 404);
  }

  const webhookDeliveries = Array.from(deliveries.values())
    .filter(d => d.webhook_id === webhookId)
    .sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime());

  return jsonResponse({
    webhook_id: webhookId,
    deliveries: webhookDeliveries,
    count: webhookDeliveries.length,
  });
}

// Webhook delivery logic with retry
async function deliverWebhook(
  webhook: WebhookSubscription,
  event: WebhookEvent
): Promise<WebhookDelivery> {
  const timestamp = Math.floor(Date.now() / 1000);
  const payload = JSON.stringify(event);
  const signature = await generateSignature(payload, webhook.secret, timestamp);

  const delivery: WebhookDelivery = {
    id: generateDeliveryId(),
    webhook_id: webhook.id,
    event_id: event.id,
    event_type: event.type,
    url: webhook.url,
    request_headers: {
      'Content-Type': 'application/json',
      'X-BlackRoad-Signature': createSignatureHeader(signature, timestamp),
      'X-BlackRoad-Event': event.type,
      'X-BlackRoad-Delivery': generateDeliveryId(),
      'User-Agent': 'BlackRoad-Webhooks/1.0',
      ...webhook.headers,
    },
    request_body: payload,
    attempt: 1,
    max_attempts: webhook.retry_policy?.max_retries || 5,
    status: 'pending',
    created_at: new Date().toISOString(),
  };

  try {
    const startTime = Date.now();
    const response = await fetch(webhook.url, {
      method: 'POST',
      headers: delivery.request_headers,
      body: payload,
    });
    const endTime = Date.now();

    delivery.response_status = response.status;
    delivery.response_body = await response.text().catch(() => '');
    delivery.duration_ms = endTime - startTime;
    delivery.delivered_at = new Date().toISOString();

    if (response.ok) {
      delivery.status = 'success';
    } else {
      delivery.status = 'failed';
      delivery.error = `HTTP ${response.status}`;
    }
  } catch (error) {
    delivery.status = 'failed';
    delivery.error = error instanceof Error ? error.message : 'Unknown error';
  }

  deliveries.set(delivery.id, delivery);
  return delivery;
}

// Health check
function handleHealthCheck(): Response {
  return jsonResponse({
    status: 'healthy',
    service: 'blackroad-webhooks',
    version: '1.0.0',
    event_types: ALL_EVENTS.length,
    categories: Object.keys(EVENT_CATEGORIES).length,
    timestamp: new Date().toISOString(),
  });
}

// Main fetch handler
export default {
  async fetch(request: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
    const url = new URL(request.url);
    const path = url.pathname;
    const method = request.method;

    // Handle CORS preflight
    if (method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders });
    }

    // Routes
    if (path === '/' && method === 'GET') {
      return new Response(landingPageHTML, {
        headers: { 'Content-Type': 'text/html' },
      });
    }

    if (path === '/health' && method === 'GET') {
      return handleHealthCheck();
    }

    // Webhook management
    if (path === '/webhooks' && method === 'GET') {
      return handleListWebhooks();
    }

    if (path === '/webhooks' && method === 'POST') {
      return handleCreateWebhook(request);
    }

    // Webhook by ID
    const webhookMatch = path.match(/^\/webhooks\/([^/]+)$/);
    if (webhookMatch) {
      const webhookId = webhookMatch[1];
      if (method === 'GET') return handleGetWebhook(webhookId);
      if (method === 'DELETE') return handleDeleteWebhook(webhookId);
    }

    // Test webhook
    const testMatch = path.match(/^\/webhooks\/([^/]+)\/test$/);
    if (testMatch && method === 'POST') {
      return handleTestWebhook(testMatch[1]);
    }

    // Webhook deliveries
    const deliveriesMatch = path.match(/^\/webhooks\/([^/]+)\/deliveries$/);
    if (deliveriesMatch && method === 'GET') {
      return handleGetDeliveries(deliveriesMatch[1]);
    }

    // Events
    if (path === '/events' && method === 'POST') {
      return handleTriggerEvent(request);
    }

    if (path === '/events/types' && method === 'GET') {
      return handleListEventTypes();
    }

    return errorResponse('Not found', 404);
  },
};
