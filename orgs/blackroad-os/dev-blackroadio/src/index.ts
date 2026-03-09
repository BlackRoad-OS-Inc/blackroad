/**
 * dev.blackroad.io — Developer playground and API explorer
 */
export interface Env { BLACKROAD_GATEWAY_URL: string; }

const PLAYGROUND_HTML = `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>BlackRoad Dev Playground</title>
<style>
  body { background: #0a0a0a; color: #fff; font-family: 'SF Pro Display', monospace; padding: 24px; }
  h1 { background: linear-gradient(135deg, #F5A623, #FF1D6C 38.2%, #9C27B0 61.8%, #2979FF); -webkit-background-clip: text; -webkit-text-fill-color: transparent; }
  textarea { width: 100%; height: 120px; background: #1a1a1a; color: #fff; border: 1px solid #333; padding: 12px; border-radius: 8px; font-family: monospace; }
  button { background: #FF1D6C; color: #fff; border: none; padding: 12px 24px; border-radius: 8px; cursor: pointer; margin: 8px 0; font-size: 14px; }
  pre { background: #1a1a1a; padding: 16px; border-radius: 8px; overflow: auto; }
  select { background: #1a1a1a; color: #fff; border: 1px solid #333; padding: 8px; border-radius: 8px; }
</style>
</head>
<body>
<h1>BlackRoad Dev Playground</h1>
<p>Interactive API explorer for BlackRoad Gateway</p>
<label>Agent: <select id="agent"><option>LUCIDIA</option><option>ALICE</option><option>OCTAVIA</option><option>PRISM</option><option>ECHO</option><option>CIPHER</option></select></label>
<br><br>
<textarea id="prompt" placeholder="Enter your message...">Hello, what can you do?</textarea>
<br>
<button onclick="sendChat()">Send to Agent</button>
<pre id="output">Response will appear here...</pre>
<script>
async function sendChat() {
  const msg = document.getElementById('prompt').value;
  const agent = document.getElementById('agent').value;
  document.getElementById('output').textContent = 'Thinking...';
  const r = await fetch('/v1/chat/completions', {
    method: 'POST', headers: {'Content-Type':'application/json'},
    body: JSON.stringify({model:'llama3.2',messages:[{role:'user',content:msg}],metadata:{agent}})
  });
  const d = await r.json();
  document.getElementById('output').textContent = d.choices?.[0]?.message?.content || JSON.stringify(d,null,2);
}
</script>
</body>
</html>`;

export default {
  async fetch(req: Request, env: Env): Promise<Response> {
    const url = new URL(req.url);
    const gw = env.BLACKROAD_GATEWAY_URL || "http://127.0.0.1:8787";
    if (url.pathname === "/" || url.pathname === "") return new Response(PLAYGROUND_HTML, { headers: { "Content-Type": "text/html" } });
    // Proxy to gateway
    const r = await fetch(`${gw}${url.pathname}${url.search}`, { method: req.method, headers: {"Content-Type":"application/json"}, body: req.method !== "GET" ? await req.text() : undefined });
    return new Response(await r.text(), { status: r.status, headers: { "Content-Type": r.headers.get("Content-Type") || "application/json", "Access-Control-Allow-Origin": "*" } });
  }
};
