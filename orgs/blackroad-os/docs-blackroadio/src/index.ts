/**
 * docs.blackroad.io — Documentation proxy / redirect worker
 */
export interface Env { DOCS_URL: string; }
export default {
  async fetch(req: Request, env: Env): Promise<Response> {
    const docsBase = env.DOCS_URL || "https://blackroad-os.github.io/blackroad-os-docs";
    const url = new URL(req.url);
    if (url.pathname === "/health") return Response.json({ status: "ok" });
    // Proxy to Docusaurus static site
    const proxied = await fetch(`${docsBase}${url.pathname}${url.search}`);
    return new Response(proxied.body, {
      status: proxied.status,
      headers: { "Content-Type": proxied.headers.get("Content-Type") || "text/html" }
    });
  }
};
