export default {
  async fetch(req, env) {
    const url = new URL(req.url);
    if (url.pathname === '/health') return Response.json({ ok: true, worker: 'asia-blackroadio' });
    if (url.pathname === '/api') return Response.json({ section: 'asia', title: 'Asia', tagline: 'BlackRoad OS Asia Pacific edge region. Low-latency agent inference for APAC users.' });
    return new Response(page(), { headers: { 'Content-Type': 'text/html;charset=UTF-8', 'Cache-Control': 'public,max-age=60' } });
  }
};

function page() {
  const G = `linear-gradient(135deg,#F5A623 0%,#FF1D6C 38.2%,#9C27B0 61.8%,#2979FF 100%)`;
  return `<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Asia — BlackRoad OS</title>
<meta name="description" content="BlackRoad OS Asia Pacific edge region. Low-latency agent inference for APAC users.">
<style>*{margin:0;padding:0;box-sizing:border-box}body{background:#000;color:#fff;font-family:-apple-system,BlinkMacSystemFont,'SF Pro Display',sans-serif;min-height:100vh}
.grad-bar{height:3px;background:${G}}
header{padding:60px 40px;border-bottom:1px solid #111}
.eye{font-size:.75rem;font-weight:600;letter-spacing:.15em;text-transform:uppercase;color:#555;margin-bottom:12px}
h1{font-size:clamp(2rem,5vw,3.5rem);font-weight:900;letter-spacing:-3px;background:${G};-webkit-background-clip:text;-webkit-text-fill-color:transparent}
.sub{font-size:1rem;opacity:.55;margin-top:10px;max-width:500px;line-height:1.6}
.body{padding:40px;max-width:1100px}
.cards{display:grid;grid-template-columns:repeat(auto-fill,minmax(260px,1fr));gap:16px;margin-top:32px}
.card{background:#0a0a0a;border:1px solid #1a1a1a;border-radius:12px;padding:24px;transition:.2s}
.card:hover{border-color:#333;transform:translateY(-2px)}
.card h3{font-size:1rem;font-weight:700;margin-bottom:6px}
.card p{font-size:.82rem;opacity:.55;line-height:1.5}
.icon{font-size:1.5rem;margin-bottom:10px}
footer{text-align:center;padding:32px;opacity:.25;font-size:.75rem;border-top:1px solid #0d0d0d}
nav{display:flex;gap:8px;flex-wrap:wrap;margin-top:20px}
nav a{padding:5px 14px;border:1px solid #1a1a1a;border-radius:100px;font-size:.8rem;color:#888;text-decoration:none;transition:.15s}
nav a:hover{color:#fff;border-color:#333}
</style></head><body>
<div class="grad-bar"></div>
<header>
  <div class="eye">BlackRoad OS · asia.blackroad.io</div>
  <h1>🌏 Asia</h1>
  <p class="sub">BlackRoad OS Asia Pacific edge region. Low-latency agent inference for APAC users.</p>
  <nav>
    <a href="https://blackroad.io">Home</a>
    <a href="https://api.blackroad.io/health">API</a>
    <a href="https://dashboard.blackroad.io">Dashboard</a>
    <a href="https://docs.blackroad.io">Docs</a>
    <a href="https://github.com/BlackRoad-OS/workers">GitHub</a>
  </nav>
</header>
<div class="body">
  <p style="font-size:.85rem;opacity:.4">Coming soon — Asia for BlackRoad OS</p>
</div>
<footer>asia.blackroad.io · © 2026 BlackRoad OS, Inc. · <a href="https://blackroad.io" style="color:#FF1D6C;text-decoration:none">blackroad.io</a></footer>
</body></html>`;
}
