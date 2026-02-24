/**
 * models.blackroad.io — BlackRoad Model Registry
 * Live data from Octavia (BlackRoad Model Server v2)
 */

const FLEET_API = 'https://fleet.blackroad.io/api/fleet';
const CORS = { 'Access-Control-Allow-Origin': '*', 'Access-Control-Allow-Methods': 'GET,OPTIONS' };

async function getModels() {
  try {
    const r = await fetch(FLEET_API, { signal: AbortSignal.timeout(5000), cf: { cacheTtl: 30 } });
    if (r.ok) {
      const data = await r.json();
      const octavia = (data.nodes || []).find(n => n.name === 'octavia');
      return octavia?.models || null;
    }
  } catch {}
  return null;
}

export default {
  async fetch(request) {
    const url = new URL(request.url);
    if (request.method === 'OPTIONS') return new Response(null, { headers: CORS });

    if (url.pathname === '/api/models') {
      const models = await getModels();
      return new Response(JSON.stringify(models || { error: 'unavailable' }), { headers: { 'Content-Type': 'application/json', ...CORS } });
    }

    const models = await getModels();
    const cats = models?.categories || {};
    const total = models?.total_models || 108;
    const live = models?.live || 20;

    const ICONS = { 'vision':'👁️','vision-hailo':'⚡','audio':'🎵','speech':'🎤','nlp':'📝','nlp-locale':'🌍','people':'👤','prediction':'🔮','location':'📍','network':'📡','llm':'🧠','core':'⚙️' };

    const cards = Object.entries(cats).map(([name, info]) => {
      const icon = ICONS[name] || '🔬';
      const liveBadge = info.live > 0 ? `<span style="background:#0f2010;color:#4ade80;font-size:.7rem;padding:3px 10px;border-radius:12px;font-weight:700;margin-left:auto">${info.live} live</span>` : `<span style="background:#111;color:#555;font-size:.7rem;padding:3px 10px;border-radius:12px;margin-left:auto">standby</span>`;
      const pills = (info.models || []).slice(0,5).map(m => `<span style="background:#111;border:1px solid #1e1e1e;color:#666;font-size:.72rem;padding:3px 8px;border-radius:4px;font-family:monospace">${m.replace('BlackRoad','')}</span>`).join('');
      const more = info.count > 5 ? `<span style="color:#444;font-size:.72rem;font-family:monospace">+${info.count - 5}</span>` : '';
      return `<div style="background:#0d0d0d;border:1px solid ${info.live > 0 ? '#1a2a1a' : '#1a1a1a'};border-radius:12px;padding:20px">
        <div style="display:flex;align-items:center;gap:10px;margin-bottom:12px">
          <span style="font-size:1.4rem">${icon}</span>
          <div><div style="font-weight:700;text-transform:uppercase;font-size:.8rem;letter-spacing:.1em;color:#888">${name}</div><div style="font-size:.75rem;color:#444">${info.count} models</div></div>
          ${liveBadge}
        </div>
        <div style="display:flex;flex-wrap:wrap;gap:5px">${pills}${more}</div>
      </div>`;
    }).join('');

    const html = `<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta http-equiv="refresh" content="60"><title>BlackRoad Models</title><style>*{box-sizing:border-box;margin:0;padding:0}body{font-family:-apple-system,BlinkMacSystemFont,'SF Pro Display',sans-serif;background:#050505;color:#fff;min-height:100vh}.header{padding:40px;border-bottom:1px solid #111;display:flex;justify-content:space-between;align-items:center;flex-wrap:wrap;gap:16px}h1{font-size:2.2rem;font-weight:800;background:linear-gradient(135deg,#F5A623,#FF1D6C,#9C27B0);-webkit-background-clip:text;-webkit-text-fill-color:transparent}</style></head><body>
<div class="header" style="padding:40px;border-bottom:1px solid #111;display:flex;justify-content:space-between;align-items:center;flex-wrap:wrap;gap:16px">
  <div><h1 style="font-size:2.2rem;font-weight:800;background:linear-gradient(135deg,#F5A623,#FF1D6C,#9C27B0);-webkit-background-clip:text;-webkit-text-fill-color:transparent">BlackRoad Models</h1><p style="color:#555;font-size:.85rem;margin-top:4px">Octavia — BlackRoad Model Server v2 · ${new Date().toUTCString()}</p></div>
  <div style="display:flex;gap:32px">
    <div style="text-align:center"><div style="font-size:2rem;font-weight:800;color:#FF1D6C">${total}</div><div style="font-size:.7rem;color:#555;text-transform:uppercase">Total</div></div>
    <div style="text-align:center"><div style="font-size:2rem;font-weight:800;color:#4ade80">${live}</div><div style="font-size:.7rem;color:#555;text-transform:uppercase">Live</div></div>
    <div style="text-align:center"><div style="font-size:2rem;font-weight:800;color:#60a5fa">${total-live}</div><div style="font-size:.7rem;color:#555;text-transform:uppercase">Available</div></div>
  </div>
</div>
<div style="padding:40px;max-width:1400px;margin:0 auto">
  <div style="display:grid;grid-template-columns:repeat(auto-fill,minmax(280px,1fr));gap:16px">
    ${cards || '<p style="color:#444;grid-column:1/-1;text-align:center;padding:60px">Loading model data from Octavia...</p>'}
  </div>
</div>
<div style="text-align:center;padding:40px;color:#222;font-size:.8rem">BlackRoad OS, Inc. · models.blackroad.io</div>
</body></html>`;

    return new Response(html, { headers: { 'Content-Type': 'text/html', 'Cache-Control': 'no-store' } });
  }
};
