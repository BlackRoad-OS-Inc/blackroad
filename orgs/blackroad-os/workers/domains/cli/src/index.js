function json(d){return new Response(JSON.stringify(d),{headers:{"Content-Type":"application/json","Access-Control-Allow-Origin":"*"}});}
const INSTALL=`curl -fsSL https://cli.blackroad.io/install.sh | bash`;
export default {
  async fetch(req){
    const {pathname:p}=new URL(req.url);
    if(p==="/install.sh") return new Response(`#!/bin/bash\nset -e\necho "Installing BlackRoad CLI..."\ngit clone https://github.com/BlackRoad-OS-Inc/blackroad /tmp/blackroad-install\ncd /tmp/blackroad-install && chmod +x br\ncp br /usr/local/bin/br 2>/dev/null || sudo cp br /usr/local/bin/br\necho "✓ br installed to /usr/local/bin/br"\nbr help`,{headers:{"Content-Type":"text/plain","Content-Disposition":"attachment; filename=install.sh"}});
    if(p==="/api/version") return json({version:"2.0.0",tools:37,commands:200});
    return new Response(`<!DOCTYPE html><html><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>CLI — BlackRoad OS</title><style>*{box-sizing:border-box;margin:0;padding:0}body{background:#000;color:#fff;font-family:-apple-system,sans-serif}.gbar{height:3px;background:linear-gradient(135deg,#F5A623,#FF1D6C,#9C27B0,#2979FF)}.header{padding:40px;border-bottom:1px solid #1a1a1a}.title{font-size:42px;font-weight:700;background:linear-gradient(135deg,#F5A623,#FF1D6C,#9C27B0,#2979FF);-webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text}.content{padding:40px;max-width:800px}pre{background:#0a0a0a;border:1px solid #1a1a1a;border-radius:10px;padding:18px;font-family:'SF Mono',monospace;font-size:13px;line-height:1.6;color:#e2e8f0;margin-bottom:20px}h3{font-size:12px;font-weight:600;letter-spacing:.12em;text-transform:uppercase;color:#555;margin:32px 0 12px;padding-bottom:8px;border-bottom:1px solid #1a1a1a}</style></head><body>
<div class="gbar"></div>
<div class="header"><div style="font-size:11px;font-weight:600;letter-spacing:.15em;text-transform:uppercase;color:#555;margin-bottom:12px">BlackRoad OS · CLI</div><h1 class="title">BR CLI</h1><p style="color:#555;font-size:15px;margin-top:8px">37 tools · 200+ commands · Your terminal, supercharged</p></div>
<div class="content">
<h3>Install</h3>
<pre>${INSTALL}</pre>
<h3>Usage</h3>
<pre>br &lt;command&gt; &lt;subcommand&gt; [args]

# Examples
br agents list          # List all agents
br deploy cloudflare    # Deploy to Cloudflare  
br git commit           # AI smart commit
br security scan        # Run security scan
br pi status            # Raspberry Pi fleet
br workers tail &lt;name&gt;  # Tail worker logs</pre>
<h3>Tool Categories (37 total)</h3>
<pre>agents    deploy    git       docker    cloudflare
ocean     vercel    pi        db        env
note      logs      perf      security  backup
deps      session   test      world     metrics
notify    agent     radar     pair      cece
snippet   search    quality   api       ci</pre>
<a href="https://console.blackroad.io" style="display:inline-block;margin-top:20px;padding:12px 24px;background:linear-gradient(135deg,#FF1D6C,#9C27B0);border-radius:8px;color:#fff;text-decoration:none;font-size:14px;font-weight:600">Full Reference →</a>
</div>
</body></html>`,{headers:{"Content-Type":"text/html;charset=utf-8"}});
  }
};
