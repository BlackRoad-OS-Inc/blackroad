// Template Library - Raw templates for fetching
import { CSS, HEADER, FOOTER, layout } from './base.js';

// Templates index page
export function index() {
  return layout('Templates', 'BlackRoad template library', `
    <section class="hero" style="padding: 80px 0 40px;">
      <div class="container">
        <h1><span>Templates</span></h1>
        <p>Fetch components and layouts for BlackRoad sites. All templates use {Variable} replacement.</p>
      </div>
    </section>

    <section class="section" style="padding-top: 0;">
      <div class="container">
        <style>
          .template-list { margin-top: 32px; }
          .template-item {
            display: flex; align-items: center; justify-content: space-between;
            background: var(--gray-900); border: 1px solid var(--gray-800);
            border-radius: 8px; padding: 16px 20px; margin-bottom: 8px; transition: all 0.15s;
          }
          .template-item:hover { border-color: var(--gray-600); }
          .template-info { flex: 1; }
          .template-name { font-family: var(--font-mono); font-size: 14px; color: var(--gray-100); }
          .template-desc { font-size: 13px; color: var(--gray-500); margin-top: 2px; }
          .template-url {
            font-family: var(--font-mono); font-size: 11px; color: var(--accent-6);
            background: rgba(30, 144, 255, 0.1); padding: 6px 10px; border-radius: 4px;
          }
          .section-label {
            font-family: var(--font-mono); font-size: 11px; text-transform: uppercase;
            letter-spacing: 0.1em; color: var(--gray-500); margin: 48px 0 16px;
            padding-bottom: 8px; border-bottom: 1px solid var(--gray-800);
          }
          .code-block {
            background: var(--gray-900); border: 1px solid var(--gray-800);
            border-radius: 8px; padding: 20px; margin-top: 32px; overflow-x: auto;
          }
          .code-block pre { font-family: var(--font-mono); font-size: 13px; color: var(--gray-300); line-height: 1.6; }
        </style>
        
        <div class="section-label">Stylesheets</div>
        <div class="template-list">
          <div class="template-item">
            <div class="template-info">
              <div class="template-name">base.css</div>
              <div class="template-desc">Core design system — fonts, colors, utilities, components</div>
            </div>
            <code class="template-url">/templates/base.css</code>
          </div>
        </div>
        
        <div class="section-label">Components</div>
        <div class="template-list">
          <div class="template-item">
            <div class="template-info"><div class="template-name">header</div><div class="template-desc">Navigation header with logo, links, and CTAs</div></div>
            <code class="template-url">/templates/components/header</code>
          </div>
          <div class="template-item">
            <div class="template-info"><div class="template-name">footer</div><div class="template-desc">Site footer with links and copyright</div></div>
            <code class="template-url">/templates/components/footer</code>
          </div>
        </div>
        
        <div class="section-label">Layouts</div>
        <div class="template-list">
          <div class="template-item">
            <div class="template-info"><div class="template-name">base</div><div class="template-desc">Full HTML document with {Header}, {Body}, {Footer} slots</div></div>
            <code class="template-url">/templates/layouts/base</code>
          </div>
        </div>
        
        <div class="section-label">Page Templates</div>
        <div class="template-list">
          <div class="template-item">
            <div class="template-info"><div class="template-name">home</div><div class="template-desc">Hero section with headline, subheadline, CTAs</div></div>
            <code class="template-url">/templates/pages/home</code>
          </div>
          <div class="template-item">
            <div class="template-info"><div class="template-name">about</div><div class="template-desc">Simple content page with header and prose</div></div>
            <code class="template-url">/templates/pages/about</code>
          </div>
          <div class="template-item">
            <div class="template-info"><div class="template-name">404</div><div class="template-desc">Error page with large code and back link</div></div>
            <code class="template-url">/templates/pages/404</code>
          </div>
          <div class="template-item">
            <div class="template-info"><div class="template-name">coming-soon</div><div class="template-desc">Placeholder page for unreleased features</div></div>
            <code class="template-url">/templates/pages/coming-soon</code>
          </div>
        </div>
        
        <div class="section-label">Usage Example</div>
        <div class="code-block">
          <pre>// Cloudflare Worker Example
const [layout, header, footer] = await Promise.all([
  fetch('https://blackroad.io/templates/layouts/base').then(r => r.text()),
  fetch('https://blackroad.io/templates/components/header').then(r => r.text()),
  fetch('https://blackroad.io/templates/components/footer').then(r => r.text()),
]);

const page = layout
  .replace('{Title}', 'My Page')
  .replace('{Description}', 'Page description')
  .replace('{Header}', header)
  .replace('{Body}', '&lt;h1&gt;Hello World&lt;/h1&gt;')
  .replace('{Footer}', footer);</pre>
        </div>
      </div>
    </section>
  `);
}

// Raw CSS for fetching
export function baseCSS() {
  return `/* BlackRoad Design System - base.css */
@import url('https://fonts.googleapis.com/css2?family=Space+Grotesk:wght@600;700&family=Inter:wght@400;500;600&family=JetBrains+Mono:wght@400;500&display=swap');

:root {
  --font-headline: 'Space Grotesk', sans-serif;
  --font-body: 'Inter', sans-serif;
  --font-mono: 'JetBrains Mono', monospace;

  --gray-950: #0a0a0a; --gray-900: #171717; --gray-800: #262626; --gray-700: #404040;
  --gray-600: #525252; --gray-500: #737373; --gray-400: #a3a3a3; --gray-300: #d4d4d4;
  --gray-200: #e5e5e5; --gray-100: #f5f5f5;

  --accent-orange: #ff8700; --accent-dark-orange: #ff5f00; --accent-pink: #ff0087;
  --accent-orchid: #af5fd7; --accent-magenta: #ff00ff; --accent-blue: #1e90ff;

  --bg-primary: var(--gray-950); --bg-secondary: var(--gray-900); --bg-elevated: var(--gray-800);
  --text-primary: var(--gray-100); --text-secondary: var(--gray-400); --text-muted: var(--gray-500);
  --border-default: var(--gray-800); --border-hover: var(--gray-700);
}

*, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
html { font-size: 16px; -webkit-font-smoothing: antialiased; }
body { font-family: var(--font-body); color: var(--text-primary); background: var(--bg-primary); min-height: 100vh; }
h1, h2, h3 { font-family: var(--font-headline); font-weight: 600; line-height: 1.2; }
code, pre, .mono { font-family: var(--font-mono); }
a { color: var(--accent-blue); text-decoration: none; }
.container { max-width: 1200px; margin: 0 auto; padding: 0 1.5rem; }
.gradient-text {
  background: linear-gradient(90deg, var(--accent-orange), var(--accent-pink), var(--accent-magenta), var(--accent-blue));
  -webkit-background-clip: text; -webkit-text-fill-color: transparent;
}
.btn { display: inline-flex; padding: 0.625rem 1.25rem; border-radius: 6px; font-weight: 500; cursor: pointer; transition: all 0.15s; border: none; }
.btn-primary { background: var(--gray-100); color: var(--gray-900); }
.btn-ghost { background: transparent; border: 1px solid var(--border-default); color: var(--text-secondary); }
.card { background: var(--bg-secondary); border: 1px solid var(--border-default); border-radius: 8px; padding: 1.5rem; }
`;
}

// Raw header component
export function header() {
  return `<!-- BlackRoad Header Component -->
<header class="br-header">
  <div class="container">
    <nav class="br-nav">
      <a href="/" class="br-logo"><span class="gradient-text">BlackRoad</span></a>
      <div class="br-nav-links">
        <a href="/products">Products</a>
        <a href="/developers">Developers</a>
        <a href="/docs">Docs</a>
      </div>
      <div class="br-nav-actions">
        <a href="/login" class="btn btn-ghost">Sign In</a>
        <a href="/signup" class="btn btn-primary">Get Started</a>
      </div>
    </nav>
  </div>
</header>
<style>
.br-header { position: sticky; top: 0; z-index: 100; background: rgba(10,10,10,0.8); backdrop-filter: blur(12px); border-bottom: 1px solid var(--border-default); padding: 1rem 0; }
.br-nav { display: flex; align-items: center; justify-content: space-between; gap: 2rem; }
.br-logo { font-family: var(--font-headline); font-size: 1.5rem; font-weight: 700; }
.br-nav-links { display: flex; gap: 2rem; }
.br-nav-links a { color: var(--text-secondary); font-size: 0.875rem; }
.br-nav-actions { display: flex; gap: 0.75rem; }
</style>`;
}

// Raw footer component
export function footer() {
  return `<!-- BlackRoad Footer Component -->
<footer class="br-footer">
  <div class="container">
    <div class="br-footer-grid">
      <div class="br-footer-brand">
        <a href="/" class="br-logo"><span class="gradient-text">BlackRoad</span></a>
        <p>AI infrastructure for the next era</p>
      </div>
      <div class="br-footer-links">
        <div class="br-footer-col"><h4>Products</h4><a href="/lucidia">Lucidia</a><a href="/prism">Prism</a></div>
        <div class="br-footer-col"><h4>Developers</h4><a href="/docs">Docs</a><a href="https://github.com/BlackRoad-OS">GitHub</a></div>
        <div class="br-footer-col"><h4>Company</h4><a href="/about">About</a><a href="/contact">Contact</a></div>
      </div>
    </div>
    <div class="br-footer-bottom"><p>© 2025 BlackRoad OS, Inc.</p></div>
  </div>
</footer>
<style>
.br-footer { background: var(--bg-secondary); border-top: 1px solid var(--border-default); padding: 4rem 0 2rem; }
.br-footer-grid { display: grid; grid-template-columns: 1.5fr 3fr; gap: 4rem; }
.br-footer-links { display: grid; grid-template-columns: repeat(3, 1fr); gap: 2rem; }
.br-footer-col h4 { font-size: 0.75rem; text-transform: uppercase; color: var(--text-secondary); margin-bottom: 1rem; }
.br-footer-col a { display: block; color: var(--text-muted); font-size: 0.875rem; padding: 0.25rem 0; }
.br-footer-bottom { border-top: 1px solid var(--border-default); margin-top: 3rem; padding-top: 1.5rem; }
.br-footer-bottom p { color: var(--text-muted); font-size: 0.75rem; }
</style>`;
}

// Base layout template
export function baseLayout() {
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>{Title} | BlackRoad</title>
  <meta name="description" content="{Description}">
  <link rel="stylesheet" href="https://blackroad.io/templates/base.css">
  {HeadExtras}
</head>
<body>
  {Header}
  <main>{Body}</main>
  {Footer}
  {Scripts}
</body>
</html>
<!-- VARIABLES: {Title}, {Description}, {HeadExtras}, {Header}, {Body}, {Footer}, {Scripts} -->`;
}

// Page templates
export function homePage() {
  return `<!-- Home Page Template -->
<section class="hero">
  <div class="container">
    <h1 class="hero-title"><span class="gradient-text">{Headline}</span></h1>
    <p class="hero-subtitle">{Subheadline}</p>
    <div class="hero-actions">
      <a href="{PrimaryCTA_URL}" class="btn btn-primary">{PrimaryCTA}</a>
      <a href="{SecondaryCTA_URL}" class="btn btn-ghost">{SecondaryCTA}</a>
    </div>
  </div>
</section>
<style>
.hero { padding: 8rem 0 6rem; text-align: center; }
.hero-title { font-size: 4rem; font-weight: 700; margin-bottom: 1.5rem; }
.hero-subtitle { font-size: 1.25rem; color: var(--text-secondary); max-width: 600px; margin: 0 auto 2.5rem; }
.hero-actions { display: flex; gap: 1rem; justify-content: center; }
</style>`;
}

export function aboutPage() {
  return `<!-- About Page Template -->
<section class="page-header">
  <div class="container">
    <h1>{PageTitle}</h1>
    <p class="page-lead">{PageLead}</p>
  </div>
</section>
<section class="content-section">
  <div class="container">{Content}</div>
</section>
<style>
.page-header { padding: 6rem 0 3rem; text-align: center; }
.page-header h1 { font-size: 3rem; margin-bottom: 1rem; }
.page-lead { font-size: 1.25rem; color: var(--text-secondary); max-width: 600px; margin: 0 auto; }
.content-section { padding: 3rem 0 6rem; }
</style>`;
}

export function notFoundPage() {
  return `<!-- 404 Page Template -->
<section class="error-page">
  <div class="container">
    <h1 class="error-code">404</h1>
    <p class="error-message">This road doesn't exist. Yet.</p>
    <a href="/" class="btn btn-primary">← Back Home</a>
  </div>
</section>
<style>
.error-page { padding: 8rem 0; text-align: center; }
.error-code { font-size: 8rem; font-weight: 700; color: var(--gray-700); }
.error-message { font-size: 1.25rem; color: var(--text-secondary); margin-bottom: 2rem; }
</style>`;
}

export function comingSoonPage() {
  return `<!-- Coming Soon Template -->
<section class="coming-soon">
  <div class="container">
    <h1><span class="gradient-text">{Title}</span></h1>
    <p>{Message}</p>
    <a href="/" class="btn btn-ghost">← Back to BlackRoad</a>
  </div>
</section>
<style>
.coming-soon { padding: 8rem 0; text-align: center; min-height: 60vh; display: flex; align-items: center; }
.coming-soon h1 { font-size: 3rem; margin-bottom: 1rem; }
.coming-soon p { font-size: 1.125rem; color: var(--text-secondary); margin-bottom: 2rem; }
</style>`;
}
