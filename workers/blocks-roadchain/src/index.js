export default {
  async fetch(req, env) {
    const url = new URL(req.url);
    if (url.pathname === '/health') return Response.json({ ok: true, worker: 'blocks-roadchain' });
    return new Response(page(), { headers: { 'Content-Type': 'text/html;charset=UTF-8' } });
  }
};
function page() {
  const G = `linear-gradient(135deg,#F5A623 0%,#FF1D6C 38.2%,#9C27B0 61.8%,#2979FF 100%)`;
  return `<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Block Browser — RoadChain</title>
<style>*{margin:0;padding:0;box-sizing:border-box}body{background:#000;color:#fff;font-family:-apple-system,sans-serif;min-height:100vh}
.bar{height:3px;background:${G}}.header{padding:50px 40px;border-bottom:1px solid #111}
.eye{font-size:.72rem;letter-spacing:.15em;text-transform:uppercase;color:#555;margin-bottom:10px}
h1{font-size:2.8rem;font-weight:900;letter-spacing:-2px;background:${G};-webkit-background-clip:text;-webkit-text-fill-color:transparent}
p{opacity:.55;margin-top:10px;font-size:.95rem}.body{padding:40px;max-width:1100px}
footer{text-align:center;padding:32px;opacity:.25;font-size:.75rem;border-top:1px solid #0d0d0d}</style></head><body>
<div class="bar"></div>
<div class="header">
  <div class="eye">RoadChain · roadchain.io</div>
  <h1>🧱 Block Browser</h1>
  <p>Browse every block on RoadChain. Full block data, transaction counts, validator info, and timestamps.</p>
</div>
<div class="body"><p style="opacity:.4;font-size:.85rem">Live data feed initializing...</p></div>
<footer>roadchain.io · © 2026 BlackRoad OS, Inc. · <a href="https://roadchain.io" style="color:#FF1D6C;text-decoration:none">roadchain.io</a></footer>
</body></html>`;
}
