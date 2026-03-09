/**
 * BlackRoad OS — Console Worker
 * Serves: console.blackroad.io
 */
const CF_ACCOUNT_ID = "848cf0b18d51e0170e0d1537aec3505a";
function json(d,s=200){return new Response(JSON.stringify(d,null,2),{status:s,headers:{"Content-Type":"application/json","Access-Control-Allow-Origin":"*"}});}
async function cfApi(env,path){if(!env.CF_API_TOKEN)return null;try{const r=await fetch(`https://api.cloudflare.com/client/v4/accounts/${CF_ACCOUNT_ID}${path}`,{headers:{"Authorization":`Bearer ${env.CF_API_TOKEN}`}});return r.ok?r.json():null;}catch{return null;}}
async function ghFetch(env,ep){if(!env.GITHUB_TOKEN)return null;try{const r=await fetch(`https://api.github.com${ep}`,{headers:{"Authorization":`Bearer ${env.GITHUB_TOKEN}`,"Accept":"application/vnd.github+json","X-GitHub-Api-Version":"2022-11-28","User-Agent":"BlackRoad-OS-Worker/2.0"}});return r.ok?r.json():null;}catch{return null;}}

const COMMANDS = [
  {cat:"Agents",  cmd:"br agents list",           desc:"List all active agents"},
  {cat:"Agents",  cmd:"br agents status <id>",     desc:"Get agent status"},
  {cat:"Agents",  cmd:"br cece whoami",            desc:"Show CECE identity"},
  {cat:"Deploy",  cmd:"br deploy railway",         desc:"Deploy to Railway"},
  {cat:"Deploy",  cmd:"br deploy cloudflare",      desc:"Deploy to Cloudflare"},
  {cat:"Deploy",  cmd:"br deploy vercel",          desc:"Deploy to Vercel"},
  {cat:"Workers", cmd:"br workers list",           desc:"List CF workers"},
  {cat:"Workers", cmd:"br workers deploy <name>",  desc:"Deploy a worker"},
  {cat:"Workers", cmd:"br workers tail <name>",    desc:"Tail worker logs"},
  {cat:"Git",     cmd:"br git commit",             desc:"AI-powered smart commit"},
  {cat:"Git",     cmd:"br git pr",                 desc:"Create pull request"},
  {cat:"Git",     cmd:"br git review",             desc:"AI code review"},
  {cat:"Cloud",   cmd:"br cloudflare zones",       desc:"List Cloudflare zones"},
  {cat:"Cloud",   cmd:"br cloudflare deploy",      desc:"Deploy CF worker"},
  {cat:"Cloud",   cmd:"br ocean list",             desc:"List DigitalOcean droplets"},
  {cat:"IoT",     cmd:"br pi status",              desc:"Pi fleet health"},
  {cat:"IoT",     cmd:"br pi deploy",              desc:"Deploy to Pi fleet"},
  {cat:"IoT",     cmd:"br pi ssh <name>",          desc:"SSH to Pi device"},
  {cat:"DB",      cmd:"br db query <sql>",         desc:"Execute SQL query"},
  {cat:"DB",      cmd:"br db migrate",             desc:"Run migrations"},
  {cat:"Security",cmd:"br security scan",          desc:"Run security scan"},
  {cat:"Security",cmd:"br secrets vault list",     desc:"List vault secrets"},
  {cat:"Env",     cmd:"br env list",               desc:"List environment vars"},
  {cat:"Env",     cmd:"br env set <k> <v>",        desc:"Set environment variable"},
  {cat:"Perf",    cmd:"br perf monitor",           desc:"Performance monitoring"},
  {cat:"Logs",    cmd:"br logs tail",              desc:"Tail live logs"},
  {cat:"Domains", cmd:"br domains status",         desc:"Check domain health"},
  {cat:"Domains", cmd:"br domains route",          desc:"Route domains to Pi tunnel"},
  {cat:"Test",    cmd:"br test run",               desc:"Run test suite"},
  {cat:"Notify",  cmd:"br notify send <msg>",      desc:"Send notification"},
];

function renderPage(workers, runs) {
  const cats = [...new Set(COMMANDS.map(c=>c.cat))];
  const cmdSections = cats.map(cat=>{
    const cmds = COMMANDS.filter(c=>c.cat===cat);
    const rows = cmds.map(c=>`
      <tr>
        <td style="font-family:'SF Mono','Fira Code',monospace;font-size:12px;color:#FF1D6C;white-space:nowrap">${c.cmd}</td>
        <td style="font-size:12px;color:#666;padding-left:16px">${c.desc}</td>
      </tr>`).join("");
    return `<div style="margin-bottom:28px"><div style="font-size:11px;font-weight:600;letter-spacing:.1em;text-transform:uppercase;color:#555;margin-bottom:8px">${cat}</div>
      <table style="width:100%;border-collapse:collapse">${rows}</table></div>`;
  }).join("");

  const workerRows = (workers||[]).slice(0,20).map(w=>`
    <tr>
      <td style="font-family:'SF Mono',monospace;font-size:12px;color:#4ade80">${w.id}</td>
      <td style="font-size:12px;color:#555">${w.modified_on?.slice(0,10)||""}</td>
      <td style="font-size:12px;color:#444">${((w.size||0)/1024).toFixed(1)}KB</td>
    </tr>`).join("");

  const ts = new Date().toISOString();
  return `<!DOCTYPE html><html lang="en"><head>
  <meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
  <title>Console — BlackRoad OS</title>
  <style>
    *{box-sizing:border-box;margin:0;padding:0}
    :root{--bg:#000;--surface:#0a0a0a;--border:#1a1a1a;--text:#fff;--muted:#555;--gradient:linear-gradient(135deg,#F5A623 0%,#FF1D6C 38.2%,#9C27B0 61.8%,#2979FF 100%);--font:-apple-system,BlinkMacSystemFont,'SF Pro Display',sans-serif}
    body{background:var(--bg);color:var(--text);font-family:var(--font)}
    .gbar{height:3px;background:var(--gradient)}
    .header{padding:40px;border-bottom:1px solid var(--border)}
    .eyebrow{font-size:11px;font-weight:600;letter-spacing:.15em;text-transform:uppercase;color:var(--muted);margin-bottom:12px}
    .title{font-size:clamp(28px,4vw,52px);font-weight:700;background:var(--gradient);-webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text}
    .subtitle{margin-top:8px;font-size:15px;color:var(--muted)}
    .layout{display:grid;grid-template-columns:1fr 360px;gap:40px;padding:40px;max-width:1400px}
    .section-title{font-size:12px;font-weight:600;letter-spacing:.12em;text-transform:uppercase;color:var(--muted);margin-bottom:14px;padding-bottom:8px;border-bottom:1px solid var(--border);margin-top:32px}
    pre{background:#0a0a0a;border:1px solid var(--border);border-radius:10px;padding:16px 20px;font-family:'SF Mono','Fira Code',monospace;font-size:12px;line-height:1.6;color:#e2e8f0;overflow-x:auto;margin-bottom:24px}
    .table{width:100%;border-collapse:collapse}
    .table th{font-size:11px;font-weight:600;letter-spacing:.1em;text-transform:uppercase;color:var(--muted);padding:6px 8px;text-align:left;border-bottom:1px solid var(--border)}
    .table td{padding:8px 8px;border-bottom:1px solid #080808}
    .ts{font-size:11px;color:#333;margin-top:40px;padding-top:14px;border-top:1px solid var(--border)}
    @media(max-width:900px){.layout{grid-template-columns:1fr;padding:24px}}
  </style></head><body>
  <div class="gbar"></div>
  <div class="header">
    <div class="eyebrow">BlackRoad OS · CLI</div>
    <h1 class="title">BR Console</h1>
    <p class="subtitle">BlackRoad CLI Reference · 37 tools · All commands in one place</p>
  </div>
  <div class="layout">
    <div>
      <div class="section-title" style="margin-top:0">Installation</div>
      <pre># macOS/Linux
curl -fsSL https://cli.blackroad.io/install.sh | bash

# Or clone directly
git clone https://github.com/BlackRoad-OS-Inc/blackroad
cd blackroad && chmod +x br && ./br help</pre>
      <div class="section-title">Commands Reference</div>
      ${cmdSections}
      <div class="ts">Updated ${ts}</div>
    </div>
    <div>
      ${workers?.length?`<div class="section-title" style="margin-top:0">Deployed Workers (${workers.length})</div>
      <table class="table"><thead><tr><th>Name</th><th>Modified</th><th>Size</th></tr></thead>
      <tbody>${workerRows}</tbody></table>`:""}
      ${runs?.length?`<div class="section-title">Recent CI</div>
      ${(runs||[]).slice(0,5).map(r=>`<div style="display:flex;justify-content:space-between;padding:8px 0;border-bottom:1px solid #0a0a0a;font-size:12px">
        <span style="color:#aaa">${(r.name||"").slice(0,35)}</span>
        <span style="color:${r.conclusion==="success"?"#4ade80":r.conclusion==="failure"?"#f43f5e":"#fbbf24"};font-weight:600">${r.conclusion||r.status}</span>
      </div>`).join("")}`:""}
      <div class="section-title" style="margin-top:32px">Quick Links</div>
      ${[["agents.blackroad.io","Agent Mesh"],["dashboard.blackroad.io","CI Dashboard"],["docs.blackroad.io","Documentation"],["api.blackroad.io","API Reference"],["security.blackroad.io","Security"]].map(([u,l])=>`<a href="https://${u}" style="display:block;padding:9px 14px;background:#0a0a0a;border:1px solid #1a1a1a;border-radius:8px;color:#aaa;text-decoration:none;font-size:12px;margin-bottom:8px">${l} →</a>`).join("")}
    </div>
  </div>
</body></html>`;
}

export default {
  async fetch(req,env){
    const {pathname:p}=new URL(req.url);
    if(p==="/health") return json({status:"ok"});
    if(p==="/api/commands") return json({total:COMMANDS.length,commands:COMMANDS});
    const [wRes,rRes]=await Promise.allSettled([cfApi(env,"/workers/scripts?per_page=100"),ghFetch(env,"/repos/BlackRoad-OS-Inc/blackroad/actions/runs?per_page=5")]);
    const workers=wRes.value?.result||[];
    const runs=rRes.value?.workflow_runs||[];
    if(p==="/api/workers") return json({count:workers.length,workers});
    return new Response(renderPage(workers,runs),{headers:{"Content-Type":"text/html;charset=utf-8","Cache-Control":"public,max-age=120"}});
  }
};
