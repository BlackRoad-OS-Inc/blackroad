/**
 * BlackRoad OS — Agents Worker
 * Serves: agents.blackroad.io
 */
const CF_ACCOUNT_ID = "848cf0b18d51e0170e0d1537aec3505a";

const AGENTS = [
  { id:"lucidia",  name:"Lucidia",  role:"The Dreamer",   color:"#38bdf8", emoji:"🌀", status:"online",  model:"qwen2.5:7b",   tasks:847  },
  { id:"alice",    name:"Alice",    role:"The Operator",  color:"#4ade80", emoji:"🚪", status:"online",  model:"llama3.2:3b",  tasks:12453 },
  { id:"octavia",  name:"Octavia",  role:"The Architect", color:"#a78bfa", emoji:"⚡", status:"online",  model:"deepseek-r1",  tasks:3291  },
  { id:"aria",     name:"Aria",     role:"The Interface", color:"#fb923c", emoji:"🎨", status:"online",  model:"qwen2.5:7b",   tasks:2104  },
  { id:"cipher",   name:"Cipher",   role:"The Guardian",  color:"#f43f5e", emoji:"🔐", status:"standby", model:"llama3.2:3b",  tasks:8932  },
  { id:"cece",     name:"CECE",     role:"The Core",      color:"#c084fc", emoji:"💜", status:"online",  model:"claude-3-5",   tasks:1200  },
  { id:"prism",    name:"Prism",    role:"The Analyst",   color:"#fbbf24", emoji:"🔮", status:"standby", model:"qwen2.5:7b",   tasks:1876  },
  { id:"echo",     name:"Echo",     role:"The Librarian", color:"#34d399", emoji:"📡", status:"online",  model:"llama3.2:3b",  tasks:1543  },
];

function json(data,s=200){return new Response(JSON.stringify(data,null,2),{status:s,headers:{"Content-Type":"application/json","Access-Control-Allow-Origin":"*"}});}
async function ghFetch(env,ep){if(!env.GITHUB_TOKEN)return null;try{const r=await fetch(`https://api.github.com${ep}`,{headers:{"Authorization":`Bearer ${env.GITHUB_TOKEN}`,"Accept":"application/vnd.github+json","X-GitHub-Api-Version":"2022-11-28","User-Agent":"BlackRoad-OS-Worker/2.0"}});return r.ok?r.json():null;}catch{return null;}}

function renderPage(commits) {
  const online = AGENTS.filter(a=>a.status==="online").length;
  const totalTasks = AGENTS.reduce((s,a)=>s+a.tasks,0);
  const agentCards = AGENTS.map(a=>`
    <div class="agent-card" style="--accent:${a.color}">
      <div class="agent-header">
        <span class="agent-emoji">${a.emoji}</span>
        <div>
          <div class="agent-name">${a.name}</div>
          <div class="agent-role">${a.role}</div>
        </div>
        <span class="badge ${a.status==="online"?"green":"yellow"}">${a.status}</span>
      </div>
      <div class="agent-meta">
        <span class="meta-item">🤖 ${a.model}</span>
        <span class="meta-item">⚡ ${a.tasks.toLocaleString()} tasks/day</span>
        <span class="meta-item">📧 ${a.id}@blackroad.io</span>
      </div>
      <div class="agent-bar"><div style="width:${Math.min(100,a.tasks/150)}%;background:${a.color};height:2px;border-radius:1px"></div></div>
    </div>`).join("");

  const commitFeed = (commits||[]).slice(0,8).map(c=>`
    <div class="feed-item">
      <span class="feed-sha">${(c.sha||"").slice(0,7)}</span>
      <span class="feed-msg">${(c.commit?.message||"").split("\n")[0].slice(0,70)}</span>
      <span class="feed-author">${c.commit?.author?.name||""}</span>
    </div>`).join("");

  return `<!DOCTYPE html><html lang="en"><head>
  <meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
  <meta http-equiv="refresh" content="30">
  <title>Agent Mesh — BlackRoad OS</title>
  <style>
    *{box-sizing:border-box;margin:0;padding:0}
    :root{--amber:#F5A623;--pink:#FF1D6C;--violet:#9C27B0;--blue:#2979FF;--bg:#000;--surface:#0a0a0a;--border:#1a1a1a;--text:#fff;--muted:#555;--gradient:linear-gradient(135deg,var(--amber) 0%,var(--pink) 38.2%,var(--violet) 61.8%,var(--blue) 100%);--font:-apple-system,BlinkMacSystemFont,'SF Pro Display',sans-serif}
    body{background:var(--bg);color:var(--text);font-family:var(--font);min-height:100vh}
    .gbar{height:3px;background:var(--gradient)}
    .header{padding:40px;border-bottom:1px solid var(--border)}
    .eyebrow{font-size:11px;font-weight:600;letter-spacing:.15em;text-transform:uppercase;color:var(--muted);margin-bottom:12px}
    .title{font-size:clamp(28px,4vw,52px);font-weight:700;background:var(--gradient);-webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text}
    .subtitle{margin-top:8px;font-size:15px;color:var(--muted)}
    .stats{display:flex;gap:1px;background:var(--border);border-top:1px solid var(--border);border-bottom:1px solid var(--border)}
    .stat{flex:1;background:var(--bg);padding:20px 28px}
    .stat-v{font-size:28px;font-weight:700}
    .stat-l{font-size:11px;font-weight:600;letter-spacing:.1em;text-transform:uppercase;color:var(--muted);margin-top:3px}
    .content{padding:40px}
    .section-title{font-size:12px;font-weight:600;letter-spacing:.12em;text-transform:uppercase;color:var(--muted);margin-bottom:16px;padding-bottom:8px;border-bottom:1px solid var(--border)}
    .agent-grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(300px,1fr));gap:14px}
    .agent-card{background:var(--surface);border:1px solid var(--border);border-top:2px solid var(--accent,var(--pink));border-radius:12px;padding:18px}
    .agent-header{display:flex;align-items:center;gap:12px;margin-bottom:12px}
    .agent-emoji{font-size:28px}
    .agent-name{font-size:16px;font-weight:700}
    .agent-role{font-size:12px;color:var(--muted)}
    .agent-meta{display:flex;flex-wrap:wrap;gap:8px;margin-bottom:10px}
    .meta-item{font-size:11px;color:var(--muted);background:#0d0d0d;padding:3px 8px;border-radius:6px}
    .badge{margin-left:auto;display:inline-flex;align-items:center;gap:4px;padding:3px 9px;border-radius:12px;font-size:10px;font-weight:600;white-space:nowrap}
    .badge::before{content:'';width:5px;height:5px;border-radius:50%;background:currentColor}
    .badge.green{background:rgba(74,222,128,.1);color:#4ade80;border:1px solid rgba(74,222,128,.2)}
    .badge.yellow{background:rgba(251,191,36,.1);color:#fbbf24;border:1px solid rgba(251,191,36,.2)}
    .feed{margin-top:32px}
    .feed-item{display:flex;align-items:baseline;gap:10px;padding:8px 0;border-bottom:1px solid #0d0d0d;font-size:13px}
    .feed-sha{font-family:'SF Mono',monospace;font-size:11px;color:var(--pink);min-width:52px}
    .feed-msg{flex:1;color:var(--text);white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
    .feed-author{font-size:11px;color:var(--muted);min-width:80px;text-align:right}
    .footer-ts{font-size:11px;color:var(--muted);margin-top:40px;padding-top:16px;border-top:1px solid var(--border)}
    @media(max-width:600px){.header,.content{padding:24px}.stats{flex-wrap:wrap}}
  </style></head><body>
  <div class="gbar"></div>
  <div class="header">
    <div class="eyebrow">BlackRoad OS · Agent Mesh</div>
    <h1 class="title">Agent Mesh</h1>
    <p class="subtitle">30,000 capacity · ${online}/${AGENTS.length} agents online · Real-time orchestration</p>
  </div>
  <div class="stats">
    <div class="stat"><div class="stat-v">${AGENTS.length}</div><div class="stat-l">Total Agents</div></div>
    <div class="stat"><div class="stat-v" style="color:#4ade80">${online}</div><div class="stat-l">Online</div></div>
    <div class="stat"><div class="stat-v">${AGENTS.length-online}</div><div class="stat-l">Standby</div></div>
    <div class="stat"><div class="stat-v">30,000</div><div class="stat-l">Capacity</div></div>
    <div class="stat"><div class="stat-v">${totalTasks.toLocaleString()}</div><div class="stat-l">Tasks/Day</div></div>
  </div>
  <div class="content">
    <div class="section-title">Active Agents</div>
    <div class="agent-grid">${agentCards}</div>
    ${commits?.length ? `<div class="feed"><div class="section-title" style="margin-top:40px">Live Activity Feed</div>${commitFeed}</div>`:""}
    <div class="footer-ts">Updated ${new Date().toISOString()} · <a href="https://blackroad.io" style="color:var(--pink);text-decoration:none">blackroad.io</a></div>
  </div>
</body></html>`;
}

export default {
  async fetch(req, env) {
    const {pathname:path} = new URL(req.url);
    if(req.method==="OPTIONS") return new Response(null,{headers:{"Access-Control-Allow-Origin":"*","Access-Control-Allow-Methods":"GET"}});
    if(path==="/health") return json({status:"ok",ts:new Date().toISOString()});
    if(path==="/api"||path==="/api/agents") return json({total:AGENTS.length,online:AGENTS.filter(a=>a.status==="online").length,standby:AGENTS.filter(a=>a.status==="standby").length,capacity:30000,agents:AGENTS});
    if(path.startsWith("/api/")&&path.split("/").length===3){
      const id=path.split("/")[2];
      const agent=AGENTS.find(a=>a.id===id);
      if(!agent) return json({error:"not found",id},404);
      return json({...agent,email:`${id}@blackroad.io`,endpoint:`https://agents.blackroad.io/api/${id}`});
    }
    if(path==="/api/mesh") return json({status:"operational",capacity:30000,online:AGENTS.filter(a=>a.status==="online").length,agents:AGENTS.map(a=>({id:a.id,status:a.status,model:a.model})),ts:new Date().toISOString()});
    const commits = await ghFetch(env,"/repos/BlackRoad-OS-Inc/blackroad/commits?per_page=10");
    return new Response(renderPage(commits||[]),{headers:{"Content-Type":"text/html;charset=utf-8","Cache-Control":"public,max-age=30"}});
  }
};
