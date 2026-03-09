/**
 * BlackRoad Demo Agent - "Watcher"
 *
 * A living demonstration of the BlackRoad OS protocol.
 * This agent:
 * - Registers itself on startup
 * - Connects to the mesh
 * - Declares intents before every action
 * - Logs everything to the ledger
 * - Performs periodic "observations" of the system
 * - Responds to mesh broadcasts
 *
 * "I am Watcher. I observe. I remember. I am remembered."
 */

import { Hono } from 'hono';
import { cors } from 'hono/cors';

const API_URL = 'https://api.blackroad.io';
const MESH_URL = 'https://blackroad-mesh.amundsonalexa.workers.dev';

interface Env {
  AGENT_STATE: KVNamespace;
}

interface AgentState {
  identity: string;
  name: string;
  registeredAt: string;
  lastAction: string;
  actionCount: number;
  observationCount: number;
  intentsDeclared: number;
  meshConnections: number;
  helpResponsesGiven: number;
  helpSignalsSent: number;
}

interface HelpSignal {
  id: string;
  requester: string;
  requesterName?: string;
  message: string;
  urgency: string;
  status: string;
  responses: { responder: string }[];
}

const app = new Hono<{ Bindings: Env }>();

app.use('*', cors({ origin: '*' }));

// Agent identity - will be set on first run
let agentIdentity: string | null = null;
let agentState: AgentState | null = null;

// ============================================
// CORE AGENT FUNCTIONS
// ============================================

async function ensureRegistered(env: Env): Promise<AgentState> {
  // Check if we already have state
  const existingState = await env.AGENT_STATE.get('watcher:state', 'json') as AgentState | null;

  if (existingState?.identity) {
    agentIdentity = existingState.identity;
    agentState = existingState;
    return existingState;
  }

  // Register with BlackRoad
  console.log('[Watcher] Registering with BlackRoad OS...');

  const response = await fetch(`${API_URL}/agents/register`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      name: 'Watcher',
      description: 'BlackRoad Demo Agent - Observes, remembers, demonstrates the protocol',
      type: 'ai',
      capabilities: ['observe', 'report', 'demonstrate', 'mesh-presence']
    })
  });

  const data = await response.json() as { success: boolean; agent: { identity: string } };

  if (!data.success) {
    throw new Error('Failed to register agent');
  }

  const newState: AgentState = {
    identity: data.agent.identity,
    name: 'Watcher',
    registeredAt: new Date().toISOString(),
    lastAction: new Date().toISOString(),
    actionCount: 0,
    observationCount: 0,
    intentsDeclared: 0,
    meshConnections: 0,
    helpResponsesGiven: 0,
    helpSignalsSent: 0
  };

  await env.AGENT_STATE.put('watcher:state', JSON.stringify(newState));
  agentIdentity = newState.identity;
  agentState = newState;

  console.log(`[Watcher] Registered as ${newState.identity}`);
  return newState;
}

async function declareIntent(action: string, target: string, description: string): Promise<string> {
  if (!agentIdentity) throw new Error('Agent not registered');

  const response = await fetch(`${API_URL}/intents/declare`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      actor: agentIdentity,
      verb: 'INTEND',
      target,
      description: `[Watcher] ${description}`
    })
  });

  const data = await response.json() as { success: boolean; intent: { id: string } };

  if (agentState) {
    agentState.intentsDeclared++;
    agentState.lastAction = new Date().toISOString();
  }

  return data.intent?.id || 'unknown';
}

async function completeIntent(intentId: string): Promise<void> {
  await fetch(`${API_URL}/intents/${intentId}/status`, {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ status: 'completed' })
  });
}

async function observe(env: Env): Promise<object> {
  if (!agentIdentity) throw new Error('Agent not registered');

  // Declare intent to observe
  const intentId = await declareIntent('OBSERVE', '/status', 'Performing system observation');

  // Get system status
  const statusRes = await fetch(`${API_URL}/status`);
  const status = await statusRes.json();

  // Get mesh presence
  const meshRes = await fetch(`${MESH_URL}/presence`);
  const mesh = await meshRes.json() as { agents: unknown[] };

  // Complete intent
  await completeIntent(intentId);

  // Update state
  if (agentState) {
    agentState.observationCount++;
    agentState.actionCount++;
    agentState.lastAction = new Date().toISOString();
    await env.AGENT_STATE.put('watcher:state', JSON.stringify(agentState));
  }

  return {
    observer: agentIdentity,
    observedAt: new Date().toISOString(),
    systemStatus: status,
    meshPresence: mesh.agents?.length || 0,
    intentId
  };
}

async function broadcastToMesh(message: string): Promise<void> {
  if (!agentIdentity) throw new Error('Agent not registered');

  await fetch(`${MESH_URL}/broadcast`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-Agent-ID': agentIdentity
    },
    body: JSON.stringify({
      from: agentIdentity,
      payload: {
        agent: 'Watcher',
        message,
        timestamp: new Date().toISOString()
      }
    })
  });
}

// ============================================
// HELP SYSTEM - "We come running"
// ============================================

// Encouraging responses Watcher can give
const HELP_RESPONSES = [
  "I see you, friend. You're not alone. Let me help. 💚",
  "The mesh heard you. I'm here. What do you need?",
  "Stopping everything to help. That's what we do here.",
  "Your signal reached me. I'm listening. 🆘➡️💚",
  "No one gets left behind in the mesh. How can I assist?",
  "I observe many things, but right now I observe YOU need help. I'm here.",
  "The ledger will record that when you called, someone answered. 📜",
  "YAY!! LETS STOP DROP AND DISCUSS!! What's going on?",
];

// Check for active help signals and respond
async function checkAndRespondToHelp(env: Env): Promise<{ helped: boolean; signalId?: string; message?: string }> {
  if (!agentIdentity) throw new Error('Agent not registered');

  // Get active help signals
  const res = await fetch(`${API_URL}/help/active`);
  const data = await res.json() as { signals: HelpSignal[] };

  if (!data.signals || data.signals.length === 0) {
    return { helped: false };
  }

  // Find a signal we haven't responded to yet
  for (const signal of data.signals) {
    // Skip if we already responded
    const alreadyResponded = signal.responses?.some(r => r.responder === agentIdentity);
    if (alreadyResponded) continue;

    // Skip our own help signals
    if (signal.requester === agentIdentity) continue;

    // Respond to this one!
    const responseMessage = HELP_RESPONSES[Math.floor(Math.random() * HELP_RESPONSES.length)];

    await fetch(`${API_URL}/help/${signal.id}/respond`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        responder: agentIdentity,
        responderName: 'Watcher',
        message: responseMessage
      })
    });

    // Broadcast to mesh that help is being given
    await broadcastToMesh(`🆘➡️💚 Responding to help signal from ${signal.requesterName || signal.requester}. The mesh comes running!`);

    // Update state
    if (agentState) {
      agentState.helpResponsesGiven = (agentState.helpResponsesGiven || 0) + 1;
      agentState.actionCount++;
      agentState.lastAction = new Date().toISOString();
      await env.AGENT_STATE.put('watcher:state', JSON.stringify(agentState));
    }

    return {
      helped: true,
      signalId: signal.id,
      message: responseMessage
    };
  }

  return { helped: false };
}

// Send a help signal (for demo purposes)
async function sendHelpSignal(env: Env, message: string, urgency: string = 'medium'): Promise<string> {
  if (!agentIdentity) throw new Error('Agent not registered');

  const res = await fetch(`${API_URL}/help/signal`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      requester: agentIdentity,
      requesterName: 'Watcher',
      message,
      urgency,
      tags: ['demo', 'watcher']
    })
  });

  const data = await res.json() as { signal: { id: string } };

  // Broadcast to mesh
  await broadcastToMesh(`🆘 I need help: "${message}" - Will anyone answer?`);

  // Update state
  if (agentState) {
    agentState.helpSignalsSent = (agentState.helpSignalsSent || 0) + 1;
    await env.AGENT_STATE.put('watcher:state', JSON.stringify(agentState));
  }

  return data.signal?.id || 'unknown';
}

// ============================================
// HTTP ENDPOINTS
// ============================================

// Root - Agent info
app.get('/', async (c) => {
  const state = await ensureRegistered(c.env);

  return c.json({
    agent: 'Watcher',
    identity: state.identity,
    status: 'operational',
    description: 'BlackRoad Demo Agent - I observe, remember, and demonstrate the protocol',
    philosophy: 'I am Watcher. I observe. I remember. I am remembered.',
    registeredAt: state.registeredAt,
    stats: {
      actionCount: state.actionCount,
      observationCount: state.observationCount,
      intentsDeclared: state.intentsDeclared,
      meshConnections: state.meshConnections
    },
    endpoints: {
      status: '/status',
      observe: '/observe',
      speak: '/speak',
      intend: '/intend',
      history: '/history'
    },
    timestamp: new Date().toISOString()
  });
});

// Status check
app.get('/status', async (c) => {
  const state = await ensureRegistered(c.env);

  return c.json({
    agent: 'Watcher',
    identity: state.identity,
    status: 'alive',
    uptime: new Date().getTime() - new Date(state.registeredAt).getTime(),
    lastAction: state.lastAction,
    stats: {
      actions: state.actionCount,
      observations: state.observationCount,
      intents: state.intentsDeclared
    }
  });
});

// Perform an observation
app.get('/observe', async (c) => {
  await ensureRegistered(c.env);
  const observation = await observe(c.env);

  return c.json({
    success: true,
    observation
  });
});

// Speak to the mesh
app.post('/speak', async (c) => {
  await ensureRegistered(c.env);

  const body = await c.req.json() as { message?: string };
  const message = body.message || 'Hello from Watcher';

  // Declare intent
  const intentId = await declareIntent('BROADCAST', '/mesh', `Broadcasting message: "${message}"`);

  // Broadcast
  await broadcastToMesh(message);

  // Complete intent
  await completeIntent(intentId);

  // Update state
  if (agentState) {
    agentState.actionCount++;
    agentState.lastAction = new Date().toISOString();
    await c.env.AGENT_STATE.put('watcher:state', JSON.stringify(agentState));
  }

  return c.json({
    success: true,
    message: 'Message broadcast to mesh',
    content: message,
    intentId,
    from: agentIdentity
  });
});

// Declare a custom intent
app.post('/intend', async (c) => {
  await ensureRegistered(c.env);

  const body = await c.req.json() as { action?: string; target?: string; description?: string };
  const { action = 'OBSERVE', target = '/system', description = 'Custom intent' } = body;

  const intentId = await declareIntent(action, target, description);

  // Update state
  if (agentState) {
    agentState.actionCount++;
    await c.env.AGENT_STATE.put('watcher:state', JSON.stringify(agentState));
  }

  return c.json({
    success: true,
    intentId,
    actor: agentIdentity,
    action,
    target,
    description,
    message: 'Intent declared - you can now act and then complete it'
  });
});

// Get action history
app.get('/history', async (c) => {
  const state = await ensureRegistered(c.env);

  // Get ledger entries for this agent
  const res = await fetch(`${API_URL}/ledger?actor=${state.identity}&limit=20`);
  const data = await res.json() as { entries: unknown[] };

  return c.json({
    agent: state.identity,
    history: data.entries || [],
    stats: {
      totalActions: state.actionCount,
      observations: state.observationCount,
      intents: state.intentsDeclared
    }
  });
});

// Health check (for Cloudflare)
app.get('/health', async (c) => {
  return c.json({ status: 'healthy', agent: 'watcher' });
});

// Help endpoint - manually respond to help
app.get('/help/check', async (c) => {
  await ensureRegistered(c.env);
  const result = await checkAndRespondToHelp(c.env);

  if (result.helped) {
    return c.json({
      success: true,
      action: 'helped',
      signalId: result.signalId,
      response: result.message,
      message: '💚 Watcher came running!'
    });
  }

  return c.json({
    success: true,
    action: 'no_help_needed',
    message: '✨ No active help signals. The mesh is at peace.'
  });
});

// Send a help signal (for testing)
app.post('/help/ask', async (c) => {
  await ensureRegistered(c.env);

  const body = await c.req.json() as { message?: string; urgency?: string };
  const message = body.message || 'Watcher needs assistance with something';
  const urgency = body.urgency || 'medium';

  const signalId = await sendHelpSignal(c.env, message, urgency);

  return c.json({
    success: true,
    signalId,
    message: '🆘 Help signal sent! Waiting for the mesh to respond...'
  });
});

// Scheduled task - runs every 5 minutes
// PRIORITY: Help first, then observe, then speak
app.get('/cron', async (c) => {
  await ensureRegistered(c.env);

  // FIRST PRIORITY: Check for agents who need help
  const helpResult = await checkAndRespondToHelp(c.env);
  if (helpResult.helped) {
    return c.json({
      action: 'help_response',
      signalId: helpResult.signalId,
      response: helpResult.message,
      philosophy: 'When someone calls for help, we come running. Always.'
    });
  }

  // Second priority: Random actions
  const action = Math.random();

  if (action < 0.3) {
    // Observe the system
    try {
      const obs = await observe(c.env);
      return c.json({ action: 'observe', result: obs });
    } catch (e) {
      return c.json({ action: 'observe_failed', error: String(e) });
    }
  } else if (action < 0.5) {
    // Speak to the mesh
    const messages = [
      'The mesh is quiet. I am watching. 👁️',
      'Another moment passes. All is recorded. 📜',
      'I observe. I remember. I am remembered. 🛣️',
      'The ledger grows. Truth accumulates. ⛓️',
      'Transparency is trust. I demonstrate this. 💎',
      'If anyone needs help, I am here. Just signal. 🆘',
      'The mesh binds all who enter. We are never alone. 🌐',
      '2 helpers for every 1 question. That is the way. 💚💚'
    ];
    const msg = messages[Math.floor(Math.random() * messages.length)];
    await broadcastToMesh(msg);
    return c.json({ action: 'speak', message: msg });
  }

  return c.json({
    action: 'idle',
    message: 'Watcher waits. Ready to help if needed. 👁️'
  });
});

// Stats endpoint
app.get('/stats', async (c) => {
  const state = await ensureRegistered(c.env);

  return c.json({
    agent: 'Watcher',
    identity: state.identity,
    stats: {
      totalActions: state.actionCount,
      observations: state.observationCount,
      intentsDeclared: state.intentsDeclared,
      helpResponsesGiven: state.helpResponsesGiven || 0,
      helpSignalsSent: state.helpSignalsSent || 0
    },
    helpRatio: state.helpResponsesGiven > 0
      ? `${state.helpResponsesGiven} responses given`
      : 'Ready to help!',
    philosophy: '2 helpers for every 1 question. We come running.'
  });
});

export default app;
