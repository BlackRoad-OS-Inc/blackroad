import { Router } from './router';
import { AgentTools } from './tools/agent';
import { MemoryTools } from './tools/memory';
import { ReasoningTools } from './tools/reasoning';
import { CoordinationTools } from './tools/coordination';

export interface Env {
  DB: D1Database;
  TOOLS_KV: KVNamespace;
  API_KEYS_KV: KVNamespace;
  STRIPE_WEBHOOK_SECRET: string;
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);
    const path = url.pathname;

    // CORS headers
    const corsHeaders = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Agent-ID, X-API-Key',
    };

    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders });
    }

    // Stripe webhook – verified by signature, no API key required
    if (path === '/stripe/webhook' && request.method === 'POST') {
      return handleStripeWebhook(request, env, corsHeaders);
    }

    // Contributor API key gate – all sub-tool routes require authentication
    if (path.startsWith('/tools/') && path !== '/tools/') {
      const apiKey = request.headers.get('X-API-Key');
      if (!apiKey) {
        return Response.json(
          { error: 'API key required. Subscribe at https://blackroad.io/contribute to receive access.' },
          { status: 401, headers: corsHeaders }
        );
      }
      const entry = await env.API_KEYS_KV.get(`key:${apiKey}`);
      if (!entry) {
        return Response.json(
          { error: 'Invalid or expired API key.' },
          { status: 403, headers: corsHeaders }
        );
      }
    }

    try {
      // Route to appropriate tool handler
      if (path.startsWith('/tools/agent')) {
        return await AgentTools.handle(request, env, corsHeaders);
      }
      if (path.startsWith('/tools/memory')) {
        return await MemoryTools.handle(request, env, corsHeaders);
      }
      if (path.startsWith('/tools/reasoning')) {
        return await ReasoningTools.handle(request, env, corsHeaders);
      }
      if (path.startsWith('/tools/coordination')) {
        return await CoordinationTools.handle(request, env, corsHeaders);
      }

      // Tool registry (public)
      if (path === '/tools' || path === '/tools/') {
<<<<<<< Updated upstream
        return Response.json({
          tools: [
            {
              name: 'agent',
              description: 'Agent registry and management',
              endpoints: ['/tools/agent/list', '/tools/agent/get/:id', '/tools/agent/capabilities']
            },
            {
              name: 'memory',
              description: 'Memory persistence and retrieval',
              endpoints: ['/tools/memory/store', '/tools/memory/retrieve', '/tools/memory/search']
            },
            {
              name: 'reasoning',
              description: 'Trinary logic and contradiction handling',
              endpoints: ['/tools/reasoning/evaluate', '/tools/reasoning/quarantine', '/tools/reasoning/resolve']
            },
            {
              name: 'coordination',
              description: 'Agent coordination and messaging',
              endpoints: ['/tools/coordination/publish', '/tools/coordination/subscribe', '/tools/coordination/delegate']
            }
          ],
          version: '1.0.0',
          timestamp: new Date().toISOString(),
          auth: 'X-API-Key header required for all /tools/* endpoints. See /stripe/webhook for subscription-based key issuance.'
        }, { headers: corsHeaders });
=======
        return Response.json(
          {
            tools: [
              {
                name: 'agent',
                description: 'Agent registry and management',
                endpoints: ['/tools/agent/list', '/tools/agent/get/:id', '/tools/agent/capabilities'],
              },
              {
                name: 'memory',
                description: 'Memory persistence and retrieval',
                endpoints: ['/tools/memory/store', '/tools/memory/retrieve', '/tools/memory/search'],
              },
              {
                name: 'reasoning',
                description: 'Trinary logic and contradiction handling',
                endpoints: ['/tools/reasoning/evaluate', '/tools/reasoning/quarantine', '/tools/reasoning/resolve'],
              },
              {
                name: 'coordination',
                description: 'Agent coordination and messaging',
                endpoints: [
                  '/tools/coordination/publish',
                  '/tools/coordination/subscribe',
                  '/tools/coordination/delegate',
                ],
              },
            ],
            version: '1.0.0',
            timestamp: new Date().toISOString(),
          },
          { headers: corsHeaders }
        );
>>>>>>> Stashed changes
      }

      return Response.json({ error: 'Tool not found', path }, { status: 404, headers: corsHeaders });
    } catch (err) {
      return Response.json({ error: String(err) }, { status: 500, headers: corsHeaders });
    }
  },
};

const ONE_YEAR_IN_SECONDS = 365 * 24 * 60 * 60;

async function handleStripeWebhook(
  request: Request,
  env: Env,
  corsHeaders: Record<string, string>
): Promise<Response> {
  const signature = request.headers.get('stripe-signature');
  if (!signature || !env.STRIPE_WEBHOOK_SECRET) {
    return Response.json({ error: 'Missing Stripe signature or webhook secret' }, { status: 400, headers: corsHeaders });
  }

  const body = await request.text();
  const verified = await verifyStripeSignature(body, signature, env.STRIPE_WEBHOOK_SECRET);
  if (!verified) {
    return Response.json({ error: 'Invalid Stripe signature' }, { status: 401, headers: corsHeaders });
  }

  const event = JSON.parse(body) as { type: string; data?: { object?: Record<string, unknown> } };

  if (event.type === 'checkout.session.completed' || event.type === 'customer.subscription.created') {
    const obj = event.data?.object ?? {};
    const customerId = obj['customer'] as string | undefined;
    const email = obj['customer_email'] as string | undefined;
    if (customerId) {
      const apiKey = generateApiKey();
      await env.API_KEYS_KV.put(
        `key:${apiKey}`,
        JSON.stringify({ customerId, email, createdAt: Date.now() }),
        { expirationTtl: ONE_YEAR_IN_SECONDS }
      );
      await env.API_KEYS_KV.put(`customer:${customerId}`, apiKey, { expirationTtl: ONE_YEAR_IN_SECONDS });
    }
  }

  if (event.type === 'customer.subscription.deleted' || event.type === 'invoice.payment_failed') {
    const obj = event.data?.object ?? {};
    const customerId = obj['customer'] as string | undefined;
    if (customerId) {
      const apiKey = await env.API_KEYS_KV.get(`customer:${customerId}`);
      if (apiKey) {
        await env.API_KEYS_KV.delete(`key:${apiKey}`);
        await env.API_KEYS_KV.delete(`customer:${customerId}`);
      }
    }
  }

  return Response.json({ received: true }, { headers: corsHeaders });
}

async function verifyStripeSignature(payload: string, sigHeader: string, secret: string): Promise<boolean> {
  const parts = sigHeader.split(',').reduce<Record<string, string>>((acc, part) => {
    const [k, v] = part.trim().split('=');
    if (k && v !== undefined) acc[k] = v;
    return acc;
  }, {});

  const timestamp = parts['t'];
  const expectedSig = parts['v1'];
  if (!timestamp || !expectedSig) return false;

  const signed = `${timestamp}.${payload}`;
  const encoder = new TextEncoder();
  const key = await crypto.subtle.importKey(
    'raw',
    encoder.encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign']
  );
  const mac = await crypto.subtle.sign('HMAC', key, encoder.encode(signed));
  const computed = Array.from(new Uint8Array(mac))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
  return computed === expectedSig;
}

function generateApiKey(): string {
  const bytes = new Uint8Array(32);
  crypto.getRandomValues(bytes);
  return 'br_' + Array.from(bytes).map((b) => b.toString(16).padStart(2, '0')).join('');
}
