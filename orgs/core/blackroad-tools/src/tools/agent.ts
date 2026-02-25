import { Env } from '../index';

export class AgentTools {
  static async handle(request: Request, env: Env, corsHeaders: Record<string, string>): Promise<Response> {
    const url = new URL(request.url);
    const path = url.pathname.replace('/tools/agent', '');

    // GET /tools/agent/list - List agents with filtering
    if (path === '/list' || path === '/list/') {
      const type = url.searchParams.get('type');
      const capability = url.searchParams.get('capability');
      const limit = parseInt(url.searchParams.get('limit') || '50');
      const offset = parseInt(url.searchParams.get('offset') || '0');

      let query = 'SELECT * FROM agents WHERE status = ?';
      const params: any[] = ['active'];

      if (type) {
        query += ' AND type = ?';
        params.push(type);
      }
      if (capability) {
        query += ' AND capabilities LIKE ?';
        params.push(`%${capability}%`);
      }
      query += ' ORDER BY id LIMIT ? OFFSET ?';
      params.push(limit, offset);

      const result = await env.DB.prepare(query).bind(...params).all();
      
      return Response.json({
        agents: result.results,
        count: result.results?.length || 0,
        offset,
        limit
      }, { headers: corsHeaders });
    }

    // GET /tools/agent/get/:id - Get specific agent
    if (path.startsWith('/get/')) {
      const agentId = path.replace('/get/', '');
      const result = await env.DB.prepare(
        'SELECT * FROM agents WHERE id = ?'
      ).bind(agentId).first();

      if (!result) {
        return Response.json({ error: 'Agent not found' }, { status: 404, headers: corsHeaders });
      }
      return Response.json({ agent: result }, { headers: corsHeaders });
    }

    // GET /tools/agent/capabilities - List all unique capabilities
    if (path === '/capabilities' || path === '/capabilities/') {
      const result = await env.DB.prepare(
        'SELECT DISTINCT type, capabilities FROM agents WHERE status = ?'
      ).bind('active').all();

      const allCapabilities = new Set<string>();
      const typeCapabilities: Record<string, Set<string>> = {};

      result.results?.forEach((row: any) => {
        const caps = JSON.parse(row.capabilities || '[]');
        caps.forEach((c: string) => allCapabilities.add(c));
        
        if (!typeCapabilities[row.type]) {
          typeCapabilities[row.type] = new Set();
        }
        caps.forEach((c: string) => typeCapabilities[row.type].add(c));
      });

      return Response.json({
        capabilities: Array.from(allCapabilities).sort(),
        byType: Object.fromEntries(
          Object.entries(typeCapabilities).map(([k, v]) => [k, Array.from(v).sort()])
        )
      }, { headers: corsHeaders });
    }

    // GET /tools/agent/types - List all agent types with counts
    if (path === '/types' || path === '/types/') {
      const result = await env.DB.prepare(
        'SELECT type, COUNT(*) as count FROM agents WHERE status = ? GROUP BY type ORDER BY count DESC'
      ).bind('active').all();

      return Response.json({ types: result.results }, { headers: corsHeaders });
    }

    // POST /tools/agent/find - Find agents by capability match
    if (path === '/find' && request.method === 'POST') {
      const body = await request.json() as { capabilities: string[], matchAll?: boolean };
      const { capabilities, matchAll = false } = body;

      let agents: any[] = [];
      
      if (matchAll) {
        // Agent must have ALL capabilities
        let query = 'SELECT * FROM agents WHERE status = ?';
        capabilities.forEach(cap => {
          query += ` AND capabilities LIKE '%${cap}%'`;
        });
        const result = await env.DB.prepare(query).bind('active').all();
        agents = result.results || [];
      } else {
        // Agent must have ANY capability
        const placeholders = capabilities.map(() => "capabilities LIKE ?").join(' OR ');
        const params = capabilities.map(c => `%${c}%`);
        const result = await env.DB.prepare(
          `SELECT * FROM agents WHERE status = ? AND (${placeholders})`
        ).bind('active', ...params).all();
        agents = result.results || [];
      }

      return Response.json({ 
        agents,
        count: agents.length,
        query: { capabilities, matchAll }
      }, { headers: corsHeaders });
    }

    return Response.json({ error: 'Unknown agent endpoint', path }, { status: 404, headers: corsHeaders });
  }
}
