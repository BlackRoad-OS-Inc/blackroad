/**
 * BlackRoad OS — Dashboard Worker
 * Serves: dashboard.blackroad.io
 */
const CF_ACCOUNT_ID = "848cf0b18d51e0170e0d1537aec3505a";

function json(d,s=200){return new Response(JSON.stringify(d,null,2),{status:s,headers:{"Content-Type":"application/json","Access-Control-Allow-Origin":"*"}});}
async function gh(env,ep){if(!env.GITHUB_TOKEN)return null;try{const r=await fetch(`https://api.github.com${ep}`,{headers:{"Authorization":`Bearer ${env.GITHUB_TOKEN}`,"Accept":"application/vnd.github+json","X-GitHub-Api-Version":"2022-11-28","User-Agent":"BlackRoad-OS-Worker/2.0"}});return r.ok?r.json():null;}catch{return null;}}
async function railway(env){if(!env.RAILWAY_TOKEN)return null;try{const r=await fetch("https://backboard.railway.app/graphql/v2",{method:"POST",headers:{"Authorization":`Bearer ${env.RAILWAY_TOKEN}`,"Content-Type":"application/json"},body:JSON.stringify({query:`query{me{projects{edges{node{id name updatedAt services{edges{node{id name}}}}}}}}}`})});return r.ok?r.json():null;}catch{return null;}}
async function cf(env,path){if(!env.CF_API_TOKEN)return null;try{const r=await fetch(`https://api.cloudflare.com/client/v4/accounts/${CF_ACCOUNT_ID}${path}`,{headers:{"Authorization":`Bearer ${env.CF_API_TOKEN}`}});return r.ok?r.json():null;}catch{return null;}}

function ago(iso){if(!iso)return"";const m=Math.floor((Date.now()-new Date(iso))/60000);if(m<1)return"just now";if(m<60)return`${m}m`;const h=Math.floor(m/60);if(h<24)return`${h}h`;return`${Math.floor(h/24)}d`;}
function ciColor(c){return c==="success"?"#4ade80":c==="failure"?"#f43f5e":"#fbbf24";}
function ciIcon(c){return c==="success"?"✅":c==="failure"?"❌":c==="in_progress"?"🔄":"⏸";}

function renderPage(runs, commits, projects, workerCount) {
  const latest = runs?.[0];
  const ciPass = (runs||[]).filter(r=>r.conclusion==="success").length;
  const ciFail = (runs||[]).filter(r=>r.conclusion==="failure").length;

  const runRows = (runs||[]).slice(0,12).map(r=>`
    <tr>
      <td style="max-width:240px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap">${r.name}</td>
      <td><span style="color:${ciColor(r.conclusion)};font-size:11px;font-weight:700">${ciIcon(r.conclusion)} ${r.conclusion||r.status}</span></td>
      <td style="color:#555;font-size:12px;font-family:'SF Mono',monospace">${r.head_branch}</td>
      <td style="color:#555;font-size:12px">${r.actor?.login||""}</td>
      <td style="color:#444;font-size:12px">${ago(r.updated_at)}</td>
    </tr>`).join("");

  const commitRows = (commits||[]).slice(0,8).map(c=>`
    <tr>
      <td style="font-family:'SF Mono',monospace;font-size:11px;color:#FF1D6C">${(c.sha||"").slice(0,7)}</td>
      <td style="max-width:300px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;font-size:13px">${(c.commit?.message||"").split("\n")[0].slice(0,80)}</td>
      <td style="color:#555;font-size:12px">${c.commit?.author?.name||""}</td>
      <td style="color:#444;font-size:12px">${ago(c.commit?.author?.date)}</td>
    </tr>`).join("");

  const projectCards = (projects||[]).slice(0,14).map(p=>`
    <div style="background:#0a0a0a;border:1px solid #1a1a1a;border-radius:10px;padding:14px 16px">
      <div style="font-size:13px;font-weight:600">⚡ ${p.name}</div>
      <div style="font-size:11px;color:#555;margin-top:4px">${p.services} service${p.services!==1?"s":""}</div>
    </div>`).join("");

  const ts = new Date().toISOString();
  return `<!DOCTYPE html><html lang="en"><head>
  <meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
  <meta http-equiv="refresh" content="60">
  <title>Dashboard — BlackRoad OS</title>
  <style>
    *{box-sizing:border-box;margin:0;padding:0}
    :root{--bg:#000;--surface:#0a0a0a;--border:#1a1a1a;--text:#fff;--muted:#555;--gradient:linear-gradient(135deg,#F5A623 0%,#FF1D6C 38.2%,#9C27B0 61.8%,#2979FF 100%);--font:-apple-system,BlinkMacSystemFont,'SF Pro Display',sans-serif}
    body{background:var(--bg);color:var(--text);font-family:var(--font);min-height:100vh}
    .gbar{height:3px;background:var(--gradient)}
    .header{padding:36px 40px;border-bottom:1px solid var(--border)}
    .eyebrow{font-size:11px;font-weight:600;letter-spacing:.15em;text-transform:uppercase;color:var(--muted);margin-bottom:10px}
    .title{font-size:clamp(24px,3vw,40px);font-weight:700;background:var(--gradient);-webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text}
    .stats{display:flex;gap:1px;background:var(--border);border-bottom:1px solid var(--border)}
    .stat{flex:1;background:var(--bg);padding:20px 24px}
    .stat-v{font-size:24px;font-weight:700}
    .stat-l{font-size:11px;font-weight:600;letter-spacing:.1em;text-transform:uppercase;color:var(--muted);margin-top:3px}
    .content{padding:32px 40px}
    .section{margin-bottom:40px}
    .section-title{font-size:12px;font-weight:600;letter-spacing:.12em;text-transform:uppercase;color:var(--muted);margin-bottom:14px;padding-bottom:8px;border-bottom:1px solid var(--border)}
    .table{width:100%;border-collapse:collapse}
    .table th{font-size:11px;font-weight:600;letter-spacing:.1em;text-transform:uppercase;color:var(--muted);padding:7px 10px;text-align:left;border-bottom:1px solid var(--border)}
    .table td{padding:9px 10px;border-bottom:1px solid #080808}
    .table tr:last-child td{border-bottom:none}
    .project-grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(180px,1fr));gap:10px}
    .ts{font-size:11px;color:#333;margin-top:40px;padding-top:14px;border-top:1px solid var(--border)}
    @media(max-width:600px){.header,.content{padding:20px}.stats{flex-wrap:wrap}}
  </style></head><body>
  <div class="gbar"></div>
  <div class="header">
    <div class="eyebrow">BlackRoad OS · Operations</div>
    <h1 class="title">Dashboard</h1>
  </div>
  <div class="stats">
    <div class="stat"><div class="stat-v" style="color:${latest?.conclusion==="success"?"#4ade80":"#fbbf24"}">${latest?.conclusion||"—"}</div><div class="stat-l">Latest CI</div></div>
    <div class="stat"><div class="stat-v" style="color:#4ade80">${ciPass}</div><div class="stat-l">Passing</div></div>
    <div class="stat"><div class="stat-v" style="color:#f43f5e">${ciFail}</div><div class="stat-l">Failing</div></div>
    <div class="stat"><div class="stat-v">${projects?.length??0}</div><div class="stat-l">Railway Projects</div></div>
    <div class="stat"><div class="stat-v">${workerCount??0}</div><div class="stat-l">CF Workers</div></div>
  </div>
  <div class="content">
    ${runs?.length?`<div class="section"><div class="section-title">CI/CD Runs — BlackRoad-OS-Inc/blackroad</div>
    <table class="table"><thead><tr><th>Workflow</th><th>Status</th><th>Branch</th><th>Actor</th><th>Updated</th></tr></thead>
    <tbody>${runRows}</tbody></table></div>`:""}
    ${commits?.length?`<div class="section"><div class="section-title">Recent Commits</div>
    <table class="table"><thead><tr><th>SHA</th><th>Message</th><th>Author</th><th>When</th></tr></thead>
    <tbody>${commitRows}</tbody></table></div>`:""}
    ${projects?.length?`<div class="section"><div class="section-title">Railway Projects (${projects.length})</div>
    <div class="project-grid">${projectCards}</div></div>`:""}
    <div class="ts">Last updated: ${ts} · Auto-refreshes every 60s</div>
  </div>
</body></html>`;
}

export default {
  async fetch(req, env) {
    const {pathname:p} = new URL(req.url);
    if(req.method==="OPTIONS") return new Response(null,{headers:{"Access-Control-Allow-Origin":"*"}});
    if(p==="/health") return json({status:"ok",ts:new Date().toISOString()});

    const [runsRes, commitsRes, railwayRes, cfRes] = await Promise.allSettled([
      gh(env,"/repos/BlackRoad-OS-Inc/blackroad/actions/runs?per_page=15"),
      gh(env,"/repos/BlackRoad-OS-Inc/blackroad/commits?per_page=10"),
      railway(env),
      cf(env,"/workers/scripts?per_page=100"),
    ]);

    const runs = runsRes.value?.workflow_runs||[];
    const commits = commitsRes.value||[];
    const projects = (railwayRes.value?.data?.me?.projects?.edges||[]).map(e=>({id:e.node.id,name:e.node.name,services:e.node.services?.edges?.length||0}));
    const workerCount = cfRes.value?.result?.length||0;

    if(p==="/api") return json({runs:runs.slice(0,5),commits:commits.slice(0,5),projects,workers:{count:workerCount},ts:new Date().toISOString()});

    return new Response(renderPage(runs,commits,projects,workerCount),{headers:{"Content-Type":"text/html;charset=utf-8","Cache-Control":"public,max-age=60"}});
  }
};
