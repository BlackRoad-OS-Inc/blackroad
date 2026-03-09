/**
 * RoadDocs Realtime Collaboration
 *
 * Features:
 * - Live editing with presence
 * - Cursor positions
 * - Selection highlighting
 * - Conflict resolution with CRDT-like approach
 * - User presence (who's viewing/editing)
 */

interface User {
  id: string;
  name: string;
  color: string;
  cursor?: CursorPosition;
  selection?: Selection;
  lastSeen: number;
}

interface CursorPosition {
  line: number;
  column: number;
}

interface Selection {
  startLine: number;
  startColumn: number;
  endLine: number;
  endColumn: number;
}

interface Operation {
  type: 'insert' | 'delete' | 'replace';
  position: number;
  text?: string;
  length?: number;
  userId: string;
  timestamp: number;
  version: number;
}

interface DocumentState {
  id: string;
  content: string;
  version: number;
  operations: Operation[];
  users: Map<string, User>;
}

interface RealtimeMessage {
  type: 'join' | 'leave' | 'cursor' | 'selection' | 'operation' | 'sync' | 'presence';
  userId: string;
  payload: any;
  timestamp: number;
}

// Generate random color for user
function generateUserColor(): string {
  const colors = [
    '#F5A623', '#FF1D6C', '#2979FF', '#9C27B0',
    '#00BCD4', '#4CAF50', '#FF5722', '#795548',
  ];
  return colors[Math.floor(Math.random() * colors.length)];
}

/**
 * Durable Object for realtime document collaboration
 */
export class RealtimeDocument {
  private state: DurableObjectState;
  private sessions: Map<WebSocket, User> = new Map();
  private document: DocumentState;

  constructor(state: DurableObjectState) {
    this.state = state;
    this.document = {
      id: '',
      content: '',
      version: 0,
      operations: [],
      users: new Map(),
    };
  }

  async fetch(request: Request): Promise<Response> {
    const url = new URL(request.url);

    if (request.headers.get('Upgrade') === 'websocket') {
      return this.handleWebSocket(request);
    }

    // REST API for document state
    switch (url.pathname) {
      case '/state':
        return new Response(JSON.stringify({
          id: this.document.id,
          content: this.document.content,
          version: this.document.version,
          users: Array.from(this.document.users.values()),
        }), {
          headers: { 'Content-Type': 'application/json' },
        });

      case '/users':
        return new Response(JSON.stringify({
          users: Array.from(this.document.users.values()),
          count: this.document.users.size,
        }), {
          headers: { 'Content-Type': 'application/json' },
        });

      default:
        return new Response('Not found', { status: 404 });
    }
  }

  private async handleWebSocket(request: Request): Promise<Response> {
    const pair = new WebSocketPair();
    const [client, server] = Object.values(pair);

    const url = new URL(request.url);
    const userId = url.searchParams.get('userId') || crypto.randomUUID();
    const userName = url.searchParams.get('name') || `User ${userId.slice(0, 4)}`;

    const user: User = {
      id: userId,
      name: userName,
      color: generateUserColor(),
      lastSeen: Date.now(),
    };

    // Accept WebSocket
    server.accept();
    this.sessions.set(server, user);
    this.document.users.set(userId, user);

    // Send initial state
    server.send(JSON.stringify({
      type: 'sync',
      payload: {
        content: this.document.content,
        version: this.document.version,
        users: Array.from(this.document.users.values()),
        yourId: userId,
        yourColor: user.color,
      },
    }));

    // Broadcast join
    this.broadcast({
      type: 'join',
      userId,
      payload: user,
      timestamp: Date.now(),
    }, server);

    // Handle messages
    server.addEventListener('message', async (event) => {
      try {
        const message: RealtimeMessage = JSON.parse(event.data as string);
        await this.handleMessage(server, message);
      } catch (e) {
        console.error('Message error:', e);
      }
    });

    // Handle close
    server.addEventListener('close', () => {
      this.sessions.delete(server);
      this.document.users.delete(userId);

      this.broadcast({
        type: 'leave',
        userId,
        payload: { name: userName },
        timestamp: Date.now(),
      });
    });

    return new Response(null, { status: 101, webSocket: client });
  }

  private async handleMessage(ws: WebSocket, message: RealtimeMessage) {
    const user = this.sessions.get(ws);
    if (!user) return;

    user.lastSeen = Date.now();

    switch (message.type) {
      case 'cursor':
        user.cursor = message.payload;
        this.broadcast({
          type: 'cursor',
          userId: user.id,
          payload: { ...message.payload, color: user.color, name: user.name },
          timestamp: Date.now(),
        }, ws);
        break;

      case 'selection':
        user.selection = message.payload;
        this.broadcast({
          type: 'selection',
          userId: user.id,
          payload: { ...message.payload, color: user.color, name: user.name },
          timestamp: Date.now(),
        }, ws);
        break;

      case 'operation':
        const op = this.applyOperation(message.payload, user.id);
        if (op) {
          this.broadcast({
            type: 'operation',
            userId: user.id,
            payload: op,
            timestamp: Date.now(),
          }, ws);

          // Persist periodically
          if (this.document.version % 10 === 0) {
            await this.state.storage.put('document', this.document);
          }
        }
        break;

      case 'presence':
        this.broadcast({
          type: 'presence',
          userId: user.id,
          payload: { users: Array.from(this.document.users.values()) },
          timestamp: Date.now(),
        });
        break;
    }
  }

  private applyOperation(op: Partial<Operation>, userId: string): Operation | null {
    const operation: Operation = {
      type: op.type!,
      position: op.position!,
      text: op.text,
      length: op.length,
      userId,
      timestamp: Date.now(),
      version: ++this.document.version,
    };

    // Apply to document content
    const content = this.document.content;
    switch (operation.type) {
      case 'insert':
        this.document.content =
          content.slice(0, operation.position) +
          (operation.text || '') +
          content.slice(operation.position);
        break;

      case 'delete':
        this.document.content =
          content.slice(0, operation.position) +
          content.slice(operation.position + (operation.length || 0));
        break;

      case 'replace':
        this.document.content =
          content.slice(0, operation.position) +
          (operation.text || '') +
          content.slice(operation.position + (operation.length || 0));
        break;
    }

    // Keep operation history (last 100)
    this.document.operations.push(operation);
    if (this.document.operations.length > 100) {
      this.document.operations = this.document.operations.slice(-100);
    }

    return operation;
  }

  private broadcast(message: RealtimeMessage, exclude?: WebSocket) {
    const data = JSON.stringify(message);

    for (const [ws] of this.sessions) {
      if (ws !== exclude) {
        try {
          ws.send(data);
        } catch (e) {
          // WebSocket closed
        }
      }
    }
  }
}

/**
 * Operational Transform utilities
 */
export class OperationalTransform {
  /**
   * Transform operation against another operation
   */
  static transform(op1: Operation, op2: Operation): Operation {
    if (op1.timestamp >= op2.timestamp) {
      return op1; // No transform needed
    }

    const transformed = { ...op1 };

    // Adjust position based on op2
    if (op2.position <= op1.position) {
      if (op2.type === 'insert') {
        transformed.position += (op2.text?.length || 0);
      } else if (op2.type === 'delete') {
        transformed.position -= Math.min(op2.length || 0, op1.position - op2.position);
      }
    }

    return transformed;
  }

  /**
   * Transform array of operations
   */
  static transformAll(ops: Operation[], against: Operation): Operation[] {
    return ops.map(op => this.transform(op, against));
  }
}

/**
 * Client-side realtime connection manager
 */
export class RealtimeClient {
  private ws: WebSocket | null = null;
  private url: string;
  private userId: string;
  private userName: string;
  private handlers: Map<string, Function[]> = new Map();
  private reconnectAttempts = 0;
  private maxReconnects = 5;
  private pendingOperations: Operation[] = [];

  constructor(url: string, userId: string, userName: string) {
    this.url = url;
    this.userId = userId;
    this.userName = userName;
  }

  connect(): Promise<void> {
    return new Promise((resolve, reject) => {
      const wsUrl = `${this.url}?userId=${this.userId}&name=${encodeURIComponent(this.userName)}`;
      this.ws = new WebSocket(wsUrl);

      this.ws.onopen = () => {
        this.reconnectAttempts = 0;
        resolve();
      };

      this.ws.onmessage = (event) => {
        const message = JSON.parse(event.data);
        this.emit(message.type, message);
      };

      this.ws.onclose = () => {
        this.emit('disconnect', {});
        this.attemptReconnect();
      };

      this.ws.onerror = (error) => {
        reject(error);
      };
    });
  }

  disconnect() {
    if (this.ws) {
      this.ws.close();
      this.ws = null;
    }
  }

  // Send cursor position
  sendCursor(line: number, column: number) {
    this.send({
      type: 'cursor',
      userId: this.userId,
      payload: { line, column },
      timestamp: Date.now(),
    });
  }

  // Send selection
  sendSelection(startLine: number, startColumn: number, endLine: number, endColumn: number) {
    this.send({
      type: 'selection',
      userId: this.userId,
      payload: { startLine, startColumn, endLine, endColumn },
      timestamp: Date.now(),
    });
  }

  // Send operation
  sendOperation(type: 'insert' | 'delete' | 'replace', position: number, text?: string, length?: number) {
    const op: Partial<Operation> = { type, position, text, length };
    this.send({
      type: 'operation',
      userId: this.userId,
      payload: op,
      timestamp: Date.now(),
    });
  }

  // Request presence update
  requestPresence() {
    this.send({
      type: 'presence',
      userId: this.userId,
      payload: {},
      timestamp: Date.now(),
    });
  }

  // Event handling
  on(event: string, handler: Function) {
    if (!this.handlers.has(event)) {
      this.handlers.set(event, []);
    }
    this.handlers.get(event)!.push(handler);
  }

  off(event: string, handler: Function) {
    const handlers = this.handlers.get(event);
    if (handlers) {
      const index = handlers.indexOf(handler);
      if (index >= 0) handlers.splice(index, 1);
    }
  }

  private emit(event: string, data: any) {
    const handlers = this.handlers.get(event) || [];
    handlers.forEach(h => h(data));
  }

  private send(message: RealtimeMessage) {
    if (this.ws?.readyState === WebSocket.OPEN) {
      this.ws.send(JSON.stringify(message));
    } else {
      // Queue for when reconnected
      if (message.type === 'operation') {
        this.pendingOperations.push(message.payload);
      }
    }
  }

  private attemptReconnect() {
    if (this.reconnectAttempts < this.maxReconnects) {
      this.reconnectAttempts++;
      const delay = Math.min(1000 * Math.pow(2, this.reconnectAttempts), 30000);

      setTimeout(() => {
        this.connect().then(() => {
          // Replay pending operations
          for (const op of this.pendingOperations) {
            this.sendOperation(op.type, op.position, op.text, op.length);
          }
          this.pendingOperations = [];
        }).catch(() => {
          this.attemptReconnect();
        });
      }, delay);
    }
  }
}

/**
 * Presence indicator component data
 */
export interface PresenceData {
  users: User[];
  avatars: string[];
  colors: string[];
  names: string[];
}

export function buildPresenceData(users: User[]): PresenceData {
  return {
    users,
    avatars: users.map(u => u.name[0].toUpperCase()),
    colors: users.map(u => u.color),
    names: users.map(u => u.name),
  };
}

/**
 * Cursor overlay data
 */
export interface CursorOverlay {
  userId: string;
  name: string;
  color: string;
  line: number;
  column: number;
  visible: boolean;
}

export function buildCursorOverlays(users: User[]): CursorOverlay[] {
  return users
    .filter(u => u.cursor)
    .map(u => ({
      userId: u.id,
      name: u.name,
      color: u.color,
      line: u.cursor!.line,
      column: u.cursor!.column,
      visible: Date.now() - u.lastSeen < 30000, // Hide after 30s inactivity
    }));
}
