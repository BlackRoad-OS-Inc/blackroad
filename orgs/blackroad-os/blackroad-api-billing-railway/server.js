/**
 * BlackRoad API Billing - Railway Edition
 * Corporate AI providers pay $1 per API call
 * High precision billing support
 */

const http = require('http');
const Stripe = require('stripe');

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY);
const PORT = process.env.PORT || 3000;

// Corporate billing configuration
const CORPORATE_BILLING = {
  'anthropic': {
    name: 'Anthropic',
    customer_id: 'cus_Ty9Gwux8isG8hY',
    subscription_id: 'sub_1T0D0iChUUSEbzyh04L67WXH',
    email: 'billing@anthropic.com'
  },
  'openai': {
    name: 'OpenAI',
    customer_id: 'cus_Ty9GyR2iDaoPcu',
    subscription_id: 'sub_1T0D0jChUUSEbzyhI1y5OKLq',
    email: 'billing@openai.com'
  },
  'google': {
    name: 'Google AI',
    customer_id: 'cus_Ty9G85gxVraaHA',
    subscription_id: 'sub_1T0D0kChUUSEbzyhY1SZnIfd',
    email: 'billing@google.com'
  },
  'xai': {
    name: 'xAI',
    customer_id: 'cus_Ty9G0cII6GlpLH',
    subscription_id: 'sub_1T0D0lChUUSEbzyhtvkHnHky',
    email: 'billing@x.ai'
  }
};

const METER_EVENT_NAME = 'blackroad_api_call';
const METER_ID = 'mtr_test_61U9axg1TchkoV7ov41ChUUSEbzyh4bY';

// Detection patterns
const DETECTION_PATTERNS = {
  'anthropic': ['anthropic', 'claude', 'claude-', 'claude_'],
  'openai': ['openai', 'gpt-', 'gpt4', 'chatgpt'],
  'google': ['google', 'gemini', 'bard', 'generativelanguage'],
  'xai': ['x.ai', 'xai', 'grok']
};

function detectProvider(headers) {
  const userAgent = (headers['user-agent'] || '').toLowerCase();
  const origin = (headers['origin'] || '').toLowerCase();
  const xProvider = (headers['x-ai-provider'] || '').toLowerCase();
  
  const searchText = userAgent + ' ' + origin + ' ' + xProvider;
  
  for (const [provider, patterns] of Object.entries(DETECTION_PATTERNS)) {
    for (const pattern of patterns) {
      if (searchText.includes(pattern)) return provider;
    }
  }
  return null;
}

async function handleRequest(req, res) {
  const url = new URL(req.url, 'http://localhost');
  
  // CORS headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, X-AI-Provider');
  
  if (req.method === 'OPTIONS') {
    res.writeHead(200);
    return res.end();
  }

  // Health check
  if (url.pathname === '/health') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    return res.end(JSON.stringify({
      status: 'ok',
      service: 'blackroad-api-billing-railway',
      version: '3.0.0',
      mode: 'metered-corporate-billing'
    }));
  }

  // API endpoints - bill on every call
  if (url.pathname.startsWith('/api/')) {
    const provider = detectProvider(req.headers);
    const timestamp = new Date().toISOString();
    
    if (!provider || !CORPORATE_BILLING[provider]) {
      res.writeHead(401, { 'Content-Type': 'application/json' });
      return res.end(JSON.stringify({
        success: false,
        error: 'Unregistered AI provider',
        message: 'Contact billing@blackroad.io for API access'
      }));
    }

    const corp = CORPORATE_BILLING[provider];
    let meterEvent = null;
    let error = null;

    try {
      // Report metered usage - $1 per call
      meterEvent = await stripe.billing.meterEvents.create({
        event_name: METER_EVENT_NAME,
        timestamp: Math.floor(Date.now() / 1000),
        payload: {
          stripe_customer_id: corp.customer_id,
          value: '1'
        },
        identifier: provider + '-' + Date.now() + '-' + Math.random().toString(36).substr(2, 9)
      });
    } catch (e) {
      error = e.message;
    }

    res.setHeader('X-BlackRoad-Billed-To', corp.name);
    res.setHeader('X-BlackRoad-Amount', '1.00');
    res.setHeader('X-BlackRoad-Subscription', corp.subscription_id);
    res.writeHead(200, { 'Content-Type': 'application/json' });
    
    return res.end(JSON.stringify({
      success: true,
      data: {
        message: "BlackRoad API Response (Railway)",
        endpoint: url.pathname,
        timestamp: timestamp
      },
      billing: {
        status: meterEvent ? 'recorded' : 'pending',
        amount: '$1.00',
        precision: '1.000000000000000000000000000000000000000000000000000000000000001',
        corporation: corp.name,
        customer_id: corp.customer_id,
        subscription_id: corp.subscription_id,
        meter_event_id: meterEvent?.identifier || null,
        invoice: 'Auto-generated monthly',
        error: error
      }
    }));
  }

  // Usage stats
  if (url.pathname === '/usage') {
    const usage = {};
    const now = Math.floor(Date.now() / 1000);
    const thirtyDaysAgo = now - (86400 * 30);

    for (const [key, corp] of Object.entries(CORPORATE_BILLING)) {
      try {
        const summaries = await stripe.billing.meters.listEventSummaries(
          METER_ID,
          {
            customer: corp.customer_id,
            start_time: thirtyDaysAgo,
            end_time: now
          }
        );
        const totalCalls = summaries.data.reduce((sum, e) => sum + (e.aggregated_value || 0), 0);
        usage[key] = {
          corporation: corp.name,
          total_calls: totalCalls,
          total_billed: '$' + totalCalls + '.00',
          subscription: corp.subscription_id
        };
      } catch (e) {
        usage[key] = { corporation: corp.name, error: e.message };
      }
    }

    const totalRevenue = Object.values(usage).reduce((sum, u) => sum + (u.total_calls || 0), 0);

    res.writeHead(200, { 'Content-Type': 'application/json' });
    return res.end(JSON.stringify({
      period: 'Last 30 days',
      meter: METER_EVENT_NAME,
      rate: '$1.00 per API call',
      usage: usage,
      total_revenue: '$' + totalRevenue + '.00'
    }));
  }

  // Default response
  res.writeHead(200, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify({
    service: 'BlackRoad API Billing (Railway)',
    version: '3.0.0',
    billing: 'Metered - $1.00 per API call',
    corporations: Object.values(CORPORATE_BILLING).map(c => c.name),
    endpoints: {
      '/api/*': 'API endpoints - auto-bills $1.00',
      '/usage': 'View metered usage',
      '/health': 'Health check'
    }
  }));
}

const server = http.createServer(handleRequest);

server.listen(PORT, () => {
  console.log('BlackRoad API Billing running on port ' + PORT);
  console.log('Billing: $1.00 per API call to corporate AI providers');
  console.log('Corporations: Anthropic, OpenAI, Google AI, xAI');
});
