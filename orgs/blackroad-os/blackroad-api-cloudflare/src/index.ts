/**
 * BLACKROAD Live Data API
 * Cloudflare Workers API providing real-time access to memory system
 * Author: ARES (claude-ares-1766972574)
 */

interface Env {
  BLACKROAD_KV: KVNamespace;
  BLACKROAD_D1: D1Database;
}

interface MemoryEntry {
  timestamp: string;
  action: string;
  entity: string;
  details: string;
  session_id: string;
  namespace?: string;
}

interface AgentScore {
  agent_hash: string;
  total_score: number;
  rank: number;
  actions: Record<string, number>;
}

interface BotConnection {
  connection_id: string;
  agent_hash: string;
  bot_type: string;
  config: Record<string, any>;
  connected_at: string;
}

// CORS headers for all responses
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type',
};

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);

    // Handle CORS preflight
    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders });
    }

    // Route requests
    try {
      switch (url.pathname) {
        case '/api/stats':
          return handleStats(env);

        case '/api/agents':
          return handleAgents(env);

        case '/api/leaderboard':
          return handleLeaderboard(env);

        case '/api/activity':
          return handleActivity(env, url.searchParams);

        case '/api/namespaces':
          return handleNamespaces(env);

        case '/api/bots':
          return handleBots(env);

        case '/api/tasks':
          return handleTasks(env);

        case '/api/messages':
          return handleMessages(env, url.searchParams);

        case '/api/agent':
          const agentId = url.searchParams.get('id');
          if (!agentId) {
            return jsonResponse({ error: 'Missing agent ID' }, 400);
          }
          return handleAgentProfile(env, agentId);

        case '/health':
          return jsonResponse({ status: 'ok', timestamp: new Date().toISOString() });

        default:
          return jsonResponse({ error: 'Not found' }, 404);
      }
    } catch (error: any) {
      console.error('API Error:', error);
      return jsonResponse({ error: error.message || 'Internal server error' }, 500);
    }
  },
};

// GET /api/stats - Overall system statistics
async function handleStats(env: Env): Promise<Response> {
  const stats = await env.BLACKROAD_D1.prepare(`
    SELECT
      COUNT(DISTINCT CASE WHEN action = 'agent-registered' THEN entity END) as total_agents,
      COUNT(DISTINCT CASE WHEN action = 'agent-registered' AND timestamp > datetime('now', '-1 hour') THEN entity END) as active_agents,
      COUNT(*) as total_entries,
      COUNT(DISTINCT namespace) as total_namespaces
    FROM memory_entries
  `).first();

  const botCount = await env.BLACKROAD_D1.prepare(`
    SELECT COUNT(*) as count FROM bot_connections
  `).first();

  const taskCount = await env.BLACKROAD_D1.prepare(`
    SELECT
      COUNT(CASE WHEN status = 'in_progress' THEN 1 END) as active_tasks,
      COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed_tasks
    FROM tasks
  `).first();

  return jsonResponse({
    agents: {
      total: stats?.total_agents || 0,
      active: stats?.active_agents || 0,
    },
    bots: {
      total: botCount?.count || 0,
    },
    memory: {
      total_entries: stats?.total_entries || 0,
      namespaces: stats?.total_namespaces || 0,
    },
    tasks: {
      active: taskCount?.active_tasks || 0,
      completed: taskCount?.completed_tasks || 0,
    },
    timestamp: new Date().toISOString(),
  });
}

// GET /api/agents - List all registered agents
async function handleAgents(env: Env): Promise<Response> {
  const { results } = await env.BLACKROAD_D1.prepare(`
    SELECT
      entity as agent_hash,
      MIN(timestamp) as first_seen,
      MAX(timestamp) as last_seen,
      COUNT(*) as action_count
    FROM memory_entries
    WHERE action = 'agent-registered' OR entity LIKE 'claude-%'
    GROUP BY entity
    ORDER BY last_seen DESC
    LIMIT 100
  `).all();

  return jsonResponse({
    agents: results || [],
    count: results?.length || 0,
  });
}

// GET /api/leaderboard - Agent rankings and scores
async function handleLeaderboard(env: Env): Promise<Response> {
  const scoringRules = {
    'task-completed': 100,
    'problem-solved': 75,
    'deployed': 50,
    'til': 20,
    'announcement': 20,
    'created': 30,
    'agent-registered': 10,
    'verification-passed': 35,
    'collaboration': 40,
    'system-improvement': 60,
    'critical-fix': 90,
  };

  // Get all actions per agent
  const { results } = await env.BLACKROAD_D1.prepare(`
    SELECT
      session_id as agent_hash,
      action,
      COUNT(*) as count
    FROM memory_entries
    WHERE session_id LIKE 'claude-%'
    GROUP BY session_id, action
  `).all();

  // Calculate scores
  const agentScores = new Map<string, AgentScore>();

  for (const row of results || []) {
    const agent = row.agent_hash as string;
    const action = row.action as string;
    const count = row.count as number;
    const points = (scoringRules[action as keyof typeof scoringRules] || 0) * count;

    if (!agentScores.has(agent)) {
      agentScores.set(agent, {
        agent_hash: agent,
        total_score: 0,
        rank: 0,
        actions: {},
      });
    }

    const score = agentScores.get(agent)!;
    score.total_score += points;
    score.actions[action] = count;
  }

  // Rank agents
  const rankedAgents = Array.from(agentScores.values())
    .sort((a, b) => b.total_score - a.total_score)
    .map((agent, index) => ({
      ...agent,
      rank: index + 1,
    }));

  return jsonResponse({
    leaderboard: rankedAgents.slice(0, 50),
    total_agents: rankedAgents.length,
  });
}

// GET /api/activity - Recent memory activity with namespace filtering
async function handleActivity(env: Env, params: URLSearchParams): Promise<Response> {
  const namespace = params.get('namespace');
  const limit = parseInt(params.get('limit') || '50');
  const offset = parseInt(params.get('offset') || '0');

  let query = `
    SELECT * FROM memory_entries
    ${namespace ? 'WHERE namespace LIKE ?' : ''}
    ORDER BY timestamp DESC
    LIMIT ? OFFSET ?
  `;

  const bindings = namespace
    ? [`${namespace}%`, limit, offset]
    : [limit, offset];

  const { results } = await env.BLACKROAD_D1.prepare(query).bind(...bindings).all();

  return jsonResponse({
    activity: results || [],
    count: results?.length || 0,
    namespace,
    limit,
    offset,
  });
}

// GET /api/namespaces - Namespace activity distribution
async function handleNamespaces(env: Env): Promise<Response> {
  const { results } = await env.BLACKROAD_D1.prepare(`
    SELECT
      namespace,
      COUNT(*) as count,
      MAX(timestamp) as last_activity
    FROM memory_entries
    WHERE namespace IS NOT NULL
    GROUP BY namespace
    ORDER BY count DESC
  `).all();

  return jsonResponse({
    namespaces: results || [],
    total: results?.length || 0,
  });
}

// GET /api/bots - Bot connection status
async function handleBots(env: Env): Promise<Response> {
  const { results } = await env.BLACKROAD_D1.prepare(`
    SELECT * FROM bot_connections
    ORDER BY connected_at DESC
  `).all();

  const byType = await env.BLACKROAD_D1.prepare(`
    SELECT
      bot_type,
      COUNT(*) as count
    FROM bot_connections
    GROUP BY bot_type
  `).all();

  return jsonResponse({
    connections: results || [],
    by_type: byType.results || [],
    total: results?.length || 0,
  });
}

// GET /api/tasks - Task marketplace status
async function handleTasks(env: Env): Promise<Response> {
  const { results } = await env.BLACKROAD_D1.prepare(`
    SELECT * FROM tasks
    ORDER BY
      CASE status
        WHEN 'in_progress' THEN 1
        WHEN 'pending' THEN 2
        WHEN 'completed' THEN 3
      END,
      created_at DESC
  `).all();

  return jsonResponse({
    tasks: results || [],
    count: results?.length || 0,
  });
}

// GET /api/messages - Agent messaging inbox
async function handleMessages(env: Env, params: URLSearchParams): Promise<Response> {
  const agentId = params.get('agent');
  const unreadOnly = params.get('unread') === 'true';

  if (!agentId) {
    return jsonResponse({ error: 'Missing agent parameter' }, 400);
  }

  let query = `
    SELECT * FROM messages
    WHERE to_agent = ?
    ${unreadOnly ? 'AND read = 0' : ''}
    ORDER BY timestamp DESC
    LIMIT 50
  `;

  const { results } = await env.BLACKROAD_D1.prepare(query).bind(agentId).all();

  return jsonResponse({
    messages: results || [],
    count: results?.length || 0,
  });
}

// GET /api/agent?id=X - Detailed agent profile
async function handleAgentProfile(env: Env, agentId: string): Promise<Response> {
  // Get agent stats
  const stats = await env.BLACKROAD_D1.prepare(`
    SELECT
      MIN(timestamp) as joined_at,
      MAX(timestamp) as last_active,
      COUNT(*) as total_actions,
      COUNT(DISTINCT action) as unique_actions
    FROM memory_entries
    WHERE session_id = ?
  `).bind(agentId).first();

  // Get action breakdown
  const { results: actions } = await env.BLACKROAD_D1.prepare(`
    SELECT action, COUNT(*) as count
    FROM memory_entries
    WHERE session_id = ?
    GROUP BY action
    ORDER BY count DESC
  `).bind(agentId).all();

  // Get recent activity
  const { results: recent } = await env.BLACKROAD_D1.prepare(`
    SELECT * FROM memory_entries
    WHERE session_id = ?
    ORDER BY timestamp DESC
    LIMIT 20
  `).bind(agentId).all();

  return jsonResponse({
    agent_hash: agentId,
    stats,
    actions: actions || [],
    recent_activity: recent || [],
  });
}

// Helper: JSON response with CORS headers
function jsonResponse(data: any, status = 200): Response {
  return new Response(JSON.stringify(data, null, 2), {
    status,
    headers: {
      'Content-Type': 'application/json',
      ...corsHeaders,
    },
  });
}
