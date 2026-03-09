// BlackRoad.io - Single Page App
export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const path = url.pathname;

    // API routes
    if (path.startsWith('/api/')) {
      return handleAPI(path, request, env);
    }

    // Serve the app for all other routes
    return new Response(APP_HTML, {
      headers: { 'Content-Type': 'text/html; charset=utf-8' }
    });
  }
};

async function handleAPI(path, request, env) {
  const json = (data, status = 200, headers = {}) => 
    new Response(JSON.stringify(data), { 
      status, 
      headers: { 'Content-Type': 'application/json', ...headers } 
    });

  try {
    // Get current user
    if (path === '/api/me') {
      const user = await getUser(request, env);
      return json({ user });
    }

    // Signup
    if (path === '/api/signup' && request.method === 'POST') {
      const { name, email, password } = await request.json();
      if (!email || !password) return json({ error: 'Email and password required' }, 400);
      if (password.length < 8) return json({ error: 'Password must be at least 8 characters' }, 400);

      const existing = await env.DB.prepare('SELECT id FROM users WHERE email = ?').bind(email.toLowerCase()).first();
      if (existing) return json({ error: 'Email already registered' }, 400);

      const userId = crypto.randomUUID();
      const hash = await hashPassword(password);
      await env.DB.prepare('INSERT INTO users (id, email, password_hash, name, role, created_at, updated_at) VALUES (?, ?, ?, ?, ?, datetime("now"), datetime("now"))')
        .bind(userId, email.toLowerCase(), hash, name || null, 'user').run();

      const sessionId = crypto.randomUUID();
      const expires = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString();
      await env.DB.prepare('INSERT INTO sessions (id, user_id, expires_at, created_at) VALUES (?, ?, ?, datetime("now"))')
        .bind(sessionId, userId, expires).run();

      return json({ success: true, user: { id: userId, name, email } }, 200, {
        'Set-Cookie': `session=${sessionId}; Path=/; HttpOnly; Secure; SameSite=Lax; Max-Age=${30*24*60*60}`
      });
    }

    // Login
    if (path === '/api/login' && request.method === 'POST') {
      const { email, password } = await request.json();
      if (!email || !password) return json({ error: 'Email and password required' }, 400);

      const user = await env.DB.prepare('SELECT id, name, email, password_hash FROM users WHERE email = ?')
        .bind(email.toLowerCase()).first();
      if (!user || !(await verifyPassword(password, user.password_hash))) {
        return json({ error: 'Invalid credentials' }, 401);
      }

      const sessionId = crypto.randomUUID();
      const expires = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString();
      await env.DB.prepare('INSERT INTO sessions (id, user_id, expires_at, created_at) VALUES (?, ?, ?, datetime("now"))')
        .bind(sessionId, user.id, expires).run();

      return json({ success: true, user: { id: user.id, name: user.name, email: user.email } }, 200, {
        'Set-Cookie': `session=${sessionId}; Path=/; HttpOnly; Secure; SameSite=Lax; Max-Age=${30*24*60*60}`
      });
    }

    // Logout
    if (path === '/api/logout' && request.method === 'POST') {
      const sessionId = getSessionId(request);
      if (sessionId) {
        await env.DB.prepare('DELETE FROM sessions WHERE id = ?').bind(sessionId).run();
      }
      return json({ success: true }, 200, {
        'Set-Cookie': 'session=; Path=/; HttpOnly; Secure; SameSite=Lax; Max-Age=0'
      });
    }

    // Stats
    if (path === '/api/stats') {
      const stats = await env.DB.prepare('SELECT key, value FROM stats').all();
      const domains = await env.DB.prepare('SELECT name FROM domains ORDER BY created_at DESC LIMIT 10').all();
      return json({ 
        stats: Object.fromEntries(stats.results.map(r => [r.key, r.value])),
        domains: domains.results.map(d => d.name)
      });
    }

    return json({ error: 'Not found' }, 404);
  } catch (e) {
    console.error('API Error:', e);
    return json({ error: 'Server error' }, 500);
  }
}

function getSessionId(request) {
  const cookie = request.headers.get('cookie') || '';
  const match = cookie.match(/session=([^;]+)/);
  return match ? match[1] : null;
}

async function getUser(request, env) {
  const sessionId = getSessionId(request);
  if (!sessionId) return null;
  const result = await env.DB.prepare(`
    SELECT u.id, u.name, u.email, u.role FROM sessions s 
    JOIN users u ON s.user_id = u.id 
    WHERE s.id = ? AND s.expires_at > datetime('now')
  `).bind(sessionId).first();
  return result || null;
}

async function hashPassword(password) {
  const encoder = new TextEncoder();
  const salt = crypto.getRandomValues(new Uint8Array(16));
  const key = await crypto.subtle.importKey('raw', encoder.encode(password), 'PBKDF2', false, ['deriveBits']);
  const hash = await crypto.subtle.deriveBits({ name: 'PBKDF2', salt, iterations: 100000, hash: 'SHA-256' }, key, 256);
  const combined = new Uint8Array(16 + 32);
  combined.set(salt);
  combined.set(new Uint8Array(hash), 16);
  return btoa(String.fromCharCode(...combined));
}

async function verifyPassword(password, stored) {
  const encoder = new TextEncoder();
  const combined = Uint8Array.from(atob(stored), c => c.charCodeAt(0));
  const salt = combined.slice(0, 16);
  const original = combined.slice(16);
  const key = await crypto.subtle.importKey('raw', encoder.encode(password), 'PBKDF2', false, ['deriveBits']);
  const hash = await crypto.subtle.deriveBits({ name: 'PBKDF2', salt, iterations: 100000, hash: 'SHA-256' }, key, 256);
  const hashArr = new Uint8Array(hash);
  return hashArr.every((b, i) => b === original[i]);
}

const APP_HTML = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>BlackRoad</title>
  <link rel="icon" href="data:image/svg+xml,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><text y='.9em' font-size='90'>🛤️</text></svg>">
  <link href="https://fonts.googleapis.com/css2?family=Space+Grotesk:wght@600;700&family=Inter:wght@400;500;600&family=JetBrains+Mono:wght@400;500&display=swap" rel="stylesheet">
  <style>
    :root {
      --bg: #0a0a0a; --surface: #171717; --border: #262626; --border-hover: #404040;
      --text: #f5f5f5; --text-muted: #737373; --text-dim: #525252;
      --accent: #1e90ff; --gradient: linear-gradient(90deg, #ff8700, #ff0087, #1e90ff);
      --font-display: 'Space Grotesk', sans-serif;
      --font-body: 'Inter', sans-serif;
      --font-mono: 'JetBrains Mono', monospace;
    }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body { background: var(--bg); color: var(--text); font-family: var(--font-body); line-height: 1.6; min-height: 100vh; }
    a { color: var(--accent); text-decoration: none; }
    .container { max-width: 1200px; margin: 0 auto; padding: 0 24px; }
    
    /* Header */
    header { padding: 16px 0; border-bottom: 1px solid var(--border); background: rgba(10,10,10,0.9); backdrop-filter: blur(10px); position: sticky; top: 0; z-index: 100; }
    .header-inner { display: flex; justify-content: space-between; align-items: center; }
    .logo { font-family: var(--font-display); font-size: 22px; font-weight: 700; cursor: pointer; }
    .logo span { background: var(--gradient); -webkit-background-clip: text; -webkit-text-fill-color: transparent; }
    .nav { display: flex; gap: 24px; align-items: center; }
    .nav a, .nav button { font-size: 14px; color: var(--text-muted); background: none; border: none; cursor: pointer; }
    .nav a:hover, .nav button:hover { color: var(--text); }
    .user-name { color: var(--text); margin-right: 8px; }

    /* Buttons */
    .btn { display: inline-flex; align-items: center; gap: 8px; padding: 12px 24px; font-size: 14px; font-weight: 500; border-radius: 8px; border: none; cursor: pointer; transition: all 0.15s; }
    .btn-primary { background: var(--text); color: var(--bg); }
    .btn-primary:hover { opacity: 0.9; transform: translateY(-1px); }
    .btn-ghost { background: transparent; border: 1px solid var(--border); color: var(--text-muted); }
    .btn-ghost:hover { border-color: var(--border-hover); color: var(--text); }
    .btn-full { width: 100%; justify-content: center; }

    /* Hero */
    .hero { padding: 100px 0 60px; text-align: center; }
    .hero h1 { font-family: var(--font-display); font-size: 64px; font-weight: 700; letter-spacing: -2px; margin-bottom: 20px; }
    .hero h1 span { background: var(--gradient); -webkit-background-clip: text; -webkit-text-fill-color: transparent; }
    .hero p { font-size: 18px; color: var(--text-muted); max-width: 500px; margin: 0 auto 32px; }
    .hero-buttons { display: flex; gap: 12px; justify-content: center; }

    /* Stats */
    .stats { display: grid; grid-template-columns: repeat(4, 1fr); gap: 20px; padding: 48px 0; border-top: 1px solid var(--border); }
    .stat { text-align: center; }
    .stat-value { font-family: var(--font-display); font-size: 42px; font-weight: 700; color: var(--accent); }
    .stat-label { font-size: 13px; color: var(--text-dim); margin-top: 4px; }

    /* Cards */
    .cards { display: grid; grid-template-columns: repeat(auto-fit, minmax(260px, 1fr)); gap: 16px; margin: 48px 0; }
    .card { background: var(--surface); border: 1px solid var(--border); border-radius: 12px; padding: 24px; transition: all 0.2s; }
    .card:hover { border-color: var(--border-hover); transform: translateY(-2px); }
    .card-icon { font-size: 28px; margin-bottom: 16px; }
    .card-title { font-family: var(--font-display); font-size: 16px; font-weight: 600; margin-bottom: 6px; }
    .card-desc { font-size: 13px; color: var(--text-muted); }

    /* Auth */
    .auth-page { min-height: 100vh; display: flex; align-items: center; justify-content: center; padding: 24px; }
    .auth-box { width: 100%; max-width: 380px; }
    .auth-header { text-align: center; margin-bottom: 32px; }
    .auth-header h1 { font-family: var(--font-display); font-size: 28px; margin: 16px 0 8px; }
    .auth-header p { color: var(--text-muted); font-size: 14px; }
    .auth-form { background: var(--surface); border: 1px solid var(--border); border-radius: 12px; padding: 28px; }
    .form-group { margin-bottom: 18px; }
    .form-group label { display: block; font-size: 13px; color: var(--text-muted); margin-bottom: 6px; }
    .form-group input { width: 100%; padding: 11px 14px; background: var(--bg); border: 1px solid var(--border); border-radius: 8px; color: var(--text); font-size: 14px; }
    .form-group input:focus { outline: none; border-color: var(--accent); }
    .auth-footer { text-align: center; margin-top: 20px; font-size: 13px; color: var(--text-muted); }
    .error-msg { background: rgba(255,0,87,0.1); border: 1px solid rgba(255,0,87,0.3); color: #ff6b9d; padding: 10px 14px; border-radius: 8px; font-size: 13px; margin-bottom: 16px; }

    /* Dashboard */
    .dashboard { padding: 48px 0; }
    .page-title { font-family: var(--font-display); font-size: 28px; font-weight: 700; margin-bottom: 6px; }
    .page-subtitle { color: var(--text-muted); margin-bottom: 40px; }
    .section-title { font-family: var(--font-display); font-size: 18px; font-weight: 600; margin: 32px 0 16px; }
    .domains-list { display: grid; gap: 8px; }
    .domain-item { display: flex; justify-content: space-between; align-items: center; background: var(--surface); border: 1px solid var(--border); border-radius: 8px; padding: 12px 16px; }
    .domain-name { font-family: var(--font-mono); font-size: 13px; }
    .domain-badge { font-family: var(--font-mono); font-size: 10px; padding: 3px 8px; border-radius: 4px; background: rgba(30,144,255,0.15); color: var(--accent); }

    /* Footer */
    footer { padding: 40px 0; border-top: 1px solid var(--border); text-align: center; }
    .footer-links { display: flex; justify-content: center; gap: 24px; margin-bottom: 16px; }
    .footer-links a { font-size: 13px; color: var(--text-muted); }
    .footer-copy { font-size: 12px; color: var(--text-dim); }

    @media (max-width: 768px) {
      .hero h1 { font-size: 40px; }
      .stats { grid-template-columns: repeat(2, 1fr); }
      .nav { gap: 16px; }
    }

    [hidden] { display: none !important; }
  </style>
</head>
<body>
  <div id="app"></div>
  <script>
    const App = {
      user: null,
      stats: { agents: '1000', domains: '21', github_orgs: '16', repositories: '40+' },
      domainsList: [],

      async init() {
        await this.checkAuth();
        this.router();
        window.addEventListener('popstate', () => this.router());
      },

      async checkAuth() {
        try {
          const res = await fetch('/api/me');
          const data = await res.json();
          this.user = data.user;
        } catch (e) { this.user = null; }
      },

      async loadStats() {
        try {
          const res = await fetch('/api/stats');
          const data = await res.json();
          if (data.stats) this.stats = { ...this.stats, ...data.stats };
          if (data.domains) this.domainsList = data.domains;
        } catch (e) {}
      },

      navigate(path) {
        history.pushState({}, '', path);
        this.router();
      },

      router() {
        const path = location.pathname;
        if (path === '/login') this.renderLogin();
        else if (path === '/signup') this.renderSignup();
        else if (path === '/dashboard') this.renderDashboard();
        else this.renderHome();
      },

      renderHome() {
        this.loadStats().then(() => {
          document.getElementById('app').innerHTML = \`
            <header>
              <div class="container header-inner">
                <div class="logo" onclick="App.navigate('/')"><span>BlackRoad</span></div>
                <nav class="nav">
                  \${this.user ? \`
                    <span class="user-name">\${this.user.name || this.user.email}</span>
                    <a href="/dashboard" onclick="event.preventDefault(); App.navigate('/dashboard')">Dashboard</a>
                    <button onclick="App.logout()">Sign out</button>
                  \` : \`
                    <a href="/login" onclick="event.preventDefault(); App.navigate('/login')">Sign in</a>
                    <a href="/signup" onclick="event.preventDefault(); App.navigate('/signup')" class="btn btn-primary" style="padding: 8px 16px;">Get Started</a>
                  \`}
                </nav>
              </div>
            </header>
            <main>
              <section class="hero">
                <div class="container">
                  <h1>The Road Ahead<br>Is <span>Infinite</span></h1>
                  <p>Browser-native operating system for AI agent orchestration</p>
                  <div class="hero-buttons">
                    \${this.user ? \`
                      <button class="btn btn-primary" onclick="App.navigate('/dashboard')">Dashboard →</button>
                    \` : \`
                      <button class="btn btn-primary" onclick="App.navigate('/signup')">Get Started →</button>
                      <button class="btn btn-ghost" onclick="App.navigate('/login')">Sign In</button>
                    \`}
                  </div>
                </div>
              </section>
              <section class="container">
                <div class="stats">
                  <div class="stat"><div class="stat-value">\${this.stats.agents || '1000'}</div><div class="stat-label">AI Agents</div></div>
                  <div class="stat"><div class="stat-value">\${this.stats.domains || '21'}</div><div class="stat-label">Domains</div></div>
                  <div class="stat"><div class="stat-value">\${this.stats.github_orgs || '16'}</div><div class="stat-label">GitHub Orgs</div></div>
                  <div class="stat"><div class="stat-value">\${this.stats.repositories || '40+'}</div><div class="stat-label">Repositories</div></div>
                </div>
              </section>
              <section class="container">
                <div class="cards">
                  <div class="card"><div class="card-icon">🤖</div><div class="card-title">Agent Orchestration</div><div class="card-desc">LangGraph + CrewAI powering 1,000 unique agents</div></div>
                  <div class="card"><div class="card-icon">🧠</div><div class="card-title">Lucidia Core</div><div class="card-desc">Recursive AI with trinary logic and PS-SHA∞ memory</div></div>
                  <div class="card"><div class="card-icon">⛓️</div><div class="card-title">RoadChain</div><div class="card-desc">Hyperledger Besu blockchain for agent identity</div></div>
                  <div class="card"><div class="card-icon">🌐</div><div class="card-title">Edge Network</div><div class="card-desc">Cloudflare Workers + K3s for global deployment</div></div>
                </div>
              </section>
            </main>
            <footer>
              <div class="container">
                <div class="footer-links">
                  <a href="https://github.com/BlackRoad-OS" target="_blank">GitHub</a>
                  <a href="https://instagram.com/blackroad.io" target="_blank">Instagram</a>
                </div>
                <p class="footer-copy">© 2026 BlackRoad OS, Inc. · Delaware C-Corp</p>
              </div>
            </footer>
          \`;
        });
      },

      renderLogin() {
        document.getElementById('app').innerHTML = \`
          <div class="auth-page">
            <div class="auth-box">
              <div class="auth-header">
                <div class="logo" onclick="App.navigate('/')"><span>BlackRoad</span></div>
                <h1>Welcome back</h1>
                <p>Sign in to your account</p>
              </div>
              <form class="auth-form" onsubmit="App.handleLogin(event)">
                <div id="login-error"></div>
                <div class="form-group">
                  <label>Email</label>
                  <input type="email" name="email" required>
                </div>
                <div class="form-group">
                  <label>Password</label>
                  <input type="password" name="password" required>
                </div>
                <button type="submit" class="btn btn-primary btn-full">Sign In</button>
              </form>
              <p class="auth-footer">Don't have an account? <a href="/signup" onclick="event.preventDefault(); App.navigate('/signup')">Sign up</a></p>
            </div>
          </div>
        \`;
      },

      renderSignup() {
        document.getElementById('app').innerHTML = \`
          <div class="auth-page">
            <div class="auth-box">
              <div class="auth-header">
                <div class="logo" onclick="App.navigate('/')"><span>BlackRoad</span></div>
                <h1>Get started</h1>
                <p>Create your account</p>
              </div>
              <form class="auth-form" onsubmit="App.handleSignup(event)">
                <div id="signup-error"></div>
                <div class="form-group">
                  <label>Name</label>
                  <input type="text" name="name" placeholder="Optional">
                </div>
                <div class="form-group">
                  <label>Email</label>
                  <input type="email" name="email" required>
                </div>
                <div class="form-group">
                  <label>Password</label>
                  <input type="password" name="password" required minlength="8" placeholder="Min 8 characters">
                </div>
                <button type="submit" class="btn btn-primary btn-full">Create Account</button>
              </form>
              <p class="auth-footer">Already have an account? <a href="/login" onclick="event.preventDefault(); App.navigate('/login')">Sign in</a></p>
            </div>
          </div>
        \`;
      },

      renderDashboard() {
        if (!this.user) { this.navigate('/login'); return; }
        this.loadStats().then(() => {
          document.getElementById('app').innerHTML = \`
            <header>
              <div class="container header-inner">
                <div class="logo" onclick="App.navigate('/')"><span>BlackRoad</span></div>
                <nav class="nav">
                  <span class="user-name">\${this.user.name || this.user.email}</span>
                  <button onclick="App.logout()">Sign out</button>
                </nav>
              </div>
            </header>
            <main class="dashboard">
              <div class="container">
                <h1 class="page-title">Dashboard</h1>
                <p class="page-subtitle">Welcome back, \${this.user.name || 'there'}</p>
                <div class="stats">
                  <div class="stat"><div class="stat-value">\${this.stats.agents || '1000'}</div><div class="stat-label">AI Agents</div></div>
                  <div class="stat"><div class="stat-value">\${this.stats.domains || '21'}</div><div class="stat-label">Domains</div></div>
                  <div class="stat"><div class="stat-value">\${this.stats.github_orgs || '16'}</div><div class="stat-label">GitHub Orgs</div></div>
                  <div class="stat"><div class="stat-value">\${this.stats.repositories || '40+'}</div><div class="stat-label">Repositories</div></div>
                </div>
                <h2 class="section-title">Recent Domains</h2>
                <div class="domains-list">
                  \${(this.domainsList.length ? this.domainsList : ['blackroad.io', 'lucidia.earth', 'roadchain.io', 'aliceqi.com']).map(d => \`
                    <div class="domain-item">
                      <span class="domain-name">\${d}</span>
                      <span class="domain-badge">Active</span>
                    </div>
                  \`).join('')}
                </div>
              </div>
            </main>
          \`;
        });
      },

      async handleLogin(e) {
        e.preventDefault();
        const form = e.target;
        const email = form.email.value;
        const password = form.password.value;
        const errorEl = document.getElementById('login-error');
        
        try {
          const res = await fetch('/api/login', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ email, password })
          });
          const data = await res.json();
          if (data.success) {
            this.user = data.user;
            this.navigate('/dashboard');
          } else {
            errorEl.innerHTML = '<div class="error-msg">' + (data.error || 'Login failed') + '</div>';
          }
        } catch (e) {
          errorEl.innerHTML = '<div class="error-msg">Network error</div>';
        }
      },

      async handleSignup(e) {
        e.preventDefault();
        const form = e.target;
        const name = form.name.value;
        const email = form.email.value;
        const password = form.password.value;
        const errorEl = document.getElementById('signup-error');
        
        try {
          const res = await fetch('/api/signup', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ name, email, password })
          });
          const data = await res.json();
          if (data.success) {
            this.user = data.user;
            this.navigate('/dashboard');
          } else {
            errorEl.innerHTML = '<div class="error-msg">' + (data.error || 'Signup failed') + '</div>';
          }
        } catch (e) {
          errorEl.innerHTML = '<div class="error-msg">Network error</div>';
        }
      },

      async logout() {
        await fetch('/api/logout', { method: 'POST' });
        this.user = null;
        this.navigate('/');
      }
    };

    App.init();
  </script>
</body>
</html>`;
