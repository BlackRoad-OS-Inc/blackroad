/**
 * cli-blackroadio — CLI Reference Worker
 * Serves the BR CLI command reference as JSON + HTML.
 */
const COMMANDS = [
  { cmd: "br radar",    desc: "Context radar — file watching + AI suggestions",          usage: "br radar [start|status|suggestions]" },
  { cmd: "br git",      desc: "Smart git — commits, branches, code review",              usage: "br git [commit|suggest|review]" },
  { cmd: "br snippet",  desc: "Snippet manager — save and retrieve code snippets",       usage: "br snippet [add|list|get|delete]" },
  { cmd: "br api",      desc: "HTTP endpoint tester and manager",                        usage: "br api [test|list|add]" },
  { cmd: "br deploy",   desc: "Multi-cloud deployment (Railway/Vercel/CF/DO/Pi)",        usage: "br deploy [--target railway|vercel|cf|do|pi]" },
  { cmd: "br docker",   desc: "Docker/container management",                             usage: "br docker [build|run|ps|stop]" },
  { cmd: "br ci",       desc: "CI/CD pipeline management",                               usage: "br ci [status|trigger|logs]" },
  { cmd: "br cloudflare", desc: "Cloudflare workers/pages management",                  usage: "br cloudflare [deploy|list|tail]" },
  { cmd: "br ocean",    desc: "DigitalOcean droplet management",                         usage: "br ocean [list|create|ssh|snapshot]" },
  { cmd: "br pi",       desc: "Raspberry Pi fleet management",                           usage: "br pi [list|deploy|ssh|status]" },
  { cmd: "br db",       desc: "Database client (SQLite/Postgres/MySQL)",                 usage: "br db [connect|query|list]" },
  { cmd: "br env",      desc: "Environment variable manager",                            usage: "br env [list|set|get|delete]" },
  { cmd: "br note",     desc: "Quick developer notes",                                   usage: "br note [add|list|find|delete]" },
  { cmd: "br logs",     desc: "Log parser with syntax highlighting",                     usage: "br logs [parse|tail|filter]" },
  { cmd: "br perf",     desc: "Performance monitor",                                     usage: "br perf [cpu|mem|net|benchmark]" },
  { cmd: "br security", desc: "Vulnerability scanner",                                   usage: "br security [scan|audit|report]" },
  { cmd: "br backup",   desc: "Backup manager (git/files/DB)",                           usage: "br backup [run|restore|list]" },
  { cmd: "br deps",     desc: "Dependency manager with CVE checks",                      usage: "br deps [check|update|audit]" },
  { cmd: "br session",  desc: "Workspace session manager",                               usage: "br session [save|restore|list]" },
  { cmd: "br test",     desc: "Test runner with coverage",                               usage: "br test [run|watch|coverage]" },
  { cmd: "br metrics",  desc: "Dashboard and system metrics",                            usage: "br metrics [dashboard|export]" },
  { cmd: "br notify",   desc: "Multi-channel notifications (Slack/email/webhook)",       usage: "br notify [send|list|config]" },
  { cmd: "br agent",    desc: "Multi-agent task router",                                 usage: "br agent [route|list|status]" },
  { cmd: "br cece",     desc: "CECE portable AI identity system",                        usage: "br cece [whoami|relationship|skill|export]" },
  { cmd: "br world",    desc: "8-bit ASCII world generator",                             usage: "br world [generate|explore]" },
];

export default {
  async fetch(request: Request): Promise<Response> {
    const url = new URL(request.url);
    const cors = { "Access-Control-Allow-Origin": "*" };
    if (url.pathname === "/commands") {
      return Response.json({ commands: COMMANDS, total: COMMANDS.length }, { headers: { ...cors, "Content-Type": "application/json" } });
    }
    if (url.pathname.startsWith("/commands/")) {
      const q = url.pathname.slice(10).toLowerCase();
      const found = COMMANDS.filter(c => c.cmd.includes(q) || c.desc.toLowerCase().includes(q));
      return Response.json({ results: found, count: found.length }, { headers: { ...cors, "Content-Type": "application/json" } });
    }
    const html = `<!DOCTYPE html>
<html lang="en"><head><meta charset="UTF-8"><title>BR CLI Reference</title>
<style>
  body{background:#000;color:#fff;font-family:'SF Mono',monospace;padding:40px;max-width:900px;margin:0 auto}
  h1{background:linear-gradient(135deg,#F5A623 0%,#FF1D6C 38.2%,#9C27B0 61.8%,#2979FF 100%);
     -webkit-background-clip:text;-webkit-text-fill-color:transparent;font-size:2rem;margin-bottom:8px}
  p{color:#888;margin-bottom:32px}.cmd{border:1px solid #222;border-radius:8px;padding:16px;margin-bottom:12px}
  .cmd-name{color:#FF1D6C;font-weight:bold;font-size:1.1rem}.desc{color:#ccc;margin:6px 0 4px}
  .usage{color:#9C27B0;font-size:.85rem;font-family:'SF Mono',monospace}
</style></head><body>
<h1>BR CLI Reference</h1>
<p>${COMMANDS.length} commands available. <a href="/commands" style="color:#2979FF">JSON API</a></p>
${COMMANDS.map(c => `<div class="cmd"><div class="cmd-name">${c.cmd}</div><div class="desc">${c.desc}</div><div class="usage">${c.usage}</div></div>`).join("")}
</body></html>`;
    return new Response(html, { headers: { ...cors, "Content-Type": "text/html;charset=UTF-8" } });
  }
};
