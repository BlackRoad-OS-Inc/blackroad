/**
 * BlackRoad OS — Docs Worker
 * Serves: docs.blackroad.io
 */
function json(d,s=200){return new Response(JSON.stringify(d,null,2),{status:s,headers:{"Content-Type":"application/json","Access-Control-Allow-Origin":"*"}});}
async function gh(env,ep){if(!env.GITHUB_TOKEN)return null;try{const r=await fetch(`https://api.github.com${ep}`,{headers:{"Authorization":`Bearer ${env.GITHUB_TOKEN}`,"Accept":"application/vnd.github+json","X-GitHub-Api-Version":"2022-11-28","User-Agent":"BlackRoad-OS-Worker/2.0"}});return r.ok?r.json():null;}catch{return null;}}

const DOCS_SECTIONS = [
  { icon:"🚀", title:"Getting Started",  path:"/getting-started", desc:"Install BR CLI, initialize your first project" },
  { icon:"🤖", title:"Agents Guide",     path:"/agents",          desc:"Configure and orchestrate AI agents"         },
  { icon:"⚡", title:"CLI Reference",    path:"/cli",             desc:"All 37 br commands with examples"            },
  { icon:"🔌", title:"API Reference",    path:"/api",             desc:"REST API endpoints and GraphQL schema"       },
  { icon:"🏗️", title:"Architecture",    path:"/architecture",    desc:"System design, components, and data flow"    },
  { icon:"☁️", title:"Infrastructure",  path:"/infrastructure",  desc:"Railway, Cloudflare, Pi fleet setup"         },
  { icon:"🔐", title:"Security",         path:"/security",        desc:"Vault, tokenless gateway, secrets mgmt"     },
  { icon:"🤝", title:"Contributing",     path:"/contributing",    desc:"How to contribute to BlackRoad OS"          },
];

const KEY_DOCS = [
  { file:"README.md",       title:"README",              desc:"Project overview and quick start" },
  { file:"CLAUDE.md",       title:"CLAUDE.md",           desc:"AI assistant guidance (1,800+ lines)" },
  { file:"AGENTS.md",       title:"Agents Guide",        desc:"Complete agent documentation"      },
  { file:"API.md",          title:"API Reference",       desc:"Full API documentation"            },
  { file:"ARCHITECTURE.md", title:"Architecture",        desc:"System architecture diagrams"      },
  { file:"SECURITY.md",     title:"Security Policy",     desc:"Security policies and bug bounty"  },
  { file:"DEPLOYMENT.md",   title:"Deployment Guide",    desc:"Multi-cloud deployment guide"      },
  { file:"CONTRIBUTING.md", title:"Contributing",        desc:"Contribution guidelines"           },
  { file:"ROADMAP.md",      title:"Roadmap",             desc:"2026 feature roadmap"              },
  { file:"PLANNING.md",     title:"Planning",            desc:"Q1–Q4 2026 priorities"             },
];

const BASE_URL = "https://github.com/BlackRoad-OS-Inc/blackroad/blob/master";

function renderPage(releases) {
  const sectionCards = DOCS_SECTIONS.map(s=>`
    <a class="doc-card" href="https://github.com/BlackRoad-OS-Inc/blackroad/blob/master${s.path.toUpperCase().replace("/","")||""}.md">
      <div class="doc-icon">${s.icon}</div>
      <div class="doc-title">${s.title}</div>
      <div class="doc-desc">${s.desc}</div>
    </a>`).join("");

  const keyDocCards = KEY_DOCS.map(d=>`
    <a class="file-card" href="${BASE_URL}/${d.file}" target="_blank">
      <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:6px">
        <span style="font-size:13px;font-weight:600;color:#fff">${d.title}</span>
        <span style="font-size:10px;font-weight:600;color:#FF1D6C;font-family:'SF Mono',monospace">${d.file}</span>
      </div>
      <div style="font-size:12px;color:#555">${d.desc}</div>
    </a>`).join("");

  const releaseItems = (releases||[]).slice(0,4).map(r=>`
    <div style="background:#0a0a0a;border:1px solid #1a1a1a;border-radius:10px;padding:16px;margin-bottom:10px">
      <div style="display:flex;justify-content:space-between;align-items:start;margin-bottom:6px">
        <span style="font-size:14px;font-weight:600">${r.name||r.tag_name}</span>
        <a href="${r.html_url}" target="_blank" style="font-size:11px;color:#FF1D6C;text-decoration:none">${r.tag_name} →</a>
      </div>
      <div style="font-size:12px;color:#555">${new Date(r.published_at).toLocaleDateString()}</div>
    </div>`).join("");

  const ts = new Date().toISOString();
  return `<!DOCTYPE html><html lang="en"><head>
  <meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
  <title>Docs — BlackRoad OS</title>
  <style>
    *{box-sizing:border-box;margin:0;padding:0}
    :root{--bg:#000;--surface:#0a0a0a;--border:#1a1a1a;--text:#fff;--muted:#555;--gradient:linear-gradient(135deg,#F5A623 0%,#FF1D6C 38.2%,#9C27B0 61.8%,#2979FF 100%);--font:-apple-system,BlinkMacSystemFont,'SF Pro Display',sans-serif}
    body{background:var(--bg);color:var(--text);font-family:var(--font)}
    .gbar{height:3px;background:var(--gradient)}
    .header{padding:40px;border-bottom:1px solid var(--border)}
    .eyebrow{font-size:11px;font-weight:600;letter-spacing:.15em;text-transform:uppercase;color:var(--muted);margin-bottom:12px}
    .title{font-size:clamp(28px,4vw,52px);font-weight:700;background:var(--gradient);-webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text}
    .subtitle{margin-top:8px;font-size:15px;color:var(--muted)}
    .search{margin-top:20px;width:100%;max-width:440px;background:#0a0a0a;border:1px solid #2a2a2a;border-radius:10px;padding:11px 16px;font-size:14px;color:#555;outline:none}
    .content{padding:40px;max-width:1200px}
    .two-col{display:grid;grid-template-columns:2fr 1fr;gap:40px}
    .section-title{font-size:12px;font-weight:600;letter-spacing:.12em;text-transform:uppercase;color:var(--muted);margin-bottom:16px;padding-bottom:8px;border-bottom:1px solid var(--border)}
    .doc-grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(200px,1fr));gap:12px;margin-bottom:40px}
    .doc-card{display:block;text-decoration:none;background:var(--surface);border:1px solid var(--border);border-radius:12px;padding:18px;transition:border-color .15s}
    .doc-card:hover{border-color:#333}
    .doc-icon{font-size:24px;margin-bottom:10px}
    .doc-title{font-size:14px;font-weight:600;color:#fff;margin-bottom:4px}
    .doc-desc{font-size:12px;color:var(--muted)}
    .file-grid{display:grid;grid-template-columns:1fr;gap:10px;margin-bottom:32px}
    .file-card{display:block;text-decoration:none;background:var(--surface);border:1px solid var(--border);border-radius:10px;padding:14px 16px;transition:border-color .15s}
    .file-card:hover{border-color:#333}
    .ts{font-size:11px;color:#333;margin-top:40px;padding-top:16px;border-top:1px solid var(--border)}
    @media(max-width:768px){.two-col{grid-template-columns:1fr}.header,.content{padding:24px}}
  </style></head><body>
  <div class="gbar"></div>
  <div class="header">
    <div class="eyebrow">BlackRoad OS · Documentation</div>
    <h1 class="title">Documentation</h1>
    <p class="subtitle">45 docs · 38,000+ lines · Everything you need to build on BlackRoad OS</p>
    <input class="search" placeholder="Search documentation..." disabled>
  </div>
  <div class="content">
    <div class="two-col">
      <div>
        <div class="section-title">Browse Documentation</div>
        <div class="doc-grid">${sectionCards}</div>
        <div class="section-title">Key Files</div>
        <div class="file-grid">${keyDocCards}</div>
      </div>
      <div>
        ${releases?.length?`<div class="section-title">Recent Releases</div>${releaseItems}`:""}
        <div class="section-title" style="margin-top:${releases?.length?32:0}px">Quick Links</div>
        ${[["GitHub Org","https://github.com/BlackRoad-OS-Inc"],["Agent Docs","https://agents.blackroad.io"],["API Ref","https://api.blackroad.io"],["CLI Ref","https://console.blackroad.io"],["Security","https://security.blackroad.io"]].map(([l,u])=>`<a href="${u}" style="display:block;padding:10px 14px;background:#0a0a0a;border:1px solid #1a1a1a;border-radius:8px;color:#fff;text-decoration:none;font-size:13px;margin-bottom:8px;transition:border-color .15s">${l} →</a>`).join("")}
      </div>
    </div>
    <div class="ts">Generated ${ts} · <a href="https://github.com/BlackRoad-OS-Inc/blackroad" style="color:#FF1D6C;text-decoration:none">GitHub →</a></div>
  </div>
</body></html>`;
}

export default {
  async fetch(req, env) {
    const {pathname:p} = new URL(req.url);
    if(p==="/health") return json({status:"ok"});
    if(p==="/api") return json({sections:DOCS_SECTIONS,files:KEY_DOCS,github:"https://github.com/BlackRoad-OS-Inc/blackroad"});
    const releases = await gh(env,"/repos/BlackRoad-OS-Inc/blackroad/releases?per_page=5");
    return new Response(renderPage(releases),{headers:{"Content-Type":"text/html;charset=utf-8","Cache-Control":"public,max-age=300"}});
  }
};
