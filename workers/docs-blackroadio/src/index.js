// docs.blackroad.io — Documentation Hub Worker
// BlackRoad OS, Inc. © 2025 — All Rights Reserved

const GH_ORG = 'BlackRoad-OS-Inc';
const DOC_REPOS = [
  { name: 'blackroad-docs',    title: 'Core Documentation',   icon: '📚', desc: 'Architecture, guides, and references' },
  { name: 'blackroad-core',    title: 'Core Platform',        icon: '⚙️', desc: 'Tokenless gateway, agent runtime' },
  { name: 'blackroad-agents',  title: 'Agent System',         icon: '🤖', desc: 'Agent orchestration and management' },
  { name: 'blackroad-infra',   title: 'Infrastructure',       icon: '🏗️', desc: 'IaC, CI/CD, deployment configs' },
  { name: 'blackroad-web',     title: 'Web Platform',         icon: '🌐', desc: 'Frontend, Next.js, UI components' },
  { name: 'blackroad-operator','title': 'Operator CLI',       icon: '💻', desc: 'CLI tooling and node bootstrap' },
];

async function fetchJSON(url, ttl = 300) {
  try {
    const r = await fetch(url, {
      headers: { 'User-Agent': 'BlackRoad-OS/2.0', Accept: 'application/json' },
      cf: { cacheTtl: ttl },
    });
    if (r.ok) return r.json();
  } catch (_) {}
  return null;
}

async function fetchReadme(repo) {
  const data = await fetchJSON(`https://api.github.com/repos/${GH_ORG}/${repo}/contents/README.md`, 300);
  if (data?.content) {
    try {
      return atob(data.content.replace(/\n/g, ''));
    } catch (_) {}
  }
  return null;
}

function markdownToHtml(md) {
  if (!md) return '<p style="color:#666">Documentation loading...</p>';
  return md
    .replace(/^### (.+)$/gm, '<h3 style="color:#F5A623;margin:1.5rem 0 .5rem">$1</h3>')
    .replace(/^## (.+)$/gm, '<h2 style="color:#FF1D6C;margin:2rem 0 .75rem;border-bottom:1px solid #111;padding-bottom:.5rem">$1</h2>')
    .replace(/^# (.+)$/gm, '<h1 style="font-size:1.8rem;font-weight:800;background:linear-gradient(135deg,#F5A623,#FF1D6C,#9C27B0,#2979FF);-webkit-background-clip:text;-webkit-text-fill-color:transparent;margin:1rem 0">$1</h1>')
    .replace(/`([^`]+)`/g, '<code style="background:#111;padding:.1em .4em;border-radius:3px;font-size:.85em;color:#4ade80">$1</code>')
    .replace(/```[\s\S]*?```/g, m => `<pre style="background:#050505;border:1px solid #111;border-radius:8px;padding:1rem;overflow-x:auto;margin:1rem 0;font-size:.82rem;color:#60a5fa">${m.replace(/```\w*\n?/g,'').replace(/```/g,'')}</pre>`)
    .replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>')
    .replace(/\[([^\]]+)\]\(([^)]+)\)/g, '<a href="$2" style="color:#2979FF" target="_blank">$1</a>')
    .replace(/^- (.+)$/gm, '<li style="margin:.3rem 0;color:#ccc">$1</li>')
    .replace(/(<li[^>]*>.*<\/li>\n?)+/g, m => `<ul style="padding-left:1.5rem;margin:.75rem 0">${m}</ul>`)
    .replace(/\n\n/g, '</p><p style="color:#ccc;line-height:1.7;margin:.75rem 0">');
}

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    const repoParam = url.searchParams.get('repo') || 'blackroad-docs';
    const now = new Date().toUTCString();

    const [readme, org] = await Promise.all([
      fetchReadme(repoParam),
      fetchJSON(`https://api.github.com/orgs/${GH_ORG}`, 300),
    ]);

    const repoLinks = DOC_REPOS.map(r => `
      <a href="?repo=${r.name}" class="doc-link ${r.name === repoParam ? 'active' : ''}">
        <span>${r.icon}</span>
        <div>
          <div style="font-weight:600;font-size:.9rem">${r.title}</div>
          <div style="font-size:.75rem;color:#555">${r.desc}</div>
        </div>
      </a>`).join('');

    const current = DOC_REPOS.find(r => r.name === repoParam) || DOC_REPOS[0];

    const html = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
  <title>Docs — ${current.title} — BlackRoad OS</title>
  <style>
    *{margin:0;padding:0;box-sizing:border-box}
    :root{--gradient:linear-gradient(135deg,#F5A623 0%,#FF1D6C 38.2%,#9C27B0 61.8%,#2979FF 100%)}
    body{font-family:-apple-system,BlinkMacSystemFont,'SF Pro Display',sans-serif;background:#000;color:#fff;min-height:100vh}
    nav{display:flex;align-items:center;gap:1.5rem;padding:1rem 2rem;border-bottom:1px solid #111;background:#000;position:sticky;top:0;z-index:100;flex-wrap:wrap}
    nav .logo{font-weight:800;background:var(--gradient);-webkit-background-clip:text;-webkit-text-fill-color:transparent}
    nav a{color:#666;text-decoration:none;font-size:.82rem}nav a:hover{color:#fff}
    .layout{display:grid;grid-template-columns:260px 1fr;min-height:calc(100vh - 60px)}
    @media(max-width:768px){.layout{grid-template-columns:1fr}}
    .sidebar{border-right:1px solid #111;padding:1.5rem;background:#050505}
    .sidebar-title{font-size:.7rem;text-transform:uppercase;letter-spacing:.1em;color:#444;margin-bottom:1rem;padding-bottom:.5rem;border-bottom:1px solid #111}
    .doc-link{display:flex;align-items:center;gap:.75rem;padding:.75rem;border-radius:8px;margin-bottom:.25rem;text-decoration:none;color:#888;transition:all .2s;cursor:pointer}
    .doc-link:hover{background:#0f0f0f;color:#fff}
    .doc-link.active{background:#0f0f0f;color:#FF1D6C;border-left:2px solid #FF1D6C}
    .content{padding:2rem 3rem;max-width:860px;line-height:1.7}
    @media(max-width:768px){.content{padding:1.5rem}}
    .content-title{font-size:1.5rem;font-weight:800;background:var(--gradient);-webkit-background-clip:text;-webkit-text-fill-color:transparent;margin-bottom:1.5rem;display:flex;align-items:center;gap:.5rem}
    .gh-link{font-size:.8rem;color:#2979FF;text-decoration:none;margin-left:auto;font-weight:400}
    .readme-body{color:#ccc}
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
  <a href="https://console.blackroad.io">Console</a>
  <a href="https://status.blackroad.io">Status</a>
</nav>
<div class="layout">
  <div class="sidebar">
    <div class="sidebar-title">Documentation</div>
    ${repoLinks}
    <div style="margin-top:1.5rem;padding-top:1rem;border-top:1px solid #111">
      <div class="sidebar-title">Organization</div>
      <div style="color:#555;font-size:.82rem">${org?.public_repos || 21} repositories</div>
      <a href="https://github.com/${GH_ORG}" style="color:#2979FF;font-size:.82rem;text-decoration:none" target="_blank">View on GitHub →</a>
    </div>
  </div>
  <div class="content">
    <div class="content-title">
      ${current.icon} ${current.title}
      <a href="https://github.com/${GH_ORG}/${repoParam}" target="_blank" class="gh-link">View on GitHub →</a>
    </div>
    <div class="readme-body">${markdownToHtml(readme)}</div>
  </div>
</div>
<div class="footer">BlackRoad OS, Inc. © ${new Date().getFullYear()} — Updated ${now}</div>
</body>
</html>`;

    return new Response(html, {
      headers: {
        'Content-Type': 'text/html;charset=UTF-8',
        'Cache-Control': 'public, max-age=60',
        'X-BlackRoad-Worker': 'docs-blackroadio',
        'X-BlackRoad-Version': '2.0.0',
      },
    });
  },
};
