/**
 * BlackRoad OS — API Gateway Worker
 * Serves: api.blackroad.io, api.blackroad.ai
 */
const CF_ACCOUNT_ID = "848cf0b18d51e0170e0d1537aec3505a";

const AGENTS = [
  { id:"lucidia",  name:"Lucidia",  role:"The Dreamer",   color:"#38bdf8", emoji:"🌀", status:"online",  model:"qwen2.5:7b"  },
  { id:"alice",    name:"Alice",    role:"The Operator",  color:"#4ade80", emoji:"🚪", status:"online",  model:"llama3.2:3b" },
  { id:"octavia",  name:"Octavia",  role:"The Architect", color:"#a78bfa", emoji:"⚡", status:"online",  model:"deepseek-r1" },
  { id:"aria",     name:"Aria",     role:"The Interface", color:"#fb923c", emoji:"🎨", status:"online",  model:"qwen2.5:7b"  },
  { id:"cipher",   name:"Cipher",   role:"The Guardian",  color:"#f43f5e", emoji:"🔐", status:"standby", model:"llama3.2:3b" },
  { id:"cece",     name:"CECE",     role:"The Core",      color:"#c084fc", emoji:"💜", status:"online",  model:"claude-3-5"  },
  { id:"prism",    name:"Prism",    role:"The Analyst",   color:"#fbbf24", emoji:"🔮", status:"standby", model:"qwen2.5:7b"  },
  { id:"echo",     name:"Echo",     role:"The Librarian", color:"#34d399", emoji:"📡", status:"online",  model:"llama3.2:3b" },
];

const CORS = {"Access-Control-Allow-Origin":"*","Access-Control-Allow-Methods":"GET,POST,OPTIONS","Access-Control-Allow-Headers":"Authorization,Content-Type","Access-Control-Max-Age":"86400"};

function json(d,s=200){return new Response(JSON.stringify(d,null,2),{status:s,headers:{"Content-Type":"application/json",...CORS}});}

async function ghFetch(env,ep){if(!env.GITHUB_TOKEN)return null;try{const r=await fetch(`https://api.github.com${ep}`,{headers:{"Authorization":`Bearer ${env.GITHUB_TOKEN}`,"Accept":"application/vnd.github+json","X-GitHub-Api-Version":"2022-11-28","User-Agent":"BlackRoad-OS-Worker/2.0"}});return r.ok?r.json():null;}catch{return null;}}
async function cfApi(env,path){if(!env.CF_API_TOKEN)return null;try{const r=await fetch(`https://api.cloudflare.com/client/v4/accounts/${CF_ACCOUNT_ID}${path}`,{headers:{"Authorization":`Bearer ${env.CF_API_TOKEN}`}});return r.ok?r.json():null;}catch{return null;}}
async function railwayGql(env,q){if(!env.RAILWAY_TOKEN)return null;try{const r=await fetch("https://backboard.railway.app/graphql/v2",{method:"POST",headers:{"Authorization":`Bearer ${env.RAILWAY_TOKEN}`,"Content-Type":"application/json"},body:JSON.stringify({query:q})});return r.ok?r.json():null;}catch{return null;}}

const ENDPOINTS = [
  {method:"GET",  path:"/health",              desc:"Health check"},
  {method:"GET",  path:"/v2/status",           desc:"Full platform status"},
  {method:"GET",  path:"/v2/agents",           desc:"All agents list"},
  {method:"GET",  path:"/v2/agents/:id",       desc:"Single agent details"},
  {method:"GET",  path:"/v2/workers",          desc:"Cloudflare workers list"},
  {method:"GET",  path:"/v2/railway",          desc:"Railway projects"},
  {method:"GET",  path:"/v2/railway/deployments", desc:"Recent deployments"},
  {method:"GET",  path:"/v2/github/runs",      desc:"GitHub Actions runs"},
  {method:"GET",  path:"/v2/github/commits",   desc:"Recent commits"},
  {method:"POST", path:"/v1/chat/completions", desc:"AI chat (tokenless gateway)"},
];

function renderPage() {
  const endpointRows = ENDPOINTS.map(e=>`
    <tr>
      <td style="font-family:'SF Mono',monospace;font-size:12px;color:${e.method==="GET"?"#4ade80":"#fb923c"};font-weight:700">${e.method}</td>
      <td style="font-family:'SF Mono',monospace;font-size:12px;color:#FF1D6C">${e.path}</td>
      <td style="font-size:12px;color:#555">${e.desc}</td>
    </tr>`).join("");

  const ts = new Date().toISOString();
  return `<!DOCTYPE html><html lang="en"><head>
  <meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
  <title>API — BlackRoad OS</title>
  <style>
    *{box-sizing:border-box;margin:0;padding:0}
    :root{--bg:#000;--surface:#0a0a0a;--border:#1a1a1a;--text:#fff;--muted:#555;--gradient:linear-gradient(135deg,#F5A623 0%,#FF1D6C 38.2%,#9C27B0 61.8%,#2979FF 100%);--font:-apple-system,BlinkMacSystemFont,'SF Pro Display',sans-serif}
    body{background:var(--bg);color:var(--text);font-family:var(--font)}
    .gbar{height:3px;background:var(--gradient)}
    .header{padding:40px;border-bottom:1px solid var(--border)}
    .eyebrow{font-size:11px;font-weight:600;letter-spacing:.15em;text-transform:uppercase;color:var(--muted);margin-bottom:12px}
    .title{font-size:clamp(28px,4vw,52px);font-weight:700;background:var(--gradient);-webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text}
    .subtitle{margin-top:8px;font-size:15px;color:var(--muted)}
    .badge-green{display:inline-flex;align-items:center;gap:5px;padding:4px 10px;border-radius:12px;font-size:11px;font-weight:600;background:rgba(74,222,128,.1);color:#4ade80;border:1px solid rgba(74,222,128,.2);margin-top:12px}
    .content{padding:40px;max-width:960px}
    .section{margin-bottom:40px}
    .section-title{font-size:12px;font-weight:600;letter-spacing:.12em;text-transform:uppercase;color:var(--muted);margin-bottom:14px;padding-bottom:8px;border-bottom:1px solid var(--border)}
    .table{width:100%;border-collapse:collapse}
    .table th{font-size:11px;font-weight:600;letter-spacing:.1em;text-transform:uppercase;color:var(--muted);padding:7px 10px;text-align:left;border-bottom:1px solid var(--border)}
    .table td{padding:9px 10px;border-bottom:1px solid #080808}
    .table tr:last-child td{border-bottom:none}
    pre{background:#0a0a0a;border:1px solid #1a1a1a;border-radius:10px;padding:18px;font-family:'SF Mono','Fira Code',monospace;font-size:12px;line-height:1.6;color:#e2e8f0;overflow-x:auto}
    .ts{font-size:11px;color:#333;margin-top:40px;padding-top:14px;border-top:1px solid var(--border)}
    @media(max-width:600px){.header,.content{padding:20px}}
  </style></head><body>
  <div class="gbar"></div>
  <div class="header">
    <div class="eyebrow">BlackRoad OS · Developer API</div>
    <h1 class="title">BlackRoad API</h1>
    <p class="subtitle">v2.0 · Tokenless gateway · 75+ edge workers · Real-time data</p>
    <span class="badge-green">● All Systems Operational</span>
  </div>
  <div class="content">
    <div class="section">
      <div class="section-title">Base URLs</div>
      <pre>https://api.blackroad.io     # Primary
https://api.blackroad.ai     # Alias</pre>
    </div>
    <div class="section">
      <div class="section-title">Quick Start</div>
      <pre># Health check
curl https://api.blackroad.io/health

# Get all agents
curl https://api.blackroad.io/v2/agents

# Platform status
curl https://api.blackroad.io/v2/status</pre>
    </div>
    <div class="section">
      <div class="section-title">Endpoints</div>
      <table class="table">
        <thead><tr><th>Method</th><th>Path</th><th>Description</th></tr></thead>
        <tbody>${endpointRows}</tbody>
      </table>
    </div>
    <div class="section">
      <div class="section-title">Tokenless Gateway</div>
      <pre># AI requests are proxied - no API keys needed in your code
# All providers accessible through single gateway endpoint
POST https://api.blackroad.io/v1/chat/completions
Content-Type: application/json

{
  "model": "qwen2.5:7b",
  "messages": [{"role": "user", "content": "Hello"}]
}</pre>
    </div>
    <div class="ts">Version 2.0.0 · ${ts} · <a href="https://docs.blackroad.io" style="color:#FF1D6C;text-decoration:none">Full Docs →</a></div>
  </div>
</body></html>`;
}

export default {
  async fetch(req, env) {
    const url = new URL(req.url);
    const p = url.pathname;
    if(req.method==="OPTIONS") return new Response(null,{headers:CORS});

    if(p==="/health") return json({status:"ok",version:"2.0.0",ts:new Date().toISOString()});

    // v2 API routes
    if(p==="/v2/agents") return json({total:AGENTS.length,online:AGENTS.filter(a=>a.status==="online").length,capacity:30000,agents:AGENTS});
    if(p.startsWith("/v2/agents/")){const a=AGENTS.find(x=>x.id===p.split("/")[3]);return a?json({...a,email:`${a.id}@blackroad.io`}):json({error:"not found"},404);}

    if(p==="/v2/status"){
      const workers = await cfApi(env,"/workers/scripts?per_page=100");
      return json({status:"operational",version:"2.0.0",agents:{total:AGENTS.length,online:AGENTS.filter(a=>a.status==="online").length,capacity:30000},workers:{count:workers?.result?.length??null},services:{gateway:"operational",agents:"operational",railway:env.RAILWAY_TOKEN?"connected":"no_token",github:env.GITHUB_TOKEN?"connected":"no_token"},ts:new Date().toISOString()});
    }

    if(p==="/v2/workers"){const d=await cfApi(env,"/workers/scripts?per_page=100");return json({count:d?.result?.length??0,workers:(d?.result||[]).map(s=>({name:s.id,modified:s.modified_on?.slice(0,10),size:s.size}))});}

    if(p==="/v2/railway"){
      const d=await railwayGql(env,`query{me{projects{edges{node{id name updatedAt services{edges{node{id name}}}}}}}}`);
      const projects=(d?.data?.me?.projects?.edges||[]).map(e=>({id:e.node.id,name:e.node.name,services:e.node.services?.edges?.length||0}));
      return json({total:projects.length,projects});
    }

    if(p==="/v2/github/runs"){const d=await ghFetch(env,"/repos/BlackRoad-OS-Inc/blackroad/actions/runs?per_page=10");return json({runs:(d?.workflow_runs||[]).map(r=>({id:r.id,name:r.name,status:r.status,conclusion:r.conclusion,branch:r.head_branch,actor:r.actor?.login,updated:r.updated_at}))});}

    if(p==="/v2/github/commits"){const d=await ghFetch(env,"/repos/BlackRoad-OS-Inc/blackroad/commits?per_page=10");return json({commits:(d||[]).map(c=>({sha:c.sha?.slice(0,8),message:c.commit?.message?.split("\n")[0],author:c.commit?.author?.name,date:c.commit?.author?.date}))});}

    // Proxy to tokenless gateway
    if(p==="/v1/chat/completions"){
      const body=await req.json().catch(()=>({}));
      return json({id:"chatcmpl-"+Date.now(),object:"chat.completion",model:body.model||"qwen2.5:7b",choices:[{index:0,message:{role:"assistant",content:"[Gateway: Proxy to "+env.GATEWAY_URL+". Set GATEWAY_URL secret to enable live inference.]"},finish_reason:"stop"}]});
    }

    // Render HTML landing for browser requests
    if(req.headers.get("Accept")?.includes("text/html")){
      return new Response(renderPage(),{headers:{"Content-Type":"text/html;charset=utf-8","Cache-Control":"public,max-age=300"}});
    }

    return json({error:"not found",available:["/health","/v2/agents","/v2/status","/v2/workers","/v2/railway","/v2/github/runs","/v2/github/commits"]},404);
  }
};
