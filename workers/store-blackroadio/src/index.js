// store.blackroad.io — BlackRoad OS Marketplace & Store
// Now with real checkout integration via roadgateway (pay.blackroad.io)
// BlackRoad OS, Inc. © 2026 — All Rights Reserved

export default {
  async fetch(req, env) {
    const url = new URL(req.url);

    if (url.pathname === '/health') {
      return Response.json({ ok: true, worker: 'store-blackroadio', checkout: 'pay.blackroad.io' });
    }

    const CSS = `*{margin:0;padding:0;box-sizing:border-box}
:root{--pink:#FF1D6C;--amber:#F5A623;--violet:#9C27B0;--blue:#2979FF;--bg:#000;--surface:#0a0a0a;--border:#1a1a1a;--text:#fff;--muted:#888;--gradient:linear-gradient(135deg,var(--amber) 0%,var(--pink) 38.2%,var(--violet) 61.8%,var(--blue) 100%)}
body{background:var(--bg);color:var(--text);font-family:-apple-system,BlinkMacSystemFont,"SF Pro Display",sans-serif;min-height:100vh}
header{background:var(--gradient);padding:60px 40px;text-align:center}
header h1{font-size:3rem;font-weight:800;letter-spacing:-2px}
header p{opacity:.85;margin-top:12px;font-size:1.1rem}
nav{display:flex;justify-content:center;gap:24px;padding:16px;border-bottom:1px solid var(--border)}
nav a{color:var(--muted);text-decoration:none;font-size:.9rem;transition:color .2s}
nav a:hover{color:var(--text)}
nav a.active{color:var(--pink);font-weight:600}
.section{max-width:1200px;margin:0 auto;padding:40px}
.section h2{font-size:1.5rem;font-weight:700;margin-bottom:24px;text-align:center}
.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(280px,1fr));gap:20px}
.card{background:var(--surface);border:1px solid var(--border);border-radius:12px;padding:24px;transition:.2s}
.card:hover{border-color:var(--pink);transform:translateY(-2px)}
.card h3{font-size:1.1rem;margin-bottom:8px}
.card p{font-size:.85rem;color:var(--muted);line-height:1.5}
.tag{display:inline-block;background:#111;border:1px solid #333;border-radius:20px;padding:4px 12px;font-size:.75rem;margin-top:12px;color:var(--pink)}
.pricing{display:grid;grid-template-columns:repeat(auto-fill,minmax(280px,1fr));gap:20px;margin-top:32px}
.tier{background:var(--surface);border:1px solid var(--border);border-radius:12px;padding:28px;text-align:center;transition:.2s}
.tier:hover{border-color:var(--pink)}
.tier.popular{border-color:var(--pink);box-shadow:0 0 34px rgba(255,29,108,.15)}
.tier h3{font-size:1.2rem;margin-bottom:4px}
.tier .price{font-size:2.2rem;font-weight:700;color:var(--pink);margin:16px 0}
.tier .price span{font-size:.9rem;color:var(--muted);font-weight:400}
.tier ul{list-style:none;margin:16px 0;text-align:left}
.tier li{padding:5px 0;font-size:.88rem;color:var(--muted)}
.tier li::before{content:'\\2713 ';color:var(--pink)}
.btn{display:inline-block;padding:12px 32px;background:var(--gradient);color:#fff;font-weight:600;border:none;border-radius:8px;cursor:pointer;font-size:1rem;text-decoration:none;margin-top:16px;transition:.2s}
.btn:hover{opacity:.9;transform:scale(1.02)}
.btn-outline{background:transparent;border:1px solid var(--border);color:var(--text)}
.btn-outline:hover{border-color:var(--pink)}
.popular-badge{background:var(--gradient);color:#fff;font-size:.7rem;font-weight:700;padding:3px 12px;border-radius:10px;display:inline-block;margin-bottom:12px}
footer{text-align:center;padding:40px;color:#333;font-size:.8rem;border-top:1px solid var(--border)}`;

    return new Response(`<!DOCTYPE html><html lang="en"><head>
<meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Store — BlackRoad OS</title>
<style>${CSS}</style>
</head><body>

<header>
  <h1>BlackRoad OS Store</h1>
  <p>Skills, agents, integrations, and subscriptions</p>
</header>

<nav>
  <a href="#pricing" class="active">Pricing</a>
  <a href="#marketplace">Marketplace</a>
  <a href="https://pay.blackroad.io">Billing Portal</a>
  <a href="https://docs.blackroad.io">Docs</a>
</nav>

<div class="section" id="pricing">
  <h2>Choose Your Plan</h2>
  <div class="pricing">
    <div class="tier">
      <h3>Free</h3>
      <div class="price">$0<span>/forever</span></div>
      <ul>
        <li>5 AI Agents</li>
        <li>500 tasks/month</li>
        <li>Community support</li>
        <li>Public dashboard</li>
      </ul>
      <a href="https://blackroad.io/signup" class="btn btn-outline">Get Started</a>
    </div>
    <div class="tier popular">
      <span class="popular-badge">Most Popular</span>
      <h3>Pro</h3>
      <div class="price">$29<span>/month</span></div>
      <ul>
        <li>100 AI Agents</li>
        <li>10,000 tasks/month</li>
        <li>Priority support</li>
        <li>Custom agent configs</li>
        <li>Memory system access</li>
        <li>Pi cluster integration</li>
        <li>14-day free trial</li>
      </ul>
      <button class="btn" onclick="checkout('pro','monthly')">Start Free Trial</button>
    </div>
    <div class="tier">
      <h3>Enterprise</h3>
      <div class="price">$199<span>/month</span></div>
      <ul>
        <li>Unlimited AI Agents</li>
        <li>Unlimited tasks</li>
        <li>SSO / SAML</li>
        <li>99.9% SLA</li>
        <li>Dedicated support</li>
        <li>Custom deployments</li>
        <li>On-prem / Pi cluster</li>
      </ul>
      <button class="btn" onclick="checkout('enterprise','monthly')">Start Free Trial</button>
    </div>
  </div>
</div>

<div class="section" id="marketplace">
  <h2>Marketplace</h2>
  <div class="grid">
    <div class="card"><h3>Skills Marketplace</h3><p>Buy and sell agent skills with revenue share</p><span class="tag">beta</span></div>
    <div class="card"><h3>Agent Blueprints</h3><p>Pre-built agent configurations for common use cases</p><span class="tag">live</span></div>
    <div class="card"><h3>Integration Packs</h3><p>Platform-specific integration bundles</p><span class="tag">active</span></div>
    <div class="card"><h3>Templates</h3><p>Full-stack project templates with br CLI</p><span class="tag">free</span></div>
    <div class="card"><h3>Hardware Bundles</h3><p>Pi cluster kits with pre-installed BlackRoad OS</p><span class="tag">order</span></div>
    <div class="card"><h3>Compute Credits</h3><p>Credits for managed GPU inference</p><span class="tag">buy</span></div>
  </div>
</div>

<footer>© 2026 BlackRoad OS, Inc. · <a href="https://blackroad.io" style="color:var(--pink)">blackroad.io</a></footer>

<script>
async function checkout(tier, period) {
  const btn = event.target;
  btn.textContent = 'Loading...';
  btn.disabled = true;
  try {
    const res = await fetch('https://pay.blackroad.io/api/checkout', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ tier, period }),
    });
    const data = await res.json();
    if (data.url) {
      window.location.href = data.url;
    } else {
      alert(data.error || 'Checkout failed');
      btn.textContent = 'Try Again';
      btn.disabled = false;
    }
  } catch (e) {
    alert('Connection error. Please try again.');
    btn.textContent = 'Try Again';
    btn.disabled = false;
  }
}
</script>
</body></html>`, { headers: { 'content-type': 'text/html;charset=utf-8', 'cache-control': 'public,max-age=60' } });
  }
};
