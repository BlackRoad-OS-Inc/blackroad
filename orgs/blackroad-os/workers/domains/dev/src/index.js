const CORS={"Access-Control-Allow-Origin":"*"};
function json(d){return new Response(JSON.stringify(d),{headers:{"Content-Type":"application/json",...CORS}});}
async function ghFetch(env,ep){if(!env.GITHUB_TOKEN)return null;try{const r=await fetch(`https://api.github.com${ep}`,{headers:{"Authorization":`Bearer ${env.GITHUB_TOKEN}`,"Accept":"application/vnd.github+json","User-Agent":"BlackRoad-OS-Worker/2.0"}});return r.ok?r.json():null;}catch{return null;}}
const TOOLS=[{name:"br CLI",desc:"37 tools — agents, deploy, git, docker, cloud, IoT, security, perf",url:"https://console.blackroad.io"},{name:"Skills SDK",desc:"@blackroad/skills-sdk — memory, reasoning, coordination",url:"https://ai.blackroad.io"},{name:"API Gateway",desc:"Tokenless AI gateway — all providers, no keys in code",url:"https://api.blackroad.io"},{name:"MCP Bridge",desc:"Local MCP server for remote agent access",url:"https://docs.blackroad.io"},{name:"Agent Mesh",desc:"30K agents, pub/sub, task marketplace",url:"https://agents.blackroad.io"},{name:"CECE Identity",desc:"Portable AI identity across providers",url:"https://docs.blackroad.io/cece"}];
export default {
  async fetch(req,env){
    const {pathname:p}=new URL(req.url);
    if(p==="/health") return json({status:"ok"});
    if(p==="/api/tools") return json(TOOLS);
    const commits=await ghFetch(env,"/repos/BlackRoad-OS-Inc/blackroad/commits?per_page=10");
    const recentCommits=(commits||[]).map(c=>({sha:c.sha?.slice(0,8),msg:c.commit?.message?.split("\n")[0],author:c.commit?.author?.name,date:c.commit?.author?.date?.slice(0,10)}));
    return new Response(`<!DOCTYPE html><html><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Dev — BlackRoad OS</title><style>*{box-sizing:border-box;margin:0;padding:0}body{background:#000;color:#fff;font-family:-apple-system,sans-serif}.gbar{height:3px;background:linear-gradient(135deg,#F5A623,#FF1D6C,#9C27B0,#2979FF)}.header{padding:40px;border-bottom:1px solid #1a1a1a}.title{font-size:42px;font-weight:700;background:linear-gradient(135deg,#F5A623,#FF1D6C,#9C27B0,#2979FF);-webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text}.layout{display:grid;grid-template-columns:1fr 360px;gap:40px;padding:40px}.section-title{font-size:11px;font-weight:600;letter-spacing:.12em;text-transform:uppercase;color:#555;margin-bottom:14px;padding-bottom:8px;border-bottom:1px solid #1a1a1a}.card{background:#0a0a0a;border:1px solid #1a1a1a;border-radius:12px;padding:16px 20px;margin-bottom:12px}.card-name{font-size:14px;font-weight:600;color:#FF1D6C;margin-bottom:4px}.card-desc{font-size:12px;color:#666}.commit{display:flex;justify-content:space-between;padding:8px 0;border-bottom:1px solid #0a0a0a;font-size:12px}.sha{font-family:'SF Mono',monospace;color:#9C27B0}.msg{color:#aaa;flex:1;margin:0 12px;overflow:hidden;white-space:nowrap;text-overflow:ellipsis}.date{color:#333}@media(max-width:900px){.layout{grid-template-columns:1fr}}</style></head><body>
<div class="gbar"></div>
<div class="header"><div style="font-size:11px;font-weight:600;letter-spacing:.15em;text-transform:uppercase;color:#555;margin-bottom:12px">BlackRoad OS · Developer Hub</div><h1 class="title">Dev Portal</h1><p style="color:#555;font-size:15px;margin-top:8px">Tools, SDKs, APIs, and documentation for building with BlackRoad OS</p></div>
<div class="layout"><div>
<div class="section-title">Developer Tools</div>
${TOOLS.map(t=>`<div class="card"><div class="card-name"><a href="${t.url}" style="color:#FF1D6C;text-decoration:none">${t.name}</a></div><div class="card-desc">${t.desc}</div></div>`).join("")}
</div><div>
<div class="section-title">Recent Commits</div>
${recentCommits.map(c=>`<div class="commit"><span class="sha">${c.sha}</span><span class="msg">${c.msg}</span><span class="date">${c.date}</span></div>`).join("")}
<div class="section-title" style="margin-top:24px">Quick Links</div>
${[["docs.blackroad.io","Documentation"],["api.blackroad.io","API Reference"],["console.blackroad.io","BR Console"],["agents.blackroad.io","Agent Mesh"]].map(([u,l])=>`<a href="https://${u}" style="display:block;padding:9px 14px;background:#0a0a0a;border:1px solid #1a1a1a;border-radius:8px;color:#aaa;text-decoration:none;font-size:12px;margin-bottom:8px">${l} →</a>`).join("")}
</div></div>
</body></html>`,{headers:{"Content-Type":"text/html;charset=utf-8","Cache-Control":"public,max-age=180"}});
  }
};
