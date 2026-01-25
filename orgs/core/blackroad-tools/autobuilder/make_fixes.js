import fs from 'fs';
import path from 'path';

import { computeKPIs } from '../kpis/compute.js';
import { evaluateBudgets } from '../policies/check_budgets.js';

const DEFAULT_INDEX = 'data/timemachine/index.json';
const SAFE_RELATIVE_PATHS = [
  'sites/blackroad/public',
  'docs',
  'pulses',
  'data',
  'frontend/public',
];

function escapeRegExp(text) {
  return text.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function createGuard(projectRoot) {
  const safeRoots = SAFE_RELATIVE_PATHS.map((relative) => path.resolve(projectRoot, relative));
  return function assertSafe(targetPath) {
    const resolved = path.resolve(targetPath);
    for (const safeRoot of safeRoots) {
      if (resolved.startsWith(safeRoot)) {
        return;
      }
    }
    throw new Error(`Path ${resolved} is outside the SAFE_PATHS whitelist.`);
  };
}

function ensureDirectory(filePath) {
  fs.mkdirSync(path.dirname(filePath), { recursive: true });
}

function ensurePreload(projectRoot, assertSafe) {
  const htmlPath = path.resolve(projectRoot, 'sites/blackroad/public/index.html');
  if (!fs.existsSync(htmlPath)) return false;
  assertSafe(htmlPath);
  const original = fs.readFileSync(htmlPath, 'utf-8');

  const imgMatch = original.match(/<img\b[^>]*src="([^"]+)"[^>]*>/i);
  if (!imgMatch) return false;
  const [imgTag, src] = imgMatch;
  let updated = original;

  if (!/fetchpriority=/i.test(imgTag)) {
    const replacement = imgTag.replace('<img', '<img fetchpriority="high"');
    updated = updated.replace(imgTag, replacement);
  }

  const preloadTag = `<link rel="preload" as="image" href="${src}" fetchpriority="high">`;
  const preloadRegex = new RegExp(`<link[^>]*rel="preload"[^>]*href="${escapeRegExp(src)}"`, 'i');
  if (!preloadRegex.test(updated)) {
    updated = updated.replace('</head>', `  ${preloadTag}\n</head>`);
  }

  if (updated !== original) {
    fs.writeFileSync(htmlPath, updated, 'utf-8');
    return true;
  }
  return false;
}

function ensureCacheHeaders(projectRoot, assertSafe) {
  const headersPath = path.resolve(projectRoot, 'sites/blackroad/public/_headers');
  assertSafe(headersPath);
  const desiredBlocks = [
    '/*\n  Cache-Control: public, max-age=600\n',
    '/assets/*\n  Cache-Control: public, max-age=31536000, immutable\n',
  ];

  let content = '';
  if (fs.existsSync(headersPath)) {
    content = fs.readFileSync(headersPath, 'utf-8');
  }

  let changed = false;
  for (const block of desiredBlocks) {
    if (!content.includes(block)) {
      content = `${content.trim()}\n${block}`.trim() + '\n';
      changed = true;
    }
  }

  if (changed || !fs.existsSync(headersPath)) {
    ensureDirectory(headersPath);
    fs.writeFileSync(headersPath, `${content.trim()}\n`, 'utf-8');
    return true;
  }
  return false;
}

function listHtmlFiles(baseDir) {
  if (!fs.existsSync(baseDir)) return [];
  const files = [];
  const stack = [baseDir];
  while (stack.length) {
    const current = stack.pop();
    const entries = fs.readdirSync(current, { withFileTypes: true });
    for (const entry of entries) {
      const entryPath = path.join(current, entry.name);
      if (entry.isDirectory()) {
        stack.push(entryPath);
      } else if (entry.name.endsWith('.html')) {
        files.push(entryPath);
      }
    }
  }
  return files;
}

function ensureAltAttributes(projectRoot, assertSafe) {
  const publicDir = path.resolve(projectRoot, 'sites/blackroad/public');
  if (!fs.existsSync(publicDir)) return false;
  const files = listHtmlFiles(publicDir);
  let changed = false;
  for (const filePath of files) {
    assertSafe(filePath);
    const original = fs.readFileSync(filePath, 'utf-8');
    const updated = original.replace(/<img\b([^>]*?)>/gi, (match) => {
      if (/alt\s*=/.test(match)) {
        return match;
      }
      const selfClosing = match.endsWith('/>');
      const suffix = selfClosing ? '/>' : '>';
      const trimmed = match.slice(0, match.length - suffix.length);
      return `${trimmed} alt=""${suffix}`;
    });
    if (updated !== original) {
      fs.writeFileSync(filePath, updated, 'utf-8');
      changed = true;
    }
  }
  return changed;
}

function refreshSitemap(projectRoot, assertSafe) {
  const sitemapPath = path.resolve(projectRoot, 'sites/blackroad/public/sitemap.xml');
  const robotsPath = path.resolve(projectRoot, 'sites/blackroad/public/robots.txt');
  const today = new Date().toISOString().split('T')[0];
  let changed = false;

  if (fs.existsSync(sitemapPath)) {
    assertSafe(sitemapPath);
    const original = fs.readFileSync(sitemapPath, 'utf-8');
    let updated = original;
    if (/<lastmod>[^<]*<\/lastmod>/i.test(original)) {
      updated = original.replace(/<lastmod>[^<]*<\/lastmod>/i, `<lastmod>${today}</lastmod>`);
    } else {
      updated = original.replace('</url>', `  <lastmod>${today}</lastmod>\n</url>`);
    }
    if (updated !== original) {
      fs.writeFileSync(sitemapPath, updated, 'utf-8');
// tools/autobuilder/make_fixes.js
// Usage: node tools/autobuilder/make_fixes.js --index data/timemachine/index.json
import fs from "node:fs";
import path from "node:path";

const args = Object.fromEntries(process.argv.slice(2).map((x,i,arr)=>{
  if (x.startsWith("--")) return [x.replace(/^--/,""), arr[i+1] && !arr[i+1].startsWith("--") ? arr[i+1] : true];
  return [null,null];
}).filter(Boolean));

const INDEX = args.index || "data/timemachine/index.json";
function ensureDir(p){ fs.mkdirSync(path.dirname(p), {recursive:true}); }
function log(action, payload={}){
  const line = JSON.stringify({ts:new Date().toISOString(), action, ...payload});
  ensureDir("data/aiops/actions.jsonl");
  fs.appendFileSync("data/aiops/actions.jsonl", line+"\n");
}

function upsertFile(p, content, tag){
  const exists = fs.existsSync(p);
  fs.mkdirSync(path.dirname(p), {recursive:true});
  fs.writeFileSync(p, content, "utf8");
  log("write_file", {path:p, tag, existed:exists});
}

const index = JSON.parse(fs.readFileSync(INDEX, "utf8"));

//
// 1) HTML tweaks (index.html) — add fetchpriority + alt; add preload hint if missing.
//
const INDEX_HTML = "sites/blackroad/public/index.html";
if (fs.existsSync(INDEX_HTML)) {
  let html = fs.readFileSync(INDEX_HTML, "utf8");
  let changed = false;

  // add fetchpriority="high" to first <img ...> if not present
  html = html.replace(/<img([^>]*?)>/i, (m, attrs)=>{
    if (/fetchpriority=/i.test(attrs)) return m;
    changed = true;
    if (!/alt=/i.test(attrs)) attrs += ' alt=""';
    return `<img${attrs} fetchpriority="high">`;
  });

  // add a generic preload for first stylesheet/script if no preload present
  if (!/rel=["']preload["']/.test(html)) {
    const mCss = html.match(/href=["']([^"']+\.css)["']/i);
    const mJs  = html.match(/src=["']([^"']+\.js)["']/i);
    if (mCss) {
      const link = `<link rel="preload" as="style" href="${mCss[1]}">`;
      html = html.replace(/<head>/i, `<head>\n  ${link}`);
      changed = true;
    } else if (mJs) {
      const link = `<link rel="preload" as="script" href="${mJs[1]}">`;
      html = html.replace(/<head>/i, `<head>\n  ${link}`);
      changed = true;
    }
  }

  const robotsLine = 'Sitemap: /sitemap.xml';
  assertSafe(robotsPath);
  let robotsContent = '';
  if (fs.existsSync(robotsPath)) {
    robotsContent = fs.readFileSync(robotsPath, 'utf-8');
  }
  if (!robotsContent.includes(robotsLine)) {
    robotsContent = `${robotsContent.trim()}\n${robotsLine}`.trim() + '\n';
    ensureDirectory(robotsPath);
    fs.writeFileSync(robotsPath, robotsContent, 'utf-8');
    changed = true;
  }

  return changed;
}

function runBudgetCheck(indexPath) {
  if (!indexPath || !fs.existsSync(indexPath)) {
    return [];
  }
  const index = JSON.parse(fs.readFileSync(indexPath, 'utf-8'));
  const report = computeKPIs(index);
  return evaluateBudgets(report);
}

function parseArgs(argv) {
  const options = {
    indexPath: DEFAULT_INDEX,
    projectRoot: process.cwd(),
    skipBudgets: false,
  };
  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (arg === '--index') {
      options.indexPath = argv[i + 1];
      i += 1;
    } else if (arg === '--root') {
      options.projectRoot = argv[i + 1];
      i += 1;
    } else if (arg === '--no-budget-check') {
      options.skipBudgets = true;
    }
  }
  return options;
}

function main(argv) {
  const options = parseArgs(argv);
  const assertSafe = createGuard(options.projectRoot);

  const actions = [];
  if (ensurePreload(options.projectRoot, assertSafe)) actions.push('preload');
  if (ensureCacheHeaders(options.projectRoot, assertSafe)) actions.push('cache-headers');
  if (ensureAltAttributes(options.projectRoot, assertSafe)) actions.push('alt-text');
  if (refreshSitemap(options.projectRoot, assertSafe)) actions.push('sitemap');

  if (!actions.length) {
    console.log('Autobuilder: no changes applied.');
  } else {
    console.log(`Autobuilder: applied fixes -> ${actions.join(', ')}`);
  }

  let exitCode = 0;
  if (!options.skipBudgets) {
    const issues = runBudgetCheck(options.indexPath ? path.resolve(options.indexPath) : null);
    if (issues.length) {
      exitCode = 1;
      for (const issue of issues) {
        console.error(`Budget violation: ${issue}`);
      }
    }
  }

  process.exit(exitCode);
}

if (import.meta.url === `file://${process.argv[1]}`) {
  main(process.argv.slice(2));
}
  if (changed) {
    fs.writeFileSync(INDEX_HTML, html, "utf8");
    log("modify_html", {path: INDEX_HTML});
  }
}

//
// 2) Static hosting headers — write _headers for cache policy (safe)
//
const HEADERS = "sites/blackroad/public/_headers";
if (!fs.existsSync(HEADERS)) {
  const content = `/*
  Cache-Control: no-store

/assets/*
  Cache-Control: public, max-age=604800, immutable
`;
  upsertFile(HEADERS, content, "cache_headers");
}

//
// 3) robots.txt & sitemap.xml if missing
//
const ROBOTS = "sites/blackroad/public/robots.txt";
if (!fs.existsSync(ROBOTS)) {
  upsertFile(ROBOTS, `User-agent: *\nAllow: /\nSitemap: https://blackroad.io/sitemap.xml\n`, "robots");
}
const SITEMAP = "sites/blackroad/public/sitemap.xml";
if (!fs.existsSync(SITEMAP)) {
  upsertFile(SITEMAP, `<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url><loc>https://blackroad.io/</loc></url>
  <url><loc>https://blackroad.io/portal</loc></url>
  <url><loc>https://blackroad.io/status</loc></url>
</urlset>`, "sitemap");
}

console.log("Autobuilder completed.");
