/**
 * network-blackroadio — BlackRoad Network Topology Worker
 * Shows infrastructure mesh: Pis, DigitalOcean, Cloudflare edge.
 */
export default {
  async fetch(request: Request): Promise<Response> {
    const nodes = [
      { id: "aria64",        ip: "192.168.4.38", type: "pi",  role: "primary",   agents: 22500, status: "active" },
      { id: "blackroad-pi",  ip: "192.168.4.64", type: "pi",  role: "edge",      agents: 7500,  status: "active", tunnel: true },
      { id: "lucidia-alt",   ip: "192.168.4.99", type: "pi",  role: "secondary", agents: 1000,  status: "idle"   },
      { id: "infinity",      ip: "159.65.43.12", type: "vps", role: "failover",  agents: 0,     status: "standby"},
      { id: "cf-edge",       ip: "cloudflare",   type: "edge",role: "cdn",       agents: 0,     status: "active" },
    ];
    const edges = [
      { from: "aria64",       to: "blackroad-pi", protocol: "tailscale", latency_ms: 2  },
      { from: "aria64",       to: "lucidia-alt",  protocol: "tailscale", latency_ms: 3  },
      { from: "blackroad-pi", to: "cf-edge",      protocol: "quic",      latency_ms: 12 },
      { from: "infinity",     to: "cf-edge",      protocol: "https",     latency_ms: 45 },
    ];
    const total_agents = nodes.reduce((s, n) => s + n.agents, 0);
    const url = new URL(request.url);
    const cors = { "Access-Control-Allow-Origin": "*", "Content-Type": "application/json" };

    if (url.pathname === "/topology") return Response.json({ nodes, edges, total_agents }, { headers: cors });
    if (url.pathname === "/nodes") return Response.json({ nodes }, { headers: cors });
    if (url.pathname.startsWith("/nodes/")) {
      const id = url.pathname.slice(7);
      const node = nodes.find(n => n.id === id);
      return node ? Response.json(node, { headers: cors }) : Response.json({ error: "Not found" }, { status: 404, headers: cors });
    }
    return Response.json({
      service: "BlackRoad Network Topology",
      total_nodes: nodes.length, total_agents,
      routes: ["/topology", "/nodes", "/nodes/:id"],
    }, { headers: cors });
  }
};
