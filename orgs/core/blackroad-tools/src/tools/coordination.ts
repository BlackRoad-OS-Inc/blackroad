import { Env } from '../index';

interface Event {
  id: string;
  topic: string;
  type: string;
  payload: any;
  source_agent: string;
  timestamp: number;
  ttl?: number;
}

interface Task {
  id: string;
  type: string;
  description: string;
  assigned_to: string;
  assigned_by: string;
  status: 'pending' | 'in_progress' | 'completed' | 'failed';
  priority: number;
  created_at: string;
  due_at?: string;
  result?: any;
}

export class CoordinationTools {
  static async handle(request: Request, env: Env, corsHeaders: Record<string, string>): Promise<Response> {
    const url = new URL(request.url);
    const path = url.pathname.replace('/tools/coordination', '');
    const agentId = request.headers.get('X-Agent-ID') || 'system';

    // POST /tools/coordination/publish - Publish event to topic
    if (path === '/publish' && request.method === 'POST') {
      const body = await request.json() as {
        topic: string;
        type: string;
        payload: any;
        ttl?: number;
      };

      const eventId = `evt_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`;
      const event: Event = {
        id: eventId,
        topic: body.topic,
        type: body.type,
        payload: body.payload,
        source_agent: agentId,
        timestamp: Date.now(),
        ttl: body.ttl || 3600
      };

      // Store in topic queue
      const topicKey = `topic:${body.topic}`;
      const existingEvents = await env.TOOLS_KV.get(topicKey);
      const events: Event[] = existingEvents ? JSON.parse(existingEvents) : [];
      events.push(event);
      
      // Keep only recent events within TTL
      const now = Date.now();
      const validEvents = events.filter(e => now - e.timestamp < (e.ttl || 3600) * 1000);
      await env.TOOLS_KV.put(topicKey, JSON.stringify(validEvents.slice(-100)));

      return Response.json({
        published: true,
        event_id: eventId,
        topic: body.topic,
        subscribers_notified: 0 // Would integrate with WebSockets/SSE
      }, { headers: corsHeaders });
    }

    // GET /tools/coordination/subscribe/:topic - Get events from topic
    if (path.startsWith('/subscribe/')) {
      const topic = path.replace('/subscribe/', '');
      const since = parseInt(url.searchParams.get('since') || '0');
      const limit = parseInt(url.searchParams.get('limit') || '50');

      const topicKey = `topic:${topic}`;
      const existingEvents = await env.TOOLS_KV.get(topicKey);
      const events: Event[] = existingEvents ? JSON.parse(existingEvents) : [];

      const filtered = events
        .filter(e => e.timestamp > since)
        .slice(-limit)
        .reverse();

      return Response.json({
        topic,
        events: filtered,
        count: filtered.length,
        latest_timestamp: filtered[0]?.timestamp || since
      }, { headers: corsHeaders });
    }

    // GET /tools/coordination/topics - List all active topics
    if (path === '/topics' || path === '/topics/') {
      // Would need to maintain a separate topic registry in production
      const knownTopics = [
        'agent.status',
        'task.created',
        'task.completed',
        'memory.committed',
        'reasoning.contradiction',
        'system.alert'
      ];

      return Response.json({
        topics: knownTopics,
        count: knownTopics.length
      }, { headers: corsHeaders });
    }

    // POST /tools/coordination/delegate - Delegate task to agent
    if (path === '/delegate' && request.method === 'POST') {
      const body = await request.json() as {
        task_type: string;
        description: string;
        target_agent?: string;
        required_capabilities?: string[];
        priority?: number;
        due_at?: string;
        payload?: any;
      };

      let targetAgent = body.target_agent;

      // If no target specified, find capable agent
      if (!targetAgent && body.required_capabilities?.length) {
        const caps = body.required_capabilities;
        let query = 'SELECT * FROM agents WHERE status = ?';
        caps.forEach(cap => {
          query += ` AND capabilities LIKE '%${cap}%'`;
        });
        query += ' LIMIT 1';
        
        const result = await env.DB.prepare(query).bind('active').first();
        if (result) {
          targetAgent = (result as any).id;
        }
      }

      if (!targetAgent) {
        return Response.json({ 
          error: 'No capable agent found',
          required_capabilities: body.required_capabilities 
        }, { status: 400, headers: corsHeaders });
      }

      const taskId = `task_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`;
      const task: Task = {
        id: taskId,
        type: body.task_type,
        description: body.description,
        assigned_to: targetAgent,
        assigned_by: agentId,
        status: 'pending',
        priority: body.priority || 5,
        created_at: new Date().toISOString(),
        due_at: body.due_at
      };

      // Store task
      const taskKey = `task:${taskId}`;
      await env.TOOLS_KV.put(taskKey, JSON.stringify(task));

      // Add to agent's task queue
      const queueKey = `queue:${targetAgent}`;
      const existingQueue = await env.TOOLS_KV.get(queueKey);
      const queue: string[] = existingQueue ? JSON.parse(existingQueue) : [];
      queue.push(taskId);
      await env.TOOLS_KV.put(queueKey, JSON.stringify(queue));

      // Publish event
      const topicKey = 'topic:task.created';
      const events = await env.TOOLS_KV.get(topicKey);
      const eventList = events ? JSON.parse(events) : [];
      eventList.push({
        id: `evt_${Date.now()}`,
        topic: 'task.created',
        type: 'task_delegated',
        payload: { task_id: taskId, assigned_to: targetAgent },
        source_agent: agentId,
        timestamp: Date.now()
      });
      await env.TOOLS_KV.put(topicKey, JSON.stringify(eventList.slice(-100)));

      return Response.json({
        delegated: true,
        task_id: taskId,
        assigned_to: targetAgent,
        status: 'pending'
      }, { headers: corsHeaders });
    }

    // GET /tools/coordination/tasks - Get agent's task queue
    if (path === '/tasks' || path === '/tasks/') {
      const status = url.searchParams.get('status');
      
      const queueKey = `queue:${agentId}`;
      const existingQueue = await env.TOOLS_KV.get(queueKey);
      const queue: string[] = existingQueue ? JSON.parse(existingQueue) : [];

      const tasks: Task[] = [];
      for (const taskId of queue) {
        const task = await env.TOOLS_KV.get(`task:${taskId}`);
        if (task) {
          const parsed = JSON.parse(task);
          if (!status || parsed.status === status) {
            tasks.push(parsed);
          }
        }
      }

      // Sort by priority (lower = higher priority)
      tasks.sort((a, b) => a.priority - b.priority);

      return Response.json({
        tasks,
        count: tasks.length,
        agent_id: agentId
      }, { headers: corsHeaders });
    }

    // POST /tools/coordination/complete - Complete a task
    if (path === '/complete' && request.method === 'POST') {
      const body = await request.json() as {
        task_id: string;
        status: 'completed' | 'failed';
        result?: any;
      };

      const taskKey = `task:${body.task_id}`;
      const task = await env.TOOLS_KV.get(taskKey);

      if (!task) {
        return Response.json({ error: 'Task not found' }, { status: 404, headers: corsHeaders });
      }

      const parsed: Task = JSON.parse(task);
      parsed.status = body.status;
      parsed.result = body.result;

      await env.TOOLS_KV.put(taskKey, JSON.stringify(parsed));

      // Publish completion event
      const topicKey = 'topic:task.completed';
      const events = await env.TOOLS_KV.get(topicKey);
      const eventList = events ? JSON.parse(events) : [];
      eventList.push({
        id: `evt_${Date.now()}`,
        topic: 'task.completed',
        type: 'task_' + body.status,
        payload: { task_id: body.task_id, result: body.result },
        source_agent: agentId,
        timestamp: Date.now()
      });
      await env.TOOLS_KV.put(topicKey, JSON.stringify(eventList.slice(-100)));

      return Response.json({
        task_id: body.task_id,
        status: body.status,
        completed: true
      }, { headers: corsHeaders });
    }

    return Response.json({ error: 'Unknown coordination endpoint', path }, { status: 404, headers: corsHeaders });
  }
}
