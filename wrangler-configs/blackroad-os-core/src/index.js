// BlackRoad OS Core Worker — identity + routing hub
const CORS = { "Access-Control-Allow-Origin": "*", "Content-Type": "application/json" };

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    
    if (url.pathname === "/") {
      return new Response(`<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>BlackRoad OS</title>
<style>*{margin:0;padding:0;box-sizing:border-box}body{background:#000;color:#fff;font-family:-apple-system,BlinkMacSystemFont,'SF Pro Display',sans-serif;min-height:100vh;display:flex;align-items:center;justify-content:center;flex-direction:column;gap:24px}
h1{font-size:clamp(2rem,8vw,5rem);font-weight:700;background:linear-gradient(135deg,#F5A623,#FF1D6C,#9C27B0,#2979FF);-webkit-background-clip:text;-webkit-text-fill-color:transparent}
p{color:#888;font-size:1.1rem}.links{display:flex;gap:16px;flex-wrap:wrap;justify-content:center}
a{color:#FF1D6C;text-decoration:none;padding:8px 16px;border:1px solid #FF1D6C33;border-radius:8px;font-size:.9rem}
a:hover{background:#FF1D6C22}.status{color:#F5A623;font-size:.85rem;margin-top:8px}
</style></head><body>
<h1>BlackRoad OS</h1>
<p>Your AI. Your Hardware. Your Rules.</p>
<div class="links">
  <a href="https://agents.blackroad.io">Agents</a>
  <a href="https://api.blackroad.io">API</a>
  <a href="https://dashboard.blackroad.io">Dashboard</a>
  <a href="https://docs.blackroad.io">Docs</a>
  <a href="https://console.blackroad.io">Console</a>
</div>
<div class="status">🟢 Pi Fleet: 7 runners online • 20 domains active • $0 cost</div>
</body></html>`, { headers: { "Content-Type": "text/html;charset=UTF-8", "Cache-Control": "s-maxage=3600" } });
    }

    if (url.pathname === "/health") {
      return Response.json({ status: "ok", service: "blackroad-os-core", ts: Date.now() }, { headers: CORS });
    }

    return Response.redirect("https://blackroad.network" + url.pathname, 301);
  }
};
