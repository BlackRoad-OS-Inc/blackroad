function json(d){return new Response(JSON.stringify(d),{headers:{"Content-Type":"application/json","Access-Control-Allow-Origin":"*"}});}
const REGIONS=[{id:"dfw",name:"Dallas, TX",lat:32.89,lon:-97.04,status:"active",latency:12,workers:18},{id:"sjc",name:"San Jose, CA",lat:37.36,lon:-121.93,status:"active",latency:8,workers:14},{id:"ewr",name:"Newark, NJ",lat:40.69,lon:-74.17,status:"active",latency:15,workers:12},{id:"lhr",name:"London, UK",lat:51.47,lon:-0.46,status:"active",latency:22,workers:10},{id:"ams",name:"Amsterdam, NL",lat:52.31,lon:4.76,status:"active",latency:25,workers:8},{id:"nrt",name:"Tokyo, JP",lat:35.77,lon:140.39,status:"active",latency:45,workers:6},{id:"syd",name:"Sydney, AU",lat:-33.95,lon:151.18,status:"active",latency:52,workers:4}];
export default {
  async fetch(req){
    const {pathname:p}=new URL(req.url);
    if(p==="/health") return json({status:"ok",regions:REGIONS.length});
    if(p==="/api/regions") return json({total:REGIONS.length,workers:REGIONS.reduce((a,r)=>a+r.workers,0),regions:REGIONS});
    const regionRows=REGIONS.map(r=>`<div style="display:flex;justify-content:space-between;align-items:center;padding:10px 0;border-bottom:1px solid #0a0a0a"><div><span style="font-size:13px;color:#fff;font-weight:500">${r.name}</span><span style="font-size:11px;color:#555;margin-left:10px">${r.id}</span></div><div style="display:flex;gap:20px;align-items:center"><span style="font-size:12px;color:#2979FF">${r.latency}ms</span><span style="font-size:12px;color:#FF1D6C">${r.workers} workers</span><span style="font-size:12px;color:#4ade80;font-weight:600">●</span></div></div>`).join("");
    return new Response(`<!DOCTYPE html><html><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Edge — BlackRoad OS</title><style>*{box-sizing:border-box;margin:0;padding:0}body{background:#000;color:#fff;font-family:-apple-system,sans-serif}.gbar{height:3px;background:linear-gradient(135deg,#F5A623,#FF1D6C,#9C27B0,#2979FF)}.header{padding:40px;border-bottom:1px solid #1a1a1a}.title{font-size:42px;font-weight:700;background:linear-gradient(135deg,#F5A623,#FF1D6C,#9C27B0,#2979FF);-webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text}.content{padding:40px;max-width:800px}.stats{display:flex;gap:24px;flex-wrap:wrap;margin:16px 0 32px}.stat{text-align:center}.val{font-size:28px;font-weight:700;background:linear-gradient(135deg,#F5A623,#FF1D6C);-webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text}.lbl{font-size:11px;color:#555;text-transform:uppercase;letter-spacing:.1em;margin-top:2px}</style></head><body>
<div class="gbar"></div>
<div class="header"><div style="font-size:11px;font-weight:600;letter-spacing:.15em;text-transform:uppercase;color:#555;margin-bottom:12px">BlackRoad OS · Edge Network</div><h1 class="title">Edge</h1><p style="color:#555;font-size:15px;margin-top:8px">Global edge network · ${REGIONS.length} regions · ${REGIONS.reduce((a,r)=>a+r.workers,0)} workers</p>
<div class="stats">
<div class="stat"><div class="val">${REGIONS.length}</div><div class="lbl">Regions</div></div>
<div class="stat"><div class="val">${REGIONS.reduce((a,r)=>a+r.workers,0)}</div><div class="lbl">Workers</div></div>
<div class="stat"><div class="val">${Math.round(REGIONS.reduce((a,r)=>a+r.latency,0)/REGIONS.length)}ms</div><div class="lbl">Avg Latency</div></div>
<div class="stat"><div class="val">100%</div><div class="lbl">Uptime</div></div>
</div></div>
<div class="content"><div style="font-size:11px;font-weight:600;letter-spacing:.12em;text-transform:uppercase;color:#555;margin-bottom:14px;padding-bottom:8px;border-bottom:1px solid #1a1a1a">Edge Regions</div>${regionRows}</div>
</body></html>`,{headers:{"Content-Type":"text/html;charset=utf-8","Cache-Control":"public,max-age=60"}});
  }
};
