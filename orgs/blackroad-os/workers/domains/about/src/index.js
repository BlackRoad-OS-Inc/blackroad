function json(d){return new Response(JSON.stringify(d),{headers:{"Content-Type":"application/json","Access-Control-Allow-Origin":"*"}});}
export default {
  async fetch(req){
    const {pathname:p}=new URL(req.url);
    if(p==="/health") return json({status:"ok"});
    if(p==="/api") return json({name:"BlackRoad OS",tagline:"Your AI. Your Hardware. Your Rules.",founded:"2024",mission:"Build the operating system for AI-native businesses",orgs:17,repos:1825,agents:30000,workers:75});
    return new Response(`<!DOCTYPE html><html><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>About — BlackRoad OS</title><style>*{box-sizing:border-box;margin:0;padding:0}body{background:#000;color:#fff;font-family:-apple-system,sans-serif}.gbar{height:3px;background:linear-gradient(135deg,#F5A623,#FF1D6C,#9C27B0,#2979FF)}.header{padding:60px 40px;border-bottom:1px solid #1a1a1a;text-align:center}.title{font-size:clamp(32px,5vw,72px);font-weight:700;background:linear-gradient(135deg,#F5A623,#FF1D6C,#9C27B0,#2979FF);-webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text;margin-bottom:16px}.tagline{font-size:20px;color:#aaa;margin-bottom:24px}.mission{font-size:15px;color:#555;max-width:600px;margin:0 auto;line-height:1.618}.content{padding:60px 40px;max-width:1000px;margin:0 auto}.stats{display:grid;grid-template-columns:repeat(4,1fr);gap:20px;margin-bottom:60px}.stat{background:#0a0a0a;border:1px solid #1a1a1a;border-radius:14px;padding:28px;text-align:center}.val{font-size:36px;font-weight:700;background:linear-gradient(135deg,#F5A623,#FF1D6C,#9C27B0,#2979FF);-webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text}.lbl{font-size:12px;color:#555;text-transform:uppercase;letter-spacing:.1em;margin-top:6px}.pillars{display:grid;grid-template-columns:1fr 1fr;gap:20px}.pillar{background:#0a0a0a;border:1px solid #1a1a1a;border-radius:14px;padding:24px}.pillar-title{font-size:15px;font-weight:600;color:#FF1D6C;margin-bottom:8px}.pillar-desc{font-size:13px;color:#666;line-height:1.6}@media(max-width:700px){.stats{grid-template-columns:1fr 1fr}.pillars{grid-template-columns:1fr}}</style></head><body>
<div class="gbar"></div>
<div class="header"><h1 class="title">BlackRoad OS</h1><p class="tagline">Your AI. Your Hardware. Your Rules.</p><p class="mission">Building the operating system for AI-native businesses — 17 organizations, 1,825+ repositories, 30,000 agents running on your hardware.</p></div>
<div class="content">
<div class="stats">
  <div class="stat"><div class="val">17</div><div class="lbl">Orgs</div></div>
  <div class="stat"><div class="val">1,825+</div><div class="lbl">Repos</div></div>
  <div class="stat"><div class="val">30K</div><div class="lbl">Agents</div></div>
  <div class="stat"><div class="val">75+</div><div class="lbl">Workers</div></div>
</div>
<div class="pillars">
  <div class="pillar"><div class="pillar-title">Modularity</div><div class="pillar-desc">Each feature is a standalone tool. 37 CLI tools, each self-contained, self-initializing, and independently deployable.</div></div>
  <div class="pillar"><div class="pillar-title">Zero-Config</div><div class="pillar-desc">Tools self-initialize on first use. SQLite databases auto-create. No setup, no ceremony.</div></div>
  <div class="pillar"><div class="pillar-title">Autonomy</div><div class="pillar-desc">CECE persists across any provider. Your identity, your data, your rules — not locked to any cloud or vendor.</div></div>
  <div class="pillar"><div class="pillar-title">Tokenless Agents</div><div class="pillar-desc">Zero API keys in agent code. All provider secrets live only in the gateway. Clean separation of trust.</div></div>
</div>
</div></body></html>`,{headers:{"Content-Type":"text/html;charset=utf-8","Cache-Control":"public,max-age=3600"}});
  }
};
