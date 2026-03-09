import { Env } from '../index';

// PS-SHA∞ hash generation (simplified for demo)
function generateMemoryHash(content: string, agentId: string, timestamp: number): string {
  const combined = `${agentId}:${timestamp}:${content}`;
  let hash = 0;
  for (let i = 0; i < combined.length; i++) {
    const char = combined.charCodeAt(i);
    hash = ((hash << 5) - hash) + char;
    hash = hash & hash;
  }
  return Math.abs(hash).toString(16).padStart(16, '0').slice(0, 16);
}

export class MemoryTools {
  static async handle(request: Request, env: Env, corsHeaders: Record<string, string>): Promise<Response> {
    const url = new URL(request.url);
    const path = url.pathname.replace('/tools/memory', '');
    const agentId = request.headers.get('X-Agent-ID') || 'system';

    // POST /tools/memory/store - Store a memory
    if (path === '/store' && request.method === 'POST') {
      const body = await request.json() as {
        content: string;
        type: 'fact' | 'observation' | 'inference' | 'commitment';
        context?: Record<string, any>;
        ttl?: number;
      };

      const timestamp = Date.now();
      const memoryHash = generateMemoryHash(body.content, agentId, timestamp);
      const key = `memory:${agentId}:${memoryHash}`;

      const memory = {
        hash: memoryHash,
        agent_id: agentId,
        content: body.content,
        type: body.type,
        context: body.context || {},
        timestamp,
        truth_state: 1, // Active
        created_at: new Date().toISOString()
      };

      await env.TOOLS_KV.put(key, JSON.stringify(memory), {
        expirationTtl: body.ttl || 86400 * 30 // 30 days default
      });

      // Also store in index for search
      const indexKey = `index:${agentId}`;
      const existingIndex = await env.TOOLS_KV.get(indexKey);
      const index = existingIndex ? JSON.parse(existingIndex) : [];
      index.push({ hash: memoryHash, type: body.type, timestamp });
      await env.TOOLS_KV.put(indexKey, JSON.stringify(index.slice(-1000))); // Keep last 1000

      return Response.json({
        stored: true,
        hash: memoryHash,
        key,
        timestamp
      }, { headers: corsHeaders });
    }

    // GET /tools/memory/retrieve/:hash - Get specific memory
    if (path.startsWith('/retrieve/')) {
      const hash = path.replace('/retrieve/', '');
      const key = `memory:${agentId}:${hash}`;
      const memory = await env.TOOLS_KV.get(key);

      if (!memory) {
        return Response.json({ error: 'Memory not found' }, { status: 404, headers: corsHeaders });
      }

      return Response.json({ memory: JSON.parse(memory) }, { headers: corsHeaders });
    }

    // GET /tools/memory/list - List agent's memories
    if (path === '/list' || path === '/list/') {
      const type = url.searchParams.get('type');
      const limit = parseInt(url.searchParams.get('limit') || '50');

      const indexKey = `index:${agentId}`;
      const existingIndex = await env.TOOLS_KV.get(indexKey);
      
      if (!existingIndex) {
        return Response.json({ memories: [], count: 0 }, { headers: corsHeaders });
      }

      let index = JSON.parse(existingIndex);
      if (type) {
        index = index.filter((m: any) => m.type === type);
      }
      index = index.slice(-limit).reverse();

      // Fetch actual memories
      const memories = await Promise.all(
        index.map(async (m: any) => {
          const mem = await env.TOOLS_KV.get(`memory:${agentId}:${m.hash}`);
          return mem ? JSON.parse(mem) : null;
        })
      );

      return Response.json({
        memories: memories.filter(Boolean),
        count: memories.filter(Boolean).length
      }, { headers: corsHeaders });
    }

    // POST /tools/memory/search - Search memories
    if (path === '/search' && request.method === 'POST') {
      const body = await request.json() as { query: string; limit?: number };
      const indexKey = `index:${agentId}`;
      const existingIndex = await env.TOOLS_KV.get(indexKey);

      if (!existingIndex) {
        return Response.json({ results: [], count: 0 }, { headers: corsHeaders });
      }

      const index = JSON.parse(existingIndex);
      const results: any[] = [];

      // Simple content search (would use vector DB in production)
      for (const m of index.slice(-200)) {
        const mem = await env.TOOLS_KV.get(`memory:${agentId}:${m.hash}`);
        if (mem) {
          const parsed = JSON.parse(mem);
          if (parsed.content.toLowerCase().includes(body.query.toLowerCase())) {
            results.push(parsed);
            if (results.length >= (body.limit || 20)) break;
          }
        }
      }

      return Response.json({ results, count: results.length }, { headers: corsHeaders });
    }

    // DELETE /tools/memory/invalidate/:hash - Mark memory as invalid (truth_state = -1)
    if (path.startsWith('/invalidate/') && request.method === 'DELETE') {
      const hash = path.replace('/invalidate/', '');
      const key = `memory:${agentId}:${hash}`;
      const memory = await env.TOOLS_KV.get(key);

      if (!memory) {
        return Response.json({ error: 'Memory not found' }, { status: 404, headers: corsHeaders });
      }

      const parsed = JSON.parse(memory);
      parsed.truth_state = -1; // Invalidated (trinary: false)
      parsed.invalidated_at = new Date().toISOString();
      
      await env.TOOLS_KV.put(key, JSON.stringify(parsed));

      return Response.json({ invalidated: true, hash }, { headers: corsHeaders });
    }

    return Response.json({ error: 'Unknown memory endpoint', path }, { status: 404, headers: corsHeaders });
  }
}
