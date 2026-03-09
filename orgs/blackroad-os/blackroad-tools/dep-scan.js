#!/usr/bin/env node
/**
 * dep-scan.js
 * Scans a project directory for `require()` and `import` usage, determines missing
 * npm packages, and installs them when `--save` is provided.
 *
 * Usage:
 *   node tools/dep-scan.js --dir /path/to/api --save
 */
const fs = require('fs');
const path = require('path');
const cp = require('child_process');
const { builtinModules } = require('module');

const args = process.argv.slice(2);
let targetDir = process.cwd();
let doSave = false;
for (let i = 0; i < args.length; i++) {
  if (args[i] === '--dir' && args[i+1]) {
    targetDir = path.resolve(args[i+1]); i++;
  } else if (args[i] === '--save') {
    doSave = true;
  }
}

function isBuiltin(mod) {
  if (!mod) return false;
  const clean = mod.startsWith('node:') ? mod.slice(5) : mod;
  return builtinModules.includes(clean) || builtinModules.includes(mod);
}

function toRootSpec(spec) {
  // '@scope/pkg/sub/path' -> '@scope/pkg'
  // 'lodash/get' -> 'lodash'
  if (!spec) return spec;
  if (spec.startsWith('@')) {
    const parts = spec.split('/');
    return parts.length >= 2 ? parts.slice(0,2).join('/') : spec;
  }
  const parts = spec.split('/');
  return parts[0];
}

const IGNORE_DIRS = new Set(['node_modules', '.git', 'dist', 'build', 'ops', 'tools']);
const JS_EXTS = new Set(['.js', '.mjs', '.cjs', '.ts', '.tsx', '.jsx']);

function listFiles(dir) {
  let acc = [];
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    if (IGNORE_DIRS.has(entry.name)) continue;
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) acc = acc.concat(listFiles(full));
    else if (JS_EXTS.has(path.extname(entry.name))) acc.push(full);
  }
  return acc;
}

function extractRequires(filePath) {
  const src = fs.readFileSync(filePath, 'utf8');
  const specs = new Set();
  const reRequire = /require\s*\(\s*['"]([^'"]+)['"]\s*\)/g;
  const reImport1 = /import\s+[^'"]*?from\s*['"]([^'"]+)['"]/g;
  const reImport2 = /import\s*['"]([^'"]+)['"]/g;
  let m;
  while ((m = reRequire.exec(src))) specs.add(m[1]);
  while ((m = reImport1.exec(src))) specs.add(m[1]);
  while ((m = reImport2.exec(src))) specs.add(m[1]);
  return Array.from(specs);
}

function isExternal(spec) {
  // ignore relative/absolute paths
  if (!spec) return false;
  if (spec.startsWith('.') || spec.startsWith('/') || spec.startsWith('file:')) return false;
  return true;
}

function isInstalled(pkg, dir) {
  try {
    require.resolve(pkg, { paths: [dir] });
    return true;
  } catch {
    return false;
  }
}

function readPkgJson(dir) {
  const p = path.join(dir, 'package.json');
  if (!fs.existsSync(p)) return null;
  try { return JSON.parse(fs.readFileSync(p, 'utf8')); }
  catch { return null; }
}

console.log(`dep-scan: scanning ${targetDir}`);
if (!fs.existsSync(targetDir) || !fs.lstatSync(targetDir).isDirectory()) {
  console.error('ERROR: --dir must be a directory');
  process.exit(1);
}

const files = listFiles(targetDir);
const foundSpecs = new Set();
for (const f of files) {
  for (const spec of extractRequires(f)) {
    if (isExternal(spec)) foundSpecs.add(toRootSpec(spec));
  }
}

// filter builtins
const candidates = Array.from(foundSpecs).filter(s => !isBuiltin(s));

// remove ones already in package.json
const pkg = readPkgJson(targetDir) || { dependencies: {}, devDependencies: {} };
const declared = new Set([
  ...Object.keys(pkg.dependencies || {}),
  ...Object.keys(pkg.devDependencies || {}),
]);

const missing = candidates.filter(s => !declared.has(s) && !isInstalled(s, targetDir)).sort();

if (missing.length === 0) {
  console.log('dep-scan: no missing packages 🎉');
  process.exit(0);
}

console.log('dep-scan: missing packages detected:');
for (const m of missing) console.log('  -', m);

if (doSave) {
  // Prefer safe, common picks if they appear:
  // e.g., use bcryptjs instead of bcrypt when scanning finds "bcrypt"
  const replacements = { bcrypt: 'bcryptjs' };
  const finalList = missing.map(m => replacements[m] || m);
  console.log('\nInstalling:', finalList.join(' '));
  try {
    cp.execSync(`npm install --save ${finalList.join(' ')}`, {
      cwd: targetDir, stdio: 'inherit', env: process.env,
    });
  } catch (e) {
    console.error('dep-scan: install failed:', e.message);
    process.exit(2);
  }
  console.log('dep-scan: installation complete');
} else {
  console.log('\nRun with --save to install automatically.');
}
