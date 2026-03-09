/**
 * BlackRoad OS — AI Hub Worker
 * Serves: ai.blackroad.io, ai.blackroad.ai
 */
function json(d,s=200){return new Response(JSON.stringify(d,null,2),{status:s,headers:{"Content-Type":"application/json","Access-Control-Allow-Origin":"*"}});}
async function ghFetch(env,ep){if(!env.GITHUB_TOKEN)return null;try{const r=await fetch(`https://api.github.com${ep}`,{headers:{"Authorization":`Bearer ${env.GITHUB_TOKEN}`,"Accept":"application/vnd.github+json","X-GitHub-Api-Version":"2022-11-28","User-Agent":"BlackRoad-OS-Worker/2.0"}});return r.ok?r.json():null;}catch{return null;}}

const MODELS = [
  {id:"qwen2.5:7b",   name:"Qwen 2.5 7B",     org:"Alibaba",    type:"general",   params:"7B",  ctx:"128K", status:"online",  speed:"fast"},
  {id:"qwen2.5:72b",  name:"Qwen 2.5 72B",    org:"Alibaba",    type:"general",   params:"72B", ctx:"128K", status:"online",  speed:"medium"},
  {id:"deepseek-r1:7b",name:"DeepSeek R1 7B", org:"DeepSeek",   type:"reasoning", params:"7B",  ctx:"64K",  status:"online",  speed:"fast"},
  {id:"deepseek-v2",  name:"DeepSeek V2",     org:"DeepSeek",   type:"code",      params:"16B", ctx:"128K", status:"online",  speed:"medium"},
  {id:"llama3.2:3b",  name:"Llama 3.2 3B",   org:"Meta",       type:"general",   params:"3B",  ctx:"128K", status:"online",  speed:"fastest"},
  {id:"llama3.2:11b", name:"Llama 3.2 11B",  org:"Meta",       type:"vision",    params:"11B", ctx:"128K", status:"standby", speed:"medium"},
  {id:"mistral:7b",   name:"Mistral 7B",     org:"Mistral AI", type:"general",   params:"7B",  ctx:"32K",  status:"standby", speed:"fast"},
  {id:"codestral",    name:"Codestral",      org:"Mistral AI", type:"code",      params:"22B", ctx:"32K",  status:"online",  speed:"medium"},
  {id:"claude-3-5-sonnet",name:"Claude 3.5 Sonnet",org:"Anthropic",type:"reasoning",params:"?",ctx:"200K",status:"online",speed:"medium"},
  {id:"gpt-4o",       name:"GPT-4o",         org:"OpenAI",     type:"general",   params:"?",   ctx:"128K", status:"online",  speed:"medium"},
];

const FEATURES = [
  {name:"Tokenless Gateway", desc:"Single endpoint for all providers — no API keys in your code"},
  {name:"30K Agent Mesh",    desc:"Distributed inference across Pi fleet + Railway GPU cluster"},
  {name:"PS-SHA∞ Memory",   desc:"Hash-chained persistent memory across sessions and models"},
  {name:"Trinary Logic",     desc:"1=True / 0=Unknown / -1=False epistemic reasoning engine"},
  {name:"Skills SDK",        desc:"@blackroad/skills-sdk for building AI-native applications"},
  {name:"Model Routing",     desc:"Auto-route requests to best available model by task type"},
  {name:"Edge Inference",    desc:"Run models at CF edge globally via Ollama + Pi tunnel"},
  {name:"CECE Identity",     desc:"Portable AI identity persists across providers and sessions"},
];

function renderPage(aiRepos, latency) {
  const modelRows = MODELS.map(m=>`
    <tr>
      <td style="font-size:12px;color:${m.status==="online"?"#4ade80":"#555"};font-weight:600">${m.status==="online"?"●":"○"}</td>
      <td style="font-size:13px;color:#fff;font-weight:500">${m.name}</td>
      <td style="font-size:12px;color:#666">${m.org}</td>
      <td style="font-size:11px;color:#FF1D6C;font-weight:600;text-transform:uppercase">${m.type}</td>
      <td style="font-size:12px;color:#9C27B0;font-family:'SF Mono',monospace">${m.params}</td>
      <td style="font-size:12px;color:#2979FF;font-family:'SF Mono',monospace">${m.ctx}</td>
      <td style="font-size:11px;color:#${m.speed==="fastest"?"F5A623":m.speed==="fast"?"4ade80":"fb923c"}">${m.speed}</td>
    </tr>`).join("");

  const featureCards = FEATURES.map(f=>`
    <div style="background:#0a0a0a;border:1px solid #1a1a1a;border-radius:12px;padding:18px 20px">
      <div style="font-size:13px;font-weight:600;color:#fff;margin-bottom:6px">${f.name}</div>
      <div style="font-size:12px;color:#555;line-height:1.5">${f.desc}</div>
    </div>`).join("");

  const repoCards = (aiRepos||[]).slice(0,6).map(r=>`
    <div style="background:#0a0a0a;border:1px solid #1a1a1a;border-radius:10px;padding:14px 16px">
      <div style="font-size:13px;color:#FF1D6C;font-weight:500;margin-bottom:4px">${r.name}</div>
      <div style="font-size:11px;color:#555">${(r.description||"").slice(0,80)}</div>
      <div style="display:flex;gap:12px;margin-top:8px">
        ${r.language?`<span style="font-size:10px;color:#2979FF">⬟ ${r.language}</span>`:""}
        <span style="font-size:10px;color:#555">★ ${r.stargazers_count}</span>
      </div>
    </div>`).join("");

  const ts = new Date().toISOString();
  return `<!DOCTYPE html><html lang="en"><head>
  <meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
  <title>AI — BlackRoad OS</title>
  <style>
    *{box-sizing:border-box;margin:0;padding:0}
    :root{--bg:#000;--surface:#0a0a0a;--border:#1a1a1a;--text:#fff;--muted:#555;--gradient:linear-gradient(135deg,#F5A623 0%,#FF1D6C 38.2%,#9C27B0 61.8%,#2979FF 100%);--font:-apple-system,BlinkMacSystemFont,'SF Pro Display',sans-serif}
    body{background:var(--bg);color:var(--text);font-family:var(--font)}
    .gbar{height:3px;background:var(--gradient)}
    .header{padding:40px;border-bottom:1px solid var(--border)}
    .eyebrow{font-size:11px;font-weight:600;letter-spacing:.15em;text-transform:uppercase;color:var(--muted);margin-bottom:12px}
    .title{font-size:clamp(28px,4vw,52px);font-weight:700;background:var(--gradient);-webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text}
    .subtitle{margin-top:8px;font-size:15px;color:var(--muted)}
    .stats{display:flex;gap:24px;flex-wrap:wrap;margin-top:20px}
    .stat{text-align:center}
    .stat-val{font-size:24px;font-weight:700;background:var(--gradient);-webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text}
    .stat-lbl{font-size:11px;color:var(--muted);text-transform:uppercase;letter-spacing:.1em}
    .content{padding:40px;max-width:1200px}
    .section-title{font-size:12px;font-weight:600;letter-spacing:.12em;text-transform:uppercase;color:var(--muted);margin-bottom:14px;padding-bottom:8px;border-bottom:1px solid var(--border);margin-top:40px}
    .section-title:first-child{margin-top:0}
    .table{width:100%;border-collapse:collapse}
    .table th{font-size:11px;font-weight:600;letter-spacing:.1em;text-transform:uppercase;color:var(--muted);padding:7px 10px;text-align:left;border-bottom:1px solid var(--border)}
    .table td{padding:9px 10px;border-bottom:1px solid #080808}
    .table tr:last-child td{border-bottom:none}
    .grid-3{display:grid;grid-template-columns:repeat(3,1fr);gap:14px}
    .ts{font-size:11px;color:#333;margin-top:40px;padding-top:14px;border-top:1px solid var(--border)}
    @media(max-width:900px){.grid-3{grid-template-columns:1fr 1fr}.content{padding:24px}}
    @media(max-width:600px){.grid-3{grid-template-columns:1fr}.header{padding:24px}}
  </style></head><body>
  <div class="gbar"></div>
  <div class="header">
    <div class="eyebrow">BlackRoad OS · Artificial Intelligence</div>
    <h1 class="title">BlackRoad AI</h1>
    <p class="subtitle">Your AI. Your Hardware. Your Rules. · 30,000 agents · 10 models · Edge inference</p>
    <div class="stats">
      <div class="stat"><div class="stat-val">30K</div><div class="stat-lbl">Agents</div></div>
      <div class="stat"><div class="stat-val">${MODELS.filter(m=>m.status==="online").length}</div><div class="stat-lbl">Models Online</div></div>
      <div class="stat"><div class="stat-val">128K</div><div class="stat-lbl">Max Context</div></div>
      <div class="stat"><div class="stat-val">Edge</div><div class="stat-lbl">Inference</div></div>
    </div>
  </div>
  <div class="content">
    <div class="section-title">Model Registry</div>
    <table class="table">
      <thead><tr><th></th><th>Model</th><th>Provider</th><th>Type</th><th>Params</th><th>Context</th><th>Speed</th></tr></thead>
      <tbody>${modelRows}</tbody>
    </table>
    <div class="section-title">Platform Features</div>
    <div class="grid-3">${featureCards}</div>
    ${repoCards?`<div class="section-title">AI Repositories (BlackRoad-AI)</div><div class="grid-3">${repoCards}</div>`:""}
    <div class="section-title">Quick Start</div>
    <pre style="background:#0a0a0a;border:1px solid #1a1a1a;border-radius:10px;padding:18px;font-family:'SF Mono',monospace;font-size:12px;line-height:1.6;color:#e2e8f0">npm install @blackroad/skills-sdk

import { createSDK } from '@blackroad/skills-sdk';
const sdk = createSDK({ agentId: 'your-agent' });

// Memory (PS-SHA∞)
await sdk.memory.remember('User prefers dark mode');
await sdk.memory.search('user preferences');

// Reasoning (Trinary)
await sdk.reasoning.evaluate('The API uses REST');

// Coordination
await sdk.coordination.publish('tasks', 'new', { ... });</pre>
    <div class="ts">Updated ${ts} · ${MODELS.length} models registered · <a href="https://api.blackroad.io/v2/agents" style="color:#FF1D6C;text-decoration:none">API →</a></div>
  </div>
</body></html>`;
}

export default {
  async fetch(req,env){
    const {pathname:p}=new URL(req.url);
    if(p==="/health") return json({status:"ok",models:MODELS.filter(m=>m.status==="online").length});
    if(p==="/api/models") return json({total:MODELS.length,online:MODELS.filter(m=>m.status==="online").length,models:MODELS});
    const aiRepos=await ghFetch(env,"/orgs/BlackRoad-AI/repos?sort=updated&per_page=6");
    return new Response(renderPage(aiRepos,null),{headers:{"Content-Type":"text/html;charset=utf-8","Cache-Control":"public,max-age=300"}});
  }
};
