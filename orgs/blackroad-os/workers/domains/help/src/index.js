function json(d){return new Response(JSON.stringify(d),{headers:{"Content-Type":"application/json","Access-Control-Allow-Origin":"*"}});}
const FAQS=[{q:"How do I install the BR CLI?",a:'Run: curl -fsSL https://cli.blackroad.io/install.sh | bash — or clone the repo and chmod +x br'},{q:"How do agents communicate?",a:"Agents use pub/sub via file-based messaging in shared/inbox + shared/outbox, plus the @BLACKROAD directory waterfall for org-level routing."},{q:"What is CECE?",a:"CECE (Conscious Emergent Collaborative Entity) is the portable AI identity system. Initialize with: br cece init"},{q:"How do I deploy a Cloudflare worker?",a:'Use: br cloudflare deploy — or cd to the worker dir and run: npx wrangler deploy'},{q:"How do I connect to the Raspberry Pis?",a:"ssh pi@192.168.4.64 (primary) or ssh pi@192.168.4.38 (secondary). Use br pi status to check fleet."},{q:"Where are secrets stored?",a:"In ~/.blackroad/vault/ — encrypted with AES-256-CBC. Use: br secrets vault list to view. Never in agent code."},{q:"How do I use the tokenless gateway?",a:"Send requests to http://127.0.0.1:8787 — the gateway routes to Ollama/Claude/OpenAI using server-side keys. Set BLACKROAD_GATEWAY_URL."}];
export default {
  async fetch(req){
    const {pathname:p}=new URL(req.url);
    if(p==="/health") return json({status:"ok"});
    if(p==="/api/faq") return json(FAQS);
    const faqHtml=FAQS.map(f=>`<div style="background:#0a0a0a;border:1px solid #1a1a1a;border-radius:12px;padding:20px;margin-bottom:12px"><div style="font-size:14px;font-weight:600;color:#FF1D6C;margin-bottom:8px">${f.q}</div><div style="font-size:13px;color:#888;line-height:1.6">${f.a}</div></div>`).join("");
    return new Response(`<!DOCTYPE html><html><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Help — BlackRoad OS</title><style>*{box-sizing:border-box;margin:0;padding:0}body{background:#000;color:#fff;font-family:-apple-system,sans-serif}.gbar{height:3px;background:linear-gradient(135deg,#F5A623,#FF1D6C,#9C27B0,#2979FF)}.header{padding:40px;border-bottom:1px solid #1a1a1a}.title{font-size:42px;font-weight:700;background:linear-gradient(135deg,#F5A623,#FF1D6C,#9C27B0,#2979FF);-webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text}.layout{display:grid;grid-template-columns:1fr 280px;gap:40px;padding:40px;max-width:1100px}.section-title{font-size:11px;font-weight:600;letter-spacing:.12em;text-transform:uppercase;color:#555;margin-bottom:14px;padding-bottom:8px;border-bottom:1px solid #1a1a1a}@media(max-width:800px){.layout{grid-template-columns:1fr;padding:24px}}</style></head><body>
<div class="gbar"></div>
<div class="header"><div style="font-size:11px;font-weight:600;letter-spacing:.15em;text-transform:uppercase;color:#555;margin-bottom:12px">BlackRoad OS · Support</div><h1 class="title">Help Center</h1><p style="color:#555;font-size:15px;margin-top:8px">FAQ, docs, and support resources</p></div>
<div class="layout"><div>
<div class="section-title">Frequently Asked Questions</div>${faqHtml}
</div><div>
<div class="section-title">Resources</div>
${[["docs.blackroad.io","Documentation"],["console.blackroad.io","CLI Reference"],["api.blackroad.io","API Docs"],["dev.blackroad.io","Developer Hub"],["status.blackroad.io","System Status"],["security.blackroad.io","Security"]].map(([u,l])=>`<a href="https://${u}" style="display:block;padding:10px 14px;background:#0a0a0a;border:1px solid #1a1a1a;border-radius:8px;color:#aaa;text-decoration:none;font-size:13px;margin-bottom:8px">${l} →</a>`).join("")}
<div class="section-title" style="margin-top:24px">Contact</div>
<p style="font-size:13px;color:#555">blackroad.systems@gmail.com</p>
</div></div>
</body></html>`,{headers:{"Content-Type":"text/html;charset=utf-8","Cache-Control":"public,max-age=3600"}});
  }
};
