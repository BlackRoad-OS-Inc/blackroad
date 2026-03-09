/**
 * 🎛️ BlackRoad Command Center
 * Unified API for all BlackRoad services
 */

export interface Env {
  GITHUB_TOKEN: string;
  STRIPE_SECRET_KEY: string;
  HF_TOKEN: string;
  CLOUDFLARE_API_TOKEN: string;
  CLOUDFLARE_ACCOUNT_ID: string;
  CONTINUITY_DB: D1Database;
}

// CORS headers
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-API-Key',
};

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders });
    }

    const url = new URL(request.url);
    const path = url.pathname;

    try {
      // Route handlers
      if (path === '/' || path === '/health') {
        return json({ status: 'ok', service: 'blackroad-command-center', version: '1.0.0' });
      }

      // GitHub routes
      if (path.startsWith('/github')) return handleGitHub(request, env, path);
      
      // Stripe routes
      if (path.startsWith('/stripe')) return handleStripe(request, env, path);
      
      // HuggingFace routes  
      if (path.startsWith('/hf')) return handleHuggingFace(request, env, path);
      
      // Cloudflare routes
      if (path.startsWith('/cf')) return handleCloudflare(request, env, path);
      
      // Agent routes
      if (path.startsWith('/agents')) return handleAgents(request, env, path);
      
      // Notify routes (multi-channel)
      if (path.startsWith('/notify')) return handleNotify(request, env, path);
      
      // Index/Stats
      if (path === '/stats') return handleStats(env);

      return json({ error: 'Not found', routes: ['/github', '/stripe', '/hf', '/cf', '/agents', '/notify', '/stats'] }, 404);
    } catch (e: any) {
      return json({ error: e.message }, 500);
    }
  },
};

function json(data: any, status = 200) {
  return new Response(JSON.stringify(data, null, 2), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

// ============ GITHUB ============
async function handleGitHub(request: Request, env: Env, path: string): Promise<Response> {
  const gh = (endpoint: string, options: RequestInit = {}) =>
    fetch(`https://api.github.com${endpoint}`, {
      ...options,
      headers: {
        Authorization: `token ${env.GITHUB_TOKEN}`,
        Accept: 'application/vnd.github.v3+json',
        'User-Agent': 'BlackRoad-Command-Center',
        ...options.headers,
      },
    }).then(r => r.json());

  // GET /github/orgs - list all orgs
  if (path === '/github/orgs' && request.method === 'GET') {
    const orgs = await gh('/user/orgs?per_page=100');
    return json(orgs.map((o: any) => ({ name: o.login, url: o.html_url })));
  }

  // GET /github/repos/:org - list repos in org
  if (path.match(/^\/github\/repos\/[\w-]+$/) && request.method === 'GET') {
    const org = path.split('/')[3];
    const repos = await gh(`/orgs/${org}/repos?per_page=100`);
    return json(repos.map((r: any) => ({ name: r.name, url: r.html_url, language: r.language })));
  }

  // POST /github/repo - create repo
  if (path === '/github/repo' && request.method === 'POST') {
    const body: any = await request.json();
    const { org = 'BlackRoad-OS', name, description = '', private: isPrivate = false } = body;
    const result = await gh(`/orgs/${org}/repos`, {
      method: 'POST',
      body: JSON.stringify({ name, description, private: isPrivate, auto_init: true }),
    });
    return json({ created: true, url: result.html_url, name: result.name });
  }

  // POST /github/file - create/update file
  if (path === '/github/file' && request.method === 'POST') {
    const body: any = await request.json();
    const { org = 'BlackRoad-OS', repo, path: filePath, content, message = 'Update via Command Center' } = body;
    const encoded = btoa(content);
    
    // Check if file exists
    let sha;
    try {
      const existing = await gh(`/repos/${org}/${repo}/contents/${filePath}`);
      sha = existing.sha;
    } catch {}
    
    const result = await gh(`/repos/${org}/${repo}/contents/${filePath}`, {
      method: 'PUT',
      body: JSON.stringify({ message, content: encoded, sha }),
    });
    return json({ success: true, url: result.content?.html_url });
  }

  return json({ error: 'Unknown GitHub route', available: ['/github/orgs', '/github/repos/:org', '/github/repo', '/github/file'] }, 404);
}

// ============ STRIPE ============
async function handleStripe(request: Request, env: Env, path: string): Promise<Response> {
  const stripe = async (endpoint: string, method = 'GET', body?: any) => {
    const options: RequestInit = {
      method,
      headers: {
        Authorization: `Bearer ${env.STRIPE_SECRET_KEY}`,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
    };
    if (body) options.body = new URLSearchParams(body).toString();
    return fetch(`https://api.stripe.com/v1${endpoint}`, options).then(r => r.json());
  };

  // GET /stripe/products
  if (path === '/stripe/products' && request.method === 'GET') {
    const products = await stripe('/products?limit=100');
    return json(products.data);
  }

  // POST /stripe/product - create product + price + payment link
  if (path === '/stripe/product' && request.method === 'POST') {
    const body: any = await request.json();
    const { name, description = '', price, currency = 'usd', recurring } = body;
    
    // Create product
    const product = await stripe('/products', 'POST', { name, description });
    
    // Create price
    const priceData: any = { 
      product: product.id, 
      unit_amount: Math.round(price * 100), 
      currency 
    };
    if (recurring) {
      priceData['recurring[interval]'] = recurring;
    }
    const priceObj = await stripe('/prices', 'POST', priceData);
    
    // Create payment link
    const link = await stripe('/payment_links', 'POST', {
      'line_items[0][price]': priceObj.id,
      'line_items[0][quantity]': 1,
    });
    
    return json({
      product: { id: product.id, name: product.name },
      price: { id: priceObj.id, amount: price, currency },
      payment_link: link.url,
    });
  }

  // GET /stripe/customers
  if (path === '/stripe/customers' && request.method === 'GET') {
    const customers = await stripe('/customers?limit=100');
    return json(customers.data.map((c: any) => ({ id: c.id, email: c.email, name: c.name })));
  }

  return json({ error: 'Unknown Stripe route', available: ['/stripe/products', '/stripe/product', '/stripe/customers'] }, 404);
}

// ============ HUGGINGFACE ============
async function handleHuggingFace(request: Request, env: Env, path: string): Promise<Response> {
  const hf = (endpoint: string) =>
    fetch(`https://huggingface.co/api${endpoint}`, {
      headers: { Authorization: `Bearer ${env.HF_TOKEN}` },
    }).then(r => r.json());

  // GET /hf/models - search models
  if (path === '/hf/models' && request.method === 'GET') {
    const url = new URL(request.url);
    const search = url.searchParams.get('q') || '';
    const models = await hf(`/models?search=${search}&limit=20`);
    return json(models.map((m: any) => ({ id: m.id, downloads: m.downloads, likes: m.likes })));
  }

  // GET /hf/spaces - search spaces
  if (path === '/hf/spaces' && request.method === 'GET') {
    const url = new URL(request.url);
    const search = url.searchParams.get('q') || '';
    const spaces = await hf(`/spaces?search=${search}&limit=20`);
    return json(spaces);
  }

  return json({ error: 'Unknown HF route', available: ['/hf/models?q=', '/hf/spaces?q='] }, 404);
}

// ============ CLOUDFLARE ============
async function handleCloudflare(request: Request, env: Env, path: string): Promise<Response> {
  const cf = (endpoint: string) =>
    fetch(`https://api.cloudflare.com/client/v4/accounts/${env.CLOUDFLARE_ACCOUNT_ID}${endpoint}`, {
      headers: { Authorization: `Bearer ${env.CLOUDFLARE_API_TOKEN}` },
    }).then(r => r.json());

  // GET /cf/workers
  if (path === '/cf/workers' && request.method === 'GET') {
    const result = await cf('/workers/scripts');
    return json(result.result?.map((w: any) => ({ name: w.id, modified: w.modified_on })) || []);
  }

  // GET /cf/kv
  if (path === '/cf/kv' && request.method === 'GET') {
    const result = await cf('/storage/kv/namespaces');
    return json(result.result?.map((ns: any) => ({ id: ns.id, title: ns.title })) || []);
  }

  // GET /cf/d1
  if (path === '/cf/d1' && request.method === 'GET') {
    const result = await cf('/d1/database');
    return json(result.result?.map((db: any) => ({ id: db.uuid, name: db.name })) || []);
  }

  return json({ error: 'Unknown CF route', available: ['/cf/workers', '/cf/kv', '/cf/d1'] }, 404);
}

// ============ AGENTS ============
async function handleAgents(request: Request, env: Env, path: string): Promise<Response> {
  // GET /agents - list all agents
  if (path === '/agents' && request.method === 'GET') {
    const result = await env.CONTINUITY_DB.prepare('SELECT * FROM agents LIMIT 100').all();
    return json(result.results || []);
  }

  // POST /agents - create agent
  if (path === '/agents' && request.method === 'POST') {
    const body: any = await request.json();
    const { name, type = 'general', capabilities = [], birthday } = body;
    const id = crypto.randomUUID();
    
    await env.CONTINUITY_DB.prepare(
      'INSERT INTO agents (id, name, type, capabilities, birthday, created_at) VALUES (?, ?, ?, ?, ?, ?)'
    ).bind(id, name, type, JSON.stringify(capabilities), birthday || new Date().toISOString(), new Date().toISOString()).run();
    
    return json({ created: true, id, name });
  }

  // GET /agents/:id
  if (path.match(/^\/agents\/[\w-]+$/) && request.method === 'GET') {
    const id = path.split('/')[2];
    const result = await env.CONTINUITY_DB.prepare('SELECT * FROM agents WHERE id = ?').bind(id).first();
    return result ? json(result) : json({ error: 'Agent not found' }, 404);
  }

  return json({ error: 'Unknown agents route', available: ['/agents', '/agents/:id'] }, 404);
}

// ============ NOTIFY ============
async function handleNotify(request: Request, env: Env, path: string): Promise<Response> {
  if (request.method !== 'POST') {
    return json({ error: 'POST only' }, 405);
  }

  const body: any = await request.json();
  const { message, channels = ['log'] } = body;
  const results: any = {};

  for (const channel of channels) {
    if (channel === 'log') {
      console.log(`[NOTIFY] ${message}`);
      results.log = true;
    }
    // Add more channels: slack, email, notion, etc.
  }

  return json({ sent: true, channels: results });
}

// ============ STATS ============
async function handleStats(env: Env): Promise<Response> {
  // Get counts from various sources
  const stats = {
    timestamp: new Date().toISOString(),
    github: { orgs: 15, repos: '315+' },
    cloudflare: { workers: 82, d1: 11, kv: 20 },
    stripe: { account: 'acct_1SUDM8ChUUSEbzyh' },
    huggingface: { user: 'blackroadio' },
  };

  return json(stats);
}
