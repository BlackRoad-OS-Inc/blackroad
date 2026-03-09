// Base templates - CSS, Header, Footer

export const CSS = `
<style>
@import url('https://fonts.googleapis.com/css2?family=Space+Grotesk:wght@600;700&family=Inter:wght@400;500;600&family=JetBrains+Mono:wght@400;500&display=swap');

:root {
  --gray-950: #0a0a0a;
  --gray-900: #171717;
  --gray-800: #262626;
  --gray-700: #404040;
  --gray-600: #525252;
  --gray-500: #737373;
  --gray-400: #a3a3a3;
  --gray-300: #d4d4d4;
  --gray-200: #e5e5e5;
  --gray-100: #f5f5f5;
  
  --accent-1: #ff8700;
  --accent-2: #ff5f00;
  --accent-3: #ff0087;
  --accent-4: #af5fd7;
  --accent-5: #ff00ff;
  --accent-6: #1e90ff;
  
  --font-headline: 'Space Grotesk', sans-serif;
  --font-body: 'Inter', sans-serif;
  --font-mono: 'JetBrains Mono', monospace;
}

* { box-sizing: border-box; margin: 0; padding: 0; }

body {
  background: var(--gray-950);
  color: var(--gray-100);
  font-family: var(--font-body);
  font-size: 16px;
  line-height: 1.6;
  min-height: 100vh;
}

a { color: inherit; text-decoration: none; }

.container { max-width: 1200px; margin: 0 auto; padding: 0 24px; }

header {
  padding: 20px 0;
  border-bottom: 1px solid var(--gray-800);
  position: sticky;
  top: 0;
  background: rgba(10, 10, 10, 0.95);
  backdrop-filter: blur(10px);
  z-index: 100;
}

.header-inner { display: flex; justify-content: space-between; align-items: center; }

.logo { font-family: var(--font-headline); font-size: 24px; font-weight: 700; }
.logo span {
  background: linear-gradient(90deg, var(--accent-1), var(--accent-3), var(--accent-6));
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}

nav { display: flex; gap: 32px; }
nav a { font-size: 14px; color: var(--gray-400); transition: color 0.15s; }
nav a:hover { color: var(--gray-100); }
nav a.active { color: var(--gray-100); }

.hero { padding: 120px 0 80px; text-align: center; }
.hero h1 {
  font-family: var(--font-headline);
  font-size: 72px;
  font-weight: 700;
  letter-spacing: -2px;
  margin-bottom: 24px;
}
.hero h1 span {
  background: linear-gradient(90deg, var(--accent-1), var(--accent-2), var(--accent-3), var(--accent-4), var(--accent-5), var(--accent-6));
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}
.hero p { font-size: 20px; color: var(--gray-400); max-width: 600px; margin: 0 auto 40px; }

.hero-buttons { display: flex; gap: 16px; justify-content: center; flex-wrap: wrap; }

.btn {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 14px 28px;
  font-size: 15px;
  font-weight: 500;
  border-radius: 8px;
  transition: all 0.15s;
  border: none;
  cursor: pointer;
}
.btn-primary { background: var(--gray-100); color: var(--gray-900); }
.btn-primary:hover { background: var(--gray-200); transform: translateY(-1px); }
.btn-ghost { background: transparent; border: 1px solid var(--gray-700); color: var(--gray-300); }
.btn-ghost:hover { border-color: var(--gray-500); color: var(--gray-100); }

.stats {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 24px;
  padding: 60px 0;
  border-top: 1px solid var(--gray-800);
  border-bottom: 1px solid var(--gray-800);
}
.stat { text-align: center; }
.stat-value { font-family: var(--font-headline); font-size: 48px; font-weight: 700; color: var(--accent-6); }
.stat-label { font-size: 14px; color: var(--gray-500); margin-top: 4px; }

.section { padding: 80px 0; }
.section-title { font-family: var(--font-headline); font-size: 36px; font-weight: 700; margin-bottom: 16px; }
.section-desc { color: var(--gray-400); max-width: 600px; margin-bottom: 48px; }

.cards { display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 24px; }
.card {
  background: var(--gray-900);
  border: 1px solid var(--gray-800);
  border-radius: 12px;
  padding: 28px;
  transition: all 0.2s;
}
.card:hover { border-color: var(--gray-700); transform: translateY(-2px); }
.card-icon {
  width: 48px;
  height: 48px;
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 24px;
  margin-bottom: 20px;
}
.card-title { font-family: var(--font-headline); font-size: 18px; font-weight: 600; margin-bottom: 8px; }
.card-desc { font-size: 14px; color: var(--gray-400); margin-bottom: 16px; }
.card-link { font-family: var(--font-mono); font-size: 12px; color: var(--accent-6); }
.card-link:hover { text-decoration: underline; }

.platform-card {
  display: flex;
  align-items: center;
  gap: 16px;
  background: var(--gray-900);
  border: 1px solid var(--gray-800);
  border-radius: 12px;
  padding: 20px 24px;
  transition: all 0.2s;
}
.platform-card:hover { border-color: var(--gray-700); background: var(--gray-800); }
.platform-icon {
  width: 40px;
  height: 40px;
  border-radius: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 20px;
  flex-shrink: 0;
}
.platform-info { flex: 1; }
.platform-name { font-weight: 600; font-size: 15px; margin-bottom: 2px; }
.platform-desc { font-size: 13px; color: var(--gray-500); }
.platform-arrow { color: var(--gray-600); font-size: 18px; }

.github-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 12px; }
.github-org {
  display: flex;
  align-items: center;
  gap: 12px;
  background: var(--gray-900);
  border: 1px solid var(--gray-800);
  border-radius: 8px;
  padding: 14px 16px;
  font-family: var(--font-mono);
  font-size: 13px;
  transition: all 0.15s;
}
.github-org:hover { border-color: var(--gray-600); background: var(--gray-800); }
.github-org svg { width: 20px; height: 20px; fill: var(--gray-400); }

.domain-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(240px, 1fr)); gap: 12px; }
.domain-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  background: var(--gray-900);
  border: 1px solid var(--gray-800);
  border-radius: 8px;
  padding: 14px 16px;
  transition: all 0.15s;
}
.domain-item:hover { border-color: var(--gray-600); }
.domain-name { font-family: var(--font-mono); font-size: 13px; }
.domain-badge {
  font-family: var(--font-mono);
  font-size: 10px;
  padding: 3px 8px;
  border-radius: 4px;
  background: rgba(30, 144, 255, 0.15);
  color: var(--accent-6);
}

footer { padding: 48px 0; border-top: 1px solid var(--gray-800); text-align: center; }
.footer-links { display: flex; justify-content: center; gap: 32px; margin-bottom: 24px; }
.footer-links a { font-size: 14px; color: var(--gray-500); }
.footer-links a:hover { color: var(--gray-300); }
.footer-copy { font-size: 13px; color: var(--gray-600); }

@media (max-width: 768px) {
  .hero h1 { font-size: 48px; }
  .stats { grid-template-columns: repeat(2, 1fr); }
  nav { display: none; }
}
</style>
`;

export const HEADER = `
<header>
  <div class="container header-inner">
    <a href="/" class="logo"><span>BlackRoad</span></a>
    <nav>
      <a href="/">Home</a>
      <a href="/connect">Connect</a>
      <a href="/ecosystem">Ecosystem</a>
      <a href="/github">GitHub</a>
      <a href="/domains">Domains</a>
      <a href="/templates">Templates</a>
      <a href="/design">Design</a>
    </nav>
  </div>
</header>
`;

export const FOOTER = `
<footer>
  <div class="container">
    <div class="footer-links">
      <a href="/instagram">Instagram</a>
      <a href="/stripe">Stripe</a>
      <a href="/cloudflare">Cloudflare</a>
      <a href="/vercel">Vercel</a>
      <a href="/notion">Notion</a>
      <a href="/salesforce">Salesforce</a>
    </div>
    <p class="footer-copy">© 2026 BlackRoad OS, Inc. · Delaware C-Corp</p>
  </div>
</footer>
`;

export function layout(title, description, body) {
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${title} — BlackRoad</title>
  <meta name="description" content="${description}">
  <link rel="icon" type="image/svg+xml" href="data:image/svg+xml,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><text y='.9em' font-size='90'>🛤️</text></svg>">
  ${CSS}
</head>
<body>
  ${HEADER}
  <main>${body}</main>
  ${FOOTER}
</body>
</html>`;
}
