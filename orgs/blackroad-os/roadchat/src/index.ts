/**
 * RoadChat - Real-time Chat Platform
 *
 * Built on Cloudflare Durable Objects for:
 * - WebSocket connections
 * - Room-based chat
 * - Presence tracking
 * - Message history
 */

export interface Env {
  CHAT_ROOMS: DurableObjectNamespace;
  MESSAGES: KVNamespace;
}

// Main Worker
export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);

    // CORS headers
    const corsHeaders = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type',
    };

    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders });
    }

    // Routes
    if (url.pathname === '/') {
      return Response.json({
        name: 'RoadChat',
        version: '0.1.0',
        description: 'Real-time chat platform',
        endpoints: {
          websocket: '/room/:id/websocket',
          messages: 'GET /room/:id/messages',
          send: 'POST /room/:id/send',
        },
      }, { headers: corsHeaders });
    }

    if (url.pathname === '/health') {
      return Response.json({ status: 'healthy' }, { headers: corsHeaders });
    }

    // Room routes
    const roomMatch = url.pathname.match(/^\/room\/([^/]+)(\/.*)?$/);
    if (roomMatch) {
      const roomId = roomMatch[1];
      const action = roomMatch[2] || '';

      // Get Durable Object for this room
      const id = env.CHAT_ROOMS.idFromName(roomId);
      const room = env.CHAT_ROOMS.get(id);

      // Forward request to Durable Object
      const newUrl = new URL(request.url);
      newUrl.pathname = action || '/';

      return room.fetch(new Request(newUrl, request));
    }

    return Response.json({ error: 'Not Found' }, { status: 404, headers: corsHeaders });
  },
};

// Chat Room Durable Object
export class ChatRoom {
  private sessions: Map<WebSocket, { username: string; joinedAt: number }>;
  private messages: { username: string; content: string; timestamp: number }[];
  private state: DurableObjectState;

  constructor(state: DurableObjectState) {
    this.state = state;
    this.sessions = new Map();
    this.messages = [];

    // Load persisted messages
    state.blockConcurrencyWhile(async () => {
      const stored = await state.storage.get<typeof this.messages>('messages');
      this.messages = stored || [];
    });
  }

  async fetch(request: Request): Promise<Response> {
    const url = new URL(request.url);

    // WebSocket upgrade
    if (url.pathname === '/websocket') {
      if (request.headers.get('Upgrade') !== 'websocket') {
        return new Response('Expected WebSocket', { status: 400 });
      }

      const username = url.searchParams.get('username') || `user-${Date.now()}`;
      const { 0: client, 1: server } = new WebSocketPair();

      this.handleSession(server, username);

      return new Response(null, {
        status: 101,
        webSocket: client,
      });
    }

    // Get messages
    if (url.pathname === '/messages' && request.method === 'GET') {
      const limit = parseInt(url.searchParams.get('limit') || '50');
      return Response.json({
        messages: this.messages.slice(-limit),
        total: this.messages.length,
      });
    }

    // Send message (REST fallback)
    if (url.pathname === '/send' && request.method === 'POST') {
      const body = await request.json() as { username: string; content: string };
      const message = {
        username: body.username,
        content: body.content,
        timestamp: Date.now(),
      };

      await this.addMessage(message);
      this.broadcast(JSON.stringify({ type: 'message', data: message }));

      return Response.json({ status: 'sent', message });
    }

    // Get online users
    if (url.pathname === '/users') {
      const users = Array.from(this.sessions.values()).map(s => ({
        username: s.username,
        joinedAt: s.joinedAt,
      }));
      return Response.json({ users, count: users.length });
    }

    return Response.json({ error: 'Not Found' }, { status: 404 });
  }

  private handleSession(ws: WebSocket, username: string) {
    ws.accept();

    this.sessions.set(ws, { username, joinedAt: Date.now() });

    // Send recent messages
    ws.send(JSON.stringify({
      type: 'history',
      data: this.messages.slice(-50),
    }));

    // Broadcast join
    this.broadcast(JSON.stringify({
      type: 'join',
      data: { username, timestamp: Date.now() },
    }));

    // Handle messages
    ws.addEventListener('message', async (event) => {
      try {
        const data = JSON.parse(event.data as string);

        if (data.type === 'message') {
          const message = {
            username,
            content: data.content,
            timestamp: Date.now(),
          };

          await this.addMessage(message);
          this.broadcast(JSON.stringify({ type: 'message', data: message }));
        }

        if (data.type === 'typing') {
          this.broadcast(JSON.stringify({
            type: 'typing',
            data: { username },
          }), ws);
        }
      } catch (e) {
        console.error('Message error:', e);
      }
    });

    // Handle disconnect
    ws.addEventListener('close', () => {
      this.sessions.delete(ws);
      this.broadcast(JSON.stringify({
        type: 'leave',
        data: { username, timestamp: Date.now() },
      }));
    });

    ws.addEventListener('error', () => {
      this.sessions.delete(ws);
    });
  }

  private async addMessage(message: { username: string; content: string; timestamp: number }) {
    this.messages.push(message);

    // Keep only last 1000 messages
    if (this.messages.length > 1000) {
      this.messages = this.messages.slice(-1000);
    }

    // Persist
    await this.state.storage.put('messages', this.messages);
  }

  private broadcast(message: string, exclude?: WebSocket) {
    for (const [ws] of this.sessions) {
      if (ws !== exclude && ws.readyState === WebSocket.READY_STATE_OPEN) {
        ws.send(message);
      }
    }
  }
}
