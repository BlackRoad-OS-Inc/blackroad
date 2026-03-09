const CF_ACCOUNT_ID="848cf0b18d51e0170e0d1537aec3505a";
function json(d){return new Response(JSON.stringify(d),{headers:{"Content-Type":"application/json","Access-Control-Allow-Origin":"*"}});}
async function cfApi(env,path){if(!env.CF_API_TOKEN)return null;try{const r=await fetch(`https://api.cloudflare.com/client/v4/accounts/${CF_ACCOUNT_ID}${path}`,{headers:{"Authorization":`Bearer ${env.CF_API_TOKEN}`}});return r.ok?r.json():null;}catch{return null;}}
export default {
  async fetch(req,env){
    const {pathname:p}=new URL(req.url);
    if(p==="/health") return json({status:"ok"});
    const r2=await cfApi(env,"/r2/buckets");
    const buckets=(r2?.result||[]).map(b=>({name:b.name,created:b.creation_date?.slice(0,10),region:b.location||"auto"}));
    if(p==="/api/buckets") return json({total:buckets.length,buckets});
    return new Response(`<!DOCTYPE html><html><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>CDN — BlackRoad OS</title><style>*{box-sizing:border-box;margin:0;padding:0}body{background:#000;color:#fff;font-family:-apple-system,sans-serif}.gbar{height:3px;background:linear-gradient(135deg,#F5A623,#FF1D6C,#9C27B0,#2979FF)}.header{padding:40px;border-bottom:1px solid #1a1a1a}.title{font-size:42px;font-weight:700;background:linear-gradient(135deg,#F5A623,#FF1D6C,#9C27B0,#2979FF);-webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text}.content{padding:40px;max-width:1000px}.stats{display:grid;grid-template-columns:repeat(4,1fr);gap:16px;margin-bottom:32px}.stat{background:#0a0a0a;border:1px solid #1a1a1a;border-radius:12px;padding:20px;text-align:center}.val{font-size:28px;font-weight:700;background:linear-gradient(135deg,#F5A623,#FF1D6C);-webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text}.lbl{font-size:11px;color:#555;text-transform:uppercase;letter-spacing:.1em;margin-top:4px}.section-title{font-size:11px;font-weight:600;letter-spacing:.12em;text-transform:uppercase;color:#555;margin-bottom:14px;padding-bottom:8px;border-bottom:1px solid #1a1a1a}.bucket-row{display:flex;justify-content:space-between;padding:9px 0;border-bottom:1px solid #080808;font-size:12px}@media(max-width:600px){.stats{grid-template-columns:1fr 1fr}}</style></head><body>
<div class="gbar"></div>
<div class="header"><div style="font-size:11px;font-weight:600;letter-spacing:.15em;text-transform:uppercase;color:#555;margin-bottom:12px">BlackRoad OS · Storage & CDN</div><h1 class="title">CDN</h1><p style="color:#555;font-size:15px;margin-top:8px">Cloudflare R2 Storage · Global CDN · Edge delivery</p></div>
<div class="content">
<div class="stats">
  <div class="stat"><div class="val">${buckets.length||"?"}</div><div class="lbl">R2 Buckets</div></div>
  <div class="stat"><div class="val">135GB</div><div class="lbl">Total Storage</div></div>
  <div class="stat"><div class="val">Global</div><div class="lbl">CDN Edge</div></div>
  <div class="stat"><div class="val">Free</div><div class="lbl">Egress</div></div>
</div>
${buckets.length?`<div class="section-title">R2 Buckets (${buckets.length})</div>
${buckets.map(b=>`<div class="bucket-row"><span style="color:#4ade80;font-family:'SF Mono',monospace">${b.name}</span><span style="color:#555">${b.region}</span><span style="color:#333">${b.created||""}</span></div>`).join("")}`:"<div style='color:#555;font-size:13px'>Set CF_API_TOKEN to view bucket data</div>"}
</div>
</body></html>`,{headers:{"Content-Type":"text/html;charset=utf-8","Cache-Control":"public,max-age=300"}});
  }
};
