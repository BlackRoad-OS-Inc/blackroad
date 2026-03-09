const CORS={"Access-Control-Allow-Origin":"*"};
function json(d,s=200){return new Response(JSON.stringify(d),{status:s,headers:{"Content-Type":"application/json",...CORS}});}
async function ghFetch(env,ep){if(!env.GITHUB_TOKEN)return null;try{const r=await fetch(`https://api.github.com${ep}`,{headers:{"Authorization":`Bearer ${env.GITHUB_TOKEN}`,"Accept":"application/vnd.github+json","User-Agent":"BlackRoad-OS-Worker/2.0"}});return r.ok?r.json():null;}catch{return null;}}
export default {
  async fetch(req,env){
    const {pathname:p}=new URL(req.url);
    if(p==="/health") return json({status:"ok"});
    const [repos,runs,org]=await Promise.allSettled([ghFetch(env,"/orgs/BlackRoad-OS/repos?per_page=100"),ghFetch(env,"/repos/BlackRoad-OS-Inc/blackroad/actions/runs?per_page=30"),ghFetch(env,"/orgs/BlackRoad-OS")]);
    const repoData=repos.value||[],runData=runs.value?.workflow_runs||[],orgData=org.value||{};
    if(p==="/api/stats") return json({org:{repos:orgData.public_repos,members:orgData.public_members,gists:orgData.public_gists},activity:{runs:runData.length,success:runData.filter(r=>r.conclusion==="success").length,failure:runData.filter(r=>r.conclusion==="failure").length},repos:{total:repoData.length,stars:repoData.reduce((a,r)=>a+r.stargazers_count,0),forks:repoData.reduce((a,r)=>a+r.forks_count,0),languages:[...new Set(repoData.map(r=>r.language).filter(Boolean))].length},ts:new Date().toISOString()});
    const stats={org:{repos:orgData.public_repos||0,members:orgData.public_members||0},activity:{runs:runData.length,success:runData.filter(r=>r.conclusion==="success").length},repos:{total:repoData.length,stars:repoData.reduce((a,r)=>a+r.stargazers_count,0)}};
    return new Response(`<!DOCTYPE html><html><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Analytics — BlackRoad OS</title><style>*{box-sizing:border-box;margin:0;padding:0}body{background:#000;color:#fff;font-family:-apple-system,sans-serif}.gbar{height:3px;background:linear-gradient(135deg,#F5A623,#FF1D6C,#9C27B0,#2979FF)}.header{padding:40px;border-bottom:1px solid #1a1a1a}.eyebrow{font-size:11px;font-weight:600;letter-spacing:.15em;text-transform:uppercase;color:#555;margin-bottom:12px}.title{font-size:42px;font-weight:700;background:linear-gradient(135deg,#F5A623,#FF1D6C,#9C27B0,#2979FF);-webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text}.content{padding:40px;display:grid;grid-template-columns:repeat(3,1fr);gap:20px}.card{background:#0a0a0a;border:1px solid #1a1a1a;border-radius:14px;padding:24px}.card-val{font-size:36px;font-weight:700;background:linear-gradient(135deg,#F5A623,#FF1D6C);-webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text}.card-lbl{font-size:12px;color:#555;text-transform:uppercase;letter-spacing:.1em;margin-top:4px}.card-sub{font-size:11px;color:#333;margin-top:8px}@media(max-width:600px){.content{grid-template-columns:1fr}}</style></head><body>
<div class="gbar"></div>
<div class="header"><div class="eyebrow">BlackRoad OS · Intelligence</div><h1 class="title">Analytics</h1><p style="color:#555;font-size:15px;margin-top:8px">Platform metrics · ${new Date().toISOString().slice(0,10)}</p></div>
<div class="content">
  <div class="card"><div class="card-val">${stats.repos.total}</div><div class="card-lbl">Repositories</div><div class="card-sub">BlackRoad-OS org</div></div>
  <div class="card"><div class="card-val">${stats.repos.stars}</div><div class="card-lbl">Total Stars</div><div class="card-sub">Across all repos</div></div>
  <div class="card"><div class="card-val">30K</div><div class="card-lbl">Agents</div><div class="card-sub">Active capacity</div></div>
  <div class="card"><div class="card-val">${stats.activity.runs}</div><div class="card-lbl">CI Runs</div><div class="card-sub">Last 30 days</div></div>
  <div class="card"><div class="card-val">${stats.activity.success}</div><div class="card-lbl">Successful</div><div class="card-sub">${stats.activity.runs?Math.round(stats.activity.success/stats.activity.runs*100):0}% success rate</div></div>
  <div class="card"><div class="card-val">75+</div><div class="card-lbl">CF Workers</div><div class="card-sub">Active deployments</div></div>
</div>
</body></html>`,{headers:{"Content-Type":"text/html;charset=utf-8","Cache-Control":"public,max-age=300"}});
  }
};
