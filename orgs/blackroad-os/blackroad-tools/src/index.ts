import { Router } from './router';
import { AgentTools } from './tools/agent';
import { MemoryTools } from './tools/memory';
import { ReasoningTools } from './tools/reasoning';
import { CoordinationTools } from './tools/coordination';

export interface Env {
  DB: D1Database;
  TOOLS_KV: KVNamespace;
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);
    const path = url.pathname;

    // CORS headers
    const corsHeaders = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Agent-ID',
    };

    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders });
    }

    try {
      // Route to appropriate tool handler
      if (path.startsWith('/tools/agent')) {
        return await AgentTools.handle(request, env, corsHeaders);
      }
      if (path.startsWith('/tools/memory')) {
        return await MemoryTools.handle(request, env, corsHeaders);
      }
      if (path.startsWith('/tools/reasoning')) {
        return await ReasoningTools.handle(request, env, corsHeaders);
      }
      if (path.startsWith('/tools/coordination')) {
        return await CoordinationTools.handle(request, env, corsHeaders);
      }

      // Tool registry
      if (path === '/tools' || path === '/tools/') {
        return Response.json({
          tools: [
            {
              name: 'agent',
              description: 'Agent registry and management',
              endpoints: ['/tools/agent/list', '/tools/agent/get/:id', '/tools/agent/capabilities']
            },
            {
              name: 'memory',
              description: 'Memory persistence and retrieval',
              endpoints: ['/tools/memory/store', '/tools/memory/retrieve', '/tools/memory/search']
            },
            {
              name: 'reasoning',
              description: 'Trinary logic and contradiction handling',
              endpoints: ['/tools/reasoning/evaluate', '/tools/reasoning/quarantine', '/tools/reasoning/resolve']
            },
            {
              name: 'coordination',
              description: 'Agent coordination and messaging',
              endpoints: ['/tools/coordination/publish', '/tools/coordination/subscribe', '/tools/coordination/delegate']
            }
          ],
          version: '1.0.0',
          timestamp: new Date().toISOString()
        }, { headers: corsHeaders });
      }

      return Response.json({ error: 'Tool not found', path }, { status: 404, headers: corsHeaders });
    } catch (err) {
      return Response.json({ error: String(err) }, { status: 500, headers: corsHeaders });
    }
  }
};
