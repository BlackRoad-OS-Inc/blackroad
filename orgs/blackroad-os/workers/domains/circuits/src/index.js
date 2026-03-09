export default {
  async fetch(req, env) {
    const url = new URL(req.url);
    if (url.pathname === '/health') return Response.json({ ok: true, worker: 'circuits-blackroadio' });
    const css = `*{margin:0;padding:0;box-sizing:border-box}body{background:#000;color:#fff;font-family:-apple-system,BlinkMacSystemFont,'SF Pro Display',sans-serif;min-height:100vh}header{background:linear-gradient(135deg,#F5A623 0%,#FF1D6C 38.2%,#9C27B0 61.8%,#2979FF 100%);padding:60px 40px;text-align:center}header h1{font-size:3rem;font-weight:800;letter-spacing:-2px}header p{opacity:.85;margin-top:12px;font-size:1.1rem}.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(280px,1fr));gap:20px;padding:40px;max-width:1200px;margin:0 auto}.card{background:#0a0a0a;border:1px solid #1a1a1a;border-radius:12px;padding:24px;transition:.2s}.card:hover{border-color:#FF1D6C;transform:translateY(-2px)}.card h3{font-size:1.1rem;margin-bottom:8px}.card p{font-size:.85rem;opacity:.6;line-height:1.5}.tag{display:inline-block;background:#111;border:1px solid #333;border-radius:20px;padding:4px 12px;font-size:.75rem;margin-top:12px;color:#FF1D6C}footer{text-align:center;padding:40px;opacity:.4;font-size:.8rem}`;
    return new Response(`<!DOCTYPE html><html><head><title>⚡ Circuits — BlackRoad OS</title><meta charset=utf-8><meta name=viewport content="width=device-width,initial-scale=1"><style>${css}</style></head><body><header><h1>⚡ Circuits</h1><p>Hardware circuits and IoT edge computing</p></header><div class=grid><div class=card><h3>Pi Cluster</h3><p>3-node Raspberry Pi inference cluster</p><span class=tag>online</span></div>
   <div class=card><h3>Edge Compute</h3><p>Distributed edge nodes across 3 locations</p><span class=tag>active</span></div>
   <div class=card><h3>GPIO Bridge</h3><p>Sensor data bridge to cloud pipeline</p><span class=tag>live</span></div>
   <div class=card><h3>FPGA Units</h3><p>Custom inference acceleration hardware</p><span class=tag>dev</span></div>
   <div class=card><h3>PWM Controllers</h3><p>Motor and servo control via WebSocket</p><span class=tag>stable</span></div>
   <div class=card><h3>Thermal Monitor</h3><p>Real-time thermal telemetry from all nodes</p><span class=tag>live</span></div></div><footer>© 2026 BlackRoad OS, Inc. · <a href=https://blackroad.io style=color:#FF1D6C>blackroad.io</a></footer></body></html>`, { headers: { 'content-type': 'text/html;charset=utf-8', 'cache-control': 'public,max-age=60' }});
  }
};
