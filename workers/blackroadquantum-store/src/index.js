export default {
  async fetch(req, env) {
    const url = new URL(req.url);
    if (url.pathname === '/health') return Response.json({ ok: true, worker: 'blackroadquantum-store' });
    return new Response(page(), { headers: { 'Content-Type': 'text/html;charset=UTF-8', 'Cache-Control': 'public,max-age=300' } });
  }
};

function page() {
  const G = `linear-gradient(135deg,#F5A623 0%,#FF1D6C 38.2%,#9C27B0 61.8%,#2979FF 100%)`;
  return `<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>BlackRoad Quantum</title><meta name="description" content="Quantum computing research and post-quantum cryptography by BlackRoad OS.">
<style>*{margin:0;padding:0;box-sizing:border-box}body{background:#000;color:#fff;font-family:-apple-system,BlinkMacSystemFont,'SF Pro Display',sans-serif;min-height:100vh;display:flex;flex-direction:column;justify-content:center;align-items:center;text-align:center;padding:40px}
.icon{font-size:5rem;margin-bottom:24px;animation:float 3s ease-in-out infinite}
@keyframes float{0%,100%{transform:translateY(0)}50%{transform:translateY(-12px)}}
h1{font-size:4rem;font-weight:900;letter-spacing:-4px;background:${G};-webkit-background-clip:text;-webkit-text-fill-color:transparent}
p{font-size:1.15rem;opacity:.65;margin-top:16px;max-width:480px;line-height:1.6}
.badge{display:inline-flex;align-items:center;gap:8px;background:#0a0a0a;border:1px solid #1a1a1a;border-radius:100px;padding:8px 20px;margin-top:28px;font-size:.85rem}
.dot{width:8px;height:8px;border-radius:50%;background:#4CAF50;box-shadow:0 0 8px #4CAF50;animation:pulse 2s infinite}
@keyframes pulse{0%,100%{opacity:1}50%{opacity:.4}}
a{color:#FF1D6C;text-decoration:none}
footer{position:fixed;bottom:20px;font-size:.75rem;opacity:.3}
</style></head><body>
<div class="icon">🔬</div>
<h1>BlackRoad Quantum</h1>
<p>Quantum computing research and post-quantum cryptography by BlackRoad OS.</p>
<div class="badge"><span class="dot"></span><span>Live on Cloudflare Edge · BlackRoad OS</span></div>
<br><a href="https://blackroad.io">← blackroad.io</a>
<footer>blackroadquantum.store · © 2026 BlackRoad OS, Inc. All rights reserved.</footer>
</body></html>`;
}
