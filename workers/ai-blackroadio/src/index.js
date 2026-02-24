// ai.blackroad.io — AI Platform Portal Worker
// BlackRoad OS, Inc. © 2025 — All Rights Reserved

const GH_ORG = 'BlackRoad-OS-Inc';
const AGENTS_API = 'https://blackroad-live-data.blackroad.workers.dev';

const AI_MODELS = [
  {
    name: 'Qwen 2.5 72B', id: 'qwen2.5:72b', provider: 'Alibaba Cloud / BlackRoad',
    icon: '🧠', category: 'General Purpose', status: 'available',
    params: '72B', context: '128K', quantization: 'Q4_K_M',
    strengths: ['Reasoning', 'Code generation', 'Multilingual', 'Math'],
    storage: 'R2: blackroad-models',
    desc: 'Primary inference model. Exceptional reasoning and code generation across 29+ languages.',
  },
  {
    name: 'DeepSeek R1 7B', id: 'deepseek-r1:7b', provider: 'DeepSeek / BlackRoad',
    icon: '🔬', category: 'Reasoning / Code', status: 'available',
    params: '7B', context: '64K', quantization: 'Q4_K_M',
    strengths: ['Chain-of-thought', 'Code review', 'Mathematics', 'Step-by-step'],
    storage: 'Railway: A100',
    desc: 'Specialized reasoning model with transparent thinking steps. Excels at complex problem-solving.',
  },
  {
    name: 'Llama 3.2 3B', id: 'llama3.2:3b', provider: 'Meta / BlackRoad',
    icon: '⚡', category: 'Fast / Lightweight', status: 'available',
    params: '3B', context: '128K', quantization: 'Q8_0',
    strengths: ['Speed', 'Edge inference', 'Low latency', 'Classification'],
    storage: 'Raspberry Pi (local)',
    desc: 'Optimized for speed on edge hardware. Runs on Raspberry Pi fleet with sub-100ms latency.',
  },
  {
    name: 'Mistral 7B', id: 'mistral:7b', provider: 'Mistral AI / BlackRoad',
    icon: '💨', category: 'Balanced', status: 'available',
    params: '7B', context: '32K', quantization: 'Q4_K_M',
    strengths: ['Instruction following', 'Summarization', 'Translation', 'Analysis'],
    storage: 'Railway: A100',
    desc: 'Well-balanced model for general instruction following and summarization tasks.',
  },
  {
    name: 'Llama 3.1 70B', id: 'llama3.1:70b', provider: 'Meta / BlackRoad',
    icon: '🦙', category: 'Large / Premium', status: 'queued',
    params: '70B', context: '128K', quantization: 'Q4_K_M',
    strengths: ['Creative writing', 'Complex analysis', 'Long context', 'Nuanced tasks'],
    storage: 'R2: pending deployment',
    desc: 'Large-scale model for premium tasks. Scheduled for deployment in next release.',
  },
  {
    name: 'Lucidia Custom', id: 'lucidia:latest', provider: 'BlackRoad OS',
    icon: '🌀', category: 'Custom / Branded', status: 'available',
    params: 'Based on Llama 3.1', context: '8K', quantization: 'native',
    strengths: ['BlackRoad context', 'Agent coordination', 'Warm tone', 'System-aware'],
    storage: 'Local: lucidia.modelfile',
    desc: 'Custom BlackRoad personality model. Warm, clear, system-aware. Built with BlackRoad context.',
  },
];

async function fetchJSON(url, ttl = 60) {
  try {
    const r = await fetch(url, {
      headers: { 'User-Agent': 'BlackRoad-OS/2.0', Accept: 'application/json' },
      cf: { cacheTtl: ttl },
    });
    if (r.ok) return r.json();
  } catch (_) {}
  return null;
}

const STATUS_COLORS = { available: '#4ade80', queued: '#fbbf24', offline: '#f87171' };
const STATUS_BG = { available: '#0f2010', queued: '#1a1000', offline: '#1a0505' };

export default {
  async fetch(request, env, ctx) {
    const now = new Date().toUTCString();
    const [agentData, orgData] = await Promise.all([
      fetchJSON(`${AGENTS_API}/agents`, 30),
      fetchJSON(`https://api.github.com/orgs/${GH_ORG}`, 300),
    ]);

    const available = AI_MODELS.filter(m => m.status === 'available').length;

    const modelCards = AI_MODELS.map(m => `
      <div class="model-card">
        <div class="model-header">
          <span class="model-icon">${m.icon}</span>
          <div class="model-info">
            <div class="model-name">${m.name}</div>
            <div class="model-provider">${m.provider}</div>
          </div>
          <span class="model-status" style="background:${STATUS_BG[m.status]};color:${STATUS_COLORS[m.status]}">${m.status}</span>
        </div>
        <div class="model-desc">${m.desc}</div>
        <div class="model-meta">
          <span class="meta-chip">⚖️ ${m.params}</span>
          <span class="meta-chip">📐 ${m.context} ctx</span>
          <span class="meta-chip">🗜️ ${m.quantization}</span>
          <span class="meta-chip cat">${m.category}</span>
        </div>
        <div class="model-strengths">
          ${m.strengths.map(s => `<span class="strength-tag">${s}</span>`).join('')}
        </div>
        <div class="model-storage">🗄️ ${m.storage}</div>
      </div>`).join('');

    const html = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
  <title>AI Platform — BlackRoad OS</title>
  <style>
    *{margin:0;padding:0;box-sizing:border-box}
    :root{--hot-pink:#FF1D6C;--electric-blue:#2979FF;--amber:#F5A623;--violet:#9C27B0;--gradient:linear-gradient(135deg,#F5A623 0%,#FF1D6C 38.2%,#9C27B0 61.8%,#2979FF 100%)}
    body{font-family:-apple-system,BlinkMacSystemFont,'SF Pro Display',sans-serif;background:#000;color:#fff;min-height:100vh}
    nav{display:flex;align-items:center;gap:1.5rem;padding:1rem 2rem;border-bottom:1px solid #111;background:#000;position:sticky;top:0;z-index:100;flex-wrap:wrap}
    nav .logo{font-weight:800;background:var(--gradient);-webkit-background-clip:text;-webkit-text-fill-color:transparent}
    nav a{color:#666;text-decoration:none;font-size:.82rem}nav a:hover{color:#fff}
    .hero{padding:3.5rem 2rem 2rem;text-align:center}
    .hero h1{font-size:clamp(2rem,5vw,3.5rem);font-weight:800;background:var(--gradient);-webkit-background-clip:text;-webkit-text-fill-color:transparent;margin-bottom:.5rem}
    .hero .sub{color:#666;font-size:1.05rem}
    .stats-bar{display:flex;justify-content:center;gap:3rem;padding:1.5rem;background:#0a0a0a;border-top:1px solid #111;border-bottom:1px solid #111;margin-bottom:3rem;flex-wrap:wrap}
    .stat-item{text-align:center}.stat-item .val{font-size:2rem;font-weight:700;color:var(--hot-pink)}.stat-item .lbl{font-size:.72rem;color:#555;text-transform:uppercase;letter-spacing:.1em}
    .grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(340px,1fr));gap:1.5rem;padding:0 2rem 4rem;max-width:1400px;margin:0 auto}
    .model-card{background:#0a0a0a;border:1px solid #1a1a1a;border-radius:12px;padding:1.5rem;transition:border-color .2s}
    .model-card:hover{border-color:#333}
    .model-header{display:flex;align-items:center;gap:1rem;margin-bottom:.75rem}
    .model-icon{font-size:2rem}
    .model-info{flex:1}.model-name{font-weight:700;font-size:1.05rem}.model-provider{font-size:.75rem;color:#555}
    .model-status{padding:.2rem .6rem;border-radius:20px;font-size:.72rem;font-weight:600;text-transform:uppercase}
    .model-desc{color:#777;font-size:.88rem;line-height:1.5;margin-bottom:.75rem}
    .model-meta{display:flex;flex-wrap:wrap;gap:.4rem;margin-bottom:.75rem}
    .meta-chip{background:#111;border:1px solid #222;padding:.2rem .5rem;border-radius:4px;font-size:.72rem;color:#888}
    .meta-chip.cat{background:#0a1628;border-color:#2979FF33;color:#60a5fa}
    .model-strengths{display:flex;flex-wrap:wrap;gap:.35rem;margin-bottom:.6rem}
    .strength-tag{background:#1a0510;border:1px solid #FF1D6C33;color:#f472b6;padding:.15rem .5rem;border-radius:4px;font-size:.7rem}
    .model-storage{font-size:.75rem;color:#444;font-family:monospace}
    .footer{text-align:center;padding:2rem;color:#333;font-size:.8rem;border-top:1px solid #111}
  </style>
</head>
<body>
<nav>
  <span class="logo">◆ BlackRoad OS</span>
  <a href="https://blackroad.io">Home</a>
  <a href="https://agents.blackroad.io">Agents</a>
  <a href="https://dashboard.blackroad.io">Dashboard</a>
  <a href="https://api.blackroad.io">API</a>
  <a href="https://docs.blackroad.io">Docs</a>
  <a href="https://status.blackroad.io">Status</a>
</nav>
<div class="hero">
  <h1>AI Platform</h1>
  <p class="sub">BlackRoad OS — Local-first, tokenless AI inference</p>
</div>
<div class="stats-bar">
  <div class="stat-item"><div class="val">${available}</div><div class="lbl">Models Available</div></div>
  <div class="stat-item"><div class="val">${AI_MODELS.length}</div><div class="lbl">Total Models</div></div>
  <div class="stat-item"><div class="val">${agentData?.online || 6}</div><div class="lbl">Agents Online</div></div>
  <div class="stat-item"><div class="val">135GB</div><div class="lbl">Model Storage</div></div>
</div>
<div class="grid">${modelCards}</div>
<div class="footer">BlackRoad OS, Inc. © ${new Date().getFullYear()} — Your AI. Your Hardware. Your Rules. — Updated ${now}</div>
</body>
</html>`;

    return new Response(html, {
      headers: {
        'Content-Type': 'text/html;charset=UTF-8',
        'Cache-Control': 'public, max-age=60',
        'X-BlackRoad-Worker': 'ai-blackroadio',
        'X-BlackRoad-Version': '2.0.0',
      },
    });
  },
};
