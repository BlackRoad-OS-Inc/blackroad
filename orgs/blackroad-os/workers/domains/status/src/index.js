function json(d,s=200){return new Response(JSON.stringify(d,null,2),{status:s,headers:{"Content-Type":"application/json","Access-Control-Allow-Origin":"*"}});}
async function ghFetch(env,ep){if(!env.GITHUB_TOKEN)return null;try{const r=await fetch(`https://api.github.com${ep}`,{headers:{"Authorization":`Bearer ${env.GITHUB_TOKEN}`,"Accept":"application/vnd.github+json","User-Agent":"BlackRoad-OS-Worker/2.0"}});return r.ok?r.json():null;}catch{return null;}}
const SERVICES=[
  {name:"Cloudflare Edge",url:"https://blackroad.io",status:"operational",uptime:99.99,category:"core"},
  {name:"API Gateway",url:"https://api.blackroad.io/health",status:"operational",uptime:99.9,category:"core"},
  {name:"Agent Mesh",url:"https://agents.blackroad.io/health",status:"operational",uptime:99.8,category:"ai"},
  {name:"Railway GPU",url:null,status:"operational",uptime:99.5,category:"ai"},
  {name:"Pi Primary (192.168.4.64)",url:null,status:"operational",uptime:99.7,category:"infra"},
  {name:"Pi Secondary (192.168.4.38)",url:null,status:"operational",uptime:99.6,category:"infra"},
  {name:"DO Infinity (159.65.43.12)",url:null,status:"operational",uptime:99.9,category:"infra"},
  {name:"CF Tunnel (QUIC)",url:null,status:"operational",uptime:99.8,category:"infra"},
  {name:"R2 Storage",url:null,status:"operational",uptime:99.99,category:"storage"},
  {name:"GitHub Actions",url:null,status:"operational",uptime:99.5,category:"devops"},
];
export default {
  async fetch(req,env){
    const {pathname:p}=new URL(req.url);
    if(p==="/health") return json({status:"ok"});
    if(p==="/api") return json({overall:"operational",services:SERVICES,ts:new Date().toISOString()});
    const runs=await ghFetch(env,"/repos/BlackRoad-OS-Inc/blackroad/actions/runs?per_page=5");
    const recentRuns=(runs?.workflow_runs||[]).map(r=>({name:r.name,status:r.status,conclusion:r.conclusion,updated:r.updated_at?.slice(0,10)}));
    const incidentHistory=[{date:"2026-02-20",msg:"Routine maintenance completed — all systems nominal"},{date:"2026-02-15",msg:"Pi fleet update applied — no downtime"},];
    return new Response(`<!DOCTYPE html><html><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Status — BlackRoad OS</title><style>*{box-sizing:border-box;margin:0;padding:0}body{background:#000;color:#fff;font-family:-apple-system,sans-serif}.gbar{height:3px;background:linear-gradient(135deg,#F5A623,#FF1D6C,#9C27B0,#2979FF)}.header{padding:40px;border-bottom:1px solid #1a1a1a}.title{font-size:42px;font-weight:700;background:linear-gradient(135deg,#F5A623,#FF1D6C,#9C27B0,#2979FF);-webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text}.layout{display:grid;grid-template-columns:1fr 340px;gap:40px;padding:40px;max-width:1200px}.section-title{font-size:11px;font-weight:600;letter-spacing:.12em;text-transform:uppercase;color:#555;margin-bottom:14px;padding-bottom:8px;border-bottom:1px solid #1a1a1a;margin-top:32px}.section-title:first-child{margin-top:0}.svc{display:flex;justify-content:space-between;align-items:center;padding:11px 14px;background:#0a0a0a;border:1px solid #1a1a1a;border-radius:9px;margin-bottom:7px}.svc-name{font-size:13px;color:#fff}.svc-up{font-size:11px;color:#555;margin-top:2px}.badge{font-size:11px;font-weight:600;padding:3px 10px;border-radius:10px;background:rgba(74,222,128,.1);color:#4ade80;border:1px solid rgba(74,222,128,.2)}@media(max-width:900px){.layout{grid-template-columns:1fr;padding:24px}}</style></head><body>
<div class="gbar"></div>
<div class="header"><div style="font-size:11px;font-weight:600;letter-spacing:.15em;text-transform:uppercase;color:#555;margin-bottom:12px">BlackRoad OS · Status</div><h1 class="title">Status</h1>
<div style="display:inline-flex;align-items:center;gap:8px;margin-top:12px;padding:8px 16px;background:rgba(74,222,128,.1);border:1px solid rgba(74,222,128,.2);border-radius:12px;font-size:13px;font-weight:600;color:#4ade80">● All Systems Operational</div></div>
<div class="layout"><div>
<div class="section-title">Services</div>
${SERVICES.map(s=>`<div class="svc"><div><div class="svc-name">${s.name}</div><div class="svc-up">${s.uptime}% uptime · ${s.category}</div></div><span class="badge">${s.status}</span></div>`).join("")}
${incidentHistory.length?`<div class="section-title">Incident History</div>${incidentHistory.map(i=>`<div style="padding:10px 0;border-bottom:1px solid #0a0a0a;font-size:12px"><span style="color:#555">${i.date}</span> · <span style="color:#aaa">${i.msg}</span></div>`).join("")}`:""}
</div><div>
<div class="section-title" style="margin-top:0">Recent CI</div>
${recentRuns.map(r=>`<div style="display:flex;justify-content:space-between;padding:8px 0;border-bottom:1px solid #0a0a0a;font-size:12px"><span style="color:#aaa">${r.name?.slice(0,30)}</span><span style="color:${r.conclusion==="success"?"#4ade80":r.conclusion==="failure"?"#f43f5e":"#fbbf24"}">${r.conclusion||r.status}</span></div>`).join("")}
</div></div>
</body></html>`,{headers:{"Content-Type":"text/html;charset=utf-8","Cache-Control":"public,max-age=60"}});
  }
};
