export default {
  async fetch(request) {
    const url = new URL(request.url);
    
    // Proxy to Pi fleet
    if (url.pathname.startsWith('/api/') || url.pathname.startsWith('/tasks')) {
      try {
        const r = await fetch(`https://fleet.blackroad.io${url.pathname}${url.search}`, {
          method: request.method, headers: request.headers,
          signal: AbortSignal.timeout(5000)
        });
        return r;
      } catch {}
    }
    
    const html = `<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<meta http-equiv="refresh" content="30">
<title>BlackRoad Ops — Operations Dashboard</title>
<style>
*{box-sizing:border-box;margin:0;padding:0}
body{font-family:-apple-system,BlinkMacSystemFont,'SF Pro Display',sans-serif;background:#050505;color:#fff;min-height:100vh}
.header{background:linear-gradient(135deg,#FF1D6C,#9C27B0,#2979FF);padding:2px 0}
.header-inner{background:#0a0a0a;margin:2px;padding:24px 40px;display:flex;justify-content:space-between;align-items:center}
h1{font-size:1.8rem;font-weight:700;letter-spacing:-0.5px}
.badge{background:#10b981;color:#fff;padding:4px 14px;border-radius:20px;font-size:.75rem;font-weight:700}
.main{padding:40px;max-width:1400px;margin:0 auto}
.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(280px,1fr));gap:20px;margin-bottom:40px}
.card{background:#111;border:1px solid #1e1e1e;border-radius:12px;padding:24px}
.card h3{color:#888;font-size:.75rem;text-transform:uppercase;letter-spacing:.1em;margin-bottom:12px}
.card .value{font-size:2rem;font-weight:700;color:#FF1D6C}
.card .sub{color:#555;font-size:.85rem;margin-top:4px}
.link-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(200px,1fr));gap:12px}
.link{background:#111;border:1px solid #1e1e1e;border-radius:8px;padding:16px;text-decoration:none;color:#fff;transition:border-color .2s}
.link:hover{border-color:#FF1D6C}
.link .icon{font-size:1.5rem;margin-bottom:8px}
.link .name{font-weight:600;margin-bottom:4px}
.link .desc{color:#666;font-size:.8rem}
.section-title{font-size:1.1rem;font-weight:600;margin-bottom:16px;color:#888}
footer{text-align:center;padding:40px;color:#333;font-size:.8rem}
</style>
</head>
<body>
<div class="header"><div class="header-inner">
<div><h1>⚙️ BlackRoad Ops</h1><p style="color:#555;margin-top:4px;font-size:.85rem">Operations &amp; Infrastructure Dashboard</p></div>
<div class="badge">LIVE</div>
</div></div>
<div class="main">
<div class="grid">
<div class="card"><h3>Pi Fleet</h3><div class="value">4</div><div class="sub">Nodes · alice · octavia · aria · lucidia</div></div>
<div class="card"><h3>CF Workers</h3><div class="value">500+</div><div class="sub">Deployed across all domains</div></div>
<div class="card"><h3>AI Models</h3><div class="value">108</div><div class="sub">20 live on octavia · Ollama</div></div>
<div class="card"><h3>Agents</h3><div class="value">30K</div><div class="sub">Capacity · 8 active agents</div></div>
</div>
<div style="margin-bottom:32px">
<div class="section-title">Operations Links</div>
<div class="link-grid">
<a href="https://fleet.blackroad.io" class="link"><div class="icon">🖥️</div><div class="name">Pi Fleet</div><div class="desc">fleet.blackroad.io</div></a>
<a href="https://agents.blackroad.io" class="link"><div class="icon">🤖</div><div class="name">Agents</div><div class="desc">agents.blackroad.io</div></a>
<a href="https://dashboard.blackroad.io" class="link"><div class="icon">📊</div><div class="name">Dashboard</div><div class="desc">dashboard.blackroad.io</div></a>
<a href="https://api.blackroad.io" class="link"><div class="icon">⚡</div><div class="name">API</div><div class="desc">api.blackroad.io</div></a>
<a href="https://console.blackroad.io" class="link"><div class="icon">🎮</div><div class="name">Console</div><div class="desc">console.blackroad.io</div></a>
<a href="https://docs.blackroad.io" class="link"><div class="icon">📚</div><div class="name">Docs</div><div class="desc">docs.blackroad.io</div></a>
</div>
</div>
</div>
<footer>BlackRoad OS · ops.blackroad.io · © BlackRoad OS, Inc.</footer>
</body></html>`;
    
    return new Response(html, { headers: { 'Content-Type': 'text/html', 'Cache-Control': 'no-cache' } });
  }
};
