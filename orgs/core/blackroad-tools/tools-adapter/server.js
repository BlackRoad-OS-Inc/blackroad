#!/usr/bin/env node
import express from "express";
import dotenv from "dotenv";
import rateLimit from "express-rate-limit";
import crypto from "crypto";
import { execFile } from "node:child_process";
import { readFile, writeFile } from "node:fs/promises";

dotenv.config();

const app = express();
app.use(express.json({ limit: "512kb" }));

// Basic rate limit
app.use(rateLimit({ windowMs: 15 * 60 * 1000, max: 300 }));

// Auth middleware
app.use((req, res, next) => {
  const token = req.get("X-Tools-Token");
  if (!token || token !== process.env.TOOLS_TOKEN) {
    return res.status(401).json({ ok: false, error: "Unauthorized" });
  }
  next();
});

// Helpers
const mask = (v) => {
  if (!v) return "";
  const tail = v.slice(-4);
  return `****${tail}`;
};

const channelAliases = {
  dev_prs: process.env.CHANNEL_DEV_PRS,
  dev_ci: process.env.CHANNEL_DEV_CI,
  releases: process.env.CHANNEL_RELEASES,
  security: process.env.CHANNEL_SECURITY,
};

const serviceAliases = {
  asana_default_project: process.env.ASANA_PROJECT_ID_MAIN,
  asana_ops_project: process.env.ASANA_PROJECT_ID_OPS,
  airtable_default_base: process.env.AIRTABLE_BASE_ID_MAIN,
  airtable_backlog_table: process.env.AIRTABLE_TABLE_BACKLOG,
  gitlab_group: process.env.GITLAB_GROUP,
  github_org: process.env.GITHUB_ORG,
};

const piAliases = {
  pi_core: process.env.PI_CORE_HOST || "pi-core",
  // add more: pi_builder, pi_observer
};

// Simple in-memory cache for memory_* (you may back by Redis)
const mem = new Map();

// Tool implementations
async function ask_cloud(args) {
  // Placeholder: your cloud LLM endpoint here
  // Return structure consistent with tool result
  return { answer: "(cloud answer placeholder)", citations: [] };
}

async function ping_pi(args) {
  const hostAlias = args.hostAlias || "pi_core";
  const host = piAliases[hostAlias];
  if (!host) throw new Error(`Unknown hostAlias: ${hostAlias}`);

  const cmd = args.command || "uname -a";
  const cmdArgs = Array.isArray(args.args) ? args.args : [];

  const sshArgs = ["-F", `${process.env.HOME}/.ssh/config`, host, cmd, ...cmdArgs];
  return new Promise((resolve) => {
    execFile("ssh", sshArgs, { timeout: 15000 }, (err, stdout, stderr) => {
      resolve({
        stdout: (stdout || "").slice(0, 20000),
        stderr: (stderr || "").slice(0, 20000),
        exitCode: err ? (err.code ?? 1) : 0,
      });
    });
  });
}

async function get_secret(args) {
  const name = args.name;
  if (!name) throw new Error("name required");
  const value = process.env[name];
  if (!value) throw new Error(`secret ${name} not found`);
  return { name, maskedPreview: mask(value), scope: "env" };
}

async function use_secret(args) {
  // Ticket pattern: surface a short-lived token reference; never the value
  const { name, purpose, target } = args;
  if (!name) throw new Error("name required");
  const value = process.env[name];
  if (!value) throw new Error(`secret ${name} not found`);

  // Compute a ticket id; wrapper keeps a map from ticket -> value for next call
  const ticket = crypto.randomBytes(8).toString("hex");
  tickets.set(ticket, { name, value, purpose, target, ts: Date.now() });
  // GC tickets after 60s
  setTimeout(() => tickets.delete(ticket), 60000);

  return { ticket, name, maskedPreview: mask(value), purpose, target };
}

const tickets = new Map();

// Resolve endpoint from aliases or literal URL
function resolveEndpoint(urlOrAlias) {
  if (urlOrAlias?.startsWith("channel_alias:")) {
    const key = urlOrAlias.split(":")[1];
    const url = channelAliases[key];
    if (!url) throw new Error(`Unknown channel alias: ${key}`);
    return url;
  }
  if (urlOrAlias?.startsWith("service_alias:")) {
    const key = urlOrAlias.split(":")[1];
    const id = serviceAliases[key];
    if (!id) throw new Error(`Unknown service alias: ${key}`);
    return id;
  }
  return urlOrAlias;
}

async function http_request(args) {
  const fetch = (await import("node-fetch")).default;
  let { method, url, headers, body, ticket } = args;

  method = (method || "GET").toUpperCase();
  url = resolveEndpoint(url);

  const reqHeaders = Object.assign({}, headers || {});
  let reqBody = body ? JSON.stringify(body) : undefined;

  // If a ticket is present, inject secret
  if (ticket) {
    const entry = tickets.get(ticket);
    if (!entry) throw new Error("Invalid or expired ticket");
    // Example: Slack webhook uses url; Asana uses Authorization header
    if (/slack|discord|webhook/.test(url)) {
      // url-based secret not needed; assume url already includes secret or env mapping
    } else if (/asana\.com/.test(url)) {
      reqHeaders["Authorization"] = `Bearer ${entry.value}`;
    } else if (/airtable\.com/.test(url)) {
      reqHeaders["Authorization"] = `Bearer ${entry.value}`;
    }
  }

  const r = await fetch(url, { method, headers: reqHeaders, body: reqBody });
  const text = await r.text();
  return { status: r.status, ok: r.ok, body: text.slice(0, 50000) };
}

async function repo_dispatch(args) {
  // Typically called via GitHub API with GITHUB_TOKEN or PAT
  // You may proxy or use octokit here; for demo, return a stub
  return { dispatched: true, eventType: args.eventType, payload: args.payload || {} };
}

async function git_ops(args) {
  const { action, params } = args;
  if (action === "git_mirror") {
    // Example: push --mirror using SSH private key from env
    const privKey = process.env.GITLAB_SSH_PRIVATE_KEY;
    const target = process.env.GITLAB_REPO_SSH || (params && params.target);
    if (!privKey || !target) throw new Error("Missing SSH key or target");

    // Write temp key
    const keyPath = "/tmp/gitlab_key";
    await writeFile(keyPath, privKey, { mode: 0o600 });
    const script = `
      set -e
      git config --global user.name "bbx-bot"
      git config --global user.email "bbx-bot@local"
      eval $(ssh-agent -s)
      ssh-add ${keyPath}
      git remote remove gitlab || true
      git remote add gitlab "${target}"
      git push --mirror gitlab
    `;
    return new Promise((resolve) => {
      execFile("bash", ["-lc", script], { timeout: 60000 }, (err, stdout, stderr) => {
        resolve({
          stdout: (stdout || "").slice(0, 20000),
          stderr: (stderr || "").slice(0, 20000),
          exitCode: err ? (err.code ?? 1) : 0,
        });
      });
    });
  }
  throw new Error(`unsupported git_ops action: ${action}`);
}

async function file_read(args) {
  const { path } = args;
  const data = await readFile(path, "utf8");
  return { path, contents: data.slice(0, 50000) };
}
async function file_write(args) {
  const { path, contents } = args;
  await writeFile(path, contents, "utf8");
  return { path, ok: true };
}
async function memory_remember(args) {
  const { key, value, ttl } = args;
  mem.set(key, { value, expires: ttl ? Date.now() + ttl : null });
  return { key, ok: true };
}
async function memory_recall(args) {
  const { key } = args;
  const v = mem.get(key);
  if (!v) return { key, value: null };
  if (v.expires && Date.now() > v.expires) {
    mem.delete(key);
    return { key, value: null };
  }
  return { key, value: v.value };
}

// Dispatcher
const handlers = {
  ask_cloud,
  ping_pi,
  get_secret,
  use_secret,
  repo_dispatch,
  git_ops,
  file_read,
  file_write,
  http_request,
  memory_remember,
  memory_recall,
};

app.post("/tools/invoke", async (req, res) => {
  const { tool, id, args } = req.body || {};
  if (!tool || !id || typeof args !== "object") {
    return res.status(400).json({ ok: false, error: "Invalid body; require tool,id,args" });
  }
  const fn = handlers[tool];
  if (!fn) return res.status(400).json({ ok: false, error: `Unsupported tool: ${tool}` });

  try {
    const result = await fn(args || {});
    return res.json({ id, ok: true, result });
  } catch (e) {
    return res.json({ id, ok: false, error: String(e.message || e) });
  }
});

const port = Number(process.env.TOOLS_PORT || 8787);
app.listen(port, () => {
  console.log(`Tools adapter listening on :${port}`);
});
